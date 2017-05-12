#!/usr/bin/env perl
# Based on code from David Farrell article on compile tests.

use Test::More;
use lib 'lib';
use File::Find;

use strict;
use warnings;

# try to import every .pm file in /lib
find( { wanted => \&try_require, follow => 0, no_chdir => 1 }, 'lib' );

sub try_require
{
    my $file = $File::Find::name;
    return if -d $file || $file !~ /\.pm\z/;
    my $module = $file;
    $module =~ s!^lib/!!;
    $module =~ s/\.pm$//;
    $module =~ s!/!::!g;
    BAIL_OUT( "$module does not compile" ) unless require_ok( $module );
    return;
}
done_testing;
