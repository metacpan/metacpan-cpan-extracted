#!perl

use Test::More tests => 2;

BEGIN {
    use_ok( 'Wx::Perl::Packager' );
}

my $good = 'os ok';
my $bad = 'Your operating system is not supported by Wx::Perl::Packager';

my $result = ( $^O =~ /^(mswin|darwin|linux)/i ) ? $good : $bad;

is( $result, $good, 'Check Operating System Supported');

1;
