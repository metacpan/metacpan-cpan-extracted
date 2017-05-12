#
# $Id: Build.PL,v 1.1 2003/12/24 13:04:15 james Exp $
#

use strict;
use warnings;

use Module::Build;

# if we don't have ithreads, this won't be pretty
use threads ();

# create the Buildfile
Module::Build->new(

    module_name          => 'Thread::App::Shutdown',

    dist_version         => '0.10',

    license              => 'perl',
    
    requires             => {
        perl              => '5.8.0',
    },
    
    build_requires       => {
        'Test::More'      => 0,
        'Test::Exception' => 0,
    },

    create_makefile_pl   => 'passthrough',

)->create_build_script;

#
# EOF
