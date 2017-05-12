#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use WWW::Fimfiction;

my $ua = WWW::Fimfiction->new;

my $story = eval{ $ua->get_story(6762) };

if($@ =~ /^Error: 503 Service Unavailable/) {
	plan skip_all => 'Fimfiction service currently unavailable';
}

is(
	$story->{id}, 
	6762,
	'ID as expected',
);

is(
	$story->{title}, 
	'To Catch a Stallion',
	'Title as expected',
);

done_testing;