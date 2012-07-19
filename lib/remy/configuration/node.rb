class Remy::Configuration::Node
  extend Remy::Configuration

  def self.configure
    temp_config = Hashie::Mash.new
    yield temp_config
    @configuration = Hashie::Mash.new(JSON.parse(File.read(temp_config.json_file)))
  end
end