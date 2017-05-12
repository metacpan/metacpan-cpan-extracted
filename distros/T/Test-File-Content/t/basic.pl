#
# This file is part of Test-File-Content
#
# This software is Copyright (c) 2012 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
use Test::File::Content;
use Test::More;
use strict;
use warnings;

my $config = {
    tt => {},
    js  => {
        'console.log' => 'console.log',
    },
    pm => 'make_immutable',
};

content_unlike($config, qw(t/));

content_like( pm => 'make_immutable', qw(lib t) );

content_like( ['pm'] => 'make_immutable', qw(lib t));

content_like( [qr/pm/] => 'make_immutable', qw(lib t));

content_like( [qr/pm/, qr/js/] => 'make_immutable', qw(lib t));

content_like( sub { return 1 } => 'make_immutable', 't/code');

done_testing;