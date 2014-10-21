require 'rspec'
$:.unshift( File.join( File.dirname( __FILE__), '..', 'lib' ) )
require 'bernstein'

RSpec.configure do |c|
  c.mock_with :rspec
end

Bernstein.configure!

include Bernstein::States

def expect_state(something, state)
  expect(something).to eq(STATES[state])
end
