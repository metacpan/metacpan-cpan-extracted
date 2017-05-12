# ABSTRACT: Simple Ad-Hoc Data Validation

package Validation::Class::Simple;

use 5.10.0;
use strict;
use warnings;

use Validation::Class::Prototype;

use Scalar::Util ('refaddr');
use Validation::Class::Util ('prototype_registry');
use Validation::Class ();

our $VERSION = '7.900057'; # VERSION


sub new {

    my $class = shift;

    $class = ref $class || $class;

    my $self = bless {}, $class;
    my $addr = refaddr $self;

    prototype_registry->add(
        $addr => Validation::Class::Prototype->new(
            package => $class # inside-out prototype
        )
    );

    # let Validation::Class handle arg processing
    $self->Validation::Class::initialize_validator(@_);

    return $self;

}

{

    no strict 'refs';

    # inject prototype class aliases unless exist

    my @aliases = Validation::Class::Prototype->proxy_methods;

    foreach my $alias (@aliases) {

        *{$alias} = sub {

            my ($self, @args) = @_;

            $self->prototype->$alias(@args);

        };

    }

    # inject wrapped prototype class aliases unless exist

    my @wrapped_aliases = Validation::Class::Prototype->proxy_methods_wrapped;

    foreach my $alias (@wrapped_aliases) {

        *{$alias} = sub {

            my ($self, @args) = @_;

            $self->prototype->$alias($self, @args);

        };

    }

}

sub proto { goto &prototype } sub prototype {

    my $self = shift;
    my $addr = refaddr $self;

    return prototype_registry->get($addr);

}

sub DESTROY {

    my $self = shift;
    my $addr = refaddr $self;

    prototype_registry->delete($addr) if $self && prototype_registry;

    return;

}


1;

__END__

=pod

=head1 NAME

Validation::Class::Simple - Simple Ad-Hoc Data Validation

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $params = {
        name  => 'Root',
        email => 'root@localhost',
        pass  => 's3cret',
        pass2 => 's2cret'
    };

    # define object specific rules
    my $rules = Validation::Class::Simple->new(
        # define fields on-the-fly
        fields => {
            name  => { required => 1 },
            email => { required => 1 },
            pass  => { required => 1 },
            pass2 => { required => 1, matches => 'pass' },
        }
    );

    # set parameters to be validated
    $rules->params->add($params);

    # validate
    unless ($rules->validate) {
        # handle the failures
        warn $rules->errors_to_string;
    }

=head1 DESCRIPTION

Validation::Class::Simple is a simple validation module built around the
powerful L<Validation::Class> data validation framework.

This module is merely a blank canvas, a clean validation class derived from
L<Validation::Class> which has not been pre-configured (e.g. configured via
keywords, etc).

It can be useful in an environment where you wouldn't care to create a
validation class and instead would simply like to pass rules to a validation
engine in an ad-hoc fashion.

=head1 QUICKSTART

If you are looking for a data validation module with an even lower learning
curve built using the same tenets and principles as Validation::Class which is
as simple and even lazier than this module, please review the documentation for
L<Validation::Class::Simple::Streamer>. Please review the
L<Validation::Class::Cookbook/GUIDED-TOUR> for a detailed step-by-step look
into how Validation::Class works.

=head1 RATIONALE

If you are new to Validation::Class, or would like more information on the
underpinnings of this library and how it views and approaches data validation,
please review L<Validation::Class::Whitepaper>.

=head1 PROXY METHODS

Each instance of Validation::Class::Simple is associated with a prototype class
which provides the data validation engine and keeps the class namespace free
from pollution and collisions, please see L<Validation::Class::Prototype> for
more information on specific methods and attributes.

Validation::Class::Simple is injected with a few proxy methods which are
basically aliases to the corresponding prototype (engine) class methods,
however it is possible to access the prototype directly using the
proto/prototype methods.

=head2 class

    $self->class;

See L<Validation::Class::Prototype/class> for full documentation.

=head2 clear_queue

    $self->clear_queue;

See L<Validation::Class::Prototype/clear_queue> for full documentation.

=head2 error_count

    $self->error_count;

See L<Validation::Class::Prototype/error_count> for full documentation.

=head2 error_fields

    $self->error_fields;

See L<Validation::Class::Prototype/error_fields> for full documentation.

=head2 errors

    $self->errors;

See L<Validation::Class::Prototype/errors> for full documentation.

=head2 errors_to_string

    $self->errors_to_string;

See L<Validation::Class::Prototype/errors_to_string> for full documentation.

=head2 get_errors

    $self->get_errors;

See L<Validation::Class::Prototype/get_errors> for full documentation.

=head2 get_fields

    $self->get_fields;

See L<Validation::Class::Prototype/get_fields> for full documentation.

=head2 get_hash

    $self->get_hash;

See L<Validation::Class::Prototype/get_hash> for full documentation.

=head2 get_params

    $self->get_params;

See L<Validation::Class::Prototype/get_params> for full documentation.

=head2 get_values

    $self->get_values;

See L<Validation::Class::Prototype/get_values> for full documentation.

=head2 fields

    $self->fields;

See L<Validation::Class::Prototype/fields> for full documentation.

=head2 filtering

    $self->filtering;

See L<Validation::Class::Prototype/filtering> for full documentation.

=head2 ignore_failure

    $self->ignore_failure;

See L<Validation::Class::Prototype/ignore_failure> for full documentation.

=head2 ignore_unknown

    $self->ignore_unknown;

See L<Validation::Class::Prototype/ignore_unknown> for full documentation.

=head2 is_valid

    $self->is_valid;

See L<Validation::Class::Prototype/is_valid> for full documentation.

=head2 param

    $self->param;

See L<Validation::Class::Prototype/param> for full documentation.

=head2 params

    $self->params;

See L<Validation::Class::Prototype/params> for full documentation.

=head2 plugin

    $self->plugin;

See L<Validation::Class::Prototype/plugin> for full documentation.

=head2 queue

    $self->queue;

See L<Validation::Class::Prototype/queue> for full documentation.

=head2 report_failure

    $self->report_failure;

See L<Validation::Class::Prototype/report_failure> for full
documentation.

=head2 report_unknown

    $self->report_unknown;

See L<Validation::Class::Prototype/report_unknown> for full documentation.

=head2 reset_errors

    $self->reset_errors;

See L<Validation::Class::Prototype/reset_errors> for full documentation.

=head2 reset_fields

    $self->reset_fields;

See L<Validation::Class::Prototype/reset_fields> for full documentation.

=head2 reset_params

    $self->reset_params;

See L<Validation::Class::Prototype/reset_params> for full documentation.

=head2 set_errors

    $self->set_errors;

See L<Validation::Class::Prototype/set_errors> for full documentation.

=head2 set_fields

    $self->set_fields;

See L<Validation::Class::Prototype/set_fields> for full documentation.

=head2 set_params

    $self->set_params;

See L<Validation::Class::Prototype/set_params> for full documentation.

=head2 set_method

    $self->set_method;

See L<Validation::Class::Prototype/set_method> for full documentation.

=head2 stash

    $self->stash;

See L<Validation::Class::Prototype/stash> for full documentation.

=head2 validate

    $self->validate;

See L<Validation::Class::Prototype/validate> for full documentation.

=head2 validate_document

    $self->validate_document;

See L<Validation::Class::Prototype/validate_document> for full documentation.

=head2 validate_method

    $self->validate_method;

See L<Validation::Class::Prototype/validate_method> for full documentation.

=head2 validate_profile

    $self->validate_profile;

See L<Validation::Class::Prototype/validate_profile> for full documentation.

=head1 EXTENSIBILITY

Validation::Class does NOT provide method modifiers but can be easily extended
with L<Class::Method::Modifiers>.

=head2 before

    before foo => sub { ... };

See L<< Class::Method::Modifiers/before method(s) => sub { ... } >> for full
documentation.

=head2 around

    around foo => sub { ... };

See L<< Class::Method::Modifiers/around method(s) => sub { ... } >> for full
documentation.

=head2 after

    after foo => sub { ... };

See L<< Class::Method::Modifiers/after method(s) => sub { ... } >> for full
documentation.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
