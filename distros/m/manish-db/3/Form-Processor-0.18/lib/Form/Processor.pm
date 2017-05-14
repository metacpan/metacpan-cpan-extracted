package Form::Processor;
use strict;
use warnings;
use base qw/ Rose::Object  Form::Processor::Model /;
use Carp;
use UNIVERSAL::require;
use Locale::Maketext;
use Form::Processor::I18N;  # base class for language files
use Scalar::Util;

our $VERSION = '0.18';


# Define basic instance interface

use Rose::Object::MakeMethods::Generic (

    boolean => [ qw(
        ran_validation
        validated
        verbose
        readonly
    )],


    scalar => [
        item_id         => {},  # Can't init from item->id because of circular references
        errors          => {},  # total errors
        name            => { interface => 'get_set_init' },  # form name (in case using multiple forms?)
        updated_or_created => {},  # silly message.
        name_prefix     => {},  # prefix used on all name fields.
        init_object     => {},  # provides a way to init from another object.
        user_data       => {},  # Just a place to store user data.
        language_handle => { interface => 'get_set_init' },  # Locale::Maketext language handle
        field_counter   => { interface => 'get_set_init' },  # For numbering fields.

        # A field can be a form, and this is a reference to that field
        # Causes all the sub-form error messages to be sent to the parent field.
        # (implemented below)
        # parent_field    => {},
    ],


    hash => [
        # Stores CGI parameters -- init will populate hash from object
        param           => { hash_key  => 'params' },
        params          => { interface => 'get_set_init' },
        reset_params    => { interface => 'reset', hash_key => 'params' },
        delete_param    => { interface => 'delete', hash_key => 'params' },

        profile         => {},

    ],


    array => [
        fields          => {},
        clear_fields    => { interface => 'clear', hash_key => 'fields' },
        add_field       => { interface => 'push', hash_key => 'fields' },

        requires        => {},
        clear_requires  => { interface => 'clear', hash_key => 'requires' },
        add_requires    => { interface => 'push', hash_key => 'requires' },

    ],
);


=head1 NAME

Form::Processor - validate and process form data

=head1 SYNOPSIS

In an application you might want a controller to handle creating and updating a
"User" record.  And not want to write much code.  Here's using L<Catalyst> as
an example:

    package MyApplication::Controller::User;
    use strict;
    use MyApplication::Form::User;

    sub edit : Local {
        my ( $self, $c, $id ) = @_;

        # Create the form object
        my $form = MyApplication::Form::User->new( $id );


        # Update or create the user record if form posted and form validates
        $form->update_from_from( $c->request->parameters  )
            if $c->form_posted;


        $c->stash->{form} = $form;
    }


The above form class might then look like this:


    package MyApplication::Form::User;
    use strict;
    use base 'Form::Processor::Model::CDBI';

    sub object_class { 'DB::User' }

    sub profile {
        my $self = shift;

        return {
            required => {
                name        => 'Text',
                age         => 'PosInteger',
                sex         => 'Select',
                birthdate   => 'DateTimeDMYHM',
            },
            optional => {
                hobbies     => 'Multiple',
                address     => 'Text',
                city        => 'Text',
                state       => 'Select',
                email       => 'Email',
            },

            dependency => [
                [qw/ address city state /],
            ],
        };
    }

    sub options_sex {
        return (
            m => 'Male',
            f => 'Female',
        );
    }


    sub validate_age {
        my ( $self, $field ) = @_;
        $field->add_error('Sorry, you must be 18')
            if $field->value < 18;
    }

Or when you need a quick, small form do this in a controller:

    my @fields = qw/ first_name last_name email /;
    $c->stash->{form} = Form::Processor->new(
        profile => {
            required => {
                map { $_ => 'Text' } qw/ first_name last_name email /,
            },
        },
    );



=head1 DESCRIPTION

[Docs under construction.  The docs are probably, well, less concise then they could be.
Editors are welcome..]


This is a class for working with forms.  A form acts as a layer between your
internal data representation (such as a database) and the outside world (such
as a web form).  Moving data between these areas often requires validation and
encoding or expanding of the data.  For example, a date might be a timestamp
internally but externally is a collection of year, month, day, hour, minute
input fields.

A form is made up of a collection of fields of possibly different types (e.g.
Text, Email, Integer, Date), where the fields require validation before being
accepted into their internal format.  The validation process is really made up of
a number of steps, where each step can be overridden to customize the process.
See L<Form::Processor::Field> for methods specific to fields.

Forms are (typically) defined by creating a separate Perl module that includes
methods for defining the fields that make up the form, plus any special and
additional validation checks on the fields.

Form::Processor does not generate any HTML.  HTML should be generated in a
"view" (and often using templates).  And besides, HTML forms are trivial to
create and in real life almost always needs customization.  The use of a
good template system makes this nearly painless.

Likewise, there is also no method to spit out an entire web form with a single
method.  Having a single method to generate a complete HTML form is often only
useful for the most simple web forms.

This module is not restricted to use in a web environment, although that is the
typical application.  It was designed for use with Catalyst, Class::DBI,
Template-Toolkit, and HTML::FillInForm.  But, those are not required.

The design of this class is based a lot on the design of Rose::HTML::Objects,
but, as mentioned, HTML widget generation is not part of the class.  This class
focuses more on moving data between the data store to the form that from the
form to html.  It's recommended that you look over Rose::HTML::Objects if not
already done so.


=head2 The Form

As shown above in the synopsis, a "form" class is where a collection of
"fields" are defined via a profile (that looks a lot like a Data::FormValidator
profile).  In general, the fields know how to validate input data, but the form
class can also include additional validation methods for each field and can
also cross-validate fields.  The form class is what is used in your application
code.

=head2 Fields

A form's "fields" are really small individual classes and they are often
sub-classed to make more specific classes with additional constraints.  For
example, an Integer field might be a subclass of the basic Text field that
limits input values to digits.  And a year field might be a subclass of an
Integer field that limits the range of integer values.

It's recommended that you create new field classes for each specific
type of data you have.  That is, create a "DeptNumber" field that knows
what a department number will look like instead of using a generic "Text" field
and then validating that in your form.  Save field validation in the form
for validation that can't be done in a generic way (like validating that the
department number actually exists by doing a database lookup).

Unlike Rose::HTML::Objects, this class does not generate (x)html.  I prefer to
leave that up to the view (templates).  But there is a plan to add that
ability via a plug-in system for those that want it.  I just find anything to do
with HTML is better in the templates where it can be easily tweaked.

A method is provided to generate a hash of current values.  This makes
populating forms via HTML::FillInForm very easy.  HTML::FillInForm is one of
those modules that people either love or hate.  I love it because HTML forms
can be written in a very clean and generic way (i.e. no extra code needed to
populate the form widgets).  It also makes it easy to populate forms in a
number of different ways in your application, which an be handy.


=head2 Compound Fields


Rose::HTML::Objects is really nice (you should take a look), and one of its
features is it handles compound fields -- fields that are made up of other
fields such as a collection of fields that are used to specify a date and time.
This class doesn't have compound fields, but there's nothing stopping
you from defining a field that is made up of a form that includes multiple fields.
See Form::Processor::Field::DateTimeDMYHM for an example of this.  After all, a field's job
is to take input from something and create an internal value.  So, its input can
be another form made up of multiple fields.

To help with this there's a "name_prefix" form setting that can be used to help
with nested forms.


=head2 A form's model class

The base class for your forms is Form::Processor, and Form::Processor can be
used on its own.  But, the fun is when used with a "form model class" -- a
class that knows how to work with your data objects.

For example, the SYNOPSIS uses Form::Processor::Model::CDBI for working with CDBI objects.
When Form::Processor::Model::CDBI is used then valid options for a field are automatically
pulled from the database by looking at the relationships set up in the CDBI
classes.  When working with an field that "has_a" relationship with another
table, then possible options can be fetched from the other table.  These options
can then be displayed in a HTML select list.  And when validating input, the
field can check that the input matches one of the available options.

As shown in the SYNOPSIS above, when using a form model class complete
controllers can be written in two lines of code.  Here's the first line:

    my $form = MyApplication::Form::User->new( $id );

That creates a form object.  If $id is defined then the $id is fetched from the
database for pre-populating the form.  The fetched data object is stored in
$form->item.  A hash suitable for HTML::FillInForm is available in $form->fif
(which can be used in a WRAPPER in Template-Toolkit or in the end() sub in
Catalyst).

Then, the next line:

    $form->update_from_from( $c->request->parameters  )
        if $c->form_posted;

If a form was posted then call $form->update_from_form.  That method
validates the parameters and then updates (or creates) the object.  Link tables
are also updated (e.g. a user "has_many" roles using a mapping/link table).

In the template the fields can be fetched with form.field('name').  Fields
have an error method to return the error(s) found during validation.
Methods on the form object can be used to tell if validation has run
or if an object was updated or created.  See Methods below.

=head2 More on fields

Each form field is associated with a general type.  The type name
is used to load a module by that name:

    my $profile = {
        required => {
            title   => 'Text',
            age     => 'Integer',
        },
    };


Type "Text" loads the Form::Processor::Field::Text module and likewise, type
'Integer' loads Form::Processor::Field::Integer.

The most basic type is "Text" which takes a single scalar value.  A "Select"
class is similar, but its value must be a valid choice from a list of options.
A "Multiple" type is like "Select" but it allows selecting more than one value
at a time.

Each field has a "value" method, which is the field's internal value.  This is
the value your database object would have (e.g. scalar, boolean 0 or 1,
DateTime object).  A field's internal value is converted to the external value
by use of the field's C<format_value()> method.  This method returns a hash which
allows a single internal value to be made up of multiple fields externally.
For example, a DateTime object internally might be formatted as a day, month, and
year externally.

There's a form method called fif, that generates a hash of all the field's
external values.  This is quite useful for populating a form using
HTML::FillInForm.

When data is passed in to validate the form, it is trimmed of leading and trailing
whitespace by default and placed in the field's "input" attribute.  Each field has
a validate method that validates the input data and then moves it to the internal
representation in the "value" attribute.  Depending on the model, it's this
internal value that is stored or used by your application.

By default, the validation is simply to copy the data from the "input" to the "value"
field attribute, but you might have a field that must be converted from a text
representation to an object (e.g. month, day, year to DateTime).

=head1 METHODS

These are the methods that can be called on a form object.  See
L<Form::Processor::Field> for methods called on individual fields
within a form.

=over 4

=item name

Gets or set the form's name.  This can be used to
set the form's name when using multiple forms on the same page.

It's also prefixed to fields when asked for the field's id.

The default is form + a one to three digit random number.

    sub name { 'useform' }

=cut

sub init_name {
    my $form = shift;
    return 'form' . int( rand 1000 );
}


# Used by set_order call.  See Field.pm
sub init_field_counter { 1 }

=item profile

Returns the profile as a hashref as shown in the SYNOPSIS.
This is the one method that you *must* override in your form class.
This is what describes your form's fields, after all.

The profile provides a concise and easy way to define the fields in your form.
Fields can also be added indiviually to a form, but using a profile is
the recommended and common approach.

Fields typically fall into two major categories: required or optional.
Therefore, the profile definition is grouped by those categories:

    my $profile => {
        required => {
            # required fields
        },
        optional => {
            # optional fields
        },
    };

The individual field names are the hash keys, and the field type is the value:

    my $profile = {
        required => {
            title   => 'Text',
            age     => 'Integer',
        },
    };

The field type maps directly to a field module, as described above.  The values may
optionally be a hash:

    my $profile = {
        required => {
            age     => {
                type    => 'Integer',
            },
        },
    };

The only required key is "type".  Any other keys are considered method
names and will be called on the field once created:

    my $profile = {
        required => {
            favorite_color => {
                type            => 'Select',
                label_column    => 'color_name',
                active_column   => 'is_active',
            },
        },
    };

Is basically:

    require Form::Processor::Field::Select;
    my $field = Form::Processor::Field::Select->new;
    $field->name( 'favorite_color' );
    $field->type( 'Select' );
    $field->form( $form );
    $field->required( 1 );
    $field->label_column( 'color_name' );
    $field->active_column( 'is_active' );
    $form->add_field( $field );



=head2 Possible profile keys


=over 4

=item required

This points to a hash reference of field names as the keys and field
types as the values.  The field types are suffixes of the name space
Form::Processor::Field:: and will be require()ed automatically.  For example:

    sub profile {
        return {
            required => {
                first_name      => 'Text',
                roles           => 'Multiple',
            },
        };
    }

causes L<Form::Processor::Field::Text> and L<Form::Processor::Field::Multiple>
to be loaded and calls their new() method.  See L<Form::Processor::Field> for
more information on the field types.

As mentioned above, the value can optionally be a hash reference instead of a
scalar.  In this case the hash must contain a "type" key.

Each of these fields have their "required" attribute set true.

=item optional

Like above, but listed fields are not set as required.

    sub profile {
        return {
            required => {
                first_name      => 'Text',
                roles           => 'Multiple',
            },
            optional => {
                age             => 'Integer',
            }
        };
    }

=item auto_optional  auto_required

This just make the above a bit easier.

This list an array of field names.  The field types will try and be determined
by various means (by calling $form->guess_field_type).  For example, with
Form::Processor::Model::CDBI it will look at the meta_info() to guess the field type.

    auto_required => [qw/ name age sex birthdate /],
    auto_optional => [qw/ hobbies address city state /],

With CDBI, if it has a has_many relationship with another CDBI object it will
be a Select (pick one from a set of options), where a has_many relationship
would be a Multiple select.

Other methods might be used such as asking the DBI layer for the column
type information, or maybe via a method in your object classes that
returns the type for each column.

The hope is that the Form::Processor::Model:: classes can get smart about determining
the field type.

=item auto_all

*this method is not implemented*

If this is set then the value represents the method used to fetch
all the field names from the object class.

    auto_all    => 'columns',  # for cdbi objects

This is not implemented yet, but something like:

    map { $_ => 'Auto' } $form->object_class->columns;


=item dependency

This is an array of arrays of field names.  During validation if any of the
fields in a given group are found to contain the pattern /\S/ then they are
considered non-blank and then *all* of the fields in group are set to required.
This should work like DFV's dependency_groups profile entry.

    sub profile {

        my @address_group       = qw/ address city state zip /;
        my @credit_card_group   = qw/ cc_no cc_expires /;
        return {
            required => {
                name    => 'Text',
                age     => 'Integer',
                date    => 'DateTimeDMYHM',
            },
            optional => {
                comment => 'Text',
                ...
            },
            dependency => [
                \@address_group,
                \@credit_card_group,
            ],
        };
    }

This class doesn't have DFV's "dependencies" option at this time.


=item unique

This is an array ref field names that should be unique in the data
base.  This feature depends on the model class being used.

=back

=cut



=item new PARAMS


New creates a new form object.  The constructor takes name/value pairs:

    MyForm->new(
        item    => $item,
        item_id => $item->id,
        verbose => 1
    );

Or, as is commonly done, only an item or item_id needs to be passed
to the constructor.  In this case a single parameter may be supplied:

    MyForm->new( $id );

or

    MyForm->new( $item );

If the value passed in is a reference then it is assumed to have 
and "id" method.  So:

    MyForm->new( $item_object );

is the same as:

    MyForm->new(
        item    => $item_object,
        item_id => $item_object->id,
    );

The constructor can accept the following parameters:

=over 4

=item item_id - the id of the object

The id (primary key) of the item (object) that the form is updating
or has just created.  The form's model class (e.g. Form::Processor::Model::CDBI)
should have an init_item method that can fetch the object from
the object_class for this id.

=item item - the object itself

An existing object (i.e. the object that id points to).  This can
be passed in to the new constructor, but typically it's loaded
by the form's model class by its init_item method.


=item name

Name of the form.  See the L<name> method above.


=item name_prefix

Prefix used for all field names listed in profile when creating
each field.  This is useful for creating compound form fields where
a single field is made up of a collection of fields.  The collection
of fields can be a complete form.  An example might be a field
that represents a DateTime object, but is made up of separate
day, month, and year fields.

=item object_class

This defines the object class of the item (used by the form's model
class to load, create, and update the object.

Typically, this would be defined as the "object_class" method in your
form class, but can be specified in the constructor, for example,
for small forms that do not use a form class (and specify the profile
directly in the constructor -- see profile below).


=item profile

This is useful for very short forms where you do not wish to define a subclass
for your form.

    my $form =  = Form::Processor::Model::CDBI->new(
        item            => $item,
        item_id         => $id,
        object_class    => $class,
        profile         => {
            required => {
                name    => 'Text',
                active  => 'Boolean',
            },
        },
    );


=item init_object

If init_object is supplied then it will be used instead of item
to pre-populate the values in the form when init_from_object is called.

This can be useful when populating a form from default values stored in
a similar but different object than the one the form is creating.

See init_from_object below.



=back

The new() method will return false if the init() method returns false.
Typically this would happen if passed in an invalid $id.  You may override the
init() method in your form class, but make sure you call

    return unless $self->SUPER::init(@_);

from your method.


=cut

sub new {
    my $class = shift;

    my $self = bless {}, $class;

    return unless $self->init( @_ );

    $self->dump_fields if $self->verbose;

    return $self;
}

=item load_form

This option is used to load form fields into memory.
This can be called in a persistent environment such as mod_perl
or FastCGI to pre-load modules.

This method is not called during normal use of the form.

This simply creates a dummy object and calls the method to load
form fields via the profile.  Any fields your form dynamically creates
outside of of the form's C<profile> method are not loaded.  Options are not loaded
as this may require reading from a data store which may not be available.

=cut

sub load_form {
    my $class = shift;

    my $self = bless {}, $class;

    $self->SUPER::init(@_);     # load passed in parameters

    $self->build_form;          # create the form fields

    return;
}



=item clear

Clears out state information on the form.  Normally this does not need to be
called by external code.  An exception might be if the form stays in memory
between uses -- but that's not the idea quite yet

=cut

sub clear {
    my $self = shift;
    $self->validated(0);
    $self->ran_validation(0);
    $self->errors(0);
    $self->clear_values;
    $self->updated_or_created(undef);
}



=item init

This is called when the form object is first created.  Parameters are passed
unchanged from the new() call.

Returning false causes new() to return false.

As mentioned in new() above, if a single option is passed then it's considered
as a "item" parameter if it's a reference, otherwise it's considered an
"item_id".

If an "item_id" is passed in (either as a single parameter or as a named
parameter) the init method will return false if the init_item method
returns false.  (Calling the item method when item is undefined automatically
calls the init_item method.)  The init_item method is typically defined in
the form's model class and should know how to translate an item_id into
an item object.  See "init_item" below.

So, the idea is you can pass in an item_id into the constructor
and have the init_item method validate the item_id and avoid
validating the $id in the calling code (e.g. in a controller method).

    MyApp::Form->new( $id ) or return 'Invalid id supplied';

Note that if $id is undefined then new() will still return true.  This allows the
same code to be used for both create and update forms.


The init method calls the build_form method which reads the profile and creates
the field objects.  See that method for its magic.

The method init_from_object is called.  This is typically specific to the type
of form model used (e.g. CDBI) and is used to load each field's internal value
from the object (which can then be used to populate the HTML form with
$form->fif).  init_from_object does nothing if no item_id (or item)
is available.  This would be the case when filling in a new blank form.

If an "init_object" is passed into the constructor then init_from_object
will use this obeject (instead of "item") to load the initial field values.
This is useful when initializing a form with values from another object.

Finally, the load_options method is called to load options for each field
value used on multiple-choice fields.  Typically, the form's model class
will know how to load the options for each field by looking at the form's
class relationships.  See load_options below.

Again, this method will return false if an item_id is supplied and an
item cannot be loaded from that id.


=cut

sub init {
    my $self = shift;


    # Deal with passing a single value to new()
    # which would be the item id or item object

    if ( 1 == @_ ) {
        my $id = shift;

        if ( ref $id ) { # passed an existing item $$$ FIXME use Scalar::Util::blessed
            @_ = ( item => $id, item_id => $id->id );
        } else {
            @_ = ( item_id => $id );
        }
    }


    $self->SUPER::init(@_);     # load passed in parameters

    $self->build_form;          # create the form fields


    # if an item id passed in try and load
    # and return false if the item is not loaded.
    # This just helps in validating the id passed in the controller

    return if defined $self->item_id && !$self->item;



    $self->init_from_object;    # load values from object, if item exists;

    $self->load_options;        # load options -- need to do after loading item

    return 1;
}


=item build_form

This parses the form profile and creates the individual
field objects.  It calls the make_field() method for each field.
See the profile() method above for details on the profile format.

For "Auto" field types it calls the guess_field_type() method with
the field name as a parameter.  Form model classes will override
guess_field_type(), or you can override in your own form class.  You
might do that if your field names are labeled with their type --
"event_time" "age_int", etc.  Although that would be an odd thing
to do.


The above can also return an array reference.

=cut

sub build_form {
    my $self = shift;

    my $profile = $self->profile;

    croak "Please define 'profile' method in subclass" unless ref $profile eq 'HASH';


    ### $$$ look at all keys in profile and allow keys to be Field names.


    for my $group ( qw/ required optional / ) {
        my $required = 'required' eq $group;

        $self->_build_fields( $profile->{$group}, $required );

        my $auto_fields = $profile->{ 'auto_' . $group } || next;

        $self->_build_fields( $auto_fields, $required );
    }
}

=item load_options


For all fields, if the field is a "Select" or "Multiple" (i.e. has an "options"
method) then will call "options_$field_nane" if that method exists, otherwise
will call the "lookup_options" method.

This should be called after $self->item is loaded because existing values
may be needed in setting the valid options.

In general, "options_$field_name" would be defined in your form class, where
"lookup_options" would be defined in the model form class and handle the more
general case of looking up the available options in the database.

Here's an example of a method defined in your form's class to populate the
"fruit" field with possible options:

    sub options_fruit {
        return (
            1 => 'Apple',
            2 => 'Grape',
            3 => 'Cherry',
        );
    }

=cut

sub load_options {
    my $self = shift;

    $self->load_field_options( $_ ) for $self->fields;
}

# Why are the options not loaded via the field?  Because the Model class
# overrides this class (Form::Processor), not a field class.  Makes is a bit
# harder to override the individual field classes that have options.  This
# probably needs addressing.

sub load_field_options {
    my ( $self, $field, @options ) = @_;

    # Populate the field?
    return unless $field->can('options');


    my $method = 'options_' . $field->name;

    @options = $self->can( $method )
            ? $self->$method( $field )
            : $self->lookup_options( $field ) unless @options;

    return unless @options;


    @options = @{$options[0]} if ref $options[0];

    croak "Options array must contain an even number of elements for field " . $field->name
        if @options % 2;

    my @opts;
    push @opts, { value => shift @options, label => shift @options }
        while @options;

    $field->options( \@opts ) if @opts;

}

=item dump_fields

Dumps the fields of the form.  For debugging.

=cut

sub dump_fields {
    my $self = shift;
    for my $field ( $self->fields ) {
        $field->dump;
        $field->form->dump_fields if $field->can('form');
    }
}


# create fields.

sub _build_fields {
    my ( $self, $fields, $required ) = @_;

    return unless $fields;

    if ( ref($fields) eq 'ARRAY' ) {
        for ( @$fields ) {
            my $field = $self->make_field( $_, 'Auto' ) || next;
            $field->required( $required );
            $self->add_field( $field );
        }

        return;
    }

    # otherwise, defined field types

    while ( my( $name, $type ) = each %$fields ) {
        my $field = $self->make_field( $name, $type ) || next;

        $field->required( $required );
        $self->add_field( $field );
    }
}


=item make_field

    $field = $form->make_field( $name, $type );

Maps the field type to a field class, and returns the field by calling
new() on that field class.

The "$name" parameter is the field's name (e.g. first_name, age).

If the second parameter is a scalar it's taken as the field's type
(e.g. Text, Integer, Multiple).

If the second parameter is a hash reference then the field type is determined
from the required "type" value (i.e. C<$type->{type}> ).


The fields are assumed to be in the Form::Processor::Field name
space.  If you want to explicitly list the field's package prefix it
with a plus sign:

    required => {
        name    => 'Text',  # Form::Processor::Field::Text
        foo     => '+My::Field::Foo',
    },



=cut

sub make_field {
    my ( $self, $name, $type_data ) = @_;

    croak 'Must pass name and type to make_field'
        unless $name && $type_data;

    $type_data = { type => $type_data } unless ref $type_data eq 'HASH';

    # Grab field type and load the class

    my $type = $type_data->{type} || die 'Failed to provide field type to make_field()';
    $type = $self->guess_field_type( $name ) if $type eq 'Auto';

    croak "Failed to set field type for field [$name]" unless $type;

    my $class = $type =~ s/^\+//
        ? $type
        : 'Form::Processor::Field::' . $type;

    $class->require or die "Failed to load field '$type': $UNIVERSAL::require::ERROR";


    # Create instance

    $type_data->{name} = $self->name_prefix
        ? $self->name_prefix . '.' . $name
        : $name;

    $type_data->{form} = $self;


    my $field = $class->new( %{$type_data} );

    # Define default field order
    unless ( $field->order ) {
        my $fields = $self->fields;
        $field->order( $fields ? scalar @{ $self->fields } + 1 : 1 );
    }


    return $field;

}




=item init_from_object

This method populates each field's value ($field->value) with
either a scalar or an array ref from the object stored in $form->item.
It does this by calling init_value() passing in the field object and
$form->item.  init_value() must return the value(s).

init_value() should be overridden in the form model subclass.  For example, in
::Model::CDBI objects are expanded to primary keys for object methods that
return a list of objects (e.g. has_many relationships).

If a method "init_value_$name" is found then that method is called instead.
This allows overriding specific fields in your form class.

=cut


sub init_from_object {
    my $self = shift;


    my $item = $self->init_object || $self->item || return;

    for my $field ( $self->fields ) {

        my @values;

        my $method = 'init_value_' . $field->name;
        if ( $self->can( $method ) ) {
            @values = $self->$method( $field, $item );

        } else {
            @values = $self->init_value( $field, $item );
        }

        my $value = @values > 1 ? \@values : shift @values;

        # Handy for later compare
        $field->init_value( $value );
        $field->value( $value );
    }

}





=item params

Returns a hash of parameters.  The parameters are initialized from the 
item (see init_params() below), or are the last set of parameters passed
to the validate() function.

See also the fif() method.

=item init_params

Calls each field's format_value() method to populate a parameters hash from
each field's internal value.  This is used to build a hash of all
values in the form for use in populating the HTML form (using HTML::FillInForm).
That has is returned by this method.

This method is called automatically when $form->params and params
are not defiend.  You may need to call this method directly if $form->item
changes while the form object is in memory to force a refresh of params.

=cut

sub init_params {
    my $form = shift;
    my %hash;
    for my $field ( $form->fields ) {

        next if $field->writeonly;

        my %params = $field->format_value;

        while ( my( $k, $v ) = each ( %params ) ) {
            $hash{ $k } = $v if defined $v;
        }
    }

    return \%hash;
}

=item clear

Clears the internal and external values of the form

=cut

sub clear_values {
    my $form = shift;

    for ( $form->fields ) {
        $_->value( undef );
        $_->input( undef );
    }
    $form->reset_params;
}

=item fif -- "fill in form"

Returns a hash of values suitable for use with HTML::FillInForm.
It's a copy of $self->params with any passowrd fields removed.

=cut


sub fif {
    my $self = shift;

    my %hash = $self->params;

    # remove password fields
    for my $field ( $self->fields ) {
        delete $hash{ $field->name } if $field->password;
    }
    return \%hash;
}

=item sorted_fields

Calls fields and returns them in sorted order by their "order"
value.


=cut

sub sorted_fields {
    my $form = shift;

    my @fields = sort { $a->order <=> $b->order } $form->fields;

    return wantarray ? @fields : \@fields;
}



=item field NAME

Searches for field named "NAME".
dies on not found.  Useful for entering the wrong field.

    my $field = $form->field('first_name');

Pass a second true value to not die on errors.

=cut

sub field {
    my ( $self, $name, $no_die ) = @_;

    $name = $self->name_prefix . '.' . $name if $self->name_prefix;

    for my $field ( $self->fields ) {
        return $field if $field->name eq $name;
    }

    return if $no_die;

    croak "Failed to lookup field name [$name] in form [$self]";
}

=item exists

Returns true (the field) if the field exists

=cut

sub exists {
    my ($self, $name) = @_;
    return $self->field( $name, 1 );
}


=item language_handle

Set or get the Locale::Maketext language handle.  If not set will look for a
language handle in the environment variable $ENV{LANGUAGE_HANDLE} and
otherwise will Create a default language handler using the name space:

    Form::Processor::I18N

You can add your own language classes to this name space, but a more
common use might be to provide an application-wide language handler.

The language handler can be passed in when creating your form instance
or set after the object is created.

=cut

sub init_language_handle {
    my $self = shift;

    my $lh = $ENV{LANGUAGE_HANDLE} || Form::Processor::I18N->get_handle ||
        die "Failed call to Text::Maketext->get_handle";

    return $lh;

}





=item validate

Validates the form from the CGI parameters passed in.
The parameters must be a hash ref with multiple values as array refs.

Returns false if validation fails.

Note that this returns the cached validated result if $form->ran_validation
is true.  So to force a re-validation call $form->clear.  This should only
happen if the $form object stays in memory between requests.

For each field:

    1) hash parameters are trimmed (override in field class) and
    saved to each field's "input" attribute.

    2) dependency fields are set by setting fields to required if needed

    3) validate_field is called for each field.  This tests that required
    fields are not blank, and that only fields marked as multiple can
    include multiple values.  For Selects and Multiple type fields the values
    must match existing options.

    If the above tests pass then the fields "validate" method is called.
    The validate method tests the input value (or values) and sets
    the field's input value based on the input data.

    The default validate method simply copies the input attribute to the
    value attribute:

        $field->value( $field->input );


    4) The form's validate_$fieldname is called, if the method exists AND
    if there's a value in the field.  Use cross_validate if you need to 
    validate fields that may be blank (such as setting defaults).

    5) The models validation method is called, if exists.  For example,
    this is used to check that a value is unique in the database.

Finally, after all fields have been processed:

    6) The form's cross_validate is called.  This allows access to all
    inflated values.  This is called even if not all fields validated.
    This just makes it easier to do bulk validation where fields may be
    in common.

If you override validate() make sure you set the flag fields like the validate
here does.

=cut

sub validate {
    my ( $self, $params ) = @_;

    $params ||= {};


    return $self->validated if $self->ran_validation;

    # Set params -- so can be used by fif later.
    $self->params( $params );

    $self->set_dependency;  # set required dependencies


    # First pass: trim values and move to "input" slot

    $_->input( $_->trim_value( $params->{ $_->full_name } ) )
            for $self->fields;



    # Second pass: Validate each field and "inflate" input -> value.

    for my $field ( $self->fields ) {
        next if $field->clear;  # Skip validation
        $field->validate_field;
    }


    # Third pass: call local validation for all *defined* values.

    for my $field ( $self->fields ) {
        next if $field->clear;  # Skip validation
        next unless defined $field->value;

        # these methods have access to the inflated values
        my $method = 'validate_' . $field->name;
        $self->$method( $field ) if $self->can( $method );
    }


    # only call if no errors?  Only call on validated fields?
    $self->cross_validate( $params );


    # model specific validation (e.g. validation that requires database lookups)
    $self->model_validate;


    $self->clear_dependency;

    # should this be an init_errors method?
    my $errors;
    for ( $self->fields ) {
        $errors++ if $_->errors;
    }

    $self->errors($errors);
    $self->ran_validation( 1 );
    $self->validated( !$errors );

    $self->dump_validated if $self->verbose;

    return $self->validated;


}

sub dump_validated {
    my $self = shift;
    warn "-- validated --\n";
    warn $_->name, ": ", ($_->errors ? join(' | ', $_->errors) : 'validated!'),"\n"
        for $self->fields;
}


=item cross_validate

This item can be overridden in the base class for the form.  It's useful
for cross checking *values* after they have been saved as their final
validated value.

This method is called even if some fields did not validate.

=cut

sub cross_validate { 1 }


# here we get a bit more iffy.
# Remember, this is before white space is trimmed.
# and before any validation.

sub set_dependency {
    my $self = shift;

    my $depends = $self->profile->{dependency} || return;

    my $params = $self->params;

    for my $group ( @$depends ) {
        next if @$group < 2;

        # process a group of fields

        for my $name ( @$group ) {


            # is there a value?
            my $value = $params->{$name};

            next unless defined $value;


            # The exception is a boolean can be zero which we count as not set.
            # This is to allow requiring a field when a boolean is true.
            next if $self->field($name)->type eq 'Boolean' && $value == 0;


            if ( ref $value ) {
                next unless grep { /\S/ } @$value;  # at least one value is non-blank
            } else {
                next unless $value =~ /\S/;
            }


            # one field was found non-blank, so set all to required
            for ( @$group ) {
                my $field = $self->field( $_ );
                next unless $field && !$field->required;
                $self->add_requires( $field );  # save for clearing later.
                $field->required(1);
            }
            last;
        }
    }
}

sub clear_dependency {
    my $self = shift;

    $_->required(0) for $self->requires;
    $self->clear_requires;
}




=item has_error

Returns true if validate has been called and the form did not
validate.

=cut

sub has_error {
    my $self = shift;
    return $self->ran_validation && !$self->validated;
}

sub has_errors {
    for ( shift->fields ) {
        return 1 if $_->errors;
    }
    return 0;
}

=item error_fields

Returns list of field with errors.

=cut

sub error_fields { return grep { $_->errors } shift->sorted_fields }

=item error_field_name

Returns the names of the fields with errors.

=cut

sub error_field_names { return map { $_->name } shift->error_fields }


=item required_text

Returns either "required" or "optional" for the specified field.

Something like:

    <div class="[% field.required_text %]">

=cut

sub required_text {
    my ( $self, $name ) = @_;
    return 'unknown' unless $name;
    return 'unknown' unless my $field = $self->field( $name );
    return $field->required_text;
}

=item value

Short cut for:

    $form->field($name)->value;

Can pass a second true value to avoid die on not found.

=cut

sub value {
    my ( $form, $name, $no_die ) = @_;
    my $field = $form->field( $name, $no_die ) || return;
    return $field->value;
}


=item value_changed

Returns true if the value in the item has changed from what is currently in the
field's value.

This only does a string compare (arrays are sorted and joined).
And note that:

    'foo' != ['foo']

which is probably incorrect.

=cut

sub value_changed {
    my ( $self, $name ) = @_;
    croak "value_chagned requires a field name" unless $name;

    my $field = ref ($name) ? $name : $self->field( $name );
    croak "Failed to lookup field name [$name]\n" unless $field;

    return $field->value_changed;
}



=item uuid

Generates a hidden html field with a unique ID which
the model class can use to check for duplicate form postings.

=cut

sub uuid {
    my $form = shift;
    require Data::UUID;
    my $uuid = Data::UUID->new->create_str;
    return qq[<input type="hidden" name="form_uuid" value="$uuid">];
}


=item parent_field

This value can be used to link a sub-form to the parent field.

One way to create a compound field -- a field that is composed of
other fields -- is by having the field include a form that is made up of
fields.  For example, a date field might be made up of a form that includes
fields for the day, month, and year.

If a form has a parent_field associated with it then any errors will be pushed
onto the parent_field instead of the current field.  In the date example, an error
in the year field will cause the error to be assigned to the date field, not directly
on the year field.

This stores a weakened value.

=cut

sub parent_field {
    my $self = shift;
    return Scalar::Util::weaken( $self->{parent_field} = shift ) if ( @_ );
    return $self->{parent_field};
}




=back



=head1 CREATING A MODEL CLASS

Form model classes are used to moved form data between a
database and the form, typically via an object relational
mapping tool (ORM).

See L<Form::Processor::Model> for details.



=head1 THINGS TO WONDER ABOUT

The CGI parameters passed in are stored in Form::Processor instead of in
each field object.

When a field is entered and then changed to a different format, what format
should be displayed?  That is, a form with a date is updated.  The text
"tomorrow" is entered.  If the form doesn't validate what should display?
The actual formatted date for tomorrow, or still the text "tomorrow"?

Currently, if the form doesn't validate "tomorrow" is displayed.  But if
the form validates (and is updated by the model class) then the form will
display the formatted date for tomorrow.  That still may be different from
what the date might look like next time it's fetched from the database 
(due to timezone settings).  Another way to go would be to re-load from the
database object to make the date look like it will next time it's fetched
on a fresh form.

Init from object happens in Form::Processor, too.  It would be nice to have each
field know how to initalize from the source object.  But, that doesn't work well
with overriding Form::Processor with the Model class.


=head1 AUTHOR

Bill Moseley - with *much* help from John Siracusa

=head1 COPYRIGHT

L<Form::Processor> is Copyright (c) 2006-2007 Bill Moseley.  All rightes
reserved.

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SUPPORT / WARRANTY

L<Form::Processor> is free software and is provided WITHOUT WARRANTY OF ANY KIND.
Users are expected to review software for fitness and usability.

=cut

1;





