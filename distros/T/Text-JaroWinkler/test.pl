#!/usr/bin/perl

use Test;
BEGIN { plan tests => 12 };
use Text::JaroWinkler qw(strcmp95);

sub call { sprintf('%.6f', strcmp95(@_)) }

ok( call("it is a dog","i am a dog.",11),
	'0.865620');

{
    my $str1 = 'Economic development of the last 20 years has brought people' .
	' surging into the cities to supply industrial manpower.';
    my $str2 = 'Republic of China on Taiwan, as a result of rapid economic' .
	' growth, a large number of rural population into cities.';

    ok( call($str1, $str2, 115), '0.838679' );
    ok( call($str1, $str2, 115, HIGH_PROB => 1), '0.735708' );
    ok( call($str1, $str2, 115, HIGH_PROB => 1, TOUPPER => 1), '0.701805' );
    ok( call($str1, $str2, 115, TOUPPER => 1),   '0.816694' );
}

{
    my $str1 = 'The new high-rise buildings must pass rigid safety inspections.' .
	' Slums are wiped out as fast as new housing can be constructed.';
    my $str2 = 'Now the urban high-rise buildings mushroomed, the public safety' .
	' into account, according to building codes, the implementation of' .
	' strict security checks.';
    my $str3 = ' The new high-rise buildings must pass rigid safety inspections.' .
	' Slums are wiped out as fast as new housing can be constructed.';

    ok( call($str1, $str2, 152), '0.843037' );
    ok( call($str1, $str2, 152, HIGH_PROB => 1), '0.738396' );
    ok( call($str1, $str2, 152, HIGH_PROB => 1, TOUPPER => 1), '0.729410' );
    ok( call($str1, $str2, 152, TOUPPER => 1),   '0.836680' );

    ok( call($str1, $str2, 152), call($str2, $str1, 152) );
    ok( call($str1, $str2, 152), call($str3, $str2, 152) );
    ok( call($str1, $str2, 152), call($str2, $str3, 152) );
}

1;
