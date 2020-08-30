# frozen_string_literal: true

require 'yaml'

module N65
  OpCodes = YAML.load_file(File.join(__dir__, '../../data/opcodes.yaml'))
end
