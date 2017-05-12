=head1 NAME

WWW::XKCD::AsText - retrieve text versions of comics on www.xkcd.com

=head1 SYNOPSIS

  use WWW::XKCD::AsText;

  my $xkcd          = WWW::XKCD::AsText->new;
  my $xkcd_retrieve = $xkcd->retrieve(1); # "A boy sits in a barrel..."

  $xkcd_retrieve->uri;   # "https://www.xkcd.com/1/"
  $xkcd_retrieve->text;  # "A boy sits in a barrel..."
  $xkcd_retrieve->error; # line_status

=cut

package WWW::XKCD::AsText;
$WWW::XKCD::AsText::VERSION = '0.006';
use namespace::autoclean;
use Moose;

use Carp;
use URI;
use JSON;
use LWP::UserAgent;

has 'timeout' => (
  is  => 'ro',
  isa => 'Maybe[Int]',
  required => 1,
  default  => 30,
);

has 'agent' => (
  is  => 'ro',
  isa => 'Maybe[Str]',
);

has 'ua' => (
  is  => 'rw',
  isa => 'Maybe[LWP::UserAgent]',
  builder => '_build_ua',
);

sub _build_ua{
  my $self = shift;
  return LWP::UserAgent->new(
    timeout => $self->timeout // 30,
    agent   => $self->agent   // '',
  );
}

has 'uri' => (
  is  => 'rw',
  isa => 'Maybe[URI]',
);

has 'error' => (
  is  => 'rw',
  isa => 'Maybe[Str]',
);

has 'text' => (
  is  => 'rw',
  isa => 'Maybe[Str]',
);

sub BUILD{
  my $self = shift;
  $self->ua($self->_build_ua) unless defined $self->ua;
}

=head1 METHODS

=head2 retrieve

Takes XKCD comic number, returns its transcript.

=cut

sub retrieve {
  my ($self, $id) = @_;

  $self->$_(undef) foreach (qw(uri text error));

  croak 'ID must be a valid number' unless $id && $id=~/^\d+$/;

  $self->uri(URI->new("http://xkcd.com/$id/"));
  my $json_uri = URI->new("https://xkcd.com/$id/info.0.json");
  my $response = $self->ua->get($json_uri);

  if ($response->is_success){
    my $decoded = decode_json($response->content);
    $self->text($decoded->{transcript});
    return $self->text;
  }

  $self->error($response->status_line);
  return;

}

1;
__PACKAGE__->meta->make_immutable;

=head1 SEE ALSO

L<WWW::xkcd|https://metacpan.org/pod/WWW::xkcd>

=head1 AUTHOR

Original author is Zoffix Znet, C<< <zoffix at cpan.org> >>,

currently maintained by Kivanc Yazan, C<< <kyzn at cpan.org> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__