require 'usb'

  class Light
    VENDOR_ID = 0x0fc5
    PRODUCT_ID = 0xb080
    INTERFACE_ID = 0

    OFF = "\x00"

    # Primaries
    GREEN = "\x01"
    RED = "\x02"
    BLUE = "\x04"

    # Secondaries
    YELLOW = "\x03"
    CYAN = "\x05"
    MAGENTA = "\x06"

    # Stacks on
    WHITE = "\x07"

    def initialize number = 0
      @devices = USB.devices.select{|device| device.idVendor == VENDOR_ID && device.idProduct == PRODUCT_ID}
      @device = @devices.sort_by{|device| device.devnum}[number]
      raise "Unable to find device" unless @device
    end

    def green
      msg(GREEN)
    end

    def red
      msg(RED)
    end

	def blue
	  msg(BLUE)
	end

	def yellow
	  msg(YELLOW)
	end

	def cyan
	  msg(CYAN)
	end

	def magenta
	  msg(MAGENTA)
    end

	def white
	  msg(WHITE)
	end

    def off
      msg(OFF)
    end

    def close
      handle.release_interface(INTERFACE_ID)
      handle.usb_close
      @handle = nil
    end

  private
    def msg(data)
      handle.usb_control_msg(0x21, 0x09, 0x0635, 0x000, "\x65\x0C#{data}\xFF\x00\x00\x00\x00", 0)
    end

    def handle
      return @handle if @handle
      @handle = @device.usb_open
      begin
        # ruby-usb bug: the arity of rusb_detach_kernel_driver_np isn't defined correctly, it should only accept a single argument.
        if USB::DevHandle.instance_method(:usb_detach_kernel_driver_np).arity == 2
          @handle.usb_detach_kernel_driver_np(INTERFACE_ID, INTERFACE_ID)
        else
          @handle.usb_detach_kernel_driver_np(INTERFACE_ID)
        end
      rescue Errno::ENODATA => e
        # Already detached
      end
      @handle.set_configuration(@device.configurations.first)
      @handle.claim_interface(INTERFACE_ID)
      @handle
    end
  end
