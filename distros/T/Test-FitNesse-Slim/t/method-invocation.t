#! perl

use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 11;

BEGIN {
  use_ok "Test::FitNesse::Slim::StatementExecutor"
    or BAIL_OUT "Cannnot use Test::FitNesse::Slim::StatementExecutor!";

  use_ok "Test::FitNesse::Slim::Statement"
    or BAIL_OUT "Cannnot use Test::FitNesse::Slim::Statement!";
}

my $executor;
my $test_slim;

sub test(&) {
  my($block) = @_;

  $executor = Test::FitNesse::Slim::StatementExecutor->new;
  $executor->create("test_slim", "Fitnesse::Slim::Test::TestSlim", []);
  $test_slim = $executor->instance("test_slim");

  $block->();
}

test {
  eval { $executor->call("test_slim", "no_args") };
  is($@, "", "can call a method with no arguments");
};

test {
  my $result = $executor->call("test_slim", "no_such_method");
  like($result, qr/\Q$Test::FitNesse::Slim::Statement::EXCEPTION_TAG\E
                   message:<<NO_METHOD_IN_CLASS  \s+
                   no_such_method\[0]            \s+
                   Fitnesse::Slim::Test::TestSlim>>/x,
    "can't call a method that doesn't exist");
};

test {
  is($executor->call("test_slim", "return_value"), "arg", "can call a method that returns a value");
};

TODO: {
  local $TODO = "FIXME";

  test {
    my $val = $executor->call("test_slim", "return_unicode_value");
    { use bytes;
      ok($val eq "Espa\357\277\275ol", "can call a method that returns a Unicode value");
    }
  };
}

test {
  eval { $executor->call("test_slim", "one_arg", "arg") };
  is($@, "", "can call a method that takes one argument");
};

test {
  my $result = eval { $executor->call("test_slim", "one_arg", qw/ 1 2 /) };
  is($@, "", "executor call should trap exceptions");
  like($result, qr/\Q$Test::FitNesse::Slim::Statement::EXCEPTION_TAG/,
    "exception in method should become SLiM exception");
};

test {
  my $result = $executor->call("no_such_instance", "no_such_method", "arg");
  like($result,
       qr/\Q$Test::FitNesse::Slim::Statement::EXCEPTION_TAG\E
          message:<<NO_INSTANCE  \s+  no_such_instance\.no_such_method\.>>/x,
       "can't call a method on an instance that doesn't exist");
};

test {
  $executor->set_symbol("v", "bob");
  is($executor->call("test_slim", "echo_string", 'hi $v.'), "hi bob.",
    "can replace symbol expressions with their values");
};

__END__
    it "can call a method on the @sut" do
      @test_slim.sut.should_receive(:sut_method).with()
      @executor.call("test_slim", "sut_method")
    end
  end

  context "Method invocations using fixture with no sut" do
    before do
      @executor.create("test_slim", "TestModule::TestSlimWithNoSut", []);
      @test_slim = @executor.instance("test_slim")
    end

    it "can't call method that doesn't exist if no 'sut' exists" do
      result = @executor.call("test_slim", "no_such_method")
      result.should include(Statement::EXCEPTION_TAG + "message:<<NO_METHOD_IN_CLASS no_such_method[0] TestModule::TestSlimWithNoSut.>>")
    end
  end

  context "Method invocations when library instances have been created." do
    before do
      @executor.create("library_old", "TestModule::LibraryOld", [])
      @executor.create("library_new", "TestModule::LibraryNew", [])
      @library_old = @executor.instance("library_old")
      @library_new = @executor.instance("library_new")
      @executor.create("test_slim", "TestModule::TestSlim", [])
      @test_slim = @executor.instance("test_slim")
    end

    it "should throw normal exception if no such method is found." do
      result = @executor.call("test_slim", "no_such_method")
      result.should include(Statement::EXCEPTION_TAG + "message:<<NO_METHOD_IN_CLASS no_such_method[0] TestModule::TestSlim.>>")
    end

    it "should still call normal methods in fixture" do
      @test_slim.should_receive(:no_args).with()
      @executor.call("test_slim", "no_args")
    end

    it "should still call methods on the sut" do
      @test_slim.sut.should_receive(:sut_method).with()
      @executor.call("test_slim", "sut_method")
    end

    it "should call a specific method on library_old" do
      @library_old.should_receive(:method_on_library_old).with()
      @executor.call("test_slim", "method_on_library_old")
    end

    it "should call a specific method on library_new" do
      @library_new.should_receive(:method_on_library_new).with()
      @executor.call("test_slim", "method_on_library_new")
    end

    it "should call method on library_new but not on library_old" do
      @library_new.should_receive(:a_method).with()
      @library_old.should_not_receive(:a_method).with()
      @executor.call("test_slim", "a_method")
    end
