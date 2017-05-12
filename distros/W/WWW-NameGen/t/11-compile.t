#!perl -T

use Test::More tests => 14;
use Test::Deep;

use_ok( 'WWW::NameGen' );

diag( "Testing WWW::NameGen $WWW::NameGen::VERSION, Perl $], $^X" );

my ($namegen, @chunks);

{
	$namegen = WWW::NameGen->new();
	ok($namegen, 'WWW::NameGen object created');
	isa_ok($namegen, 'WWW::NameGen', 'WWW::NameGen object ref match');
}

{
	my @names = $namegen->generate();
	is(scalar @names, 10, '@names count good - 10');
}

{
	my @names = $namegen->generate( min => 20, nocache => 1);
	is(scalar @names, 20, '@names count good - 20');
}

SKIP: {
	skip 'No need to test this', 1;
	my @names = $namegen->generate( min => 7000, nocache => 1);
	is(scalar @names, 2500, '@names max - 7000');
}

{
	my @names = $namegen->generate( min => 100, nocache => 1);
	is(scalar @names, 100, '@names count good - 100');
	my @othernames = $namegen->generate( min => 100);
	cmp_deeply(\@names, \@othernames, 'caching tests - good');
	is($names[0], $othernames[0], 'more caching tests - good')
}

SKIP: {
	skip 'No need to test this', 4;
	@chunks = $namegen->get_chunks(300);
	$count = 0; map { $count += $_ } @chunks;
	is($count, 300, 'get_chunk count 300 - good');

	@chunks = $namegen->get_chunks(5000);
	$count = 0; map { $count += $_ } @chunks;
	is($count, 5000, 'get_chunk count 5000 - good');

	@chunks = $namegen->get_chunks(9871);
	$count = 0; map { $count += $_ } @chunks;
	is($count, 9871, 'get_chunk count 9871 - good');

	@chunks = $namegen->get_chunks(11210);
	$count = 0; map { $count += $_ } @chunks;
	is($count, 11210, 'get_chunk count 11210 - good');
}

SKIP: {
	skip 'this test is silly', 1;
	my @names = $namegen->generate( min => 2_000_000_000);
	is(scalar @names, 2_000_000_000, '@names count good - 2_000_000_000');
}