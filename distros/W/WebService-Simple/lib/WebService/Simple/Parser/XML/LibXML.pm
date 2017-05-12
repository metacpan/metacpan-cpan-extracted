package WebService::Simple::Parser::XML::LibXML;
use strict;
use warnings;
use base qw(WebService::Simple::Parser);
use XML::LibXML;

__PACKAGE__->mk_accessors($_) for qw(libxml);

sub new
{
    my $class = shift;
    my $args  = shift || {};
    $args->{libxml} ||= XML::LibXML->new;
    $class->SUPER::new($args);
}

sub parse_response
{
    my $self = shift;
    $self->libxml->parse_string( $_[0]->decoded_content );
}

1;

__END__

=head1 NAME

WebService::Simple::Parser::XML::LibXML - Parse XML content using XML::LibXML

=head1 SYNOPSIS

  my $service = WebService::Simple->new(
    base_url => ...,
    response_parser => 'XML::LibXML',
  );
  my $res = $service->get(...);
  my $dom = $res->parse_response();

=head1 METHODS

=head2 new

=head2 parse_response

=cut
