package Test::UniqueTestNames::Test;

use strict;
use warnings;

my $unnamed_ok = 0;

sub new {
    my ( $class, $name, $line_number ) = @_;

    die 'tests must have a line number' unless defined $line_number;

    my $self = {
        name         => $name || '<no test name>',
        line_numbers => [ $line_number ],
    };

    return bless( $self, $class );
}

sub name {
    my ( $self ) = @_;

    return $self->{ name };
}

sub short_name {
    my ( $self ) = @_;

    my $name = $self->{ name };
    return $name if length $name < 40;

    substr($name, 40) = '...';
    return $name;
}

sub line_numbers {
    my ( $self ) = @_;

    my %line_frequency;
    for( @{ $self->{ line_numbers } } ) {
        $line_frequency{ $_ }++;
    }

    return \%line_frequency;
}

sub lowest_line_number {
    my ( $self ) = @_;

    my @sorted_line_numbers = sort @{ $self->{ line_numbers } };

    return $sorted_line_numbers[0];
}

sub add_line_number {
    my ( $self, $line_number ) = @_;

    die "add_line_number must be called on an instance" unless ref $self;

    push @{ $self->{ line_numbers } }, $line_number;
}

sub fails {
    my ( $self ) = @_;

    die "fails must be called on an instance" unless ref $self;

    return 0 if $self->name =~ /^The object isa/;

    if( $self->name eq '<no test name>' ) {
        return $unnamed_ok
            ? 0
            : 1;
    }

    return 1 if @{ $self->{ line_numbers } } > 1;

    return 0;
}

sub unnamed_ok {
    my ( $self, $value ) = @_;

    $unnamed_ok = $value if defined $value;
    
    return $unnamed_ok;
}

sub occurrences {
    my ( $self ) = @_;

    my $occurrences = 0;

    $occurrences += $_ for values %{ $self->line_numbers };

    return $occurrences;
}

1;
