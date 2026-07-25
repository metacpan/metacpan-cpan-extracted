package Wildling::Generator;

use strict;
use warnings;

use Wildling::ParsePattern qw(parse_pattern);

sub new {
    my ( $class, $input_pattern, $dictionaries ) = @_;
    my $tokens = parse_pattern( $input_pattern, $dictionaries );
    my $count  = 1;
    for my $token (@$tokens) {
        $count *= $token->count();
    }
    return bless {
        source => $input_pattern,
        tokens => $tokens,
        count  => $count,
    }, $class;
}

sub source {
    my ($self) = @_;
    return $self->{source};
}

sub count {
    my ($self) = @_;
    return $self->{count};
}

sub tokens {
    my ($self) = @_;
    return $self->{tokens};
}

sub get {
    my ( $self, $index ) = @_;
    return '' if $index > $self->{count} - 1 || $index < 0;

    my @string_array;
    my $index_with_offset = $index;
    for my $token ( @{ $self->{tokens} } ) {
        my $token_count = $token->count();
        push @string_array, $token->get( $index_with_offset % $token_count );
        $index_with_offset = int( $index_with_offset / $token_count );
    }
    return join '', @string_array;
}

1;
