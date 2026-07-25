# frozen_string_literal: true

module Baklib
  module ProjectRoot
    module_function

    def call
      ENV.fetch('BAKLIB_PROJECT_ROOT', Dir.pwd)
    end
  end
end
