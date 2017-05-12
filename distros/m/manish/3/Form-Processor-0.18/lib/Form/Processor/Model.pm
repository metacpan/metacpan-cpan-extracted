package Form::Processor::Model;
use strict;
use warnings;
use base 'Rose::Object';
use Carp;
use Data::Dumper;
use Scalar::Util qw/ blessed /;


# Define instance data

use Rose::Object::MakeMethods::Generic (

    scalar => [
        object_class    => { interface => 'get_set_init' },
        #item_id         => {},  # Can't init from item->id because of circular references
        item            => { interface => 'get_set_init' },
    ],
);

=head1 NAME

Form::Model -- default model base class

=head1 SYNOPSIS

    # A class to define a form in your application
    package MyApplication::Form::User;
    use strict;

    # Inherit from the form model class for your ORM
    use base 'Form::Processor::Model::CDBI

    # Relate the form to a specific ORM class
    sub object_class{ 'MyDB::User' }

    sub profile {

        [...]
    }

=head1 DESCRIPTION

This is an empty base class that defines methods called by
Form::Processor to support interfacing forms with a data store
such as a database.

This module provides instructions on methods to override to create
a Form::Processor::Model class to work with a specific object relational
mapping (ORM) tool.

For an example see L<Form::Processor::Model::CDBI> for working with
the Class::DBI ORM.

=head1 METHODS

=over 4

=item object_class

This sets and returns a value used by the model class to access
the ORM class related to a form.

For example, if the model class interfaces with Class::DBI and
a form is created for updating, say, MyDB::Users then in your form
class:

    sub object_class { 'MyDB::Users' }

This gives the model class a way to access the data store.
If this is not a fixed value (as above) then do not define the
method in your subclass and instead set the value when the form
is created:

    my $form = MyApp::Form::Users->new;
    $form->object_class( $my_object );

The value can be any scalar (or object) needed by the specific ORM
to access the data related to the form.

This method does not need to be defined in a model subclass unless
you wish to do extra validation.

The default returns the class of "item", if item is defined.  It's not as useful
as it sounds because "item" doesn't exist when creating new records.

This can also be set as a parameter to new, but will be overridden in subclasses.

=cut


sub init_object_class {
    my $self = shift;
    my $item = $self->item;
    return ref $item;   # may be undefined
}



=item init_item

This is called first time $form->item is called.  This method must be
defined in the model class to fetch the object based on the item id.
It should return the item's object.  Column values are fetched and updated
by calling methods on the returned object.

For example, with Class::DBI you might return:

    return $self->object_class->retrieve( $self->item_id );

=cut

sub init_item { return }


=item guess_field_type

Returns the guessed field type.  The field name is passed as the first argument.
This is only required if using "Auto" type of fields in your form classes.

The default is to die, since we can't guess.  To be useful this must be
overridden in a form model class.  You could override this in your form class, for
example, if you use a field naming convention that indicates the field type.

Form::Processor::Model::CDBI uses CDBI's meta_info() method to look at
relationships and figure out the field type.  Other form model classes might
look at the database for this information, for example.

=cut

sub guess_field_type { Carp::confess "Don't know how to determine field type of [$_[1]]" }


=item lookup_options

This method is called to find possible options for a given field
from the database.  The default method returns undef.

Returns an array reference of key/value pairs for the column passed in.
These values are used for the values and labels for field types that
provide a list of options to select from (e.g. Select, Multiple).

A 'Select' type field (or a field that inherits from
Form::Processor::Field::Select) can set a number of scalars that control how
options are looked up:

    label_column()          - the name of the column that holds the label
    active_column()         - column name that indicates if a row is acitve
    sort_order()            - column name used for sorting the options

The default for label_column is "name".

Form::Processor::Model::CDBI, for example, uses meta_info() to look at related
classes and returns a list of options sorted by the label column which by
default is "name".


=cut

sub lookup_options { return }



=item init_value

This method populates a form field's value from the item object.
This is typically done by calling the field's name as an method
on the object.

The default method basically does:

    my $name = $field->name;
    return $item->can( $name ) ? $item->$name : undef
        if blessed( $item );

=cut

sub init_value {
    my ($self, $field, $item) = @_;
    my $name = $field->name;

    return $item->can( $name ) ? $item->$name : undef
        if blessed( $item );


    return $item->{$name};

}

=item update_from_form

Update or create the object.

This needs to be overridden in the model subclass or in your
form subclass.

It should update $form->item, if set, otherwise create a new item.

The update/create should be done inside a transaction if do_transaction is
available.

Any field names that are related to the class by "has_many" and have a mapping
table should also be updated.

Validation must also be run unless validation has already been run.
($form->clear might need to be called if the $form object stays in memory
between requests.)

See Form::Processor::Model::CDBI for an example.


The default method dies.

=cut

sub update_from_form {
    die "must define 'update_from_form' in Form::Processor::Model subclass";
}




=item model_validate

Validates profile items that are dependent on the model.
This is called via the validation process and the model class
must at least validate "unique" constraints defined in the form
class.

Any errors on a field found should be set by calling the field's
add_error method:

    $field->add_error('Value must be unique in the database');

The default method does nothing.

=cut

sub model_validate { };




=back

=head1 AUTHOR

Bill Moseley

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.


=cut

1;




















