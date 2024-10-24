use strict;
use warnings;

# ABSTRACT: Internal value object for the "Unknown::Values" distribution

package Unknown::Values::Instance;
$Unknown::Values::Instance::VERSION = '0.102';
use Carp 'confess';

use 5.01000;
my @to_overload;

BEGIN {
    my %to_overload = (
        sort        => [qw{ <=> cmp }],
        compare     => [qw{ <= >= < > lt le gt ge == eq != ne}],
        math        => [qw{ + - * / ** atan2 cos sin exp log sqrt int abs }],
        string      => [qw{ qr x }],
        files       => [qw{ <> -X }],
        bits        => [qw{ << >> & | ^ ~ }],
        bool        => [ 'bool', '!' ],
        dereference => [qw< ${} @{} %{} &{} *{} >],
        nomethod    => ['nomethod'],
    );
    while ( my ( $method, $ops ) = each %to_overload ) {
        push @to_overload => $_ => $method foreach @$ops;
    }
}

use overload @to_overload, '""' => 'to_string';
my $CORE_UNKNOWN = __PACKAGE__->new;

sub to_string {
    confess("Attempt to coerce unknown value to a string");
}

sub new {
    my $class   = shift;
    my $unknown = bless {} => $class;
    return $unknown;
}

# this helps to prevent some infinite loops
sub bool {$CORE_UNKNOWN}

sub compare {

    # this suppresses the "use of unitialized value in sort" warnings
    wantarray ? () : 0;
}

sub sort {
    if    ( $_[2] )                                { return -1 }
    elsif ( Unknown::Values::is_unknown( $_[1] ) ) { return 0 } # unnecessary?
    else                                           { return 1 }
}

sub math { confess("Math cannot be performed on unknown values") }

sub dereference {
    confess("Dereferencing cannot be performed on unknown values");
}

sub files {
    confess("File operations cannot be performed on unknown values");
}

sub string {
    confess("String operations cannot be performed on unknown values");
}

sub bits {
    confess("Bit manipulation cannot be performed on unknown values");
}

sub nomethod {
    if ( defined( my $operator = $_[3] ) ) {
        confess("'$operator' operations are not allowed with unknown values");
    }
    else {

        # XXX seems bit manipulation can trigger this
        confess("Illegal operation performed on unknown value");
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Unknown::Values::Instance - Internal value object for the "Unknown::Values" distribution

=head1 VERSION

version 0.102

=head1 DESCRIPTION

For Internal Use Only! See L<Unknown::Values>.

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
