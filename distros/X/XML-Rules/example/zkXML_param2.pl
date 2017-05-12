use strict;
use warnings;

use XML::Rules;

my $xml = <<XML;
<config>
<param name="SequenceNumber">66</param>
<param name="T1">6</param>
<param name="T3">6</param>
<param name="T4">540</param>
<param name="DownloadDate">11-28-07</param>
</config>
XML

my $parser = XML::Rules->new(
	rules => [
		param => sub {$_[1]->{name} => $_[1]->{_content}},
		config => 'pass no content',
	],
);
my $tree = $parser->parse($xml);

use Data::Dumper;
print Dumper($tree);

print "The download date was $tree->{DownloadDate}\n";
