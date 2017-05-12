#!/usr/bin/perl -w
use strict;

use vars qw( @options );

BEGIN {
  @options = qw(
    autosync
    autorestart
    watchfiles
    cookiefile
    dumprequests
    dumpresponses
    verbose
    warnings
  );
};

use Test::More tests => scalar @options*4 +1+4;

SKIP: {
  BEGIN {
    $ENV{PERL_RL} = 0;
    use_ok('WWW::Mechanize::Shell');
  };

  my $s = WWW::Mechanize::Shell->new( 'test', rcfile => undef, warnings => undef );

  for my $option (@options) {
    my $oldval = $s->option($option);
    my $oldval2 = $s->option($option,"newvalue");
    is( $s->option($option), "newvalue", "Setting option '$option' via ->option()" );
    is( $oldval, $oldval2, "->option('$option','newvalue') returns the previous value");
    is( $s->option($option,$oldval2), "newvalue", "->option('$option','newvalue') returns the previous value (2)");
    is( $s->option($option), $oldval, "Setting option '$option' via ->option() (2)");
  };

  my $warned;
  no warnings 'redefine';
  local *Carp::carp = sub { $warned = $_[0] };
  my $res = $s->option('doesnotexist');
  is( $res, undef, "Nonexisting option returns undef");
  is( $warned, "Unknown option 'doesnotexist'", "Nonexisting option raises a warning");
  $res = $s->option('doesnotexist','newvalue');
  is( $res, undef, "Nonexisting option returns undef" );
  is( $warned, "Unknown option 'doesnotexist'","Nonexisting option raises a warning" );
};
