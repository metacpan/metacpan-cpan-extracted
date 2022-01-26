package Unknown::Values::Instance::Object;
$Unknown::Values::Instance::Object::VERSION = '0.102';
use strict;
use warnings;

# ABSTRACT: Internal null value object for the "Unknown::Values" distribution

use Unknown::Values::Instance;

use Carp 'confess';
use base 'Unknown::Values::Instance';

# Make sure we don't grab the UNIVERSAL:: versions of these
sub isa     { $_[0] }
sub can     { $_[0] }
sub DOES    { $_[0] }
sub VERSION { $_[0] }

# and everything else receives an unknown object
sub AUTOLOAD { $_[0] }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Unknown::Values::Instance::Object - Internal null value object for the "Unknown::Values" distribution

=head1 VERSION

version 0.102

=head1 SYNOPSIS

    package Employee {
        use parent 'Person';
        use Unknown::Values ':OBJECT';

        sub new {
            my ( $class, $id ) = @_;
            my $self = $self->next::method($id) // return unknown;
            ...
            return $self
        }
        
        # ...
    }

    ...

The following assumes that C<$employee> is C<unknown>:

    my $employee = Employee->new($id);

    # you can call any method on $employee
    if ( $employee->salary > $threshold ) {
        ... will never get here if $employee is unknown
    }

    say $employee->name; # fatal
    if ( is_unknown $employee ) {
        ... works as expected
    }

    if ( $employee->isa('Employee') ) {
        ... isa always returns unknown
    }

=head1 DESCRIPTION

C<use Unknown::Values ':OBJECT'> implements a variation of the L<NULL object pattern|https://en.wikipedia.org/wiki/Null_object_pattern>.

In addition to having all of the behavior of L<Unknown::Values>, you can call
any method on the object and it will return the unknown object instances.

=head2 Subclassing Unknown Objects

Sometimes you want to provide a default value for a method. You can subclass
unknown objects to allow this:

    package Unknown::Person {
        use parent 'Unknown::Values::Instance::Object';

        sub name { return '<unknown>' }
    }

    package Person {
        sub new {
            my ( $class, $name, $age ) = @_;

            if ( not defined $name ) {
                return Unknown::Person->new;
            }
            return bless {
                name => $name,
                age  => $age,
            } => $class;
        }

        sub name { $_[0]->{name} }
        sub age  { $_[0]->{age} }
    }

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
