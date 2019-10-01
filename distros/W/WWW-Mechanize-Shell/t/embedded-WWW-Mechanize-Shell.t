#!/opt/perl58/bin/perl -w

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

my $Original_File = 'lib/WWW/Mechanize/Shell.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

SKIP: {
    # A header testing whether we find all prerequisites :
      # Check for module WWW::Mechanize::Shell
  eval { require WWW::Mechanize::Shell };
  skip "Need module WWW::Mechanize::Shell to run this test", 1
    if $@;

  # Check for module strict
  eval { require strict };
  skip "Need module strict to run this test", 1
    if $@;


    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 33 lib/WWW/Mechanize/Shell.pm

  #!/usr/bin/perl -w
  use strict;
  use WWW::Mechanize::Shell;

  my $shell = WWW::Mechanize::Shell->new("shell");

  if (@ARGV) {
    $shell->source_file( @ARGV );
  } else {
    $shell->cmdloop;
  };




;

  }
};
is($@, '', "example from line 33");

};
SKIP: {
    # A header testing whether we find all prerequisites :
      # Check for module WWW::Mechanize::Shell
  eval { require WWW::Mechanize::Shell };
  skip "Need module WWW::Mechanize::Shell to run this test", 1
    if $@;

  # Check for module strict
  eval { require strict };
  skip "Need module strict to run this test", 1
    if $@;


    # The original POD test
    {
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 33 lib/WWW/Mechanize/Shell.pm

  #!/usr/bin/perl -w
  use strict;
  use WWW::Mechanize::Shell;

  my $shell = WWW::Mechanize::Shell->new("shell");

  if (@ARGV) {
    $shell->source_file( @ARGV );
  } else {
    $shell->cmdloop;
  };




  BEGIN {
    require WWW::Mechanize::Shell;
    $ENV{PERL_RL} = 0;
    $ENV{COLUMNS} = '80';
    $ENV{LINES} = '24';
  };
  BEGIN {
    no warnings 'once';
    no warnings 'redefine';
    *WWW::Mechanize::Shell::cmdloop = sub {};
    *WWW::Mechanize::Shell::display_user_warning = sub {};
    *WWW::Mechanize::Shell::source_file = sub {};
  };
  isa_ok( $shell, "WWW::Mechanize::Shell" );

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

};
SKIP: {
    # A header testing whether we find all prerequisites :

    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;

};
