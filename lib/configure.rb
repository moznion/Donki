# TODO correspond to YAML?
class Configure
  def initialize(filename)
    @config_file = filename
  end

  def parse
    JSON.parse(fetchConfigFile)
  end

  def fetchConfigFile
    File.open(@config_file, :encoding => Encoding::UTF_8) { |file| file.read }
  end
  private :fetchConfigFile
end

