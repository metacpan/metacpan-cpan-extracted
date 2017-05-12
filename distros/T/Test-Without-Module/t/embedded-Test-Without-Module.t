#!D:\Programme\indigoperl-5.6\bin\perl.exe -w

use Test::More 'no_plan';

package Catch;

sub TIEHANDLE {
    my($class, $var) = @_;
    return bless { var => $var }, $class;
}

sub PRINT  {
    my($self) = shift;
    ${'main::'.$self->{var}} .= join '', @_;
}

sub OPEN  {}    # XXX Hackery in case the user redirects
sub CLOSE {}    # XXX STDERR/STDOUT.  This is not the behavior we want.

sub READ {}
sub READLINE {}
sub GETC {}
sub BINMODE {}

my $Original_File = 'D:lib\Test\Without\Module.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

SKIP: {
    # A header testing whether we find all prerequisites :
      # Check for module My::Module
  eval { require My::Module };
  skip "Need module My::Module to run this test", 1
    if $@;

  # Check for module Test::Without::Module
  eval { require Test::Without::Module };
  skip "Need module Test::Without::Module to run this test", 1
    if $@;


    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 109 lib/Test/Without/Module.pm

  use Test::Without::Module qw( My::Module );

  # Now, loading of My::Module fails :
  eval { require My::Module; };
  warn $@ if $@;

  # Now it works again
  eval q{ no Test::Without::Module qw( My::Module ) };
  eval { require My::Module; };
  print "Found My::Module" unless $@;

;

  }
};
is($@, '', "example from line 109");

};
SKIP: {
    # A header testing whether we find all prerequisites :
    
    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;

};
