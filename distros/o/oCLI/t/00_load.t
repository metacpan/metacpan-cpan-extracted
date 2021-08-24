#!/usr/bin/env perl
# 
# Ensure that each Perl module can be loaded without compilation errors.
use warnings;
use strict;
use Test::More;
use File::Find;

find(
    sub {
        return unless $_ =~ /\.pm$/;
        if ( $File::Find::name =~ m|(oCLI/.+?)$| ) {
            my $module = $1;
            $module =~ s/\.pm//;
            $module =~ s/\//::/g;
            use_ok( $module, "Module $module compiles." );
        }
    }, 'lib'
);

done_testing();
