#!/usr/bin/perl5.8.4 -w

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

my $Original_File = 'lib/Test/Numeric.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 42 lib/Test/Numeric.pm
use Test::Numeric;



 is_number   '12.34e56',  "valid number";
 is_number   '-12.34E56', "valid number";
 isnt_number 'test',      "not a number";

 is_even 2, "an even number";
 is_odd  3, "an odd number";
 
 is_integer   '123',    'an integer';
 isnt_integer '123.45', 'not an integer';
 
 is_formatted   '1-.2', '123.45';
 isnt_formatted '1-.2', '123.4';

;

  }
};
is($@, '', "example from line 42");

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

