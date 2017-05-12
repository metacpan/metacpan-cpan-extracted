#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use Test::MockModule;

use YAML::LoadURI;
use FindBin qw/$Bin/;

my $mock = Test::MockModule->new('LWP::Simple');
$mock->mock(
    'get',
    sub ($) {
        open(my $fh, '<', "$Bin/META.yml");
        local $/;
        my $content = <$fh>;
        close($fh);
        return $content;
    }
);

my $hash = LoadURI( 'http://search.cpan.org/dist/WWW-Contact/META.yml' );
is $hash->{name}, 'libwww-perl';

1;