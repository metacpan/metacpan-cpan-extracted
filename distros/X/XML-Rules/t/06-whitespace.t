#!perl -T

use strict;
use warnings;
use Test::More tests => 8;

use XML::Rules;

my $XML = '<root>
	<r id="1"> a <x></x>	b </r>
	<r id="2">  <x></x>  </r>
	<r id="3"> a <y></y>	b </r>
	<r id="4">  <y></y>  </r>
</root>';

my %good = (
	0+0 => { 1 => ' a 	b ',	2 => '    ',	3 => ' a y	b ',	4 => '  y  ', },
	0+4 => { 1 => ' a 	b ',	2 => '    ',	3 => ' a y	b ',	4 => '  y  ', },
	1+0 => { 1 => ' a 	b ',	2 => '  ',		3 => ' a y	b ',	4 => '  y  ', },
	1+4 => { 1 => ' a	b ',		2 => '  ',		3 => ' a y	b ', 	4 => '  y  ', },
	2+0 => { 1 => ' a 	b ',	2 => undef,		3 => ' a y	b ',	4 => '  y  ', },
	2+4 => { 1 => ' ab ',		2 => undef,		3 => ' a y	b ',	4 => '  y  ', },
	3+0 => { 1 => ' a 	b ',	2 => undef,		3 => ' a y	b ',	4 => 'y', },
	3+4 => { 1 => ' ab ',		2 => undef,		3 => ' ayb ',	4 => 'y', },
);

use Data::Dumper;
for my $stripspaces (0 .. 3) {
	for my $spaceonly (0,4) {
		my $parser = XML::Rules->new(
			stripspaces => $stripspaces+$spaceonly,
			rules => [
				'x' => sub {return},
				'y' => sub {return 'y'},
				'r' => sub {$_[1]->{id} => $_[1]->{_content}},
				'root' => 'pass no content',
			],
		);
		my $data = $parser->parse($XML);

#		print "stripspaces => $stripspaces+$spaceonly\n";
#		print Dumper($data);
#		print "\n\n";

		is_deeply( $data, $good{$stripspaces+$spaceonly}, "stripspaces => " . ($stripspaces+$spaceonly));

#exit if $stripspaces == 1;

	}
}