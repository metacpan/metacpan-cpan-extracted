package roles;
# ABSTRACT: A simple pragma for composing roles.

use strict;
use warnings;

use MOP             ();
use Module::Runtime ();

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:STEVAN';

sub import {
    shift;
    my $pkg   = caller(0);
    my $meta  = MOP::Util::get_meta( $pkg );
    my @roles = map Module::Runtime::use_package_optimistically( $_ ), @_;

    $meta->set_roles( @roles );

    MOP::Util::defer_until_UNITCHECK(sub {
        MOP::Util::compose_roles( MOP::Util::get_meta( $pkg ) )
    });
}

sub DOES {
    my ($self, $role) = @_;
    # get the class ...
    my $class = ref $self || $self;
    # if we inherit from this, we are good ...
    return 1 if $class->isa( $role );
    # next check the roles ...
    my $meta = MOP::Util::get_meta( $class );
    # test just the local (and composed) roles first ...
    return 1 if $meta->does_role( $role );
    # then check the inheritance hierarchy next ...
    return 1 if scalar grep { MOP::Util::get_meta( $_ )->does_role( $role ) } @{ $meta->mro };
    return 0;
}

1;

__END__

=pod

=head1 NAME

roles - A simple pragma for composing roles.

=head1 VERSION

version 0.03

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

    # ...

    US::Currency->roles::DOES('Eq');         # true
    US::Currency->roles::DOES('Printable');  # true
    US::Currency->roles::DOES('Comparable'); # true

=head1 DESCRIPTION

This is a very simple pragma which takes a list of roles as
package names, adds them to the C<@DOES> package variable
and then schedules for role composition to occur during the
next available UNITCHECK phase.

=head2 C<roles::DOES>

Since Perl v5.10 there has been a C<UNIVERSAL::DOES> method
available, however it is unaware of this module so is not
very useful to us. Instead we supply a replacement in the
form of C<roles::DOES> method that can be used like this:

  $instance->roles::DOES('SomeRole');

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2018 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
