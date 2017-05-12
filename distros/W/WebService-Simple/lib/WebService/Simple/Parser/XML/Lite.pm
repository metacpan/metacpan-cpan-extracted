package WebService::Simple::Parser::XML::Lite;
use strict;
use warnings;
use base qw(WebService::Simple::Parser);
use XML::Parser::Lite::Tree;
use XML::Parser::Lite::Tree::XPath;

__PACKAGE__->mk_accessors($_) for qw(lite);

sub new
{
    my $class = shift;
    my %args  = @_;

    my $lite = delete $args{lite} || XML::Parser::Lite::Tree::instance();
    my $self  = $class->SUPER::new(%args);
    $self->{lite} = $lite;
    return $self;
}

sub parse_response
{
    my $self = shift;
    XML::Parser::Lite::Tree::XPath->new(
        $self->{lite}->parse( $_[0]->decoded_content ) );
}

1;

__END__

=head1 NAME

WebService::Simple::Parser::XML::Lite - Parse XML content using
 XML::Parser::Lite::Tree and XML::Parser::Lite::Tree::XPath

=head1 SYNOPSIS

  my $service = WebService::Simple->new(
    base_url => ...,
    response_parser => 'XML::Lite',
  );
  my $res = $service->get(...);
  my $tree = $res->parse_response();

=head1 METHODS

=head2 new

=head2 parse_response

=head1 AUTHOR

mattn C<< <mattn.jp@gmail.com> >>

=cut
