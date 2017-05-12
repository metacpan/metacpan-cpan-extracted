package UNIVERSAL::derived_classes;

use strict;
use vars qw( $VERSION );

$VERSION = '0.02';

sub UNIVERSAL::derived_classes {
    my ($super_class, $reversed) = @_;

    if (my $blessed_class = ref $super_class) {
        $super_class = $blessed_class;
    }

    my @derived_classes;

    my $find_derived_classes; $find_derived_classes = sub {
        my ($outer_class) = @_;

        my $symbol_table_hashref
                = do { no strict 'refs'; \%{ "${outer_class}::" } };

        SYMBOL:
        for my $symbol (keys %$symbol_table_hashref) {
            next SYMBOL if $symbol !~ /\A (\w+):: \z/x;
            my $inner_class = $1;

            next SYMBOL if $inner_class eq 'SUPER'; # skip '*::SUPER'

            my $class = $outer_class ? "${outer_class}::$inner_class"
                                     : $inner_class;

            if ( $class->isa($super_class) and $class ne $super_class ) {
                push @derived_classes, $class;
            }

            next SYMBOL if $class eq 'main';        # skip 'main::*'

            $find_derived_classes->($class);
        }
    };

    my $root_class = q{};
    $find_derived_classes->($root_class);

    undef $find_derived_classes;

    @derived_classes = sort {   $a->isa($b) ?  1
                              : $b->isa($a) ? -1
                                            :  0
                            } @derived_classes;

    return reverse @derived_classes if $reversed;
    return         @derived_classes             ;
}

sub UNIVERSAL::derived_classes_reversed {
    my ($super_class) = @_;
    return $super_class->derived_classes('reversed');
}

1;
__END__

=head1 NAME

UNIVERSAL::derived_classes - Returns derived classes of a class

=head1 SYNOPSIS

    require UNIVERSAL::derived_classes;

    package A;

    package B;
    @ISA = qw( A );

    package C;
    @ISA = qw( B );

    package main;
    my @derived_classes          = A->derived_classes;          # B, C
    my @derived_classes_reversed = A->derived_classes_reversed; # C, B

=head1 DESCRIPTION

C<UNIVERSAL::derived_classes> provides the following methods:

=over 4

=item C<< CLASS->derived_classes(REVERSED) >>

=item C<< $obj->derived_classes(REVERSED) >>

Where

=over 4

=item C<REVERSED>

is the flag to reverse classes

=back

When used as a class method (C<< CLASS->derived_classes(REVERSED) >>),
C<derived_classes> returns derived classes of the C<CLASS>.

When used as an instance method (C<< $obj->derived_classes(REVERSED) >>),
C<derived_classes> returns derived classes of a class where C<$obj> is
blessed. 

If the C<REVERSED> flag is I<true> then reversed derived classes are returned.

=item C<< CLASS->derived_classes_reversed >>

=item C<< $obj->derived_classes_reversed >>

C<derived_classes_reversed> is same as C<derived_classes(REVERSED)>

=back

=head1 AUTHOR

Yuji Tamashiro, E<lt>yuji@tamashiro.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Yuji Tamashiro

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
