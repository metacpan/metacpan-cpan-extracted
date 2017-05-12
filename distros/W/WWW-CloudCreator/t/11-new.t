use strict;
use warnings;

use Test::More no_plan => 1;
use Test::Group;

use Data::Dumper;

test 'compile and use' => sub {
	use_ok 'WWW::CloudCreator';
};

test 'empty cloud' => sub {
	my $cloud = WWW::CloudCreator->new();
	ok($cloud, 'WWW::CloudCreator object created');
	isa_ok($cloud, 'WWW::CloudCreator', 'WWW::CloudCreator obj ref match');
	my @weights = $cloud->gencloud;
	is_deeply(\@weights, [''], 'cloud results match -- good');
};

test 'almost empty cloud' => sub {
	my $cloud = WWW::CloudCreator->new();
	ok($cloud, 'WWW::CloudCreator object created');
	isa_ok($cloud, 'WWW::CloudCreator', 'WWW::CloudCreator obj ref match');
	ok( $cloud->add('friends', 40) );
	my @weights = $cloud->gencloud;
	is_deeply(\@weights, [[ 'friends', 1, 'font-size:8;' ],], 'cloud results match -- good');
};

test 'basic cloud' => sub {
	my $cloud = WWW::CloudCreator->new(
	  smallest => 8,
	  largest => 16,
	  cold => '000',
	  hot => '000',
	);
	ok($cloud, 'WWW::CloudCreator object created');
	isa_ok($cloud, 'WWW::CloudCreator', 'WWW::CloudCreator obj ref match');
	ok( $cloud->add('friends', 40) );
	ok(! $cloud->add('famiy', undef));
	ok(! $cloud->add(undef, undef));
	ok(! $cloud->add(undef, 123));
	$cloud->add('tech', 103);
	my @weights = $cloud->gencloud;
	is_deeply(\@weights, [
        [ 'friends', 40, 'color: #000;font-size: 8pt;' ],
        [ 'tech', 103, 'color: #000;font-size: 16pt;' ]
	], 'cloud results match -- good');
};

