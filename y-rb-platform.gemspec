# frozen_string_literal: true

# Builds a PREBUILT, binary (platform) gem: the compiled ext (lib/yrb.bundle)
# is packaged directly and `extensions` is empty, so `bundle install` never
# invokes Rust — it just drops the binary in. Set GEM_PLATFORM to the generic
# Ruby platform (e.g. arm64-darwin, x86_64-linux-gnu), NOT Gem::Platform.local,
# which on macOS bakes in the Darwin OS version and only matches that release.
# The compiled lib/yrb.bundle must already exist (via `rake compile`) for the
# host this spec is built on.
require_relative "lib/y/version"

Gem::Specification.new do |spec|
  spec.name = "y-rb"
  spec.version = Y::VERSION
  spec.platform = ENV.fetch("GEM_PLATFORM")
  spec.authors = ["Hannes Moser"]
  spec.email = %w[hmoser@gitlab.com box@hannesmoser.at]

  spec.summary = "Ruby bindings for yrs"
  spec.description = "Ruby bindings for yrs. Yrs \"wires\" is a Rust port of the Yjs framework."
  spec.homepage = "https://github.com/y-crdt/yrb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  # The compiled ext is yrb.bundle on macOS, yrb.so on Linux — glob both so this
  # one spec builds a correct binary gem on either host.
  spec.files = Dir["lib/**/*.rb"] + Dir["lib/**/*.{bundle,so}"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rake", "~> 13.2"
  spec.add_dependency "rb_sys", "~> 0.9.110"
end
