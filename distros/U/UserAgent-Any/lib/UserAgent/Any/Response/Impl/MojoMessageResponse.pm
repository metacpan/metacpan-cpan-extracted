package UserAgent::Any::Response::Impl::MojoMessageResponse;

use 5.036;

use Moo;

use namespace::clean;

with 'UserAgent::Any::Response::Impl';

our $VERSION = 0.01;

sub status_code ($self) {
  return $self->{res}->code;
}

sub status_text ($self) {
  return $self->{res}->message;
}

sub success ($self) {
  return $self->{res}->is_success;
}

sub content ($self) {
  return $self->{res}->text;
}

sub raw_content ($self) {
  return $self->{res}->body;
}

sub headers ($self) {
  my @all_headers;
  for my $k (@{$self->{res}->headers->names}) {
    push @all_headers, map { ($k, $_) } $self->header($k);
  }
  return @all_headers;
}

sub header ($self, $header) {
  return @{$self->{res}->headers->every_header($header)} if wantarray;
  return $self->{res}->headers->header($header);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

UserAgent::Any::Response::Impl::MojoMessageResponse

=head1 SYNOPSIS

Implementation of L<UserAgent::Any::Response> for the L<Mojo::Message::Response>
class.
