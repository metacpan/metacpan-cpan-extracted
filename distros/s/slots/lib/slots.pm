package slots;
# ABSTRACT: A simple pragma for managing class slots.

use strict;
use warnings;

use MOP ();

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:STEVAN';

sub import {
    shift;
    my $pkg   = caller(0);
    my $meta  = MOP::Util::get_meta( $pkg );
    my %slots = @_;

    $meta->add_slot( $_, $slots{ $_ } ) for keys %slots;

    MOP::Util::defer_until_UNITCHECK(sub {
        MOP::Util::inherit_slots( MOP::Util::get_meta( $pkg ) )
    });
}

1;

__END__

=pod

=head1 NAME

slots - A simple pragma for managing class slots.

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    package Point {
        use strict;
        use warnings;

        use parent 'UNIVERSAL::Object';
        use slots (
            x => sub { 0 },
            y => sub { 0 },
        );

        sub clear {
            my ($self) = @_;
            $self->{x} = 0;
            $self->{y} = 0;
        }
    }

    package Point3D {
        use strict;
        use warnings;

        use parent 'Point';
        use slots (
            z => sub { 0 },
        );

        sub clear {
            my ($self) = @_;
            $self->next::method;
            $self->{z} = 0;
        }
    }

=head1 DESCRIPTION

This is a very simple pragma which takes a set of key/value
arguments and assigns it to the C<%HAS> package variable of
the calling class.

This module will also detect superclasses and insure that
slots are inherited correctly, this wil occur during the
next available UNITCHECK phase.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2018 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
