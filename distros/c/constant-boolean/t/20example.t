#!/usr/bin/perl

use strict;
use warnings;

use Carp ();

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More tests => 5;

eval q{
  use constant::boolean;

  use File::Spec;

  sub is_package_exist {
    my ($package) = @_;
    return FALSE unless defined $package;
    foreach my $inc (@INC) {
        my $filename = File::Spec->catfile(
            split( /\//, $inc ), split( /\::/, $package )
        ) . '.pm';
        return TRUE if -f $filename;
    };
    return FALSE;
  };
};

is( $@, '', 'compilation' );
ok( is_package_exist('constant::boolean'), "is_package_exist('constant::boolean')" );
ok( ! is_package_exist('constant::boolean::IHopeItDoesNotExist'), "! is_package_exist('constant::boolean::IHopeItDoesNotExist')" );
ok( ! is_package_exist(), "! is_package_exist()" );
isnt( prototype('is_package_exist'), '', 'is_package_exist() is not a constant' );
