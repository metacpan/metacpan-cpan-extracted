#!/usr/local/perl/5.8.8/bin/perl -w

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

my $Original_File = 'lib/uny2k.pm';

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

#line 146 lib/uny2k.pm
use uny2k;
my $year = (localtime)[5];



    $full_year = $year + 1900;

    $two_digit_year = $year % 100;







;

  }
};
is($@, '', "example from line 146");

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 146 lib/uny2k.pm
use uny2k;
my $year = (localtime)[5];



    $full_year = $year + 1900;

    $two_digit_year = $year % 100;







my $real_year = (CORE::localtime)[5];
is( $full_year,      '19'.$real_year,   "undid + 1900 fix" );
is( $two_digit_year, $real_year,        "undid % 100 fix"  );

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

