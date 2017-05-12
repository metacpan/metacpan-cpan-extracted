package    # mask from CPAN?
  Fake::Ohloh;

use strict;
use warnings;

use Object::InsideOut;
use base qw/ WWW::Ohloh::API /;
use Carp;

use XML::LibXML;
use WWW::Ohloh::API;

my @results_of : Field;
my @parser_of : Field;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub parser {
    my $self = shift;
    return $parser_of[$$self] ||= XML::LibXML->new;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub stash {
    my $self = shift;
    my ( $url, $xml ) = @_;

    my $dom =
      -f 't/samples/' . $xml
      ? $self->parser->parse_file( 't/samples/' . $xml )
      : $self->parser->parse_string($xml);

    push @{ $results_of[$$self] }, [ $url, $dom->findnodes('//result[1]') ];

    return $self;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _query_server {
    my $self  = shift;
    my $stash = shift @{ $results_of[$$self] }
      or croak "no more results stashed";
    return @$stash;
}

'end of FakeOhloh';
