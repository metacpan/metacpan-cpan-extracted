package WebSource::Fetcher::xml;

use strict;
use LWP::UserAgent;
use HTTP::Cookies;
use WebSource::Parser;
use WebSource::Fetcher;
use WebSource::XMLParser;

use Carp;

our @ISA = ('WebSource::Fetcher','WebSource::XMLParser');

=head1 NAME

WebSource::Fetcher::xml : fetching module
  When run downloads given urls and returns the corresponding documents

=head1 DESCRIPTION

=head1 SYNOPSIS

  $fetcher = WebSource::Fetcher::xml->new(wsnode => $node);

  # for the rest it works as a WebSource::Module

=head1 METHODS

=over 2

=item B<< $source = WebSource->new(desc => $node); >>

Create a new Fetcher;

=cut

sub _init_ {
  my $self = shift;
  $self->WebSource::Fetcher::_init_;
  $self->WebSource::XMLParser::_init_;
}

=item B<< $fetcher->handle($env); >>

Builds an HTTP::Request from the data in enveloppe, fetches
the URI (eventually stores it in a file) and builds
the corresponding DOM object

=cut

sub handle {
  my ($self,$env) = @_;
  return WebSource::XMLParser::handle($self,
            WebSource::Fetcher::handle($self,$env));
}

=back

=head1 SEE ALSO

WebSource::Module

=cut

1;
