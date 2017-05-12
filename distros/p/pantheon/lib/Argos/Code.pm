package Argos::Code;

=head1 NAME

Argos::Code - Argos code interface

=head1 SYNOPSIS

 use base qw( Argos::Code );

 my $code = Argos::Code->new( '/code/file' );

=cut
use strict;
use warnings;
use Carp;

=head1 CODE

A file that contains a CODE.

=cut
sub new
{
    my ( $class, $code ) = splice @_;

    confess "undefined code" unless $code;
    $code = readlink $code if -l $code;

    my $error = "invalid code $code";
    confess "$error: not a regular file" unless -f $code;

    $code = do $code;
    confess "$error: $@" if $@;
    bless $code, ref $class || $class;
}

sub param
{
    my $self = shift;
    return ( log => sub {}, cache => {}, @_ );
}

1;
