#!/usr/bin/perl
# $Id: test.t 1932 2008-02-15 10:48:29Z guillomovitch $

use strict;
use File::Temp qw/tempdir/;
use Test::More tests => 3;
use Test::Exception;

BEGIN {
    use_ok('Youri::Config');
}

my $dir = tempdir(CLEANUP => $ENV{TEST_DEBUG} ? 0 : 1);

create_configuration_file($dir . '/invalid', <<'EOF');
key: value
keys:
	- value1
	- value2
EOF

throws_ok {
    Youri::Config->new(
        directories => [ $dir ],
        file        => 'invalid',
    );
} qr/^Invalid configuration file/,
'invalid configuration file';

create_configuration_file($dir . '/valid', <<EOF);
key: value
keys:
        - value1
        - value2
EOF

lives_ok {
    Youri::Config->new(
        directories => [ $dir ],
        file        => 'valid',
    );
} 'valid configuration file';

sub create_configuration_file {
    my ($file, $content) = @_;

    open (my $fh, '>', $file) or die "unable to create file $file: $!";
    print $fh $content;
    close $fh;
}
