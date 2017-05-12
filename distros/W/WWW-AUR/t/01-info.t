#!/usr/bin/perl

use warnings 'FATAL' => 'all';
use strict;
use Test::More;

use_ok 'WWW::AUR::RPC';

my $name = 'yaourt';
ok my $info = WWW::AUR::RPC::info( $name );
is $info->{ name }, $name;

my @VALID_FIELDS = qw{ id name version category desc url urlpath
                       license votes outdated };

for my $field ( @VALID_FIELDS ) {
    ok exists $info->{ $field }, qq{info contains "$field" field};
}

is $info->{packagebase}, $name, 'packagebase was converted to its name';

done_testing();

