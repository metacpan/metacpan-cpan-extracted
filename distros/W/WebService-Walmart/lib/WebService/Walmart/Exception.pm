package WebService::Walmart::Exception;
use strict;
use warnings;
$WebService::Walmart::Exception::VERSION = "0.01";

use Moose;
with 'Throwable';

use overload
    q{""}    => 'as_string',
    fallback => 1;

has message => ( is => 'rw', isa => 'Str');
has method  => ( is => 'rw', isa => 'Str');
has code    => ( is => 'rw', isa => 'Int');
has reason  => ( is => 'rw', isa => 'Str');
has filename => ( is => 'rw', isa => 'Str');
has linenum  => ( is => 'rw', isa => 'Str');

sub as_string {
    my $self = shift;
    my $message = $self->method.'(): ';
    $message   .= $self->message . ' ' . $self->code . ' ' . $self->reason. ' ';
    $message   .= 'file: ' . $self->filename .' on line number ' . $self->linenum. ' ';
    $message   .= "\n";
    return $message;
}

1;
=pod


=head1 SYNOPSIS

This module represents an exception. 

You probably shouldn't be calling this directly

=cut
