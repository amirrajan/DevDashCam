class OverlayWindow < NSWindow
  def show
    @calibration_offset_x = -50
    @calibration_offset_y = 0
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
    self.setAlphaValue(1.0)
    self.setOpaque(false)
    process_gaze
    start_timer
  end

  def start_timer
    NSTimer.scheduledTimerWithTimeInterval(
      0.016,
      target: self,
      selector: 'tick',
      userInfo: nil,
      repeats: true
    )
  end

  def tick
    if @tick == 0
      NSThread.detachNewThreadSelector :process_gaze, toTarget: self, withObject: nil
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
    self.setFrameOrigin(NSMakePoint(next_x.to_i + @calibration_offset_x, next_y.to_i + @calibration_offset_y))
    @current_x = next_x
    @current_y = next_y
  end

  def process_gaze
    pid = NSProcessInfo.processInfo.processIdentifier
    pipe = NSPipe.pipe
    file = pipe.fileHandleForReading;
    task = NSTask.alloc.init
    task.launchPath = "/usr/local/bin/run-gaze-cli"
    task.standardOutput = pipe;
    task.launch
    data = file.readDataToEndOfFile
    file.closeFile
    output = NSString.alloc.initWithData(data, encoding: NSUTF8StringEncoding)
    x_ratio = output.split(',')[0].to_f
    y_ratio = output.split(',')[1].to_f
    if (x_ratio != 0 && y_ratio != 0)
      # 0, 0 is top left
      # 1, 1 is bottom right
      # 0, 1 is bottom left
      # 1, 0 is top right
      next_target_x = @screen_width * x_ratio
      next_target_y = @screen_height - (@screen_height * y_ratio)
      @target_x = next_target_x
      @target_y = next_target_y
      puts "#{x_ratio},#{y_ratio}"
      puts "#{@target_x},#{@target_y}"
      puts "#{@current_x},#{@current_y}"
    end


  end
end
