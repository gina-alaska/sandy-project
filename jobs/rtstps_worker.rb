require 'mixlib/shellout'

class RtstpsWorker < SandyWorker

  def command
    sat_xml = case File.basename(source_file).split(".").first
    when /^npp/
      'npp.xml'
    when /^a\D/
      'aqua.xml'
    when /^t\D/
      'terra.xml'
    else
      raise 'Unknown satellite type'
    end

    rthome = ENV['RTSTPS_HOME']

    "#{rthome}/bin/batch.sh #{rthome}/config/#{sat_xml} #{filename}"
  end

end
