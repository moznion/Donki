class Configure
  def initialize(filename)
    @config_file = filename
  end

  def parse
    begin
      JSON.parse(fetchConfigFile)
    rescue JSON::ParserError
      YAML.load(fetchConfigFile)
    end
  end

  def fetchConfigFile
    File.open(@config_file, :encoding => Encoding::UTF_8) { |file| file.read }
  end
  private :fetchConfigFile
end

