#!perl -T

use strict;
use warnings;
use Test::More tests => 2;

use XML::Rules;

my $XML = '<root>
	<r id="1">ab</r>
	<r id="2"> cd</r>
	<r id="3">ef </r>
	<r id="4"> gh </r>
</root>';

my %good = (
	0 => { 1 => 'ab',	2 => ' cd',	3 => 'ef ',	4 => ' gh ', },
	8 => { 1 => 'ab',	2 => 'cd',	3 => 'ef',	4 => 'gh', },
);

use Data::Dumper;
for my $stripspaces (0,8) {
	my $parser = XML::Rules->new(
		stripspaces => $stripspaces,
		rules => [
			'r' => sub {$_[1]->{id} => $_[1]->{_content}},
			'root' => 'pass no content',
		],
	);
	my $data = $parser->parse($XML);

#	print "stripspaces => $stripspaces\n";
#	print Dumper($data);
#	print "\n\n";

	is_deeply( $data, $good{$stripspaces}, "stripspaces => " . ($stripspaces));

#exit if $stripspaces == 1;
}