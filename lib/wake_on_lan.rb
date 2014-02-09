require 'json'
require 'mac_address'
require 'ipaddress'
require 'terminal-table'
require 'colorize'
require 'socket'

class WakeOnLan 
  FILE_PATH = File.expand_path("~/.wakeOnLan")
  
  def initialize
      @command_or_device_name = ARGV.shift
  end
  
  def exec 
    case (@command_or_device_name || '').downcase
    when 'register'
      register_device
    when 'remove'
      remove_device
    when 'list'
      list_devices
    when 'status'
      query_devices
    when 'help', '--help', ''
      display_help
    else
      wake_device(@command_or_device_name)
    end 
  end
    
  def display_help 
    puts "Wake - Wakes a device over LAN"
    puts " Usage: wake <device-name>"
    puts "             register <mac> <ip> <name>"
    puts "             remove <name>"
    puts "             list"
    puts "             status [<name>]"
    puts "             help"
  end
  
  def register_device
    # Expected params -> mac, ip, name
    if(ARGV.size < 3) 
      puts "Failed:".red << " Incorrect usage."
      display_help
      exit 1
    else
      mac  = ARGV.shift
      ip   = ARGV.shift
      name = ARGV.join(' ')
      unless mac.valid_mac? 
        puts "Failed: ".red << "Mac address supplied was not in a correct format."
        display_help
        exit 1
      end
      unless IPAddress.valid?(ip)
        puts "Failed: ".red << "IP address supplied was not in a correct format."
        register_device
        exit 1
      end
      name.strip!
      unless name.size > 0
        puts "Failed: ".red << "You must provide a name to the new device."
        register_device
        exit 1
      end
      load_devices_list
      device = { 
          name: name,
          mac: mac,
          ip: ip
      }
      if get_device_by_mac(mac)
        puts "Failed: ".red <<  "MAC Address #{mac} is already belongs to '#{get_device_by_mac(mac)['name']}'"
        exit 1
      elsif get_device_by_ip(ip)
        puts "Failed: ".red <<  "IP Address #{ip} is already belongs to '#{get_device_by_ip(ip)['name']}'"
        exit 1
      elsif get_device_by_name(name)
        puts "Failed: ".red << "Another device is already registered with the given name."
        exit 1
      else
        @devices << device
        if flush_devices_list
          puts "Success: ".green << "Registered device '#{name}' with MAC Address #{mac} and IP #{ip}"
          exit 0
        else
          puts "Failed: ".red << "Unable to register device. Try again."
          exit 1
        end
      end
    end
  end
  
  def remove_device
    if(ARGV.size < 1)
      puts "Failed: ".red << "Incorrect usage."
      display_help
      exit 1
    else 
      load_devices_list
      name = ARGV.join(' ')
      device = get_device_by_name(name)
      unless device
        puts "Failed: ".red << "Unknown device '#{name}'."
        puts "Use " << "wake list".green << " to get a list of registered devices."
        exit 1
      else
        index = _get_device({ return_as_index: true }) { |device| device['name'].downcase == name.downcase}
        @devices.delete_at(index)
        if flush_devices_list
          puts "Success: ".green << "Device '#{name}' has been removed."
          exit 0
        else 
          puts "Failed: ".red << "Unable to remove device. Try again."
          exit 1
        end
      end
    end
  end
  
  def list_devices
    load_devices_list
    if(@devices.size < 1) 
      puts "Whoa! ".blue << "The device list seems to be empty."
      puts "Start adding new devices using " << "wake register <mac> <ip> <name>".green
    else
      table = Terminal::Table.new headings: ['Name', 'MAC Address', 'IP Address'] do |t|
        @devices.each do |device| 
          t << [device['name'], device['mac'], device['ip']]
        end
      end
      puts table
    end
    exit 0
  end
  
  def query_devices
    load_devices_list
    if(@devices.size < 1) 
      puts "Whoa! ".red << "The device list seems to be empty."
      puts "Start adding new devices using " << "wake register <mac> <ip> <name>".green
    else
      puts "Querying devices..."
      devices = @devices.clone
      status = []
      table = Terminal::Table.new headings: ['Name', 'MAC Address', 'IP Address', 'Status'] do |t|
        devices.each do |device|
          status = is_device_up?(device['ip']) ? ":D".green : ":(".red
          t << [device['name'], device['mac'], device['ip'], status]
        end
      end
      puts table
    end
  end
  
  def wake_device(name_begin)
    name = "#{name_begin}"
    if ARGV.size > 0
      name << " "
      name << ARGV.join(' ')
    end
    load_devices_list
    device = get_device_by_name(name)
    unless device
      puts "Failed: ".red << "Unknown device #{name}."
      puts "Use " << "wake list".green << " to see a list of registered devices"
      exit 1
    else
      if is_device_up?(device['ip']) 
        puts "Okay: ".green << "Device #{name} is already up."
      else
        print "Waking up #{name}... "
        begin
          socket = UDPSocket.open()
          socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, 1)
          magicpacket = (0xff.chr)*6+(device['mac'].split(/:/).pack("H*H*H*H*H*H*"))*16
          socket.send(magicpacket, 0, "255.255.255.255", 9);
          socket.close
          socket = nil;
        rescue Exception => ex
          puts "Error".red
          puts "Exception: ".red << ex.message
          exit 1
        end
        puts "OK".green
      end
      exit 0
    end
  end
  private
  def load_devices_list
    result = []
    if(File.exists?(FILE_PATH)) 
      raw_json = File.read(FILE_PATH)
      begin
        result = JSON.parse(raw_json)
      rescue Exception => e
      end
    end
    
    @devices = result
  end
  
  def flush_devices_list 
    return false unless @devices 
    result = JSON.generate(@devices)
    begin
      open(FILE_PATH, 'w') { |file| file.puts(result) }
    rescue Exception => e
      return false
    end
    return true
  end
  def get_device_by_mac(mac)
    _get_device { |item| item['mac'].downcase == mac }
  end
  def get_device_by_ip(ip) 
    _get_device { |item| item['ip'].downcase == ip }
  end
  def get_device_by_name(name) 
    _get_device { |item| item['name'].downcase == name.downcase }
  end
  def is_device_up?(ip) 
    result = `ping -t 1 -q -c 1 #{ip}`
    $?.exitstatus == 0
  end
  def _get_device(options={})
    return_index = options.has_key?(:return_as_index) ? options[:return_as_index] : false
    
    raise "Unable to call _get_device without a block." unless block_given?
    index = @devices.index { |item| yield(item) }
    return false unless index
    (return_index ? index : @devices[index])
  end
end