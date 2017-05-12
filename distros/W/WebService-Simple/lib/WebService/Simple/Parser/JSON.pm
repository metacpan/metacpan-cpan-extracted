# $Id$

package WebService::Simple::Parser::JSON;
use strict;
use warnings;
use base qw(WebService::Simple::Parser);
use JSON 2.0;

sub new
{
    my $class = shift;
    my %args  = @_;

    my $json  = delete $args{json} || JSON->new;
    my $self  = $class->SUPER::new(%args);
    $self->{json} = $json;
    return $self;
}

sub parse_request
{
    my $self = shift;
#   my $content = $_[0]->decoded_content;
#   # JSONP to pure JSON
#   $content =~ s/[a-zA-Z_\$][a-zA-Z0-9_\$]*\s*\((.+)\)\s*;?\s*$/$1/;
    $self->{json}->encode( $_[0] );
}

sub parse_response
{
    my $self = shift;
    my $content = $_[0]->decoded_content;
    # JSONP to pure JSON
    $content =~ s/[a-zA-Z_\$][a-zA-Z0-9_\$]*\s*\((.+)\)\s*;?\s*$/$1/;
    $self->{json}->decode( $content );
}

1;

__END__

=head1 NAME

WebService::Simple::Parser::JSON - Parse JSON content

=head1 SYNOPSIS

  my $service = WebService::Simple->new(
    base_url => ...,
    response_parser => 'JSON',
  );
  my $res = $service->get(...);
  my $json = $res->parse_response();

=head1 METHODS

=head2 new

=head2 parse_response

=cut
