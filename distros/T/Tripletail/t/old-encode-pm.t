#!perl
use strict;
use warnings;
use File::Spec;
use Test::More tests => 1;

use t::make_ini {
    ini => {
        TL => {
            stacktrace => 'full',
            trap       => 'diewithprint'
           }
       }
};
use Tripletail $t::make_ini::INI_FILE;

$TL->trapError(
    -main => sub {
        $TL->newTemplate(File::Spec->devnull());
        pass q{`use Encode' doesn't clash with our custom __DIE__ handler};
    });
