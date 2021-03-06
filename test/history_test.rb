require File.join(File.dirname(__FILE__), 'test_helper')
require 'fileutils'

HISTORY_FILE = File.dirname(__FILE__) + '/ripl_history'

describe "History with readline" do
  def shell
    Ripl.shell(:history => HISTORY_FILE, :readline => false, :completion => false)
  end

  before_all { reset_shell }
  before do
    reset_ripl
    if defined? Readline
      1.upto(Readline::HISTORY.size) { Readline::HISTORY.shift }
    end
  end
  after { FileUtils.rm_f HISTORY_FILE }

  it "#after_loop saves history" do
    inputs = %w{blih blah}
    shell.instance_variable_set '@history', inputs
    shell.after_loop
    File.read(HISTORY_FILE).should == inputs.join("\n")
  end

  it "#before_loop loads previous history" do
    File.open(HISTORY_FILE, 'w') {|f| f.write "check\nthe\nmike" }
    stub(Ripl::Runner).load_rc
    shell.before_loop
    shell.history.to_a.should == %w{check the mike}
  end

  it "#before_loop has empty history if no history file exists" do
    stub(Ripl::Runner).load_rc
    shell.before_loop
    shell.history.to_a.should == []
  end

  it "#write_history is accessible to plugins in #after_loop" do
    mod = Object.const_set "Ping_write_history", Module.new
    mod.send(:define_method, 'write_history') { @history = ['pong_write_history'] }
    Shell.send :include, mod
    shell.after_loop
    shell.history.should == ['pong_write_history']
  end
end
