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
    @monitor_index = 0
    @tick = 0
    @target_x = 0
    @target_y = 0
    @current_x = @screen_width.fdiv(2)
    @current_y = @screen_height.fdiv(2)
    @log_path     =  '~/.devdashcam/log'.stringByExpandingTildeInPath
    @config_path  =  '~/.devdashcam/config'.stringByExpandingTildeInPath
    @overlay_path =  '~/Desktop/overlay.png'.stringByExpandingTildeInPath
    @source = NSImage.alloc.initWithContentsOfFile(@overlay_path)
    @config_last_change_date = get_last_modified_for_file @config_path
    self.orderFrontRegardless
    self.setContentSize(@source.size)
    self.setBackgroundColor(NSColor.colorWithPatternImage(@source))
    self.setLevel(NSFloatingWindowLevel)
    self.contentView.setWantsLayer(false)
    self.setAlphaValue(@overlay_opacity)
    self.setOpaque(false)
    create_dev_dash_cam_directory
    write_default_config_file
    write_empty_log_file
    set_member_variables_from_config
    start_daemon
    start_timer
  end

  def default_config_text
    @default_config_text ||= <<-HEREDOC
# after you have calibrated, you may want to tweak the values
# from your eye tracker slightly.

# A negative `calibration-offset-x` will shift the overlay to
# the left (positive will shift it right) in pixels.
calibration-offset-x   -50

# The monitor index (if you have multiple monitors)
monitor-index 0

# A negative `calibration-offset-y` well shift the overlay down
# (positive will shift it up) in pixels.
calibration-offset-y   -75

# This value will increass or decrease the opacity of ther overlay.
overlay-opacity        0.8

# This is the path to the overlay png (make sure to use transparancies
# or you won't be able to click through the overlay.
overlay-path           ~/Desktop/overlay.png

# This value controls how sensitive the overlay is to eye movement (in pixels).
# If your eye moves slightly within the pixel threshold, the overlay will not move.
# I high number will make the overlay less sensitive to movement. A small value
# will make it more sensitive.
overlay-sensitivity    30

# This controls how quickly the overlay moves to the new location. A value of 1.0
# will move the overlay very quickly to the new location. A value of 0.01 will
# move the overlay more slowly to the new location.
overlay-speed          0.07

# This is the location of the log file for "all the things"
# Dev Dash Cam does.
log-file               ~/.devdashcam/log

# This represents the resolution of the main monitor the overlay is on.
screen-resolution      2560,1067
HEREDOC
  end

  def create_dev_dash_cam_directory
    root_directory = '~/.devdashcam'.stringByExpandingTildeInPath
    NSFileManager.defaultManager.createDirectoryAtPath(
      root_directory,
      attributes: {}
    )
  end

  def write_default_config_file overwrite = false
    file_exists = NSFileManager.defaultManager.fileExistsAtPath('~/.devdashcam/config'.stringByExpandingTildeInPath, nil)
    return if file_exists && overwrite == false

    content = default_config_text
    file_contents = content.dataUsingEncoding(NSUTF8StringEncoding)
    NSFileManager.defaultManager.createFileAtPath(
      @config_path,
      contents: file_contents,
      attributes: {}
    )
  end

  def write_empty_log_file
    file_contents = "".dataUsingEncoding(NSUTF8StringEncoding)
    NSFileManager.defaultManager.createFileAtPath(
      @log_path,
      contents: file_contents,
      attributes: {}
    )
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
      when "screen-resolution"
        @screen_width = config_value.split(',')[0].to_i
        @screen_height = config_value.split(',')[1].to_i
      when "overlay-path"
        @overlay_path = config_value.stringByExpandingTildeInPath
      when "monitor-index"
        @monitor_index = config_value.to_i
      end
    end

    @target_screen = NSScreen.screens[@monitor_index] || NSScreen.screens[0]

    puts "@calibration_offset_x: #{@calibration_offset_x}"
    puts "@calibration_offset_y: #{@calibration_offset_y}"
    puts "@overlay_opacity     : #{@overlay_opacity     }"
    puts "@overlay_path        : #{@overlay_path        }"
    puts "@screen_width        : #{@screen_width        }"
    puts "@screen_height       : #{@screen_height       }"
    puts "@monitor_index       : #{@monitor_index       }"
    puts "@target_screen       : #{@target_screen.frame.origin.x},#{@target_screen.frame.origin.y},#{@target_screen.frame.size.width},#{@target_screen.frame.size.height}"
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
      @last_overlay_path = @overlay_path
    end

    data = @file.availableData
    if data.length > 0
      output = NSString.alloc.initWithData(data, encoding: NSUTF8StringEncoding)
      output = output.each_line.to_a.last
      x_ratio = output.split(',')[0].to_f
      y_ratio = output.split(',')[1].to_f
      next_target_x = @target_screen.frame.size.width * x_ratio
      cardinal_y = (@target_screen.frame.size.height * y_ratio)
      next_target_y = @target_screen.frame.size.height - cardinal_y

      if (@target_x - next_target_x).abs > @overlay_sensitivity || (@target_y - next_target_y).abs > @overlay_sensitivity
        @target_x = @target_screen.frame.origin.x + next_target_x unless x_ratio == 0
        @target_y = @target_screen.frame.origin.y + next_target_y unless y_ratio == 0
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
