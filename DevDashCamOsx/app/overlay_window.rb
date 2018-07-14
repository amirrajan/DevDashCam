class OverlayWindow < NSWindow
  def show
    $overlay = self
    @calibration_offset_x = -85
    @calibration_offset_y = -45
    @screen_width = 2560
    @screen_height = 1067
    @tick = 0
    @target_x = 0
    @target_y = 0
    @current_x = @screen_width.fdiv(2)
    @current_y = @screen_height.fdiv(2)
    @source = NSImage.alloc.initWithContentsOfFile("/Users/amiralirajan/Desktop/overlay.png")
    self.orderFrontRegardless
    self.setContentSize(@source.size)
    self.setBackgroundColor(NSColor.colorWithPatternImage(@source))
    self.setLevel(NSFloatingWindowLevel)
    self.contentView.setWantsLayer(false)
    self.setAlphaValue(0.8)
    self.setOpaque(false)
    start_daemon
    start_timer
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
    fileHandle = NSFileHandle.fileHandleForWritingAtPath '/Users/amiralirajan/Desktop/thegaze.log'
    fileHandle.seekToEndOfFile
    fileHandle.writeData "#{text}\n".dataUsingEncoding(NSUTF8StringEncoding)
    fileHandle.closeFile
  end

  def set_next_target
    data = @file.availableData
    if data.length > 0
      output = NSString.alloc.initWithData(data, encoding: NSUTF8StringEncoding)
      output = output.each_line.to_a.last
      x_ratio = output.split(',')[0].to_f
      y_ratio = output.split(',')[1].to_f
      # puts "output"
      # puts "#{x_ratio},#{y_ratio}"
      next_target_x = @screen_width * x_ratio
      cardinal_y = (@screen_height * y_ratio)
      next_target_y = @screen_height - cardinal_y

      if (@target_x - next_target_x).abs > 30 || (@target_y - next_target_y) > 30
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
