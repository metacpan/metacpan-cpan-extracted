package Valiant;

our $VERSION = '0.001017';
$VERSION = eval $VERSION;

1;

=head1 NAME

Valiant - Object validation inspired by Ruby on Rails and more.

=begin html

<a href="https://github.com/jjn1056/valiant/actions"><img src="https://github.com/jjn1056/valiant/actions/workflows/linux.yml/badge.svg"></a>
<a href="https://github.com/jjn1056/valiant/actions"><img src="https://github.com/jjn1056/valiant/actions/workflows/macos.yml/badge.svg"></a>
<a href="https://github.com/jjn1056/valiant/actions"><img src="https://github.com/jjn1056/valiant/actions/workflows/windows.yml/badge.svg"></a>
<a href="https://metacpan.org/pod/Valiant"><img src="https://badge.fury.io/pl/Valiant.svg"></a>
<a href="https://codecov.io/github/jjn1056/Valiant/?branch=main"><img alt="Coverage" src="https://codecov.io/github/jjn1056/Valiant/coverage.svg?branch=main"></a>

=end html

=head1 SYNOPSIS

    package Local::Person;

    use Moo;
    use Valiant::Validations;
    use Valiant::Filters;

    has name => (is=>'ro');
    has age => (is=>'ro');

    filters_with => 'Trim';

    validates name => (
      length => {
        maximum => 10,
        minimum => 3,
      }
    );

    validates age => (
      numericality => {
        is_integer => 1,
        less_than => 200,
      },
    );

    validates_with 'MySpecialValidator' => (arg1=>'foo', arg2=>'bar');

    my $person = Local::Person->new(
        name => 'Ja',
        age => 300,
      );

    $person->validate;
    $person->valid;     # FALSE
    $person->invalid;   # TRUE

    my %errors = $person->errors->to_hash(full_messages=>1);

    # \%errors = +{
    #   age => [
    #     "Age must be less than 200",
    #   ],
    #   name => [
    #     "Name is too short (minimum is 3 characters)',   
    #   ],
    # };

=head1 DESCRIPTION

Domain level validations for L<Moo> or L<Moose> classes and related capabilities such as attribute
filtering and internationalization.  Provides a domain specific language
which allows you to defined for a given class what a valid state for an instance of that
class would be and to gather reportable error messages.  Used to defined constraints
related to business logic or for validating user input (for example via CGI forms).

When we say domain level or business logic validation, what we mean is that
invalid data is a possible and expected state that needs to be evaluated and reported to
the end user for correction.  For example when writing a web application you might have
a form that requests user profile information (such as name, DOB, address, etc).  Its an
expected condition that the user might submit form data that is invalid in some way (such
as a DOB that is in the future) but is still 'well formed' and is able to be processed.
In these cases your business logic would be to inform the user of the incorrect data and
request fixes (rather than simply throw a 500 server error and giving up).  

This differs from type constraints (such as L<Type::Tiny>) that you might put on your
L<Moo> attributes which are used to express when attributes have values that are
so unacceptable that no further work can be done and an exception must be thrown. 

In fact you will note that when using validations that you generally won't add type constraints
on your L<Moo> attributes.  That's because type constraints are applied when the
object is instantiated and throw an exception when they fail.  Validations on the other 
hand permit you to create the object and collect all the validation failure conditions.
Also since you have a created object you can do more complex validations (such as those
that involve the state of more than one attribute).  You would only use attribute type
constraints when the created object would be in such an invalid state that one could
not correctly validate it anyway.  An example of this might be when an attribute is assigned
an array value when a scalar is expected.

L<Valiant> fits into a similar category as L<HTML::Formhander> and L<FormFu> although
its not HTML form specific. Prior art for this would be the validations system for ActiveRecords 
in Ruby on Rails and the Javascript library class-validator.js, both of which the author reviewed 
extensively when writing this code:

L<https://rubyonrails.org>, L<https://github.com/typestack/class-validator>

Documentation here details using L<Valiant> with L<Moo> or L<Moose> based classes.
If you want to use L<Valiant> with L<DBIx::Class> you will also wish to review
L<DBIx::Class::Valiant> which details how L<Valiant> glues into L<DBIx::Class>.

This document reviews all the bits of the L<Valiant> system as a whole (validations, filters,
internationalization, errores etc).   You might also like to review API details from the following
files:

L<Valiant::Validates>, a L<Moo::Role> which adds a validation API to your class, or L<Valiant::Validations>
which wraps L<Valiant::Validates> in an easy to use DSL (domain specific language).

L<Valiant::Filterable>, a L<Moo::Role> which adds API to apply filtering to incoming attributes at
object creation time, or L<Valiant::Filters>, which wraps this in an easy to use DSL.

L<Valiant::I18N>, API information on how we provide internationalized error messages for your
validations.

L<Valiant::Validator> and L<Valiant::Filter> which provides details about validations and filters that
are packaged with L<Valiant>.

=head1 WHY OBJECT VALIDATION AS CLASS DATA?

Validating the state of things is one of the most common tasks we perform.  For example
a user might wish to change their profile information and you need to make sure that
the new settings conform to acceptable limits (such as the user first and last name
fits into the database and have acceptable characters, that a password is complex enough
and that an address is complete, etc).  This logic can get tricky over time as a system grows in
complexity and edge cases need to be accounted for (for example for business reasons you might
wish to allow pre-existing users to conform to different password complexity constraints or
require newer users to supply more profile details).

One approach to this is to build a specific validation object that receives and processes
data input.  If the incoming data passes, you can proceed to send the data to your
storage object (such as L<DBIx::Class>)  If it fails you then proceed to message the user the
failure conditions.  For example this is the approach taken by L<HTML::Formhandler>.

The approach has much to merit because it clearly separates your validation logic from
your storage logic.  However when there is a big affinity between the two (such as when
all your HTML forms are very similar to your database tables) this can lead to a lot of
redundant code (such as defining the same field names in more than one class) which leads
to a maintainance and understanding burden.  Also it can be hard to do proper validation
without access to a data object since often you will have validation logic that is dependent
on the current state of your data.  For example you might require that a new password not
be one of the last three used; in this case you need access to the storage layer anyway.

L<Valiant> offers a DSL (domain specific language) for adding validation meta data as
class data to your business objects.  This allows you to maintain separation of
concerns between the job of validation and the rest of your business logic but also keeps
the validation work close to the object that actually needs it, preventing action at a
distance confusion.  The actual validation code can be neatly encapsulated into standalone
validator classes (subclasses based on L<Valiant::Validator> or L<Valiant::Validator::Each>)
so they can be reused across more than one business object. To bootstrap your validation work,
L<Valiant> comes with a good number of validators which cover many common cases, such as validating
string lengths and formats, date-time validation and numeric validations.  Lastly, the validation meta data
which is added via the DSL can aggregate across consumed roles and inherited classes.  So you can
create shared roles and base classes which defined validations that are used in many places.

Once you have decorated your business logic classes with L<Valiant> validations, you can 
run those validations on blessed instances of those classes and inspect errors.  There is
also some introspection capability making it possible to do things like generate display UI
from your errors.

=head1 EXAMPLES

The following are some example cases of how one can use L<Valiant> to perform object validation

=head2 The simplest possible case

At its most simple, a validation can be just a reference to a subroutine which adds validation
error messages based on conditions you code:

    package Local::Simple

    use Valiant::Validations;
    use Moo;

    has name => (is => 'ro');
    has age => (is => 'ro');

    validates_with sub {
      my ($self, $opts) = @_;
      $self->errors->add(name => "Name is too long") if length($self->name) > 20;
      $self->errors->add(age => "Age can't be negative") if  $self->age < 1;
    };

    my $simple = Local::Simple->new(
      name => 'A waaay too loooong name', # more than 20 characters
      age => -10, # less than 1
    );

    $simple->validate;
    $simple->valid;     # FALSE
    $simple->invalid;   # TRUE

    my %errors = $simple->errors->to_hash(full_messages=>1);

    #\%errors = {
    #  age => [
    #    "Age can't be negative",
    #  ],
    #  name => [
    #    "Name is too long",
    #  ],
    #}

The subroutine reference that the C<validates_with> keyword accepts will receive the blessed
instance as the first argument and a hash of options as the second.  Options are added as
additional arguments after the subroutine reference.  This makes it easier to create parameterized
validation methods:

    package Local::Simple2;

    use Valiant::Validations;
    use Moo;

    has name => (is => 'ro');
    has age => (is => 'ro');

    validates_with \&check_length, length_max => 20;
    validates_with \&check_age_lower_limit, min => 5;

    sub check_length {
      my ($self, $opts) = @_;
      $self->errors->add(name => "is too long") if length($self->name) > $opts->{length_max};
    }

    sub check_age_lower_limit {
      my ($self, $opts) = @_;
      $self->errors->add(age => "can't be lower than $opts->{min}") if $self->age < $opts->{min};
    }

    my $simple2 = Local::Simple2->new(
      name => 'A waaay too loooong name',
      age => -10,
    );

    $simple2->validate;
    $simple2->valid;     # FALSE
    $simple2->invalid;   # TRUE

    my %errors = $simple2->errors->to_hash(full_messages=>1);

    #\%errors = {
    #  age => [
    #    "Age can't be lower than 5",
    #  ],
    #  name => [
    #    "Name is too long",
    #  ],
    #}

The validation methods have access to the fully blessed instance so you can create complex
validation rules based on your business requirements, including retrieving information from
shared storage classes.

Since many of your validations will be directly on attributes of your object, you can use the
C<validates> keyword which offers some shortcuts and better code reusability for attributes.
We can rewrite the last class as follows:

    package Local::Simple3;

    use Valiant::Validations;
    use Moo;

    has name => (is => 'ro');
    has age => (is => 'ro');

    validates name => ( \&check_length => { length_max => 20 } );
    validates age => ( \&check_age_lower_limit => { min => 5 } );

    sub check_length {
      my ($self, $attribute, $value, $opts) = @_;
      $self->errors->add($attribute => "is too long", $opts) if length($value) > $opts->{length_max};
    }

    sub check_age_lower_limit {
      my ($self, $attribute, $value, $opts) = @_;
      $self->errors->add($attribute => "can't be lower than $opts->{min}", $opts) if $value < $opts->{min};
    }

    my $simple3 = Local::Simple2->new(
      name => 'A waaay too loooong name',
      age => -10,
    );

    $simple3->validate;

    my %errors = $simple3->errors->to_hash(full_messages=>1);

    #\%errors = {
    #  age => [
    #    "Age can't be lower than 5",
    #  ],
    #  name => [
    #    "Name is too long",
    #  ],
    #}

Using the C<validates> keyword allows you to name the attribute for which the validations are intended.
When you do this the signature of the arguments for the subroutine reference changes to included both
the attribute name (as a string) and the current attribute value.  This is useful since you can now
use the validation method across different attributes, avoiding hardcoding its name into your validation rule.
One difference from C<validates_with> you will note is that if you want to pass arguments as parameter options
you need to use a hashref and not a hash.  This is due to the fact that C<validates> can take a list of
validators, each with its own arguments. For example you could have the following:

    validates name => (
      \&check_length => { length_max => 20 },
      \&looks_like_a_name,
      \&is_unique_name_in_database,
    );

Also, similiar to the C<has> keyword that L<Moo> imports, you can use an arrayref of attribute name for grouping
those with the same validation rules:

    validates ['first_name', 'last_name'] => ( \&check_length => { length_max => 20 } );

At this point you can see how to write fairly complex and parameterized validations on your attributes
directly or on the object as a whole (using C<validates> for attributes and C<validates_with> for validations
that are not directly tied to an attribute but instead validate the object as a whole).  However it is
often ideal to isolate your validation logic into a stand alone class to promote code reuse as well as
better separate your valiation logic from your classes.  

=head2 Using a validator class

Although you could use subroutine references for all your validation if you did so you'd likely end
up with a lot of repeated code across your classes.  This is because a lot of validations are standard
(such as string length and allowed characters, numeric ranges and so on).  As a result you will likely
build at least some custom validators and make use of the prepacked ones that ship with L<Valiant> (see L<Valiant::Validator>).
Lets return to one of the earlier examples that used C<valiates_with> but instead of using a subroutine
reference we will rewrite it as a custom validator:

    package Local::Person::Validator::Custom;

    use Moo;
    with 'Valiant::Validator';

    has 'max_name_length' => (is=>'ro', required=>1);
    has 'min_age' => (is=>'ro', required=>1);

    sub validate {
      my ($self, $object, $opts) = @_;
      $object->errors->add(name => "is too long", $opts) if length($object->name) > $self->max_name_length;
      $object->errors->add(age => "can't be lower than @{[ $self->min_age ]}", $opts) if $object->age < $self->min_age;
    }

And use it in a class:

    package Local::Person;

    use Valiant::Validations;
    use Moo;

    has name => (is => 'ro');
    has age => (is => 'ro');

    validates_with Custom => (
      max_name_length => 20, 
      min_age => 5,
    );

    my $person = Local::Person->new(
      name => 'A waaay too loooong name',
      age => -10,
    );

    $person->validate;
    $person->invalid; # TRUE

    my %errors = $person->errors->to_hash(full_messages=>1) };

    #\%errors =  +{
    #  age => [
    #    "Age can't be lower than 5",
    #  ],
    #  name => [
    #    "Name is too long",
    #  ],
    #}; 

A custom validator is just a class that does the C<validate> method (although I recommend that you
consume the L<Valiant::Validator> role as well; this might be required at some point).  When this validator
is added to a class, it is instantiated once with any provided arguments (which are passed to C<new> as init_args).
Each time you call validate, it runs the C<validate> method with the following signature:

    sub validate {
      my ($self, $object, $opts) = @_;
      $object->errors->add(...) if ...
    }

Where C<$self> is the validator object, C<$object> is the current instance of the class you are
validating and C<$opts> is the options hashref.

Within this method you can do any special or complex validation and add error messages to the C<$object>
based on its current state.

=head2 Custom Validator Namespace Resolution

When you use a custom validator class namepart (either via C<validates> or
C<validates_with>) we search thru a number of namespaces to find a match.  This is done
to allow you to create increasingly custom valiators for your classes.  Basically we start with the
package name of the class which is adding the validator, add "::Validator::${namepart}" and then look
down the namespace tree for a loadable file.  If we don't find a match in your project package
namespace we then also look in the two globally shared namespaces C<Valiant::ValidatorX> and
C<Valiant::Validator>.  If we still don't find a match we then throw an exception.  For example
if your package is named C<Local::Person> as in the class above and you specify the C<Custom> validator
we will search for it in all the namespaces below, in order written:

    Local::Person::Validator::Custom
    Local::Validator::Custom
    Validator::Custom
    Valiant::ValidatorX::Custom
    Valiant::Validator::Custom

This lookup only happens once when your classes are first loaded, so this will cause a a delay in startup
but not at runtime.  However the delay probably makes L<Valiant> unsuitable for non persistant applications
such as CGI web applications or possibly scripts that run as part of a cron job.

B<NOTE:> The namespace C<Valiant::Validator> is reserved for validators that ship with L<Valiant>.  The
C<Valiant::ValidatorX> namespace is reserved for additional validators on CPAN that are packaged separately
from L<Valiant>.  If you wish to share a custom validator that you wrote the proper namespace to use on
CPAN is C<Valiant::ValidatorX>.

You can also prepend your validator name with '+' which will cause L<Valiant> to ignore the namespace 
resolution and try to load the class directly.  For example:

    validates_with '+App::MyValidator';

Will try to load the class C<App::MyValidator> and use it as a validator directly (or throw an exception if
it fails to load).

=head2 Validator classes and attributes

Since many of your validations will be on your class's attributes, L<Valiant> makes it easy to use custom
and prepackaged validator classes directly on attributes.  All validator classes which operate on attributes
must consume the role L<Valiant::Validator::Each>.  Here's an example of a class which is using several of
the prepackaged attribute validator classes that comes with L<Valiant>.

    package Local::Task;

    use Valiant::Validations;
    use Moo;

    has priority => (is => 'ro');
    has description => (is => 'ro');
    has due_date => (is => 'ro');

    validates priority => (
      presence => 1,
      numericality => { only_integer => 1, between => [1,10] },
    );

    validates description => (
      presence => 1,
      length => [10,60],
    );

    validates due_date => (
      presence => 1,
      date => 'is_future',
    );

In this case our class defines three attributes, 'priority' (which defined how important a task
is), 'description' (which is a human read description of the task that needs to happen) and
a 'due_date' (which is when the task should be completed).  We then have validations which
place some constraints on the allowed values for these attributes.  Our validations state that:

    'priority' must be defined, must be an integer and the number must be from 1 thru 10.
    'description' must be defined and a string that is longer than 10 characters but less than 60.
    'due_date' must be in a date format (YYYY-MM-DD or eg. '2000-01-01') and also must be a future date.

This class uses the following validators: L<Valiant::Validator::Presence>, to verify that the attribute
has a meaningful defined value; L<Valiant::Validator::Numericality>, to verify the value is an integer and is
between 1 and 10; L<Valiant::Validator::Length>, to check the length of a string and 
L<Valiant::Validator::Date> to verify that the value looks like a date and is a date in the future.

Canonically a validator class accepts a hashref of options, but many of the packaged validators also
accept shortcut forms for the most common use cases.  For example since its common to require a date be
sometime in the future you can write "date => 'is_future'".  Documentation for these shortcut forms are detailed
in each validator class.

=head2 Creating a custom attribute validator class

Creating your own custom attribute validator classes is just as easy as it was for creating a general
validator class.  You need to write a L<Moo> class that consumes the L<Valiant::Validator::Each> role
and provides a C<validates_each> method with the following signature:

    sub validates_each {
      my ($self, $object, $attribute, $value, $opts) = @_; 
    }

Where C<$self> is the validator class instance (this is created once when the validator is added to the class),
C<$object> is the instance of the class you are validating, C<$attribute> is the string name of the attribute
this validation is running on, C<$value> is the current attribute's value and C<$opts> is a hashref of options
passed to the class.  For example, here is simple Boolean truth validator:

    package MyApp::Validator::True;

    use Moo;

    with 'Valiant::Validator::Each';

    sub validate_each {
      my ($self, $object, $attribute, $value, $opts) = @_;
      $object->errors->add($attribute, 'is not a true value', $opts) unless $value;
    }

And example of using it in a class:

    package MyApp::Foo;

    use Moo;
    use Valiant::Validations;

    has 'bar' => ('ro'=>1);

    validates bar => (True => +{}); # No arguments passed to MyApp::Validator::True->new()

Two things to note: There is no meaning assigned to the return value of C<validate_each> (or of C<validates>).
Also you should remember to pass C<$opts> as the third argument to the C<add> method.  Even if you are not
using the options hashref in your custom validator, it might contain values that influence other aspects
of the framework, such as how the error message is formatted.

When resolving an attribute validator namepart, the same rules described above for general validator classes apply.

=head1 PREPACKAGED VALIDATOR CLASSES

Please see L<Valiant::Validator> for a list of all the valiators that are shipped with
L<Valiant> and/or search CPAN for validators in the L<Valiant::ValidatorX> namespace.

=head1 TYPE CONSTRAINT SUPPORT

If you are comfortable using common type contraint libaries such as L<Type::Tiny> you can
use those directly as validation rules much in the same way you can use subroutine references.

    package Local::Test::Check;

    use Moo;
    use Valiant::Validations;
    use Types::Standard 'Int';

    has drinking_age => (is=>'ro');

    validates drinking_age => (
      Int->where('$_ >= 21'), +{
        message => 'is too young to drink!',
      },
    );

When using this option you should use a library system such as L<Type::Tiny> that provides
an object with a C<check> method that returns a boolean indicating if the constraint was passed
or not.  There are several such library systems on CPAN that you might find useful in helping
you to write validations.

Please note this is just wrapping L<Valiant::Validator::Check> so if you need more control
you might prefer to use the validator class.

=head1 INHERITANCE AND ROLES

You can aggregate validation rules via inheritance and roles.  This makes it so that if you
have a number of classes with similar validation rules you can avoid repeating yourself.
Example:

    package Person;

    use Moo;
    use Valiant::Validations;

    has 'name' => (is=>'ro',);
    has 'age' => (is=>'ro');

    validates name => (
      presence => 1,
      length => [3,20],
    );

    validates age => (
      numericality => {
        only_integer => 1,
        greater_than => 0,
        less_than => 150,
      },
    );

    package IsRetirementAge;

    use Moo::Role;
    use Valiant::Validations;

    requires 'age';

    validates age => (
      numericality => {
        greater_than => 64,
      },
    );

    package Retiree;

    use Moo;
    use Valiant::Validations;

    extends 'Person';
    with 'IsRetirementAge';

    1;

    my $retiree = Retiree->new(name=>'Molly Millions', age=>24);

    $retiree->invalid; # true

    my %errors = $object->errors->to_hash(full_messages=>1);
    # \%errors = +{
    #   age => ["Age must be greater than 64" ]
    # }

=head1 GLOBAL ATTRIBUTE VALIDATOR OPTIONS

All attribute validators can accept the following options.  Options can be added to each
validator separately (if you have several) or can be added globally to the end
of the validator rules.  Global rules run first, followed by those applied to
each validator.

=head2 allow_undef

If the attribute value is undef, skip validation and allow it.

    package Person;

    use Moo;
    use Valiant::Validations;

    has 'name' => (is=>'ro',);
    has 'age' => (is=>'ro');

    validates name => (
      format => 'alphabetic',
      length => [3,20],
      allow_undef => 1, # Skip BOTH 'format' and 'length' validators if 'name' is undefined.
    );

    validates age => (
      numericality => {
        only_integer => 1,
        greater_than => 0,
        less_than => 150,
        allow_undef => 1,  # Skip only the 'numericality' validator if 'age' is undefined
      },
    );
 
=head2 allow_blank

If the attribute is blank (that is its one of undef, '', or a scalar composing only
whitespace) skip validation and allow it.  This is similar to the C<allow_undef> option
except it allows a broader definition of 'blank'.  Useful for form validations.

=head2 if / unless

Accepts a coderef or the name of a method which executes and is expected to
return true or false.  If false we skip the validation (or true for C<unless>).
Recieves the object, the attribute name, value to be checked and the options hashref
as arguments.

You can set more than one value to these with an arrayref:

    if => ['is_admin', sub { ... }, 'active_account'],

Example:

    package Person;

    use Moo;
    use Valiant::Validations;

    has 'name' => (is=>'ro',);
    has 'password' => (is=>'ro'); 

    validates name => (
      format => 'alphabetic',
      length => [3,20],
    );

    validates password => (
      length => [12,32],
      with => \&is_a_secure_looking_password,
      unless => sub {
        my ($self, $attr, $value, $opts) = @_;
        $self->name eq 'John Napiorkowski';  # John can make an insecure password if he wants!
      },
    );

=head2 message

Provide a global error message override for the constraint.  Message can be formated in the
same way as the second argument to 'errors->add' and will accept a string,
a translation tag, a reference to a string or a reference to a function.  Using
this will override the custom error message provided by the validator.

    package Person;

    use Moo;
    use Valiant::Validations;

    has 'name' => (is=>'ro',);
    has 'age' => (is=>'ro');

    validates name => (
      format => 'alphabetic',
      length => [3,20],
      message => 'Unacceptable Name', # Overrides both the 'format' and 'length' messages.
    );

    validates age => (
      presence => 1,
      numericality => {
        only_integer => 1,
        greater_than => 0,
        less_than => 150,
        message => 'Age given is not valid',  # overrides just the 'numericality' messages
                                              # and not the 'presence' message.
      },
    );

Please not that many validators also provide error type specific messages for custom
errors (as well as the ability to setup your own errors in a localization file.)  Using 
this attribute is the easiest but probably not always your best option.

Messages can be:

=over 4

=item A string

If a string this is the error message recorded.

    validates name => (
      format => 'alphabetic',
      length => [3,20],
      message => 'Unacceptable Name',
    );

=item A translation tag

    use Valiant::I18N;

    validates name => (
      format => 'alphabetic',
      length => [3,20],
      message => _t('bad_name'),
    );

This will look up a translated version of the tag.  See L<Valiant::I18N> for more details.

=item A scalar reference

    validates name => (
      format => 'alphabetic',
      length => [3,20],
      message => \'Unacceptable {{attribute}}',
    );

Similar to string but we will expand any placeholder variables which are indicated by the
'{{' and '}}' tokens (which are removed from the final string).  You can use any placeholder
that is a key in the options hash (and you can pass additional values when you add an error).
By default the following placeholder expansions are available attribute (the attribute name),
value (the current attribute value), model (the human name of the model containing the
attribute and object (the actual object instance that has the error).

=item A subroutine reference

    validates name => (
      format => 'alphabetic',
      length => [3,20],
      message => sub {
        my ($self, $attr, $value, $opts) = @_;
        return "Unacceptable $attr!";
      }
    );

Similar to the scalar reference option just more flexible since you can write custom code
to build the error message.  For example you could return different error messages based on
the identity of a person.  Also if you return a translation tag instead of a simple string
we will attempt to resolve it to a translated string (see L<Valiant::I18N>).

=back

=head2 strict

When true instead of adding a message to the errors list, will throw exception with the
error instead.  If the true value is a string (basically anything other than a 1) we use the
string given as the message.  If the true value is the name of a class that provides a C<throw>
message, will use that instead.  Lastly if the value is a coderef we call that.

=head2 on

A scalar or array reference of contexts that can be used to control the situation ('context')
under which the validation is executed. If you specify an C<on> context that 
validation will only run if you pass that context via C<validate>.  However if you
don't set a context for the validate (in other words you don't set an C<on> value)
then that validation ALWAYS runs (whether or not you set a context via C<validate>.
Basically not setting a context means validation runs in all contexts and none.
Examples:

  package Local::Test::Person;

  use Moo;
  use Valiant::Validations;
  use Valiant::I18N;

  has age => (is=>'ro');

  validates age => (
    numericality => {
      is_integer => 1,
      less_than => 200,
    },
    numericality => {
      greater_than_or_equal_to => 18,
      on => 'voter',
    },
    numericality => {
      greater_than_or_equal_to => 65,
      on => 'retiree',
    },
    numericality => {
      greater_than_or_equal_to => 100,
      on => 'centarion',
    },
  );

  my $person = Local::Test::Person->new(age=>50);

  $person->validate();
  $person->valid; # True.

  $person->validate(context=>'retiree');
  $person->valid; # False; "Age must be greater than or equal to 65"

  $person->validate(context=>'voter');
  $person->valid; # True.

  $person->validate(context=>'centarion');
  $person->valid; # False; "Age must be greater than or equal to 100"

  my $another_person = Local::Test::Person->new(age=>"not a number");

  $another_person->validate();
  $another_person->valid; # False "Age does not look like an integer"

In this example you can see that since the first validation does not set an C<on> context
it always runs no matter what context you set via C<validate> (even when you don't set one).
So we always check that the value is an integer.

Basically the rule to remember is validations with no C<on> option will run no matter the context
is set via validation options (or set automatically).
Validations with some C<on> option will only run in the specified context.

So if your validation requests one or more contexts via C<on> they only run when at least one
of the passed contexts is matching. If your validation does not request a context via C<on>
then they match ANY or NONE contexts!

=head1 GLOBAL MODEL VALIDATOR OPTIONS

Model validators (added via C<validates_with>) support a subset of the the same options
as L</"GLOBAL ATTRIBUTE VALIDATOR OPTIONS">.  These options work identically as described
in that section:

    if/unless
    on
    message
    strict

=head1 ERROR MESSAGES

When you create an instance of a class that consumes the L<Valiant::Validates> role (typically
by using L<Valiant::Validations> to import the standard methods into the class) that role will
add an attribute called C<errors> to your class.  This attribute will contain an instance of
L<Valiant::Errors>, which is a collection class that contains a list of errors (instances of
L<Valiant::Error>) along with methods to add, retrieve and introspect errors.  You should
review L<Valiant::Errors> for the full class API since we will only coverage the most commonly
used methods in our example.

The most common use cases you will have is adding errors and checking for and recovering error
messages.

=head2 Adding an error message.

You can add an error message anywhere in your code, although most commonly you will do so in you
validation methods or validation callbacks.  In all cases the method signature is the same:

    $object->errors->add($attribute_name, $error_message, \%opts);

Where C<$attribute_name> is the string name of the attribute for which a validation error is being
recorded, C<$error_message> is one of the allowed error message types (see below for details) and
\%opts is a hashref of options and/or error message template variable expansions which is used to
influence how the error is processed.

When the error is scoped to the C<$object> and not a particular attribute you can just use C<undef>
instead of an attribute name.  This will record the error as a model error:

    $object->errors->add(undef, $error_message, \%opts);

Lastly the C<%opts> hashref can be left off the method call if you don't have it.  Generally its
passed as the last argument to C<validate> or any validation subroutine references
but if you are adding an error outside those methods you won't have it.  For example you might wrap a  
database call insidean eval and wish to add a model error if there's an exception.

=head2 Error message types.

When adding an error there's four options for what the value of <$error_message> can be and are described
above L</'GLOBAL ATTRIBUTE VALIDATOR OPTIONS'>

=head2 Message priority

L<Valiant> allows you to set messages at various points to give you a lot of flexibility in 
customizing your response.  You can add errors messages at the point you add it to the errors
collection, in the options for the validator and globally for all validators in a chain.  For
example:

    package MyApp::Errors;

    use Moo;
    use Valiant::Validations;

    has name => (is=>'ro');

    validates name => (
      with => {
        cb => sub {
          my ($self, $attr, $value, $opts) = @_;
          $self->errors->add($attr, 'is always in error!', $opts);  #LAST
        },
        message => 'has wrong value', #FIRST
      },
      message => 'has some sort of error', #SECOND
    );

Here you can see error messages at three levels. Here's the resolution order:

    Messages added to the errors collection via ->add are last
    Messages added globally to a validation clause are second
    Messages added via the 'message' option for a validator is first

In this case the error would be "Name has wrong value".

B<Note> for the outermost global message, please keep in mind that it will override all the error
messages of any of the validators in the clause.

=head2 Accessing and displaying error messages

Once you have validated your object (via the ->validate method) you can check for for validate
state and review or display any errors.

=head3 Checking for errors on a validated object

You can use the C<valid> or C<invalid> methods on your object to check for its validation state.
These methods won't run validations, unless they have not yet been run, so you can call them as
often as you want without incurring a runtime performance penalty.

B<NOTE> However if you pass arguments such as C<context> then any existing validations are cleared
and validations are re run.

    $object->validate;
    $object->valid; # TRUE if there are no errors, FALSE otherwise
    $object->invalid # Opposite of 'valid'

You can also just check the size of the errors collection (size of 0 means no errors):

    $object->validate;
    $object->errors->size;

To make this a bit easier the C<validate> method returns its calling object so you can chain methods:

    $object->validate->valid;

=head3 Retrieving error messages

The L<Valiant::Errors> collection object gives you a few ways to retrieve error messages.  Assuming
there is a model with errors like the following for these examples and discussion:

    $model->errors->add(undef, "Your Form is invalid");
    $model->errors->add(name => "is too short");
    $model->errors->add(name => "has disallowed characters");
    $model->errors->add(age => "must be above 5");
    $model->errors->add(email => "does not look like an email address");
    $model->errors->add(password => "is too short");
    $model->errors->add(password => "can't look like your name");
    $model->errors->add(password => "needs to contain both numbers and letters");

=over 4

=item Getting all the errors at once, or groups of errors

You can get all the error messages in a simple array with either the C<messages> or
C<full_messages> method on the errors collection:

For C<messages>:

    is_deeply [$model->errors->messages], [
      "Your Form is invalid",
      "is too short",
      "has disallowed characters",
      "must be above 5",
      "does not look like an email address",
      "is too short",
      "can't look like your name",
      "needs to contain both numbers and letters",
    ];

For C<full_messages>:

    is_deeply [$model->errors->full_messages], [
      "Your Form is invalid",
      "Name is too short",
      "Name has disallowed characters",
      "Age must be above 5",
      "Email does not look like an email address",
      "Password is too short",
      "Password can't look like your name",
      "Password needs to contain both numbers and letters",
    ];

This combines all the attribute and model message into a flat list.  Please not that
the current order is the order in which messages are added as errors to the errors
collection.

The only difference between C<messages> and C<full_messages> is that the latter will
combine your error message with a human readable version of your attribute name.  By
default this is just a title cased version of the attribute name but you can customize
this via setting a translation (see L</INTERNATONALIZATION>).  C<full_messages> by 
default uses the following expansion template: "{{attribute}} {{message}}" however you can
customize this by setting the C<format> key in your translation file (again see L</INTERNATONALIZATION>).

If you just want the model level errors you can use C<model_messages>:

    is_deeply [$model->errors->model_messages], [
      "Your Form is invalid",
    ];

There is a similar pair of methods for just getting messages associated with attributes:
C<attribute_messages> and C<full_attribute_messages>:

    is_deeply [$model->errors->attribute_messages], [
      "is too short",
      "has disallowed characters",
      "must be above 5",
      "does not look like an email address",
      "is too short",
      "can't look like your name",
      "needs to contain both numbers and letters",
    ];

    is_deeply [$model->errors->full_attribute_messages], [
      "Name is too short",
      "Name has disallowed characters",
      "Age must be above 5",
      "Email does not look like an email address",
      "Password is too short",
      "Password can't look like your name",
      "Password needs to contain both numbers and letters",
    ];

Lastly you can retrieve all the error messages as a hash using the C<to_hash> method.  This
return a hash where the hash keys refer to attributes with errors (or in the case of model
errors the key is '*') and the value is an arrayref of the error(s) associated with that key.
The C<to_hash> method accepts an argument to control if the error messages return using
the C<full_messages> value or the C<messages> value:

    is_deeply +{ $model->errors->to_hash }, {
      "*" => [
        "Your Form is invalid",
      ],
      age => [
        "must be above 5",
      ],
      email => [
        "does not look like an email address",
      ],
      name => [
        "is too short",
        "has disallowed characters",
      ],
      password => [
        "is too short",
        "can't look like your name",
        "needs to contain both numbers and letters",
      ],
    };

    is_deeply +{ $model->errors->to_hash(full_messages=>1) }, {
      "*" => [
        "Your Form is invalid",
      ],
      age => [
        "Age must be above 5",
      ],
      email => [
        "Email does not look like an email address",
      ],
      name => [
        "Name is too short",
        "Name has disallowed characters",
      ],
      password => [
        "Password is too short",
        "Password can't look like your name",
        "Password needs to contain both numbers and letters",
      ],
    };

=item Getting errors for individual attributes

Similar to the method that allows you to get the errors just for the model you
can get errors for individual attibutes with the C<messages_for> and C<full_messages_for>
methods:

    is_deeply [$model->errors->full_messages_for('password')], [
        "Password is too short",
        "Password can't look like your name",
        "Password needs to contain both numbers and letters",
      ];

    is_deeply [$model->errors->messages_for('password')], [
        "is too short",
        "can't look like your name",
        "needs to contain both numbers and letters",
      ];

If you request errors for an attribute that has none you will get an empty array.

Please note that these methods always return arrays even if the case where you have only
a single error.

=item Searching for errors, interating and introspection.

L<Valiant::Errors> contains additional methods for iterating over error collections,
searching for errors and introspecting errors.  Please refer to that package for
full documentation and examples.

=back

=head1 NESTED OBJECTS AND ARRAYS

In some cases you may have complex, nested objects or objects that contain arrays of
values which need validation.  When an object is nested as a attribute under another
object it may itself contain validations. For these more complex cases we provide
two validator classes L<Valiant::Validator::Object> and L<Valiant::Validator::Array>.
You should refer to documentation in each of those validators for API level overview and
examples.

=head1 INTERNATONALIZATION

Internationalization for L<Valiant> will concern our ability to create tags that represent
human readable strings for different languages.  Generally we will create tags, which are
abstract labels representing a message, and then map those lables to various human languages
which we wish to support.  In using L<Valiant::I18N> with L<Valiant> there are generally
three things that we will internationalize:

=over 4

=item error messages

=item attribute names

=item model names

=back

L<Valiant> when looking up tags for translations will follow a precedence order which allows 
you to set base translations for your models, errors and attributes but then override them.
For example lets say you have a class defined as so:

    package Retiree;

    use Moo;
    use Valiant::Validations;
    use Valiant::I18N;

    extends 'Person'

    has 'name' => (is=>'ro');

    validates 'name', sub {
      my ($self, $attribute, $value, $opts) = @_;
      $self->errors->add($attribute => _t('too_long'), +{%$opts, count=>36}) if length($value||'') > 36;
    };

This defines a class with one attribute that has a single validation which makes sure the 'name'
is less than 36 characters.  Let's see how translations are resolved:

    my $p = Retiree->new(name=>'x'x100);
    $p->invalid;

    warn $p->model_name->human; # returns "Retiree"

When resolving a translated version of the Model name we check the following tags:

    valiant.models.retiree
    valiant.models.person

Basically we check each model in the @ISA list, which lets you create a base set of translations
that you can override.  If none of the tags are defined as translations then we just use the
humanized version of the package name.  We follow a similar process for translating attributes:

    warn $p->human_attribute_name('name'); " returns "Name"

We check the following tags in order:

    valiant.attributes.retiree.name
    valiant.attributes.person.name
    attributes.name

And again if we fail we just use the humanized version of the attribute name ("Name"). Errors
are similar:

    warn $p->errors->messages_for('name'); "is too long (maximum is 36 characters)"

We follow these tags:

    valiant.errors.models.retiree.attributes.name.too_long
    valiant.errors.models.retiree.too_long
    valiant.errors.models.person.attributes.name.too_long
    valiant.errors.models.person.too_long
    valiant.errors.messages.too_long
    errors.attributes.name.too_long
    errors.messages.too_long

In this case there is no default so if the tag isn't found we just generate an error.

=head2 Substitution Parameters and Pluralization

In the case of error messages there is an additional complication in that often we need to
customize the message base on the value of the attributes.  For example when the attribute
represents a number of items often the message for zero items will be different than for
many (think "You have 3 items in you bag, the minimum is 5" versus "You have no items in
your bag, the minimum is 5").  The rules for this can be complex depending on the language.
Therefore in the case of error messages you will need the ability to return a different
string for those cases.   We can see this example in the last error message example above
which specified a maximum of 36 characters.   The way this works with errors is that when
adding a error message the final argument hashref is passed to the translator:

    $self->errors->add($attribute => _t('too_long'), +{%$opts, count=>36}) if length($value||'') > 36;

And the translation tag for this looks like:

    {
      en => {
        errors => {
          messages => {
            too_long => {
              one => 'is too long (maximum is 1 character)',
              other => 'is too long (maximum is {{count}} characters)',
            },
          }
        }
      }
    }

Here you can see that when 'count' is 1 we use one translation but when its more than one we
have a slightly different tag.   Any keys passed to $opts can be used as a subsitution parameter
but the 'count' parameter is special since its also used for pluralization.   In the case when
'count' is 0, 1 or more than one we match subkeys as in the example give (when count is 0 we match
'zero'; when its 1 we match 'one' and if something else we match 'other'.

Please be careful what you pass as options to substitution placeholders since you can open up
injection style attackes on your code.

=head2 How roles impact translation tag lookups

Since we can't count on role application order we don't by default use roles as translation
tag namespace lookups in the same way as inherited classes.  However since it can be useful
to set translation tags at the role level we allow you to indicate that a role should be used
in the lookup.  Roles so added will be checked after an base classes.   You mark a role for
lookup via the 'push_to_i18n_lookup' keyword:

    package TestRole;

    use Moo::Role;
    use Valiant::Validations;
    use Valiant::I18N;

    validates_with sub {
      my ($self) = @_;
      $self->errors->add(undef, 'Failed TestRole');
      $self->errors->add('name');
      $self->errors->add(name => _t 'bad', +{ all=>1 } );
    };

    push_to_i18n_lookup;

Then we'd use 'test_role' as an extra lookup key.   For example if we composed "TestRole" into
the 'Retiree" class above and then checked the model name we'd use this lookup:

    valiant.models.retiree
    valiant.models.person
    valiant.models.role_name

for the 'name' attribute:

We check the following tags in order:

    valiant.attributes.retiree.name
    valiant.attributes.person.name
    valiant.attributes.role_name.name
    attributes.name

And finally for the 'too_long' error tag:

    valiant.errors.models.retiree.attributes.name.too_long
    valiant.errors.models.retiree.too_long
    valiant.errors.models.person.attributes.name.too_long
    valiant.errors.models.person.too_long
    valiant.errors.models.role_name.attributes.name.too_long
    valiant.errors.models.role_name.too_long
    valiant.errors.messages.too_long
    errors.attributes.name.too_long
    errors.messages.too_long

=head2 full_messages* version messages*

When getting the text of error messages you can use either the 'full_messages*' or 'messages'
methods (see L<Valiant::Errors>, L<Valiant::Error>).  The only difference between the 'full' and
non full messages is that the 'full' versions combine the attribute name with the translated text
of the error.   The default pattern for this is: "{{attribute}} {{message}}" but you can override
this as usual following a pattern similar to error lookups.

    valiant.errors.models.person.attributes.name.format
    valiant.errors.models.person.format
    errors.format.attributes.name
    errors.format
    
As before we'd also check base classes and roles as indicated.

=head1 FILTERING

Quite often you will wish to allow your users a bit of leeway when providing information.
For example you might want incoming data for a field to be in all capitals, and to be free from
any extra post or trailing whitespace.  You could test for these in a validation and return
error conditions when they are present. However that is not always the best user experience.  In
cases where you are willing to accept such input from users but you want to 'clean up' the data
before trying to validate it you can use filters.

For now please see L<Valiant::Filters> and L<Valiant::Filters> for API level documentations on
filters as well as some examples. Also see L<Valiant::Filter> for a list of the prepackaged filter
that ship with L<Valiant>

=head1 HTML FORM GENERATION

HTML Form generation is not specifically added to the L<Valiant> validation code, but there is
a set of packages designed to work with L<Valiant> as well as L<DBIx::Class::Valiant> ORM integration:
L<Valiant::HTML::FormBuilder>, L<Valiant::HTML::Form> and L<Valiant::HTML::FormTags>.  This code
is currently under active development although I expect that the publically documented API
is very likely to remain stable.  Here's a simple example of what this form integration looks like;
for now you'll need to refer to the API docs and the example application for more on how to use
this.

Given a model like:

    package Local::Person;

    use Moo;
    use Valiant::Validations;

    has first_name => (is=>'ro');
    has last_name => (is=>'ro');

    validates ['first_name', 'last_name'] => (
      length => {
        maximum => 20,
        minimum => 3,
      }
    );

Wrap a formbuilder object around it and generate HTML form field controls:

    use Valiant::HTML::Form 'form_for';

    my $person = Local::Person->new(first_name=>'J', last_name=>'Napiorkowski');
    $person->validate;

    print form_for($person, sub {
      my $fb = shift;
      return  $fb->label('first_name'),
              $fb->input('first_name'),
              $fb->errors_for('first_name', +{ class=>'invalid-feedback' }),
              $fb->label('last_name'),
              $fb->input('last_name'),
              $fb->errors_for('last_name'+{ class=>'invalid-feedback' });
    });

Generates something like:

    <form accept-charset="UTF-8" id="new_person" method="post">
      <label for="person_first_name">First Name</label>
      <input id="person_first_name" name="person.first_name" type="text" value="John"/>
      <div class='invalid-feedback'>First Name is too short (minimum is 3 characters).</div>
      <label for="person_last_name">Last Name</label>
      <input id="person_last_name" name="person.last_name" type="text" value="Napiorkowski"/>
    </form>

=head1 DEBUGGING

You can set the %ENV variable C<VALIANT_DEBUG> to a number ranging 1 to 3 which will give
increasing more detailed debugging output that should assist you if things are not working
as expected.  Debug level 1 only returns messages during the startup / compile stage so its
reasonable safe to run even in a production environment since it should not impact run time
performance.

=head1 SEE ALSO

There's no lack of validation systems on CPAN.   I've used (and contributed) to
L<HTML::FormHandler> and L<Data::MuForm>.   I've also used L<HTML::FormFu>.  Recently I 
spotted L<Form::Tiny> which is a similar DSL style system as L<Valiant> but with a smaller
footprint and sane looking code.  This list is not exhaustive, just stuff I've either used or 
reviewed.

L<Valiant>, L<Valiant::Validations>, L<Valiant::Validates>, L<Valiant::Filters>,
L<Valiant::Filterable>

=head1 DEDICATIONS

This module is eternally dedicated to the memory of my beloved animal companions; our Bernese 
Mountain Dog 'Tornado' who we lost to cancer in 16 August 2020; our Akita 'Sunshine' who passed
from complications due to age on July 14th, 2021 and their pup 'Squeaker' also lost to cancer on
December 18th, 2021.

The distribution as a whole is dedicated in their memory, but specifically the core L<Valiant>
code is dedicated to Tornado, the DBIC integration work to Sunshine and the HTML form generation
and templating code to Squeaker.

If you find this code useful, if it helps your company or makes you money please consider a donation
to help other owners of these dog breeds or aid in the quest to end dog cancer: 

L<http://www.berner.org/pages/charities.php>, L<https://akitarescue.rescuegroups.org/info/donate>,
L<https://wearethecure.org/donations/>.

Or to any dog charity that fits best with your personal beliefs and economic means.

=head1 COPYRIGHT & LICENSE
 
Copyright 2022, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

