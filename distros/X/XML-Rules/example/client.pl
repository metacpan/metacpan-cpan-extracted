use strict;
use XML::Rules;

my $parser = XML::Rules->new(
	start_rules => [
		'^division_name,fax' => 'skip',
	],
	rules => [
		_default => 'content trim',
		ClientData => sub {
			print OUT ( "$_[1]->{client_desc}($_[1]->{branch_ref_no}/$_[1]->{client_no}): $_[1]->{address}, $_[1]->{city}, $_[1]->{state}, $_[1]->{country}\n"); return}
	]
);

sub do_parse {
	$parser->parsefile($ARGV[0] || 'Client.xml')
}

use Benchmark;
timethese( 3, {
 'parse' => \&do_parse,
}
);