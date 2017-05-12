#!/usr/bin/perl -w
#
# Display a text version from the RSS feed on http://search.cpan.org/uploads.rdf
# using external hash to collect the item data
#
use lib '../lib';
use XML::Parser::GlobEvents;

use LWP::Simple;
my $url = 'http://search.cpan.org/uploads.rdf';
my $xml = get($url);

print $xml if @ARGV;
binmode select, ':crlf:utf8';

parse_rdf($xml);

sub parse_rdf {
    my($xml) = @_;
    my %row;
	XML::Parser::GlobEvents::parse(\$xml,
    	'item' => {
            Start => sub {
            	%row = ( 'description' => '[no description]' );
            },
            End => sub {
	            print <<"ITEM";
$row{title} ($row{'dc:creator'}): $row{description}
ITEM
            }
        },
        'item/*' => sub {
            my($node) = @_;
            $row{ $node->{-name} } = $node->{-text};
        }
    );
}
