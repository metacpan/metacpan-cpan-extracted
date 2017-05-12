use FindBin;
use Test::More;
use utf8;
use strict;
use warnings;

{

    use_ok 'Validation::Class';
    use_ok 'Validation::Class::Prototype';

}

{

    # no importing - #fail

    package TestClass;
    use Validation::Class ();

    package main;

    my $class;

    eval { $class = TestClass->new };

    ok !$class, "TestClass cannot be instantiated wo/definitions or importing";

}

{

    # importing nothing - #hack

    package TestClass::Alt;
    use Validation::Class qw(//);

    package main;

    my $class;

    $class = TestClass::Alt->new;

    ok ref $class, "TestClass::Alt instantiated";
    ok !$class->can('attribute'), "TestClass::Alt wo/ attribute keyword";
    ok !$class->can('bld'), "TestClass::Alt wo/ bld keyword";
    ok !$class->can('build'), "TestClass::Alt wo/ build keyword";
    ok !$class->can('dir'), "TestClass::Alt wo/ dir keyword";
    ok !$class->can('directive'), "TestClass::Alt wo/ directive keyword";
    ok !$class->can('doc'), "TestClass::Alt wo/ doc keyword";
    ok !$class->can('document'), "TestClass::Alt wo/ document keyword";
    ok !$class->can('fld'), "TestClass::Alt wo/ fld keyword";
    ok !$class->can('field'), "TestClass::Alt wo/ field keyword";
    ok !$class->can('flt'), "TestClass::Alt wo/ flt keyword";
    ok !$class->can('filter'), "TestClass::Alt wo/ filter keyword";
    ok !$class->can('has'), "TestClass::Alt wo/ has keyword";
    ok !$class->can('load'), "TestClass::Alt wo/ load keyword";
    ok !$class->can('msg'), "TestClass::Alt wo/ msg keyword";
    ok !$class->can('message'), "TestClass::Alt wo/ message keyword";
    ok !$class->can('mth'), "TestClass::Alt wo/ mth keyword";
    ok !$class->can('method'), "TestClass::Alt wo/ method keyword";
    ok !$class->can('mxn'), "TestClass::Alt wo/ mxn keyword";
    ok !$class->can('mixin'), "TestClass::Alt wo/ mixin keyword";
    ok !$class->can('obj'), "TestClass::Alt wo/ obj keyword";
    ok !$class->can('object'), "TestClass::Alt wo/ object keyword";
    ok !$class->can('pro'), "TestClass::Alt wo/ pro keyword";
    ok !$class->can('profile'), "TestClass::Alt wo/ profile keyword";
    ok !$class->can('set'), "TestClass::Alt wo/ set keyword";

}

{

    # no importing - #hack

    package TestClass::Hack;
    use Validation::Class ();

    Validation::Class->prototype(__PACKAGE__);    # init prototype and cache it

    package main;

    my $class = TestClass::Hack->new;

    ok "TestClass::Hack" eq ref $class,
      "TestClass::Hack instantiated, via the setup hack";

    ok !$class->can($_),
      "TestClass::Hack has NOT been injected with the $_ method"
      for @Validation::Class::EXPORT;

    ok $class->can($_), "TestClass::Hack has been injected with the $_ method"
      for qw/new proto prototype/,
      @Validation::Class::Prototype::proxy_methods,
      @Validation::Class::Prototype::proxy_methods_wrapped;

}

{

    # traditional usage

    package TestClass::Traditional;
    use Validation::Class;

    package main;

    my $class = TestClass::Traditional->new;

    ok "TestClass::Traditional" eq ref $class,
      "TestClass::Traditional instantiated, via the setup hack";

    ok $class->can($_),
      "TestClass::Traditional has been injected with the $_ method"
      for @Validation::Class::EXPORT;

    ok $class->can($_),
      "TestClass::Traditional has been injected with the $_ method"
      for qw/new proto prototype/,
      @Validation::Class::Prototype::proxy_methods,
      @Validation::Class::Prototype::proxy_methods_wrapped;

}

{

    # traditional usage with keywords

    package TestClass::WithKeywords;
    use Validation::Class;

    set {
        # as long as it doesn't fail -- will test elsewhere
    };

    # a mixin template

    mxn 'basic' => {required => 1};

    # a validation rule

    fld 'login' => {
        label => 'User Login',
        error => 'Login invalid.',
        mixin => 'basic',

        validation => sub {

            my ($self, $this_field, $all_params) = @_;

            return $this_field->{value} eq 'admin' ? 1 : 0;

          }

    };

    # a validation rule

    fld 'password' => {
        label => 'User Password',
        error => 'Password invalid.',
        mixin => 'basic',

        validation => sub {1}    # always successful

    };

    # a validation profile

    pro 'registration' => sub {

        my ($self, @args) = @_;

        return $self->validate(qw(+login +password))

    };

    # an auto-validating method

    mth 'register' => {

        input => 'registration',      # validate registration profile
        using => sub {'happy-test'}

    };

    package main;

    my $class = TestClass::WithKeywords->new(
        login    => 'admin',
        password => 'pass'
    );

    ok "TestClass::WithKeywords" eq ref $class,
      "TestClass::WithKeywords instantiated";

    ok $class->proto->mixins->{basic}->{required} == 1,
      'TestClass::WithKeywords has mixin basic, required directive set';

    ok defined $class->fields->{$_}->{label}
      && defined $class->fields->{$_}->{error}
      && defined $class->fields->{$_}->{mixin}
      && defined $class->fields->{$_}->{validation},
      "TestClass::WithKeywords has $_ with label, error, mixin "
      . "and validation directives set"
      for ('login', 'password');

    ok defined $class->proto->profiles->{registration},
      "TestClass::WithKeywords has registration profile";

    ok defined $class->proto->methods->{register},
      "TestClass::WithKeywords has self-validating register method";

    ok $class->validate_profile('registration'),
      "TestClass::WithKeywords has successfully executed the registration profile";

    ok "happy-test" eq $class->register(),
      "TestClass::WithKeywords has successfully executed the register method "
      . "which returned the desired output";

}

{

    # overriding injected methods (all)

    package TestClass::Overrider;
    use Validation::Class;

    no warnings 'redefine';

    sub adt       {'noop'}
    sub adopt     {'noop'}
    sub attribute {'noop'}
    sub bld       {'noop'}
    sub build     {'noop'}
    sub dir       {'noop'}
    sub directive {'noop'}
    sub doc       {'noop'}
    sub document  {'noop'}
    sub ens       {'noop'}
    sub ensure    {'noop'}
    sub fld       {'noop'}
    sub field     {'noop'}
    sub flt       {'noop'}
    sub filter    {'noop'}
    sub has       {'noop'}
    sub load      {'noop'}
    sub msg       {'noop'}
    sub message   {'noop'}
    sub mth       {'noop'}
    sub method    {'noop'}
    sub mxn       {'noop'}
    sub mixin     {'noop'}
    sub obj       {'noop'}
    sub object    {'noop'}
    sub pro       {'noop'}
    sub profile   {'noop'}
    sub set       {'noop'}

    sub new       {'noop'}
    sub proto     {'noop'}
    sub prototype {'noop'}

    sub class            {'noop'}
    sub clear_queue      {'noop'}
    sub error            {'noop'}
    sub error_count      {'noop'}
    sub error_fields     {'noop'}
    sub errors           {'noop'}
    sub errors_to_string {'noop'}
    sub get_errors       {'noop'}
    sub fields           {'noop'}
    sub filtering        {'noop'}
    sub ignore_failure   {'noop'}
    sub ignore_unknown   {'noop'}
    sub is_valid         {'noop'}
    sub param            {'noop'}
    sub params           {'noop'}
    sub queue            {'noop'}
    sub report_failure   {'noop'}
    sub report_unknown   {'noop'}
    sub reset_errors     {'noop'}
    sub set_errors       {'noop'}
    sub stash            {'noop'}

    sub validate         {'noop'}
    sub validate_profile {'noop'}
    sub validate_method  {'noop'}

    sub validates         {'noop'}
    sub profile_validates {'noop'}
    sub method_validates  {'noop'}

    package main;

    my $class = bless {}, 'TestClass::Overrider';

    ok "TestClass::Overrider" eq ref $class,
      "TestClass::Overrider instantiated";

    ok 'noop' eq $class->$_,
      "TestClass::Overrider method $_ method was overriden"
      for @Validation::Class::EXPORT;

    ok !do {
        eval { 1 if 'noop' eq $class->$_ };
        $@;
      }, "TestClass::Overrider method $_ method was overriden"
      for qw/new proto prototype/,
      @Validation::Class::Prototype::proxy_methods,
      @Validation::Class::Prototype::proxy_methods_wrapped;

}

done_testing;
