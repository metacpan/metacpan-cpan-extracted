package WebService::Simple::Parser::XML::Feed;
use strict;
use warnings;
use base qw(WebService::Simple::Parser);
use XML::Feed;

sub new {
    my $class = shift;
    my %args  = @_;
    my $self  = $class->SUPER::new(%args);
    return $self;
}

sub parse_response {
    my $self = shift;
    my $content = $_[0]->decoded_content;
    XML::Feed->parse( \$content );
}

1;

__END__
=head1 NAME

WebService::Simple::Parser::XML::Feed - Parse XML content using XML::Feed

=head1 SYNOPSIS

  my $service = WebService::Simple->new(
    base_url => ...,
    response_parser => 'XML::Feed',
  );
  my $res = $service->get(...);
  my $feed = $res->parse_response();

=head1 METHODS

=head2 new

=head2 parse_response

=head1 AUTHOR

Yusuke Wada  C<< <yusuke@kamawada.com> >>

=cut
