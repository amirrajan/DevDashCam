class OverlayWindow < NSWindow
  def show
    $overlay = self
    @config = {}
    @calibration_offset_x = 0
    @calibration_offset_y = 0
    @screen_width = 2560
    @screen_height = 1067
    @overlay_opacity = 0.8
    @overlay_sensitivity = 30
    @tick = 0
    @target_x = 0
    @target_y = 0
    @current_x = @screen_width.fdiv(2)
    @current_y = @screen_height.fdiv(2)
    @log_path =  '~/.devdashcam/log'.stringByExpandingTildeInPath
    @config_path = "~/.devdashcam/config".stringByExpandingTildeInPath
    @overlay_path = '~/Desktop/overlay.png'.stringByExpandingTildeInPath
    @source = NSImage.alloc.initWithContentsOfFile(@overlay_path)
    @config_last_change_date = get_last_modified_for_file @config_path
    self.orderFrontRegardless
    self.setContentSize(@source.size)
    self.setBackgroundColor(NSColor.colorWithPatternImage(@source))
    self.setLevel(NSFloatingWindowLevel)
    self.contentView.setWantsLayer(false)
    self.setAlphaValue(@overlay_opacity)
    self.setOpaque(false)
    start_daemon
    start_timer
  end

  def set_member_variables_from_config
    content = NSString.stringWithContentsOfFile(@config_path, encoding: NSUTF8StringEncoding, error: nil)
    content.each_line do |l|
      tokens = l.split(' ').map { |t| t.strip }
      config_name = tokens[0]
      config_value = tokens[1]
      case config_name
      when "calibration-offset-x"
        @calibration_offset_x = config_value.to_f
      when "calibration-offset-y"
        @calibration_offset_y = config_value.to_f
      when "overlay-opacity"
        @overlay_opacity = config_value.to_f
      when "screen_resolution"
        @screen_width = config_value.split(',')[0].to_i
        @screen_height = config_value.split(',')[1].to_i
      when "overlay-path"
        @overlay_path = config_value.stringByExpandingTildeInPath
      end
    end

    puts @calibration_offset_x
    puts @calibration_offset_y
    puts @overlay_opacity
    puts @overlay_path
    puts @screen_width
    puts @screen_height
  end

  def get_last_modified_for_file file
    file_url = NSURL.fileURLWithPath(file.stringByExpandingTildeInPath);
    file_date = Pointer.new(:object)
    file_url.getResourceValue(file_date, forKey: NSURLContentModificationDateKey, error: nil);
    file_date[0]
  end

  def start_timer
    NSTimer.scheduledTimerWithTimeInterval(
      0.008,
      target: self,
      selector: 'tick',
      userInfo: nil,
      repeats: true
    )
  end

  def tick
    if @tick == 0
      NSThread.detachNewThreadSelector :set_next_target,
                                       toTarget: self,
                                       withObject: nil
    end

    @tick += 1

    if @tick == 30
      @tick = 0
    end

    performSelectorOnMainThread 'move_view',
                                withObject: self,
                                waitUntilDone: true
  end

  def move_view
    next_x = @current_x - ((@current_x - @target_x) * 0.07)
    next_y = @current_y - ((@current_y - @target_y) * 0.07)
    self.setFrameOrigin(
      NSMakePoint(next_x.to_i + @calibration_offset_x,
                  next_y.to_i + @calibration_offset_y))
    @current_x = next_x
    @current_y = next_y
  end

  def write_gaze_to_file text
    fileHandle = NSFileHandle.fileHandleForWritingAtPath @log_path
    fileHandle.seekToEndOfFile
    fileHandle.writeData "#{text}\n".dataUsingEncoding(NSUTF8StringEncoding)
    fileHandle.closeFile
  end

  def set_next_target
    self.setAlphaValue(@overlay_opacity)

    if @config_last_change_date != get_last_modified_for_file(@config_path)
      @config_last_change_date = get_last_modified_for_file @config_path
      set_member_variables_from_config
    end

    if @last_overlay_path != @overlay_path
      @source = NSImage.alloc.initWithContentsOfFile(@overlay_path)
      self.orderFrontRegardless
      self.setContentSize(@source.size)
      self.setBackgroundColor(NSColor.colorWithPatternImage(@source))
    end

    data = @file.availableData
    if data.length > 0
      output = NSString.alloc.initWithData(data, encoding: NSUTF8StringEncoding)
      output = output.each_line.to_a.last
      x_ratio = output.split(',')[0].to_f
      y_ratio = output.split(',')[1].to_f
      next_target_x = @screen_width * x_ratio
      cardinal_y = (@screen_height * y_ratio)
      next_target_y = @screen_height - cardinal_y

      if (@target_x - next_target_x).abs > @overlay_sensitivity || (@target_y - next_target_y) > @overlay_sensitivity
        @target_x = next_target_x unless x_ratio == 0
        @target_y = next_target_y unless y_ratio == 0
        write_gaze_to_file "#{next_target_x},#{cardinal_y}"
      end
    end

    @file.waitForDataInBackgroundAndNotify
  end

  def start_daemon
    @pipe = NSPipe.pipe
    @file = @pipe.fileHandleForReading;
    @task = NSTask.alloc.init
    @task.launchPath = "/usr/local/bin/run-gaze-cli"
    @task.standardOutput = @pipe;
    @task.launch
    @file.waitForDataInBackgroundAndNotify
  end
end
