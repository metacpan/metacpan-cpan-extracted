#!perl -T

# $Id: 02-cache.t 34 2013-03-14 14:51:02Z sysdef $

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    ok(
        eval {
            my $username;
            eval { $username = $ENV{LOGNAME} || $ENV{USER} || getpwuid($<); };
            my $cache_dir = '/var/cache/www-klicktel-api/';

            # create cache directory
            if ( $username ne 'root' ) {
                $cache_dir = '/home/' . $username . '/.klicktel/cache/';
                mkdir '/home/' . $username . '/.klicktel'
                    if !-d '/home/' . $username . '/.klicktel';
            }
            if ( !-d $cache_dir ) {
                mkdir $cache_dir
                    or BAIL_OUT("cannot create cache dir '$cache_dir': $!");
                chmod '0111', $cache_dir
                    or BAIL_OUT("cannot chmod cache dir '$cache_dir': $!");
            }
            return 1 if -w $cache_dir;
            return 0;
        },
        "creating and testing cache directory"
    );

}
