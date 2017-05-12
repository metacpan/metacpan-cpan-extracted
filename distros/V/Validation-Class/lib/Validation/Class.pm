# ABSTRACT: Powerful Data Validation Framework

package Validation::Class;

use 5.10.0;
use strict;
use warnings;

use Module::Find;

use Validation::Class::Util '!has';
use Clone 'clone';
use Exporter ();

use Validation::Class::Prototype;

our $VERSION = '7.900057'; # VERSION

our @ISA    = qw(Exporter);
our @EXPORT = qw(

    adopt
    adt
    attribute
    bld
    build
    dir
    directive
    doc
    document
    ens
    ensure
    fld
    field
    flt
    filter
    has
    load
    msg
    message
    mth
    method
    mxn
    mixin
    pro
    profile
    set

);

sub return_class_proto {

    my $class = shift || caller(2);

    return prototype_registry->get($class) || do {

        # build new prototype class

        my $proto = Validation::Class::Prototype->new(
            package => $class
        );

        no strict 'refs';
        no warnings 'redefine';

        # respect foreign constructors (such as $class->new) if found

        my $new = $class->can("new") ?
            "initialize_validator" : "new"
        ;

        # injected into every derived class (override if necessary)

        *{"$class\::$new"}      = sub { goto \&$new };
        *{"$class\::proto"}     = sub { goto \&prototype };
        *{"$class\::prototype"} = sub { goto \&prototype };

        # inject prototype class aliases unless exist

        my @aliases = $proto->proxy_methods;

        foreach my $alias (@aliases) {

            next if $class->can($alias);

            # slight-of-hand

            $proto->set_method($alias, sub {

                shift @_;

                $proto->$alias(@_);

            });

        }

        # inject wrapped prototype class aliases unless exist

        my @wrapped_aliases = $proto->proxy_methods_wrapped;

        foreach my $alias (@wrapped_aliases) {

            next if $class->can($alias);

            # slight-of-hand

            $proto->set_method($alias, sub {

                my $self = shift @_;

                $proto->$alias($self, @_);

            });

        }

        # cache prototype
        prototype_registry->add($class => $proto);

        $proto; # return-once

    };

}

sub configure_class_proto {

    my $configuration_routine = pop;

    return unless "CODE" eq ref $configuration_routine;

    no strict 'refs';

    my $proto = return_class_proto shift;

    $configuration_routine->($proto);

    return $proto;

}

sub import {

    my $caller = caller(0) || caller(1);

    strict->import;
    warnings->import;

    __PACKAGE__->export_to_level(1, @_);

    return return_class_proto $caller # provision prototype when used

}

sub initialize_validator {

    my $self   = shift;
    my $proto  = $self->prototype;

    my $arguments = $proto->build_args(@_);

    # provision a validation class configuration

    $proto->snapshot;

    # override prototype attributes if requested

    if (defined($arguments->{fields})) {
        my $fields = delete $arguments->{fields};
        $proto->fields->clear->add($fields);
    }

    if (defined($arguments->{params})) {
        my $params = delete $arguments->{params};
        $proto->params->clear->add(clone $params);
    }

    # process attribute assignments

    my $proxy_methods = { map { $_ => 1 } ($proto->proxy_methods) } ;

    while (my($name, $value) = each (%{$arguments})) {

        $self->$name($value) if

            $self->can($name)              &&
            $proto->fields->has($name)     ||
            $proto->attributes->has($name) || $proxy_methods->{$name}

        ;

    }

    # process builders

    foreach my $builder ($proto->builders->list) {

        $builder->($self, $arguments);

    }

    # initialize prototype

    $proto->normalize($self);

    # ready-set-go !!!

    return $self;

}




sub adt { goto &adopt } sub adopt {

    my $package = shift if @_ == 4;

    my ($class, $type, $name) = @_;

    my $aliases = {
        has => 'attribute',
        dir => 'directive',
        doc => 'document',
        fld => 'field',
        flt => 'filter',
        msg => 'message',
        mth => 'method',
        mxn => 'mixin',
        pro => 'profile'
    };

    my $keywords = { map { $_ => $_ } values %{$aliases} };

    $type = $keywords->{$type} || $aliases->{$type};

    return unless $class && $name && $type;

    my $store  = "${type}s";
    my $config = prototype_registry->get($class)->configuration;
    my $data   = clone $config->$store->get($name);

    @_ = ($name => $data) and goto &$type;

    return;

}


sub has { goto &attribute } sub attribute {

    my $package = shift if @_ == 3;

    my ($attributes, $default) = @_;

    return unless $attributes;

    $attributes = [$attributes] unless isa_arrayref $attributes;

    return configure_class_proto $package => sub {

        my ($proto) = @_;

        $proto->register_attribute($_ => $default) for @{$attributes};

        return $proto;

    };

}


sub bld { goto &build } sub build {

    my $package = shift if @_ == 2;

    my ($code) = @_;

    return unless ("CODE" eq ref $code);

    return configure_class_proto $package => sub {

        my ($proto) = @_;

        $proto->register_builder($code);

        return $proto;

    };

}


sub dir { goto &directive } sub directive {

    my $package = shift if @_ == 3;

    my ($name, $code) = @_;

    return unless ($name && $code);

    return configure_class_proto $package => sub {

        my ($proto) = @_;

        $proto->register_directive($name, $code);

        return $proto;

    };

}


sub doc { goto &document } sub document {

    my $package = shift if @_ == 3;

    my ($name, $data) = @_;

    $data ||= {};

    return unless ($name && $data);

    return configure_class_proto $package => sub {

        my ($proto) = @_;

        $proto->register_document($name, $data);

        return $proto;

    };

};



sub ens { goto &ensure } sub ensure {

    my $package = shift if @_ == 3;

    my ($name, $data) = @_;

    $data ||= {};

    return unless ($name && $data);

    return configure_class_proto $package => sub {

        my ($proto) = @_;

        $proto->register_ensure($name, $data);

        return $proto;

    };

}


sub fld { goto &field } sub field {

    my $package = shift if @_ == 3;

    my ($name, $data) = @_;

    $data ||= {};

    return unless ($name && $data);

    return configure_class_proto $package => sub {

        my ($proto) = @_;

        $proto->register_field($name, $data);

        return $proto;

    };

}


sub flt { goto &filter } sub filter {

    my $package = shift if @_ == 3;

    my ($name, $code) = @_;

    return unless ($name && $code);

    return configure_class_proto $package => sub {

        my ($proto) = @_;

        $proto->register_filter($name, $code);

        return $proto;

    };

}


sub set { goto &load } sub load {

    my $package;
    my $data;

    # handle different types of invocations

    # 1   - load({})
    # 2+  - load(a => b)
    # 2+  - package->load({})
    # 3+  - package->load(a => b)

    # --

    # load({})

    if (@_ == 1) {

        if ("HASH" eq ref $_[0]) {

            $data = shift;

        }

    }

    # load(a => b)
    # package->load({})

    elsif (@_ == 2) {

        if ("HASH" eq ref $_[-1]) {

            $package = shift;
            $data    = shift;

        }

        else {

            $data = {@_};

        }

    }

    # load(a => b)
    # package->load(a => b)

    elsif (@_ >= 3) {

        if (@_ % 2) {

            $package = shift;
            $data    = {@_};

        }

        else {

            $data = {@_};

        }

    }

    return configure_class_proto $package => sub {

        my ($proto) = @_;

        $proto->register_settings($data);

        return $proto;

    };

}


sub msg { goto &message } sub message {

    my $package = shift if @_ == 3;

    my ($name, $template) = @_;

    return unless ($name && $template);

    return configure_class_proto $package => sub {

        my ($proto) = @_;

        $proto->register_message($name, $template);

        return $proto;

    };

}


sub mth { goto &method } sub method {

    my $package = shift if @_ == 3;

    my ($name, $data) = @_;

    return unless ($name && $data);

    return configure_class_proto $package => sub {

        my ($proto) = @_;

        $proto->register_method($name, $data);

        return $proto;

    };

}


sub mxn { goto &mixin } sub mixin {

    my $package = shift if @_ == 3;

    my ($name, $data) = @_;

    $data ||= {};

    return unless ($name && $data);

    return configure_class_proto $package => sub {

        my ($proto) = @_;

        $proto->register_mixin($name, $data);

        return $proto;

    };

}


sub new {

    my $class = shift;

    $class = ref $class || $class;

    my $proto = return_class_proto $class;

    my $self  = bless {},  $class;

    initialize_validator $self, @_;

    return $self;

}


sub pro { goto &profile } sub profile {

    my $package = shift if @_ == 3;

    my ($name, $code) = @_;

    return unless ($name && $code);

    return configure_class_proto $package => sub {

        my ($proto) = @_;

        $proto->register_profile($name, $code);

        return $proto;

    };

}


sub proto { goto &prototype } sub prototype {

    my ($self) = pop @_;

    return return_class_proto ref $self || $self;

}


1;

__END__

=pod

=head1 NAME

Validation::Class - Powerful Data Validation Framework

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    use Validation::Class::Simple::Streamer;

    my  $params = {username => 'admin', password => 's3cret'};
    my  $input  = Validation::Class::Simple::Streamer->new(params => $params);

    # check username parameter
    $input->check('username')->required->between('5-255');
    $input->filters([qw/trim strip/]);

    # check password parameter
    $input->check('password')->required->between('5-255')->min_symbols(1);
    $input->filters([qw/trim strip/]);

    # run validate
    $input->validate or die $input->errors_to_string;

=head1 DESCRIPTION

Validation::Class is a scalable data validation library with interfaces for
applications of all sizes. The most common usage of Validation::Class is to
transform class namespaces into data validation domains where consistency and
reuse are primary concerns. Validation::Class provides an extensible framework
for defining reusable data validation rules. It ships with a complete set of
pre-defined validations and filters referred to as
L<"directives"|Validation::Class::Directives/DIRECTIVES>.

The core feature-set consist of self-validating methods, validation profiles,
reusable validation rules and templates, pre and post input filtering, class
inheritance, automatic array handling, and extensibility (e.g. overriding
default error messages, creating custom validators, creating custom input
filters and much more). Validation::Class promotes DRY (don't repeat yourself)
code. The main benefit in using Validation::Class is that the architecture is
designed to increase the consistency of data input handling. The following is
a more traditional usage of Validation::Class, using the DSL to construct a
validator class:

    package MyApp::Person;

    use Validation::Class;

    # data validation template
    mixin basic     => {
        required    => 1,
        max_length  => 255,
        filters     => [qw/trim strip/]
    };

    # data validation rules for the username parameter
    field username  => {
        mixin       => 'basic',
        min_length  => 5
    };

    # data validation rules for the password parameter
    field password  => {
        mixin       => 'basic',
        min_length  => 5,
        min_symbols => 1
    };

    package main;

    my $person = MyApp::Person->new(username => 'admin', password => 'secr3t');

    # validate rules on the person object
    unless ($person->validates) {
        # handle the failures
        warn $person->errors_to_string;
    }

    1;

=head1 QUICKSTART

If you are looking for a simple in-line data validation module built
using the same tenets and principles as Validation::Class, please review
L<Validation::Class::Simple> or L<Validation::Class::Simple::Streamer>. If you
are new to Validation::Class, or would like more information on the
underpinnings of this library and how it views and approaches data validation,
please review L<Validation::Class::Whitepaper>. Please review the
L<Validation::Class::Cookbook/GUIDED-TOUR> for a detailed step-by-step look into
how Validation::Class works.

=head1 KEYWORDS

=head2 adopt

The adopt keyword (or adt) copies configuration and functionality from
other Validation::Class classes. The adopt keyword takes three arguments, the
name of the class to be introspected, and the configuration type and name to be
recreated. Basically, anything you can configure using a Validation::Class
keyword can be adopted into other classes using this keyword with the exception
of coderefs registered using the build keyword. Please note! If you are adopting
a field declaration which has an associated mixin directive defined on the
target class, you must adopt the mixin explicitly if you wish it's values to be
interpolated.

    package MyApp::Exployee;

    use Validate::Class;
    use MyApp::Person;

    adopt MyApp::Person, mixin   => 'basic';
    adopt MyApp::Person, field   => 'first_name';
    adopt MyApp::Person, field   => 'last_name';
    adopt MyApp::Person, profile => 'has_fullname';

    1;

=head2 attribute

The attribute keyword (or has) registers a class attribute, i.e. it creates an
accessor (getter and setter) on the class. Attribute declaration is flexible and
only requires an attribute name to be configured. Additionally, the attribute
keyword can takes two arguments, the attribute's name and a scalar or coderef to
be used as it's default value.

    package MyApp::Person;

    use Validate::Class;

    attribute 'first_name' => 'Peter';
    attribute 'last_name'  => 'Venkman';
    attribute 'full_name'  => sub {
        join ', ', $_[0]->last_name, $_[0]->first_name
    };

    attribute 'email_address';

    1;

=head2 build

The build keyword (or bld) registers a coderef to be run at instantiation much
in the same way the common BUILD routine is used in modern OO frameworks.

    package MyApp::Person;

    use Validation::Class;

    build sub {

        my ($self, $args) = @_;

        # run after instantiation in the order defined

    };

    1;

The build keyword takes one argument, a coderef which is passed the instantiated
class object.

=head2 directive

The directive keyword (or dir) registers custom validator directives to be used
in your field definitions. Please note that custom directives can only be used
with field definitions. This is a means of extending the list of directives per
instance. See the list of core directives, L<Validation::Class::Directives>,
or review L<Validation::Class::Directive> for insight into creating your own
CPAN installable directives.

    package MyApp::Person;

    use Validate::Class;

    # define a custom class-level directive
    directive 'blacklisted' => sub {

        my ($self, $field, $param) = @_;

        if (defined $field->{blacklisted} && defined $param) {
            if ($field->{required} || $param) {
                if (exists_in_blacklist($field->{blacklisted}, $param)) {
                    my $handle = $field->label || $field->name;
                    $field->errors->add("$handle has been blacklisted");
                    return 0;
                }
            }
        }

        return 1;

    };

    field 'email_address' => {
        blacklisted => '/path/to/blacklist'
        email => 1,
    };

    1;

The directive keyword takes two arguments, the name of the directive and a
coderef which will be used to validate the associated field. The coderef is
passed four ordered parameters; a directive object, the class prototype object,
the current field object, and the matching parameter's value. The validator
(coderef) is evaluated by its return value as well as whether it altered any
error containers.

=head2 document

The document keyword (or doc) registers a data matching profile which can be
used to validate heiarchal data. It will store a hashref with pre-define path
matching rules for the data structures you wish to validate. The "path matching
rules", which use a specialized object notation, referred to as the document
notation, can be thought of as a kind-of simplified regular expression which is
executed against the flattened data structure. The following are a few general
use-cases:

    package MyApp::Person;

    use Validation::Class;

    field  'string' => {
        mixin => [':str']
    };

    # given this JSON data structure
    {
        "id": "1234-A",
        "name": {
            "first_name" : "Bob",
            "last_name"  : "Smith",
         },
        "title": "CIO",
        "friends" : [],
    }

    # select id to validate against the string rule
    document 'foobar'  =>
        { 'id' => 'string' };

    # select name -> first_name/last_name to validate against the string rule
    document 'foobar'  =>
        {'name.first_name' => 'string', 'name.last_name' => 'string'};

    # or
    document 'foobar'  =>
        {'name.*_name' => 'string'};

    # select each element in friends to validate against the string rule
    document 'foobar'  =>
        { 'friends.@'  => 'string' };

    # or select an element of a hashref in each element in friends to validate
    # against the string rule
    document 'foobar'  =>
        { 'friends.@.name' => 'string' };

The document declaration's keys should follow the aforementioned document
notation schema and it's values should be strings which correspond to the names
of fields (or other document declarations) that will be used to preform the
data validation. It is possible to combine document declarations to validate
hierarchical data that contains data structures matching one or more document
patterns. The following is an example of what that might look like.

    package MyApp::Person;

    use Validation::Class;

    # data validation rule
    field  'name' => {
        mixin      => [':str'],
        pattern    => qr/^[A-Za-z ]+$/,
        max_length => 20,
    };

    # data validation map / document notation schema
    document 'friend' => {
        'name' => 'name'
    };

    # data validation map / document notation schema
    document 'person' => {
        'name' => 'name',
        'friends.@' => 'friend'
    };

    package main;

    my $data = {
        "name"   => "Anita Campbell-Green",
        "friends" => [
            { "name" => "Horace" },
            { "name" => "Skinner" },
            { "name" => "Alonzo" },
            { "name" => "Frederick" },
        ],
    };

    my $person = MyApp::Person->new;

    unless ($person->validate_document(person => $data)) {
        warn $person->errors_to_string if $person->error_count;
    }

    1;

Alternatively, the following is a more verbose data validation class using
traditional styling and configuration.

    package MyApp::Person;

    use Validation::Class;

    field  'id' => {
        mixin      => [':str'],
        filters    => ['numeric'],
        max_length => 2,
    };

    field  'name' => {
        mixin      => [':str'],
        pattern    => qr/^[A-Za-z ]+$/,
        max_length => 20,
    };

    field  'rating' => {
        mixin      => [':str'],
        pattern    => qr/^\-?\d+$/,
    };

    field  'tag' => {
        mixin      => [':str'],
        pattern    => qr/^(?!evil)\w+/,
        max_length => 20,
    };

    document 'person' => {
        'id'                             => 'id',
        'name'                           => 'name',
        'company.name'                   => 'name',
        'company.supervisor.name'        => 'name',
        'company.supervisor.rating.@.*'  => 'rating',
        'company.tags.@'                 => 'name'
    };

    package main;

    my $data = {
        "id"      => "1234-ABC",
        "name"    => "Anita Campbell-Green",
        "title"   => "Designer",
        "company" => {
            "name"       => "House of de Vil",
            "supervisor" => {
                "name"   => "Cruella de Vil",
                "rating" => [
                    {   "support"  => -9,
                        "guidance" => -9
                    }
                ]
            },
            "tags" => [
                "evil",
                "cruelty",
                "dogs"
            ]
        },
    };

    my $person = MyApp::Person->new;

    unless ($person->validate_document(person => $data)) {
        warn $person->errors_to_string if $person->error_count;
    }

    1;

Additionally, the following is yet another way to validate a document by
passing the document specification directly instead of by name.

    package MyApp::Person;

    use Validation::Class;

    package main;

    my $data = {
        "id"      => "1234-ABC",
        "name"    => "Anita Campbell-Green",
        "title"   => "Designer",
        "company" => {
            "name"       => "House of de Vil",
            "supervisor" => {
                "name"   => "Cruella de Vil",
                "rating" => [
                    {   "support"  => -9,
                        "guidance" => -9
                    }
                ]
            },
            "tags" => [
                "evil",
                "cruelty",
                "dogs"
            ]
        },
    };

    my $spec = {
        'id'                            => { max_length => 2 },
        'name'                          => { mixin      => ':str' },
        'company.name'                  => { mixin      => ':str' },
        'company.supervisor.name'       => { mixin      => ':str' },
        'company.supervisor.rating.@.*' => { pattern    => qr/^(?!evil)\w+/ },
        'company.tags.@'                => { max_length => 20 },
    };

    my $person = MyApp::Person->new;

    unless ($person->validate_document($spec => $data)) {
        warn $person->errors_to_string if $person->error_count;
    }

    1;

=head2 ensure

The ensure keyword (or ens) is used to convert a pre-existing method
into an auto-validating method. The auto-validating method will be
registered and function as if it was created using the method keyword.
The original pre-existing method will be overridden with a modifed version
which performs the pre and/or post validation routines.

    package MyApp::Person;

    use Validation::Class;

    sub register {
        ...
    }

    ensure register => {
        input  => ['name', '+email', 'username', '+password', '+password2'],
        output => ['+id'], # optional output validation, dies on failure
    };

    package main;

    my $person = MyApp::Person->new(params => $params);

    if ($person->register) {
        # handle the successful registration
    }

    1;

The ensure keyword takes two arguments, the name of the method to be
overridden and a hashref of required key/value pairs. The hashref may
have an input key (e.g. input, input_document, input_profile, or input_method).
The `input` key (specifically) must have a value which must be either an
arrayref of fields to be validated, or a scalar value which matches (a
validation profile or auto-validating method name). The hashref may also have
an output key (e.g. output, output_document, output_profile, or output_method).
The `output` key (specifically) must have a value which must be either an
arrayref of fields to be validated, or a scalar value which matches (a
validation profile or auto-validating method name). Whether and what the
method returns is yours to decide. The method will return undefined if
validation fails. The ensure keyword wraps and functions much in the same way
as the method keyword.

=head2 field

The field keyword (or fld) registers a data validation rule for reuse and
validation in code. The field name should correspond with the parameter name
expected to be passed to your validation class or validated against.

    package MyApp::Person;

    use Validation::Class;

    field 'username' => {
        required   => 1,
        min_length => 1,
        max_length => 255
    };

The field keyword takes two arguments, the field name and a hashref of key/values
pairs known as directives. For more information on pre-defined directives, please
review the L<"list of core directives"|Validation::Class::Directives/DIRECTIVES>.

The field keyword also creates accessors which provide easy access to the
field's corresponding parameter value(s). Accessors will be created using the
field's name as a label having any special characters replaced with an
underscore.

    # accessor will be created as send_reminders
    field 'send-reminders' => {
        length => 1
    };

Please note that prefixing field names with a double plus-symbol instructs the
register to merge your declaration with any pre-existing declarations within the
same scope (e.g. fields imported via loading roles), whereas prefixing field
names with a single plus-symbol instructs the register to overwrite any
pre-existing declarations.

    package MyApp::Person;

    use Validation::Class;

    set role => 'MyApp::User';

    # append existing field and overwrite directives
    field '++email_address' => {
        required => 1
    };

    # redefine existing field
    field '+login' => {
        required => 1
    };

    1;

=head2 filter

The filter keyword (or flt) registers custom filters to be used in your field
definitions. It is a means of extending the pre-existing filters declared by
the L<"filters directive"|Validation::Class::Directive::Filters> before
instantiation.

    package MyApp::Person;

    use Validate::Class;

    filter 'flatten' => sub {
        $_[0] =~ s/[\t\r\n]+/ /g;
        return $_[0];
    };

    field 'biography' => {
        filters => ['trim', 'strip', 'flatten']
    };

    1;

The filter keyword takes two arguments, the name of the filter and a
coderef which will be used to filter the value the associated field. The coderef
is passed the value of the field and that value MUST be operated on directly.
The coderef should also return the transformed value.

=head2 load

The load keyword (or set), which can also be used as a class method, provides
options for extending the current class by declaring roles, requirements, etc.

The process of applying roles, requirement, and other settings to the current
class mainly involves introspecting the namespace's methods and merging relevant
parts of the prototype configuration.

=head2 load-classes

The `classes` (or class) option uses L<Module::Find> to load all child classes
(in-all-subdirectories) for convenient access through the
L<Validation::Class::Prototype/class> method, and when introspecting a larger
application. This option accepts an arrayref or single argument.

    package MyApp;

    use Validation::Class;

    load classes => ['MyApp::Domain1', 'MyApp::Domain2'];

    package main;

    my $app = MyApp->new;

    my $person = $app->class('person'); # return a new MyApp::Person object

    1;

=head2 load-requirements

    package MyApp::User;

    use Validate::Class;

    load requirements => 'activate';

    package MyApp::Person;

    use Validation::Class;

    load role => 'MyApp::User';

    sub activate {}

    1;

The `requirements` (or required) option is used to ensure that if/when the class
is used as a role the calling class has specific pre-existing methods. This
option accepts an arrayref or single argument.

    package MyApp::User;

    use Validate::Class;

    load requirements => ['activate', 'deactivate'];

    1;

=head2 load-roles

    package MyApp::Person;

    use Validation::Class;

    load role => 'MyApp::User';

    1;

The `roles` (or role) option is used to load and inherit functionality from
other validation classes. These classes should be used and thought-of as roles
although they can also be fully-functioning validation classes. This option
accepts an arrayref or single argument.

    package MyApp::Person;

    use Validation::Class;

    load roles => ['MyApp::User', 'MyApp::Visitor'];

    1;

=head2 message

The message keyword (or msg) registers a class-level error message template that
will be used in place of the error message defined in the corresponding directive
class if defined. Error messages can also be overridden at the individual
field-level as well. See the L<Validation::Class::Directive::Messages> for
instructions on how to override error messages at the field-level.

    package MyApp::Person;

    use Validation::Class;

    field email_address => {
        required   => 1,
        min_length => 3,
        messages   => {
            # field-level error message override
            min_length => '%s is not even close to being a valid email address'
        }
    };

    # class-level error message overrides
    message required   => '%s is needed to proceed';
    message min_length => '%s needs more characters';

    1;

The message keyword takes two arguments, the name of the directive whose error
message you wish to override and a string which will be used to as a template
which is feed to sprintf to format the message.

=head2 method

The method keyword (or mth) is used to register an auto-validating method.
Similar to method signatures, an auto-validating method can leverage
pre-existing validation rules and profiles to ensure a method has the
required pre/post-conditions and data necessary for execution.

    package MyApp::Person;

    use Validation::Class;

    method 'register' => {

        input  => ['name', '+email', 'username', '+password', '+password2'],
        output => ['+id'], # optional output validation, dies on failure
        using  => sub {

            my ($self, @args) = @_;

            # do something registrationy
            $self->id(...); # set the ID field for output validation

            return $self;

        }

    };

    package main;

    my $person = MyApp::Person->new(params => $params);

    if ($person->register) {

        # handle the successful registration

    }

    1;

The method keyword takes two arguments, the name of the method to be created
and a hashref of required key/value pairs. The hashref may have a `using` key
whose value is the coderef to be executed upon successful validation. The
`using` key is only optional when a pre-existing subroutine has the same name
or the method being declared prefixed with a dash or dash-process-dash. The
following are valid subroutine names to be called by the method declaration in
absence of a `using` key. Please note, unlike the ensure keyword, any
pre-existing subroutines will not be wrapped-and-replaced and can be executed
without validation if called directly.

    sub _name {
        ...
    }

    sub _process_name {
        ...
    }

The hashref may have an input key
(e.g. input, input_document, input_profile, or input_method). The `input` key
(specifically) must have a value which must be either an arrayref of fields to
be validated, or a scalar value which matches (a validation profile or
auto-validating method name), which will be used to perform data validation
B<before> the aforementioned coderef has been executed. Whether and what the
method returns is yours to decide. The method will return undefined if
validation fails.

    # alternate usage

    method 'registration' => {
        input  => ['name', '+email', 'username', '+password', '+password2'],
        output => ['+id'], # optional output validation, dies on failure
    };

    sub _process_registration {
        my ($self, @args) = @_;
            $self->id(...); # set the ID field for output validation
        return $self;
    }

Optionally the hashref may also have an output key (e.g. output,
output_document, output_profile, or output_method). The `output` key
(specifically) must have a value which must be either an arrayref of
fields to be validated, or a scalar value which matches (a validation profile
or auto-validating method name), which will be used to perform data validation
B<after> the aforementioned coderef has been executed.

Please note that output validation failure will cause the program to die,
the premise behind this decision is based on the assumption that given
successfully validated input a routine's output should be predictable and
if an error occurs it is most-likely a program error as opposed to a user error.

See the ignore_failure and report_failure attributes on the prototype to
control how method validation failures are handled.

=head2 mixin

The mixin keyword (or mxn) registers a validation rule template that can be
applied (or "mixed-in") to any field by specifying the mixin directive. Mixin
directives are processed first so existing field directives will override any
directives created by the mixin directive.

    package MyApp::Person;

    use Validation::Class;

    mixin 'boilerplate' => {
        required   => 1,
        min_length => 1,
        max_length => 255
    };

    field 'username' => {
        # min_length, max_length, .. required will be overridden
        mixin    => 'boilerplate',
        required => 0
    };

Since version 7.900015, all classes are automatically configured with the
following default mixins for the sake of convenience:

    mixin ':flg' => {
        required   => 1,
        min_length => 1,
        filters    => [qw/trim strip numeric/],
        between    => [0, 1]
    };

    mixin ':num' => {
        required   => 1,
        min_length => 1,
        filters    => [qw/trim strip numeric/]
    };

    mixin ':str' => {
        required   => 1,
        min_length => 1,
        filters    => [qw/trim strip/]
    };

Please note that the aforementioned mixin names are prefixed with a semi-colon but
are treated as an exception to the rule. Prefixing mixin names with a double
plus-symbol instructs the register to merge your declaration with any pre-existing
declarations within the same scope (e.g. mixins imported via loading roles),
whereas prefixing mixin names with a single plus-symbol instructs the register
to overwrite any pre-existing declarations.

    package MyApp::Moderator;

    use Validation::Class;

    set role => 'MyApp::Person';

    # overwrite and append existing mixin
    mixin '++boilerplate' => {
        min_symbols => 1
    };

    # redefine existing mixin
    mixin '+username' => {
        required => 1
    };

    1;

The mixin keyword takes two arguments, the mixin name and a hashref of key/values
pairs known as directives.

=head2 profile

The profile keyword (or pro) registers a validation profile (coderef) which as
in the traditional use of the term is a sequence of validation routines that
validates data relevant to a specific action.

    package MyApp::Person;

    use Validation::Class;

    profile 'check_email' => sub {

        my ($self, @args) = @_;

        if ($self->email_exists) {
            my $email = $self->fields->get('email');
            $email->errors->add('Email already exists');
            return 0;
        }

        return 1;

    };

    package main;

    my $user = MyApp::Person->new(params => $params);

    unless ($user->validate_profile('check_email')) {
        # handle failures
    }

    1;

The profile keyword takes two arguments, a profile name and coderef which will
be used to execute a sequence of actions for validation purposes.

=head1 METHODS

=head2 new

The new method instantiates a new class object, it performs a series of actions
(magic) required for the class to function properly, and for that reason, this
method should never be overridden. Use the build keyword for hooking into the
instantiation process.

In the event a foreign (pre-existing) `new` method is detected, an
`initialize_validator` method will be injected into the class containing the
code (magic) necessary to normalize your environment.

    package MyApp::Person;

    use Validation::Class;

    # hook
    build sub {

        my ($self, @args) = @_; # on instantiation

    };

    sub new {

        # rolled my own
        my $self = bless {}, shift;

        # execute magic
        $self->initialize_validator;

    }

    1;

=head2 prototype

The prototype method (or proto) returns an instance of the associated class
prototype. The class prototype is responsible for manipulating and validating
the data model (the class). It is not likely that you'll need to access
this method directly, see L<Validation::Class::Prototype>.

    package MyApp::Person;

    use Validation::Class;

    package main;

    my $person = MyApp::Person->new;

    my $prototype = $person->prototype;

    1;

=head1 PROXY METHODS

Validation::Class mostly provides sugar functions for modeling your data
validation requirements. Each class you create is associated with a prototype
class which provides the data validation engine and keeps your class namespace
free from pollution, please see L<Validation::Class::Prototype> for more
information on specific methods and attributes. Validation::Class injects a few
proxy methods into your class which are basically aliases to the corresponding
prototype class methods, however it is possible to access the prototype directly
using the proto/prototype methods.

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

=head2 ignore_intervention

    $self->ignore_intervention;

See L<Validation::Class::Prototype/ignore_intervention> for full documentation.

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

=head1 UPGRADE

Validation::Class is stable, its feature-set is complete, and is currently in
maintenance-only mode, i.e. Validation::Class will only be updated with minor
enhancements and bug fixes. However, the lessons learned will be incorporated
into a compelete rewrite uploaded under the namespace L<Validation::Interface>.
The Validation::Interface fork is designed to have a much simpler API with less
options and better execution, focused on validating hierarchical data as its
primarily objective.

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

=head1 SEE ALSO

Validation::Class does not validate blessed objects. If you need a means for
validating object types you should use a modern object system like L<Moo>,
L<Mouse>, or L<Moose>. Alternatively, you could use decoupled object
validators like L<Type::Tiny>, L<Params::Validate> or L<Specio>.

=back

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
