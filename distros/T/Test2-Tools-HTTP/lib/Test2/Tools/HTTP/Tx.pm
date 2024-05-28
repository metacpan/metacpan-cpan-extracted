package Test2::Tools::HTTP::Tx;

use strict;
use warnings;
use 5.014;
use Test2::API ();
use Carp ();

# ABSTRACT: Object representing the last transaction for Test2::Tools::HTTP
our $VERSION = '0.12'; # VERSION


sub req { shift->{req} }
sub res { shift->{res} }
sub ok  { shift->{ok}  }
sub connection_error { shift->{connection_error} }
sub location { shift->{location} }

sub _note_or_diag
{
  my($self, $method) = @_;
  my $ctx = Test2::API::context();

  $ctx->$method($self->req->method . ' ' . $self->req->uri);
  $ctx->$method($self->req->headers->as_string);
  $ctx->$method($self->req->decoded_content || $self->req->content);
  if($self->res)
  {
    $ctx->$method($self->res->code . ' ' . $self->res->message);
    $ctx->$method($self->res->headers->as_string);
    $ctx->$method($self->res->decoded_content || $self->res->content);
  }
  $ctx->$method("ok = " . $self->ok);

  $ctx->release;
}


sub note
{
  my($self) = shift;
  my $ctx = Test2::API::context();
  $self->_note_or_diag('note');
  $ctx->release;
}


sub diag
{
  my($self) = shift;
  my $ctx = Test2::API::context();
  $self->_note_or_diag('diag');
  $ctx->release;
}


sub add_helper
{
  my(undef, $sig, $code) = @_;

  my($class, $name) = split /\./, $sig;

  my %class = (
    tx => 'Test2::Tools::HTTP::Tx',
    req => 'Test2::Tools::HTTP::Tx::Request',
    res => 'Test2::Tools::HTTP::Tx::Response',
  );

  $class = $class{lc $class} if $class{lc $class};

  Carp::croak("$class already can $name") if $class->can($name);

  no strict 'refs';
  *{"${class}::${name}"} = $code;
}

package Test2::Tools::HTTP::Tx::Request;

use parent 'HTTP::Request';

package Test2::Tools::HTTP::Tx::Response;

use parent 'HTTP::Response';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Tools::HTTP::Tx - Object representing the last transaction for Test2::Tools::HTTP

=head1 VERSION

version 0.12

=head1 SYNOPSIS

 use Test2::V0;
 use Test2::Tools::HTTP;
 use HTTP::Request::Common;
 
 http_request GET('http://example.test');
 
 # get the HTTP::Request/Response object
 my $req = http_tx->req;
 my $res = http_tx->res;
 
 # send a diagnostic of the most recent
 # transaction as a note.
 http_tx->note;
 
 done_testing;

=head1 DESCRIPTION

This class provides an interface to the most recent transaction performed by
C<http_request> in L<Test2::Tools::HTTP>.

=head1 METHODS

=head2 req

 my $req = http_tx->req;

The L<HTTP::Request> object.

=head2 res

 my $res = http_tx->res;

The L<HTTP::Response> object.  May or may not be defined in the case of a
connection error.

=head2 ok

 my $bool = http_tx->ok;

True if the most recent call to C<http_request> passed.

=head2 connection_error

 my $string = http_tx->connection_error;

The connection error if any from the most recent C<http_reequest>.

=head2 location

The C<Location> header converted to an absolute URL, if provided by the response.

=head2 note

 http_tx->note;

Send the request, response and ok to Test2's "note" output.  Note that the message bodies may be decoded, but
the headers will not be modified.

=head2 diag

Send the request, response and ok to Test2's "diag" output.  Note that the message bodies may be decoded, but
the headers will not be modified.

=head2 add_helper

 Test2::Tools::HTTP::Tx->add_helper( $name, $code );

Adds a transaction helper to the given class.  For example.

 Test2::Tools::HTTP::Tx->add_helper( 'tx.foo' => sub {
   my $tx = shift;
   ...
 } );
 Test2::Tools::HTTP::Tx->add_helper( 'req.bar' => sub {
   my $req = shift;
   ...
 } );
 Test2::Tools::HTTP::Tx->add_helper( 'res.baz' => sub {
   my $res = shift;
   ...
 } );

Lets you call these helpers thus:

 http_tx->foo;
 http_tx->req->bar;
 http_tx->res->baz;

A useful application of this technique is to provide conversion of the response body:

 use JSON::PP qw( decode_json );
 Test2::Tools::HTTP::Tx->add_helper( 'res.json' => sub {
   my $res = shift;
   decode_json( $res->decoded_content );
 });

You cannot add helpers that replace existing methods.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
