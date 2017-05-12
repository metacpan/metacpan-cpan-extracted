#!perl -T

use strict;
use warnings;
use Test::More tests => 5;

use XML::Tiny::Simple qw(parsestring);
my $doc = parsestring(*DATA);

#~ use Data::Dumper; is( Dumper($doc), '?', '?');
is(ref $doc, 'HASH', 'ref($doc) is HASH');
is($doc->{root}->{branch}->{second}->{leaf}->[0]->{flower}, "false", "access tag");
is($doc->{root}->{branch}->{second}->{leaf}->[0]->{content}, "a dead leaf", "access content");
is($doc->{root}->{branch}->{first}->{name}, "first", "access attribut");
is($doc->{root}->{branch}->{first}->{tag}, "branch", "access tag's name");


__DATA__
<?xml version="1.0" encoding="utf-8" ?>
<root>
	<branch name="first"/>
	<branch name="second">
		<leaf flower="false">a dead leaf</leaf>
		<leaf flower="true">another leaf</leaf>
	</branch>
</root>