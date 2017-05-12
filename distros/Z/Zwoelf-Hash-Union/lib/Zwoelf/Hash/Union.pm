package Zwoelf::Hash::Union;

our $VERSION = 0.1;

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw( merge_hash unique_array );

use Test::Deep::NoTest;
use List::Util qw(reduce none);
use Hash::Merge;

=head1 NAME

Zwoelf::Hash::Union

=head1 DESCRIPTION

Work in progress: Menat to merge to hashes together like Hash::Merge BUT
will produce unions of any arrays that occur under the same key

=head1 SYNOPSIS

    use Zwoelf::Hash::Union qw( merge_hash unique_array );

    unique_array([ {a=>1}, {b=>2}, {c=>3}, {b=>2} ])
    # yields
    [{ a => 1 }, { b => 2 }, { c => 3 }];

    merge_hash(
        { a => 1, b => [{ b => 2 }, { c => 3 }] },
        { a => 2, b => [{ b => 2 }, { d => 4 }] },
    );
    # yields
    { a => 2, b => [{ b => 2}, { c => 3 }, { d => 4 }] },
    
    merge_hash(
        { a => 1, b => [{ b => 2 }, { c => 3 }] },
        { a => 2, b => [{ b => 2 }, { d => 4 }] },
        'LEFT_PRECEDENT'
    );
    # yields
    { a => 1, b => [{ b => 2}, { c => 3 }, { d => 4 }] },

=cut

sub unique_array {
    my ( $array ) = @_;
    return 
        reduce { push @$a, $b if none { eq_deeply( $_, $b) } @$a ; $a }
        ( [], @$array )
    ;
}

sub merge_hash {
    my ( $a, $b, $precedence ) = @_;
    my $merge  = Hash::Merge->new( $precedence || 'RIGHT_PRECEDENT' );
    my $merged = $merge->merge( $a, $b );
    return unify_hash( $merged );
}

sub unify_hash {
    my ( $hash ) = @_;
    for my $key ( keys %$hash ){
        $hash->{$key} = unify_value( $hash->{$key} );
    }
    return $hash;
}

sub unify_array {
    my ( $array ) = @_;
    for my $index ( 0..$#$array ){
        $array->[ $index ] = unify_value( $array->[ $index ] )
    }
    return $array;
}

sub unify_value {
    my ( $value ) = @_;
    return
          ref $value eq 'ARRAY' ? unify_array( unique_array( $value ) )
        : ref $value eq 'HASH'  ? unify_hash( $value )
        : $value
    ;
}
1;
