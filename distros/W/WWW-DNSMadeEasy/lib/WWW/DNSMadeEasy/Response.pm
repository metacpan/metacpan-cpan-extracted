package WWW::DNSMadeEasy::Response;
our $VERSION = '0.100';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: DNSMadeEasy Response

use Moo;
use JSON;

has http_response => (
    is       => 'ro',
    required => 1,
    handles   => ['is_success', 'content', 'decoded_content', 'status_line', 'code', 'header', 'as_string'],
);

sub data { shift->as_hashref(@_) }

sub as_hashref { 
    my ($self) = @_;
    return unless $self->http_response->content; # DELETE return 200 but empty content
    return decode_json($self->http_response->content);
}

sub error {
    my ($self) = @_;
    my $err = $self->data->{error};
    $err = [$err] unless ref($err) eq 'ARRAY';
    return wantarray ? @$err : join("\n", @$err);
}

sub request_id {
    my ( $self ) = @_;
    $self->header('x-dnsme-requestId');
}

sub request_limit {
    my ( $self ) = @_;
    $self->header('x-dnsme-requestLimit');
}

sub requests_remaining {
    my ( $self ) = @_;
    $self->header('x-dnsme-requestsRemaining');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::DNSMadeEasy::Response - DNSMadeEasy Response

=head1 VERSION

version 0.100

=head1 SYNOPSIS

  my $response = WWW::DNSMadeEasy->new(...)->request(...);
  if ($response->is_success) {
      my $data = $response->as_hashref;
      my $requestsremaining = $response->header('x-dnsme-requestsremaining');
  } else {
      my @errors = $response->error;
  }

=head1 DESCRIPTION

Response object to fetch headers and error data

=head1 METHODS

=head2 is_success

=head2 content

=head2 decoded_content

=head2 status_line

=head2 code

=head2 header

=head2 as_string

All above are from L<HTTP::Response>

    my $requestsremaining = $response->header('x-dnsme-requestsremaining');
    my $json_data = $response->as_string;

=head2 as_hashref

    my $data = $response->as_hashref;

convert response JSON to HashRef

=head2 error

    my @errors = $response->error;

get the detailed request errors

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/Getty/p5-www-dnsmadeeasy>

  git clone https://github.com/Getty/p5-www-dnsmadeeasy.git

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by L<Torsten Raudssus|https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
