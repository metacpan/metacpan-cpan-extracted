#!perl
#
# This file is part of WWW-Shorten-SCK
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

BEGIN {
    unless ( $ENV{AUTHOR_TESTING} ) {
        print qq{1..0 # SKIP these tests are for testing by the author\n};
        exit;
    }
}

use strict;
use warnings;

use Test::Perl::Critic ( -profile => "xt/perlcritic.rc" )
    x !!-e "xt/perlcritic.rc";
all_critic_ok();
