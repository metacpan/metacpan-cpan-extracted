use strictures 2;

package Tie::Redis::Candy;

# ABSTRACT: Tie Redis to HashRef or ArrayRef

use Redis;
use Tie::Redis::Candy::Hash;
use Tie::Redis::Candy::Array;
use Exporter qw(import);

our $VERSION = '1.001';    # VERSION

our @EXPORT_OK = qw(redis_hash redis_array);

sub redis_hash {
    my ( $redis, $key, %init ) = @_;
    tie( my %hash, 'Tie::Redis::Candy::Hash', $redis, $key );
    $hash{$_} = delete $init{$_} for keys %init;
    bless( \%hash, 'Tie::Redis::Candy::Hash' );
}

sub redis_array {
    my ( $redis, $listname, @init ) = @_;
    tie( my @array, 'Tie::Redis::Candy::Array', $redis, $listname );
    while ( my $item = shift @init ) {
        push @array => $item;
    }
    bless( \@array, 'Tie::Redis::Candy::Array' );
}

1;

__END__

=pod

=head1 NAME

Tie::Redis::Candy - Tie Redis to HashRef or ArrayRef

=head1 VERSION

version 1.001

=head1 SYNOPSIS

    use Tie::Redis::Candy qw(redis_hash redis_array);
    
    my $redis = Redis->new(...);
    
    my $hashref = redis_hash($redis, $key, %initial_values);
    $hashref->{foo} = 'bar';
    
    my $arrayref = redis_array($redis, $listname, @initial_values);
    push @$arrayref => ('foo', 'bar');

=head1 DESCRIPTION

This module is inspired by L<Tie::Redis> and L<Redis::Hash>/L<Redis::List>.

=head1 FUNCTIONS

=head2 redis_hash ($redis, $key, %initial_values);

C<$redis> must be an instance of L<Redis>. C<$key> is the name of the hash key.

The hash will not cleared at this point, but the initial values are appended.

=head2 redis_array ($redis, $listname, @initial_values);

Behaves similiar to L</redis_hash>, except that a redis array is used.

The array will not cleared at this point, but the initial values are pushed at the B<end> of list.

=head1 SERIALIZATION

Serialization is done by L<CBOR::XS> which is fast and light.

=head1 EXPORTS

Nothing by default. L</redis_hash> and L</redis_array> can be exported on request.

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
