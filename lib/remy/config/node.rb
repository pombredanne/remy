class Remy::Config::Node
  extend Remy::Config

  def self.configure
    temp_config = Hashie::Mash.new
    yield temp_config
    @config = Hashie::Mash.new(JSON.parse(File.read(temp_config.json_file)))
  end
end
