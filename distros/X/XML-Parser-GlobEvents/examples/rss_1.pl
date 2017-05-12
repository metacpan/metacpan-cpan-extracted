#!/usr/bin/perl -w
#
# Display a text version from the RSS feed on http://search.cpan.org/uploads.rdf
# using node tree
#

use lib '../lib';
use XML::Parser::GlobEvents;

use LWP::Simple;
my $url = 'http://search.cpan.org/uploads.rdf';
my $xml = get($url);

print $xml if @ARGV;
binmode select, ':crlf:utf8';

XML::Parser::GlobEvents::parse(\$xml,
    'item' => sub {
        my($node) = @_;
        # use Data::Dumper; print Dumper $node;
        $node->{description}{-text} ||= '[no description]';
	    print <<"ITEM";
$node->{title}{-text} ($node->{'dc:creator'}{-text}): $node->{description}{-text}
ITEM
    }
);





