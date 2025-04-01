#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;
use Cwd;

BEGIN {
    unshift @INC, map { /(.*)/; $1 } split( /:/, $ENV{PERL5LIB} ) if defined $ENV{PERL5LIB} and ${^TAINT};
    my $cwd = ${^TAINT} ? do { local $_ = getcwd; /(.*)/; $1 } : '.';
    unshift @INC, File::Spec->catdir( $cwd, 'inc' );
    unshift @INC, File::Spec->catdir( $cwd, 'lib' );
    unshift @INC, File::Spec->catdir( $cwd, 't/tlib' );
}

use Carp ();

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More tests => 3;

ok(
  not (
    # must use string eval
    eval "use all::mandatory 'all::mandatory::Test4::'; 1;"
  ),
  'all:mandatory raises error if module cannot be loaded (Test4/Test1.pm)' . " (message: $@)"
);

ok(
  not (
    # must use string eval
    eval "use all::mandatory 'all::mandatory'; 1;"
  ),
  'all:mandatory raises error if a module cannot be loaded (Test4.pm)' . " (message: $@)"
);

ok(
  not (
    # must use string eval
    eval "use all::mandatory 'all::mandatory::DoesNotExist'; 1;"
  ),
  'all:mandatory raises error if no modules under a namespace exist' . " (message: $@)"
);
