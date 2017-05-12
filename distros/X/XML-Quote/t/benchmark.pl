#!/usr/bin/perl
# $Version: release/perl/base/XML-Quote/t/benchmark.pl,v 1.4 2003/01/25 13:17:41 godegisel Exp $
use strict;
use XML::Quote;
use Benchmark;
use utf8;

use vars qw(@TESTS_0 @TESTS_1);

@TESTS_0=(
'plain text without any special symbols',
q{some symbols & "" ''''><<},
44,
123.11,
'некий "тест >в <\'ютф8 &',
);

timethese(1_000_000,{
'xs quote'	=>	sub {
	my $res;
	for my $t (@TESTS_0)	{
		$res=xml_quote($t);
	}
},

'perl quote'	=>	sub {
	my $res;
	for my $t (@TESTS_0)	{
		$res=perl_quote($t);
	}
},

});

@TESTS_1=(
'plain text without any special symbols',
q{some symbols &amp; &quot;&quot; &apos;&apos;&apos; &gt; &lt;&lt;},
44,
123.11,
'некий &quot;тест &gt;в &lt;&apos;ютф8 &amp;',
);

timethese(1_000_000,{
'xs dequote'	=>	sub {
	my $res;
	for my $t (@TESTS_1)	{
		$res=xml_dequote($t);
	}
},

'perl dequote'	=>	sub {
	my $res;
	for my $t (@TESTS_1)	{
		$res=perl_dequote($t);
	}
},

});

sub perl_quote	{
	my $str=shift;

	$str=~s/&/&amp;/g;
	$str=~s/"/&quot;/g;
	$str=~s/'/&apos;/g;
	$str=~s/>/&gt;/g;
	$str=~s/</&lt;/g;

	return $str;
}

sub perl_dequote	{
	my $str=shift;

	$str=~s/&quot;/"/g;
	$str=~s/&apos;/'/g;
	$str=~s/&gt;/>/g;
	$str=~s/&lt;/</g;
	$str=~s/&amp;/&/g;

	return $str;
}
