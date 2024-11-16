package UserAgent::Any::Response::Impl::HttpPromiseResponse;

use 5.036;

use Moo;

use namespace::clean;

with 'UserAgent::Any::Response';

our $VERSION = 0.01;

sub status_code ($this) {
  return $this->{res}->code;
}

sub status_text ($this) {
  return $this->{res}->status;
}

sub success ($this) {
  return $this->{res}->is_success;
}

sub content ($this) {
  return $this->{res}->decoded_content;
}

sub raw_content ($this) {
  return $this->{res}->content;
}

sub headers ($this) {
  return $this->{res}->flatten();
}

sub header ($this, $header) {
  return $this->{res}->header($header);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

UserAgent::Any::Response::Impl::HttpPromiseResponse

=head1 SYNOPSIS

Implementation of L<UserAgent::Any::Response> for the L<HTTP::Promise::Response>
class.
