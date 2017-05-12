# This file was part of Redis, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
# Copyright (c) 2015 by Pedro Melo, Damien Krotkine.

use strictures 2;

package Tie::Redis::Candy::Array;

# ABSTRACT: tie Perl arrays to Redis lists - the candy way

use Carp qw(croak confess);
use CBOR::XS qw(encode_cbor decode_cbor);
use base 'Tie::Array';

my $undef = encode_cbor(undef);

our $VERSION = '1.001';    # VERSION

sub TIEARRAY {
    my ( $class, $redis, $listname ) = @_;

    croak "not a Redis instance: $redis"
      unless ref($redis) =~ m{^(?:Test::Mock::)?Redis$};

    my $self = {
        list  => $listname,
        redis => $redis,
    };

    return bless( $self, $class );
}

sub FETCH {
    my ( $self, $index ) = @_;
    my $data = $self->{redis}->lindex( $self->{list}, $index );
    return unless defined $data;
    decode_cbor($data);
}

sub FETCHSIZE {
    my ($self) = @_;
    $self->{redis}->llen( $self->{list} );
}

sub STORE {
    my ( $self, $index, $value ) = @_;
    $self->{redis}->lset( $self->{list}, $index, encode_cbor($value) );
}

sub STORESIZE {
    my ( $self, $count ) = @_;
    $self->{redis}->ltrim( $self->{list}, 0, $count );
}

sub CLEAR {
    my ($self) = @_;
    $self->{redis}->del( $self->{list} );
}

sub PUSH {
    my ( $self, @values ) = @_;
    $self->{redis}->rpush( $self->{list}, encode_cbor($_) ) for @values;
}

sub POP {
    my ($self) = @_;
    map { defined($_) ? decode_cbor($_) : undef }
      $self->{redis}->rpop( $self->{list} );
}

sub SHIFT {
    my ($self) = @_;
    map { defined($_) ? decode_cbor($_) : undef }
      $self->{redis}->lpop( $self->{list} );
}

sub UNSHIFT {
    my ( $self, @values ) = @_;
    $self->{redis}->lpush( $self->{list}, encode_cbor($_) ) for reverse @values;
}

sub SPLICE {
    confess 'UNIMPLEMENTED';
}

sub EXTEND {
}

sub DESTROY {
}

1;

__END__

=pod

=head1 NAME

Tie::Redis::Candy::Array - tie Perl arrays to Redis lists - the candy way

=head1 VERSION

version 1.001

=head1 SYNOPSYS

    my $redis = Redis->new;
    
    tie @my_list, 'Tie::Redis::Candy::List', 'list_name', $redis;
    
    $value = $my_list[$index];
    $my_list[$index] = $value;
    
    $count = @my_list;
    
    push @my_list, 'values';
    $value = pop @my_list;
    unshift @my_list, 'values';
    $value = shift @my_list;
    
    ## NOTE: fourth parameter of splice is *NOT* supported for now
    @other_list = splice(@my_list, 2, 3);
    
    @my_list = ();

=head1 HISTORY

This module is originally based on L<Redis::List> by I<Pedro Melo> and I<Damien Krotkine>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/zurborg/libtie-redis-candy-perl/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

David Zurborg <zurborg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Zurborg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
