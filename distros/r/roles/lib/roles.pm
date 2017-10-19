package roles;
# ABSTRACT: A simple pragma for composing roles.

use strict;
use warnings;

use MOP         ();
use Devel::Hook ();

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

sub import {
    shift;
    my $role = caller;
    my @roles = @_;

    {
        no strict   'refs';
        no warnings 'once';
        push @{ $role.'::DOES' } => @roles;
    }

    Devel::Hook->push_UNITCHECK_hook(sub {
        my $meta;
        {
            no strict   'refs';
            no warnings 'once';
            if ( @{ $role.'::ISA' } ) {
                $meta = MOP::Class->new( $role )
            }
            else {
                $meta = MOP::Role->new( $role )
            }
        }

        MOP::Util::APPLY_ROLES(
            $meta,
            [ $meta->roles ],
            to => ($meta->isa('MOP::Class') ? 'class' : 'role')
        );
    });
}

1;

__END__

=pod

=head1 NAME

roles - A simple pragma for composing roles.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    package Eq {
        use strict;
        use warnings;

        sub equal_to;

        sub not_equal_to {
            my ($self, $other) = @_;
            not $self->equal_to($other);
        }
    }

    package Comparable {
        use strict;
        use warnings;

        use roles 'Eq';

        sub compare;

        sub equal_to {
            my ($self, $other) = @_;
            $self->compare($other) == 0;
        }

        sub greater_than {
            my ($self, $other) = @_;
            $self->compare($other) == 1;
        }

        sub less_than {
            my ($self, $other) = @_;
            $self->compare($other) == -1;
        }

        sub greater_than_or_equal_to {
            my ($self, $other) = @_;
            $self->greater_than($other) || $self->equal_to($other);
        }

        sub less_than_or_equal_to {
            my ($self, $other) = @_;
            $self->less_than($other) || $self->equal_to($other);
        }
    }

    package Printable {
        use strict;
        use warnings;

        sub to_string;
    }

    package US::Currency {
        use strict;
        use warnings;

        use roles 'Comparable', 'Printable';

        sub new {
            my ($class, %args) = @_;
            bless { amount => $args{amount} // 0 } => $class;
        }

        sub compare {
            my ($self, $other) = @_;
            $self->{amount} <=> $other->{amount};
        }

        sub to_string {
            my ($self) = @_;
            sprintf '$%0.2f USD' => $self->{amount};
        }
    }

=head1 DESCRIPTION

This is a very simple pragma which takes a list of roles as
package names, adds them to the C<@DOES> package variable
and then schedule for composition to occur during UNITCHECK.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
