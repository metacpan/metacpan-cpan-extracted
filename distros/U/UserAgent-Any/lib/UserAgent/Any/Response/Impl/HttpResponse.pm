package UserAgent::Any::Response::Impl::HttpResponse;

use 5.036;

use Encode 'decode';
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

has _content => (
  is => 'ro',
  lazy => 1,
  default => sub ($self) {
    my $fc = $self->_forced_charset;
    return decode($fc, $self->raw_content) if defined $fc;
    return $self->{res}->decoded_content;
  },
);

sub content ($self) {
  return $self->_content;
}

sub raw_content ($self) {
  return $self->{res}->content;
}

sub headers ($self) {
  return $self->{res}->flatten();
}

sub header ($self, $header) {
  return $self->{res}->header($header);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

UserAgent::Any::Response::Impl::HttpResponse

=head1 SYNOPSIS

Implementation of L<UserAgent::Any::Response> for the L<HTTP::Response> class.
