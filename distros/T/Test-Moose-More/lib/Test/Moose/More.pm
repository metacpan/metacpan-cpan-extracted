#
# This file is part of Test-Moose-More
#
# This software is Copyright (c) 2017, 2016, 2015, 2014, 2013, 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Test::Moose::More;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: 0.047-23-gb33a6e7
$Test::Moose::More::VERSION = '0.048';

# ABSTRACT: More tools for testing Moose packages

use strict;
use warnings;

use Sub::Exporter::Progressive -setup => {
    exports => [ qw{
        attribute_options_ok
        check_sugar_ok
        check_sugar_removed_ok
        does_metaroles_ok
        does_not_metaroles_ok
        does_not_ok
        does_not_require_method_ok
        does_ok
        has_attribute_ok
        has_method_from_anywhere_ok
        has_method_ok
        has_no_method_from_anywhere_ok
        has_no_method_ok
        is_anon
        is_anon_ok
        is_class
        is_class_ok
        is_immutable_ok
        is_not_anon
        is_not_anon_ok
        is_not_immutable_ok
        is_not_pristine_ok
        is_pristine_ok
        is_role
        is_role_ok
        meta_ok
        method_from_pkg_ok
        method_is_accessor_ok
        method_is_not_accessor_ok
        method_not_from_pkg_ok
        no_meta_ok
        requires_method_ok
        role_wraps_after_method_ok
        role_wraps_around_method_ok
        role_wraps_before_method_ok
        validate_attribute
        validate_class
        validate_role
        validate_thing
        with_immutable
    } ],
    groups => {
        default  => [ ':all' ],
        validate => [ map { "validate_$_" } qw{ attribute class role thing } ],
    },
};

use Test::Builder;
use Test::More;
use Test::Moose 'with_immutable';
use List::MoreUtils 'apply';
use Scalar::Util 'blessed';
use Syntax::Keyword::Junction 'any';
use Moose::Util 'resolve_metatrait_alias', 'does_role', 'find_meta';
use Moose::Util::TypeConstraints;
use Carp 'confess';
use Data::OptList;

use Test::Moose::More::Utils;

# debugging...
#use Smart::Comments;

my $tb = Test::Builder->new();

our $THING_NAME;

sub _thing_name {
    my ($thing, $thing_meta) = @_;

    return $THING_NAME if $THING_NAME;

    $thing_meta ||= find_meta($thing);

    # try very hard to come up with a meaningful name
    my $desc
        = !!$thing_meta  ? $thing_meta->name
        : blessed $thing ? ref $thing
        : ref $thing     ? 'The object'
        :                  $thing
        ;

    return $desc;
}


{
    my $_yes = sub { $tb->ok(!!shift, shift . ' has a meta')           };
    my $_no  = sub { $tb->ok( !shift, shift . ' does not have a meta') };
    sub meta_ok    ($;$) { unshift @_, $_yes, $_[0]; goto \&_method_ok_guts }
    sub no_meta_ok ($;$) { unshift @_, $_no,  $_[0]; goto \&_method_ok_guts }
}


sub does_ok ($$;$) {
    my ($thing, $roles, $message) = @_;

    my $thing_meta = find_meta($thing);

    $roles     = [ $roles ] unless ref $roles;
    $message ||= _thing_name($thing, $thing_meta) . ' does %s';

    # this generally happens when we're checking a vanilla attribute
    # metaclass, which turns out to be a
    # Class::MOP::Class::Immutable::Class::MOP::Class.  If our metaclass does
    # not have a does_role() method, then by definition the metaclass cannot
    # do the role (that is, it's a Class::MOP metaclass).
    my $_does = $thing_meta->can('does_role') || sub { 0 };

    BEGIN { warnings::unimport 'redundant' if $^V gt v5.21.1 }
    $tb->ok(!!$thing_meta->$_does($_), sprintf($message, $_))
        for @$roles;

    return;
}


sub does_not_ok ($$;$) {
    my ($thing, $roles, $message) = @_;

    my $thing_meta = find_meta($thing);

    $roles     = [ $roles ] unless ref $roles;
    $message ||= _thing_name($thing, $thing_meta) . ' does not do %s';

    my $_does = $thing_meta->can('does_role') || sub { 0 };

    BEGIN { warnings::unimport 'redundant' if $^V gt v5.21.1 }
    $tb->ok(!$thing_meta->$_does($_), sprintf($message, $_))
        for @$roles;

    return;
}


# helper to dig for an attribute
sub _find_attribute {
    my ($thing, $attr_name) = @_;

    my $meta = find_meta($thing);

    # if $thing is a role, find_attribute_by_name() is not available to us
    return $meta->isa('Moose::Meta::Role')
        ? $meta->get_attribute($attr_name)
        : $meta->find_attribute_by_name($attr_name)
        ;
}

sub has_attribute_ok ($$;$) {
    my ($thing, $attr_name, $message) = @_;

    $message ||= _thing_name($thing) . " has an attribute named $attr_name";
    return $tb->ok(!!_find_attribute($thing => $attr_name), $message);
}


{
    my $_has_test = sub { $tb->ok(!!$_[0]->has_method($_), "$_[1] has method $_")           };
    my $_no_test  = sub { $tb->ok( !$_[0]->has_method($_), "$_[1] does not have method $_") };

    sub has_no_method_ok ($@) { unshift @_, $_no_test;  goto \&_method_ok_guts }
    sub has_method_ok    ($@) { unshift @_, $_has_test; goto \&_method_ok_guts }
}
{
    my $_has_test = sub { $tb->ok(!!$_[0]->find_method_by_name($_), "$_[1] has method $_")           };
    my $_no_test  = sub { $tb->ok( !$_[0]->find_method_by_name($_), "$_[1] does not have method $_") };

    sub has_no_method_from_anywhere_ok ($@) { unshift @_, $_no_test;  goto \&_method_ok_guts }
    sub has_method_from_anywhere_ok    ($@) { unshift @_, $_has_test; goto \&_method_ok_guts }
}

sub _method_ok_guts {
    my ($_test, $thing, @methods) = @_;

    ### $thing
    my $meta = find_meta($thing);
    my $name = _thing_name($thing, $meta);

    # the test below is run one stack frame up (down?), so let's handle that
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    # "tiny evil?" -- Eleanor Weyl

    ### @methods
    $_test->($meta => $name)
        for @methods;

    return;
}


{
    my $_yes = sub { $tb->ok($_[0]->original_package_name eq $_[1], "$_[3] is from $_[1]")     };
    my $_no  = sub { $tb->ok($_[0]->original_package_name ne $_[1], "$_[3] is not from $_[1]") };
    sub method_from_pkg_ok($$$)     { _method_from_pkg_ok($_yes, @_) }
    sub method_not_from_pkg_ok($$$) { _method_from_pkg_ok($_no,  @_) }

    my $_yes_acc = sub { $tb->ok( $_[0]->isa('Class::MOP::Method::Accessor'), "$_[3] is an accessor method")     };
    my $_no_acc  = sub { $tb->ok(!$_[0]->isa('Class::MOP::Method::Accessor'), "$_[3] is not an accessor method") };
    sub method_is_accessor_ok($$)     { _method_from_pkg_ok($_yes_acc, @_) }
    sub method_is_not_accessor_ok($$) { _method_from_pkg_ok($_no_acc,  @_) }
}

sub _method_from_pkg_ok {
    my ($test, $thing, $method, $orig_pkg) = @_;

    ### $thing
    my $meta = find_meta($thing);
    my $name = _thing_name($thing, $meta);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $mmeta = $meta->find_method_by_name($method)
        or return $tb->ok(0, "$name has no method $method");

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return $test->($mmeta, $orig_pkg, $meta, "${name}'s method $method");
}


sub role_wraps_around_method_ok ($@) { unshift @_, 'around'; goto \&_role_wraps }
sub role_wraps_before_method_ok ($@) { unshift @_, 'before'; goto \&_role_wraps }
sub role_wraps_after_method_ok  ($@) { unshift @_, 'after';  goto \&_role_wraps }

sub _role_wraps {
    my ($style, $thing, @methods) = @_;

    my $meta_method = "get_${style}_method_modifiers";

    ### $thing
    my $meta = find_meta($thing);
    my $name = _thing_name($thing, $meta);

    ### @methods
    $tb->ok(!!$meta->$meta_method($_), "$name wraps $style method $_")
        for @methods;

    return;
}


{
    my $_is_test  = sub { $tb->ok( $_[0]->requires_method($_), "$_[1] requires method $_")         };
    my $_not_test = sub { $tb->ok(!$_[0]->requires_method($_), "$_[1] does not require method $_") };

    sub requires_method_ok ($@)         { unshift @_, $_is_test;  goto \&_method_ok_guts }
    sub does_not_require_method_ok ($@) { unshift @_, $_not_test; goto \&_method_ok_guts }
}


sub is_immutable_ok ($;$) {
    my ($thing, $message) = @_;

    ### $thing
    my $meta = find_meta($thing);

    $message ||= _thing_name($thing, $meta) . ' is immutable';
    return $tb->ok($meta->is_immutable, $message);
}

sub is_not_immutable_ok ($;$) {
    my ($thing, $message) = @_;

    ### $thing
    my $meta = find_meta($thing);

    $message ||= _thing_name($thing, $meta) . ' is not immutable';
    return $tb->ok(!$meta->is_immutable, $message);
}



{
    my $_is_test  = sub { $tb->ok( $_[0]->is_pristine(), "$_[1] is pristine")     };
    my $_not_test = sub { $tb->ok(!$_[0]->is_pristine(), "$_[1] is not pristine") };

    # FIXME should probably rename _method_ok_guts()...
    sub is_pristine_ok ($)     { @_ = ($_is_test,  @_, q{}); goto \&_method_ok_guts }
    sub is_not_pristine_ok ($) { @_ = ($_not_test, @_, q{}); goto \&_method_ok_guts }
}


# NOTE: deprecate at some point late 2015
sub is_role  ($) { goto \&is_role_ok  }
sub is_class ($) { goto \&is_class_ok }

sub is_role_ok  ($) { unshift @_, 'Role';  goto \&_is_moosey_ok }
sub is_class_ok ($) { unshift @_, 'Class'; goto \&_is_moosey_ok }

sub _is_moosey_ok {
    my ($type, $thing) =  @_;

    my $thing_name = _thing_name($thing);

    my $meta = find_meta($thing);
    $tb->ok(!!$meta, "$thing_name has a metaclass");
    return unless !!$meta;

    my $is_moosey = $meta->isa("Moose::Meta::$type");

    # special check for class -- this will happen when, say, you're validating
    # an attribute and it's a bog standard Moose::Meta::Attribute: strictly
    # speaking its metaclass is Class::MOPish, but really,
    # a Moose::Meta::Attribute is a Moose class.  Or arguably so.  Certainly
    # in the context of what we're asking about here.  Better approaches to
    # this welcomed as pull requests :)

    $is_moosey ||= ($meta->name || q{}) =~ /^Moose::Meta::/
        if $type eq 'Class';

    return $tb->ok($is_moosey, "$thing_name is a Moose " . lc $type);
}


# NOTE: deprecate at some point late 2015
sub is_anon     ($) { goto \&is_anon_ok     }
sub is_not_anon ($) { goto \&is_not_anon_ok }

sub is_anon_ok ($) {
    my ($thing, $message) = @_;

    my $thing_meta = find_meta($thing);
    $message ||= _thing_name($thing, $thing_meta) . ' is anonymous';

    return $tb->ok(!!$thing_meta->is_anon, $message);
}

sub is_not_anon_ok ($) {
    my ($thing, $message) = @_;

    my $thing_meta = find_meta($thing);
    $message ||= _thing_name($thing, $thing_meta) . ' is not anonymous';

    return $tb->ok(!$thing_meta->is_anon, $message);
}


sub check_sugar_removed_ok ($) {
    my $t = shift @_;

    # check some (not all) Moose sugar to make sure it has been cleared
    $tb->ok(!$t->can($_) => "$t cannot $_") for known_sugar;

    return;
}


sub check_sugar_ok ($) {
    my $t = shift @_;

    # check some (not all) Moose sugar to make sure it has been cleared
    $tb->ok($t->can($_) => "$t can $_") for known_sugar;

    return;
}


sub does_metaroles_ok($$)     { push @_, \&does_ok;     goto &_does_metaroles }
sub does_not_metaroles_ok($$) { push @_, \&does_not_ok; goto &_does_metaroles }

sub _does_metaroles {
    my ($thing, $metaroles, $test_func) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $meta = find_meta($thing);
    my $name = _thing_name($thing, $meta);

    for my $mop (sort keys %$metaroles) {

        my $mop_metaclass = get_mop_metaclass_for $mop => $meta;

        local $THING_NAME = "${name}'s $mop metaclass $mop_metaclass";
        $test_func->($mop_metaclass => $metaroles->{$mop});
    }

    return;
}


sub validate_thing ($@) { _validate_subtest_wrapper(\&_validate_thing_guts, @_) }
sub validate_class ($@) { _validate_subtest_wrapper(\&_validate_class_guts, @_) }
sub validate_role  ($@) { _validate_subtest_wrapper(\&_validate_role_guts,  @_) }

sub _validate_subtest_wrapper {
    my ($func, $thing, %args) = @_;

    # note incrementing by 2 because of our upper curried function
    local $Test::Builder::Level = $Test::Builder::Level + 2;

    # run tests w/o a subtest wrapper...
    return $func->($thing => %args)
        unless $args{-subtest};

    $args{-subtest} = _thing_name($thing)
        if "$args{-subtest}" eq '1';

    # ...or with one.
    return $tb->subtest(delete $args{-subtest} => sub { $func->($thing => %args) });
}

sub _validate_thing_guts {
    my ($thing, %args) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $meta = find_meta($thing);
    my $name = _thing_name($thing, $meta);

    ### anonymous...
    $args{anonymous} ? is_anon_ok $thing : is_not_anon_ok $thing
        if exists $args{anonymous};

    ### sugar checking...
    $args{sugar} ? check_sugar_ok $thing : check_sugar_removed_ok $thing
        if exists $args{sugar};

    # metaclass checking
    for my $mop (sort keys %{ $args{metaclasses} || {} }) {

        my $mop_metaclass = get_mop_metaclass_for $mop => $meta;

        local $THING_NAME = "${name}'s $mop metaclass";
        validate_class $mop_metaclass => (
            -subtest => "Checking the $mop metaclass, $mop_metaclass",
            %{ $args{metaclasses}->{$mop} },
        );
    }

    ### roles...
    do { does_ok($thing, $_) for @{$args{does}} }
        if exists $args{does};
    do { does_not_ok($thing, $_) for @{$args{does_not}} }
        if exists $args{does_not};

    ### methods...
    do { has_method_ok($thing, $_) for @{$args{methods}} }
        if exists $args{methods};
    do { has_no_method_ok($thing, $_) for @{$args{no_methods}} }
        if exists $args{no_methods};

    ### attributes...
    ATTRIBUTE_LOOP:
    for my $attribute (@{Data::OptList::mkopt($args{attributes} || [])}) {

        my ($name, $opts) = @$attribute;
        has_attribute_ok($thing, $name)
            or next ATTRIBUTE_LOOP;

        if (!!$opts) {

            SKIP: {
                skip 'Cannot examine attribute metaclass in roles', 1
                    if (find_meta($thing)->isa('Moose::Meta::Role'));

                local $THING_NAME = _thing_name($thing) . "'s attribute $name";
                _validate_attribute(_find_attribute($thing, $name) => (
                    -subtest => "checking $THING_NAME",
                    %$opts,
                ));
            }
        }
    }

    return;
}

sub _validate_class_guts {
    my ($class, %args) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return unless is_class_ok $class;

    my $meta = find_meta($class);
    my $name = _thing_name($class, $meta);

    do { ok($class->isa($_), "$name isa $_") for @{$args{isa}} }
        if exists $args{isa};

    # check our mutability
    do { is_immutable_ok $class }
        if exists $args{immutable} && $args{immutable};
    do { is_not_immutable_ok $class }
        if exists $args{immutable} && !$args{immutable};

    # metaclass / metarole checking
    do { does_metaroles_ok $class => $args{class_metaroles} }
        if exists $args{class_metaroles};
    do { does_not_metaroles_ok $class => $args{no_class_metaroles} }
        if exists $args{no_class_metaroles};

    confess 'Cannot specify both a metaclasses and class_metaclasses to validate_class()!'
        if $args{class_metaclasses} && $args{metaclasses};

    $args{metaclasses} = $args{class_metaclasses}
        if exists $args{class_metaclasses};

    return validate_thing $class => %args;
}

# _validate_role_guts() is where the main logic of validate_role() lives;
# we're broken out here so as to allow it all to be easily wrapped -- or not
# -- in a subtest.

sub _validate_role_guts {
    my ($role, %args) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    # basic role validation
    return unless is_role_ok $role;

    requires_method_ok($role => @{ $args{required_methods} })
        if defined $args{required_methods};

    role_wraps_before_method_ok($role => @{ $args{before} })
        if defined $args{before};
    role_wraps_around_method_ok($role => @{ $args{around} })
        if defined $args{around};
    role_wraps_after_method_ok($role => @{ $args{after} })
        if defined $args{after};

    # metarole checking
    do { does_metaroles_ok $role => $args{role_metaroles} }
        if exists $args{role_metaroles};
    do { does_not_metaroles_ok $role => $args{no_role_metaroles} }
        if exists $args{no_role_metaroles};


    confess 'Cannot specify both a metaclasses and role_metaclasses to validate_class()!'
        if $args{role_metaclasses} && $args{metaclasses};

    $args{metaclasses} = $args{role_metaclasses}
        if exists $args{role_metaclasses};

    # if we've been asked to compose ourselves, then do that -- otherwise return
    $args{-compose}
        ?        validate_thing $role => %args
        : return validate_thing $role => %args
        ;

    # compose it and validate that class.
    my $anon = Moose::Meta::Class->create_anon_class(
        roles => [$role],
        methods => { map { $_ => sub {} } @{ $args{required_methods} || [] } },
    );

    # take anything in required_methods and put it in methods for this test
    $args{methods}
        = defined $args{methods}
        ? [ @{$args{methods}}, @{$args{required_methods} || []} ]
        : [ @{$args{required_methods}                    || []} ]
        ;
    delete $args{required_methods};
    # and add a test for the role we're actually testing...
    $args{does} = [ $role, @{ $args{does} || [] } ];

    # aaaand a subtest wrapper to make it easier to read...
    local $THING_NAME = _thing_name($role) . q{'s composed class};
    return validate_class $anon->name => (
        -subtest => 'role composed into ' . $anon->name,
        %args,
    );
}


sub _validate_attribute       { _validate_subtest_wrapper(\&__validate_attribute_guts,                 @_) }
sub validate_attribute ($$@)  { _validate_subtest_wrapper( \&_validate_attribute_guts, [shift, shift], @_) }

sub _validate_attribute_guts {
    my ($thingname, %opts) = @_;
    my ($thing, $name) = @$thingname;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return unless has_attribute_ok($thing, $name);
    my $att = _find_attribute($thing => $name);

    local $THING_NAME = _thing_name($thing) . "'s attribute $name";
    return _validate_attribute($att, %opts);
}

sub __validate_attribute_guts {
    my ($att, %opts) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my %thing_opts =
        map   { $_ => delete $opts{"-$_"} }
        apply { s/^-//                    }
        grep  { /^-/                      }
        sort keys %opts
        ;

    $thing_opts{does} = [ map { resolve_metatrait_alias(Attribute => $_) } @{$thing_opts{does}} ]
        if $thing_opts{does};

    ### %thing_opts
    {
        # If $THING_NAME is set, we're processing an attribute metaclass via
        # _validate_attribute_guts() or _validate_thing_guts()
        local $THING_NAME = "${THING_NAME}'s metaclass"
            if !!$THING_NAME;
        validate_class $att => %thing_opts
            if keys %thing_opts;
    }

    return _attribute_options_ok($att, %opts);
}

sub attribute_options_ok ($$@) {
    my ($thing, $name, %opts) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return unless has_attribute_ok($thing, $name);
    my $att = _find_attribute($thing => $name);

    return _validate_subtest_wrapper(\&_attribute_options_ok => ($att, %opts));
}

sub _attribute_options_ok {
    my ($att, %opts) = @_;

    goto \&_role_attribute_options_ok
        if $att->isa('Moose::Meta::Role::Attribute');
    goto \&_class_attribute_options_ok;
}

sub _role_attribute_options_ok {
    my ($att, %opts) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $name                    = $att->name;
    my $thing_name              = _thing_name($name, $att);

    exists $opts{required} and delete $opts{required}
        ? ok($att->is_required,  "$thing_name is required")
        : ok(!$att->is_required, "$thing_name is not required")
        ;

    exists $opts{lazy} and delete $opts{lazy}
        ? ok($att->is_lazy,  "$thing_name is lazy")
        : ok(!$att->is_lazy, "$thing_name is not lazy")
        ;

    exists $opts{coerce} and delete $opts{coerce}
        ? ok( $att->should_coerce, "$thing_name should coerce")
        : ok(!$att->should_coerce, "$thing_name should not coerce")
        ;

    ### for now, skip role attributes: blessed $att
    return $tb->skip('cannot yet test role attribute layouts')
        if keys %opts;
}

sub _class_attribute_options_ok {
    my ($att, %opts) = @_;

    my @check_opts =
        qw{ reader writer accessor predicate default builder clearer };
    my @unhandled_opts = qw{ isa does handles traits };

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $name = $att->name;

    my $thing_name = _thing_name($name, $att);

    # XXX do we really want to do this?
    if (my $is = delete $opts{is}) {
        $opts{accessor} = $name if $is eq 'rw' && ! exists $opts{accessor};
        $opts{reader}   = $name if $is eq 'ro' && ! exists $opts{reader};
    }

    # helper to check an attribute option we expect to be a string, !exist, or
    # undef
    my $check = sub {
        my $property = shift || $_;
        my $value    = delete $opts{$property};
        my $has      = "has_$property";

        # deeper and deeper down the rabbit hole...
        local $Test::Builder::Level = $Test::Builder::Level + 1;

        defined $value
            ? ok($att->$has,  "$thing_name has a $property")
            : ok(!$att->$has, "$thing_name does not have a $property")
            ;
        is($att->$property, $value, "$thing_name option $property correct")
    };

    exists $opts{required} and delete $opts{required}
        ? ok($att->is_required,  "$thing_name is required")
        : ok(!$att->is_required, "$thing_name is not required")
        ;

    $check->($_) for grep { any(@check_opts) eq $_ } sort keys %opts;

    do { $tb->skip("cannot test '$_' options yet", 1); delete $opts{$_} }
        for grep { exists $opts{$_} } @unhandled_opts;

    if (exists $opts{init_arg}) {

        $opts{init_arg}
            ?  $check->('init_arg')
            : ok(!$att->has_init_arg, "$thing_name has no init_arg")
            ;
        delete $opts{init_arg};
    }

    exists $opts{lazy} and delete $opts{lazy}
        ? ok($att->is_lazy,  "$thing_name is lazy")
        : ok(!$att->is_lazy, "$thing_name is not lazy")
        ;

    exists $opts{coerce} and delete $opts{coerce}
        ? ok( $att->should_coerce, "$thing_name should coerce")
        : ok(!$att->should_coerce, "$thing_name should not coerce")
        ;

    for my $opt (sort keys %opts) {

        do { fail "unknown attribute option: $opt"; next }
            unless $att->meta->find_attribute_by_name($opt);

        $check->($opt);
    }

    #fail "unknown attribute option: $_"
        #for sort keys %opts;

    return;
}

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl Chad Etheridge Granum Karen subtest MOPs metaroles

=head1 NAME

Test::Moose::More - More tools for testing Moose packages

=head1 VERSION

This document describes version 0.048 of Test::Moose::More - released June 17, 2017 as part of Test-Moose-More.

=head1 SYNOPSIS

    use Test::Moose::More;

    is_class_ok 'Some::Class';
    is_role_ok  'Some::Role';
    has_method_ok 'Some::Class', 'foo';

    # ... etc

=head1 DESCRIPTION

This package contains a number of additional tests that can be employed
against Moose classes/roles.  It is intended to replace L<Test::Moose> in your
tests, and re-exports any tests that it has and we do not, yet.

=head2 Export Groups

By default, this package exports all test functions.  You can be more
selective, however, and there are a number of export groups (aside from the
default C<:all>) to help you achieve those dreams!

=over 4

=item :all

All exportable functions.

=item :validate

L</validate_attribute>, L</validate_class>, L</validate_role>, L</validate_thing>

=back

=head1 TEST FUNCTIONS

=head2 meta_ok $thing

Tests C<$thing> to see if it has a metaclass; C<$thing> may be the class name or
instance of the class you wish to check.  Passes if C<$thing> has a metaclass.

=head2 no_meta_ok $thing

Tests C<$thing> to see if it does not have a metaclass; C<$thing> may be the class
name or instance of the class you wish to check.  Passes if C<$thing> does not
have a metaclass.

=head2 does_ok $thing, < $role | \@roles >, [ $message ]

Checks to see if C<$thing> does the given roles.  C<$thing> may be the class name or
instance of the class you wish to check.

Note that the message will be taken verbatim unless it contains C<%s>
somewhere; this will be replaced with the name of the role being tested for.

=head2 does_not_ok $thing, < $role | \@roles >, [ $message ]

Checks to see if C<$thing> does not do the given roles.  C<$thing> may be the
class name or instance of the class you wish to check.

Note that the message will be taken verbatim unless it contains C<%s>
somewhere; this will be replaced with the name of the role being tested for.

=head2 has_attribute_ok $thing, $attribute_name, [ $message ]

Checks C<$thing> for an attribute named C<$attribute_name>; C<$thing> may be a
class name, instance, or role name.

=head2 has_method_ok $thing, @methods

Queries C<$thing>'s metaclass to see if C<$thing> has the methods named in
C<@methods>.

Note: This does B<not> include inherited methods; see
L<Class::MOP::Class/has_method>.

=head2 has_no_method_ok $thing, @methods

Queries C<$thing>'s metaclass to ensure C<$thing> does not provide the methods named
in C<@methods>.

Note: This does B<not> include inherited methods; see
L<Class::MOP::Class/has_method>.

=head2 has_method_from_anywhere_ok $thing, @methods

Queries C<$thing>'s metaclass to see if C<$thing> has the methods named in
C<@methods>.

Note: This B<does> include inherited methods; see
L<Class::MOP::Class/find_method_by_name>.

=head2 has_no_method_from_anywhere_ok $thing, @methods

Queries C<$thing>'s metaclass to ensure C<$thing> does not provide the methods
named in C<@methods>.

Note: This B<does> include inherited methods; see
L<Class::MOP::Class/find_method_by_name>.

=head2 method_from_pkg_ok $thing, $method, $orig_pkg

Given a thing (role, class, etc) and a method, test that it originally came
from C<$orig_pkg>.

=head2 method_not_from_pkg_ok $thing, $method, $orig_pkg

Given a thing (role, class, etc) and a method, test that it did not come from
C<$orig_pkg>.

=head2 method_is_accessor_ok $thing, $method

Given a thing (role, class, etc) and a method, test that the method is an
accessor -- that is, it descends from L<Class::MOP::Method::Accessor>.

=head2 method_is_not_accessor_ok $thing, $method

Given a thing (role, class, etc) and a method, test that the method is B<not>
an accessor -- that is, it does not descend from L<Class::MOP::Method::Accessor>.

=head2 role_wraps_around_method_ok $role, @methods

Queries C<$role>'s metaclass to see if C<$role> wraps the methods named in
C<@methods> with an around method modifier.

=head2 role_wraps_before_method_ok $role, @methods

Queries C<$role>'s metaclass to see if C<$role> wraps the methods named in
C<@methods> with an before method modifier.

=head2 role_wraps_after_method_ok $role, @methods

Queries C<$role>'s metaclass to see if C<$role> wraps the methods named in
C<@methods> with an after method modifier.

=head2 requires_method_ok $thing, @methods

Queries C<$thing>'s metaclass to see if C<$thing> requires the methods named in
C<@methods>.

Note that this really only makes sense if C<$thing> is a role.

=head2 does_not_require_method_ok $thing, @methods

Queries C<$thing>'s metaclass to ensure C<$thing> does not require the methods named
in C<@methods>.

Note that this really only makes sense if C<$thing> is a role.

=head2 is_immutable_ok $thing

Passes if C<$thing> is immutable.

=head2 is_not_immutable_ok $thing

Passes if C<$thing> is not immutable; that is, is mutable.

=head2 is_pristine_ok $thing

Passes if C<$thing> is pristine.  See L<Class::MOP::Class/is_pristine>.

=head2 is_not_pristine_ok $thing

Passes if C<$thing> is not pristine.  See L<Class::MOP::Class/is_pristine>.

=head2 is_role_ok $thing

Passes if C<C<$thing>'s> metaclass is a L<Moose::Meta::Role>.

=head2 is_class_ok $thing

Passes if C<C<$thing>'s> metaclass is a L<Moose::Meta::Class>.

=head2 is_anon_ok $thing

Passes if C<$thing> is "anonymous".

=head2 is_not_anon_ok $thing

Passes if C<$thing> is not "anonymous".

=head2 check_sugar_removed_ok $thing

Ensures that all the standard Moose sugar is no longer directly callable on a
given package.

=head2 check_sugar_ok $thing

Checks and makes sure a class/etc can still do all the standard Moose sugar.

=head2 does_metaroles_ok $thing => { $mop => [ @traits ], ... };

Validate the metaclasses associated with a class/role metaclass.

e.g., if I wanted to validate that the attribute trait for
L<MooseX::AttributeShortcuts> is actually applied, I could do this:

    { package TestClass; use Moose; use MooseX::AttributeShortcuts; }
    use Test::Moose::More;
    use Test::More;

    does_metaroles_ok TestClass => {
       attribute => ['MooseX::AttributeShortcuts::Trait::Attribute'],
    };
    done_testing;

This function will accept either class or role metaclasses for C<$thing>.

The MOPs available for classes (L<Moose::Meta::Class>) are:

=over 4

=item class

=item attribute

=item method

=item wrapped_method

=item instance

=item constructor

=item destructor

=back

The MOPs available for roles (L<Moose::Meta::Role>) are:

=over 4

=item role

=item attribute

=item method

=item required_method

=item wrapped_method

=item conflicting_method

=item application_to_class

=item application_to_role

=item application_to_instance

=item applied_attribute

=back

Note!  Neither this function nor C<does_not_metaroles_ok()> attempts to
validate that the MOP type passed in is a member of the above lists.  There's
no gain here in implementing such a check, and a negative to be had:
specifying an invalid MOP type will result in immediate explosions, while it's
entirely possible other MOP types will be added (either to core, via traits,
or "let's subclass Moose::Meta::Class/etc and implement something new").

=head2 does_not_metaroles_ok $thing => { $mop => [ @traits ], ... };

As with L</does_metaroles_ok>, but test that the metaroles are not consumed, a
la L</does_not_ok>.

=head2 validate_thing

Runs a bunch of tests against the given C<$thing>, as defined:

    validate_thing $thing => (

        attributes => [ ... ],
        methods    => [ ... ],
        isa        => [ ... ],

        # ensures sugar is/is-not present
        sugar      => 0,

        # ensures $thing does these roles
        does       => [ ... ],

        # ensures $thing does not do these roles
        does_not   => [ ... ],
    );

C<$thing> can be the name of a role or class, an object instance, or a
metaclass.

=over 4

=item *

-subtest => 'subtest name...'

If set, all tests run will be wrapped in a subtest, the name of which will be
whatever C<-subtest> is set to.

=item *

isa => [ ... ]

A list of superclasses thing should have.

=item *

anonymous => 0|1

Check to see if the class is/isn't anonymous.

=item *

does => [ ... ]

A list of roles the thing should do.

=item *

does_not => [ ... ]

A list of roles the thing should not do.

=item *

attributes => [ ... ]

The attributes list specified here is in the form of a list of names, each
optionally followed by a hashref of options to test the attribute for; this
hashref takes the same arguments L</validate_attribute> does.  e.g.:

    validate_thing $thing => (

        attributes => [
            'foo',
            'bar',
            baz => { is => 'ro', ... },
            'bip',
        ],
    );

=item *

methods => [ ... ]

A list of methods the thing should have; see L</has_method_ok>.

=item *

no_methods => [ ... ]

A list of methods the thing should not have; see L</has_no_method_ok>.

=item *

sugar => 0|1

Ensure that thing can/cannot do the standard Moose sugar.

=item *

metaclasses => { $mop => { ... }, ... }

Validates this thing's metaclasses: that is, given a MOP type (e.g. class,
attribute, method, ...) and a hashref, find the associated metaclass of the
given type and invoke L</validate_thing> on it, using the hashref as options
for C<validate_thing()>.

e.g.

    validate_thing 'TestClass' => (
        metaclasses  => {
            attribute => {
                isa  => [ 'Moose::Meta::Attribute' ],
                does => [ 'MetaRole::attribute'    ],
            },
        },
    );

...yields:

    # Subtest: Checking the attribute metaclass, Moose::Meta::Class::__ANON__::SERIAL::1
        ok 1 - TestClass's attribute metaclass has a metaclass
        ok 2 - TestClass's attribute metaclass is a Moose class
        ok 3 - TestClass's attribute metaclass isa Moose::Meta::Attribute
        ok 4 - TestClass's attribute metaclass does MetaRole::attribute
        1..4
    ok 1 - Checking the attribute metaclass, Moose::Meta::Class::__ANON__::SERIAL::1

Note that C<validate_class()> and C<validate_role()> implement this using
C<class_metaclasses> and C<role_metaclasses>, respectively.

=back

=head2 validate_role

The same as C<validate_thing()>, but ensures C<$thing> is a role, and allows
for additional role-specific tests.

    validate_role $thing => (

        required_methods => [ ... ],

        # ...and all other options from validate_thing()
    );

=over 4

=item *

-compose => 0|1

When true, attempt to compose the role into an anonymous class, then use it to
run L</validate_class>.  The options we're given are passed to C<validate_class()>
directly, except that any C<required_methods> entry is removed and its contents
pushed onto C<methods>.  (A stub method for each entry in C<required_methods>
will also be created in the new class.)

e.g.:

    ok 1 - TestRole has a metaclass
    ok 2 - TestRole is a Moose role
    ok 3 - TestRole requires method blargh
    ok 4 - TestRole does TestRole
    ok 5 - TestRole does not do TestRole::Two
    ok 6 - TestRole has method method1
    ok 7 - TestRole has an attribute named bar
    # Subtest: role composed into Moose::Meta::Class::__ANON__::SERIAL::1
        ok 1 - TestRole's composed class has a metaclass
        ok 2 - TestRole's composed class is a Moose class
        ok 3 - TestRole's composed class does TestRole
        ok 4 - TestRole's composed class does not do TestRole::Two
        ok 5 - TestRole's composed class has method method1
        ok 6 - TestRole's composed class has method blargh
        ok 7 - TestRole's composed class has an attribute named bar
        1..7
    ok 8 - role composed into Moose::Meta::Class::__ANON__::SERIAL::1
    1..8

=item *

-subtest => 'subtest name...'

If set, all tests run will be wrapped in a subtest, the name of which will be
whatever C<-subtest> is set to.

=item *

required_methods => [ ... ]

A list of methods the role requires a consuming class to supply.

=item *

before => [ ... ]

A list of methods the role expects to wrap before, on application to a class.

See L<Moose/before> for information on before method modifiers.

=item *

around => [ ... ]

A list of methods the role expects to wrap around, on application to a class.

See L<Moose/around> for information on around method modifiers.

=item *

after => [ ... ]

A list of methods the role expects to wrap after, on application to a class.

See L<Moose/after> for information on after method modifiers.

=item *

role_metaroles => { $mop => [ $role, ... ], ... }

Checks metaclasses to ensure the given metaroles are applied.  See
L</does_metaroles_ok>.

=item *

no_role_metaroles => { $mop => [ $role, ... ], ... }

Checks metaclasses to ensure the given metaroles are applied.  See
L</does_not_metaroles_ok>.

=item *

role_metaclasses => { $mop => { ... }, ... }

Validates this role's metaclasses: that is, given a MOP type (e.g. role,
attribute, method, ...) and a hashref, find the associated metaclass of the
given type and invoke L</validate_thing> on it, using the hashref as options
for C<validate_thing()>.

e.g.

    validate_role 'TestRole' => (
        metaclasses  => {
            attribute => {
                isa  => [ 'Moose::Meta::Attribute' ],
                does => [ 'MetaRole::attribute'    ],
            },
        },
    );

...yields:

    # Subtest: Checking the attribute metaclass, Moose::Meta::Class::__ANON__::SERIAL::1
        ok 1 - TestRole's attribute metaclass has a metaclass
        ok 2 - TestRole's attribute metaclass is a Moose class
        ok 3 - TestRole's attribute metaclass isa Moose::Meta::Attribute
        ok 4 - TestRole's attribute metaclass does MetaRole::attribute
        1..4
    ok 1 - Checking the attribute metaclass, Moose::Meta::Class::__ANON__::SERIAL::1

Note that C<validate_class()> and C<validate_role()> implement this using
C<class_metaclasses> and C<role_metaclasses>, respectively.

=item *

class_metaclasses => { $mop => { ... }, ... }

As with role_metaclasses, above, except that this option is only used
if C<-compose> is also specified.

=back

=head2 validate_class

The same as C<validate_thing()>, but ensures C<$thing> is a class, and allows
for additional class-specific tests.

    validate_class $thing => (

        isa  => [ ... ],

        attributes => [ ... ],
        methods    => [ ... ],

        # ensures sugar is/is-not present
        sugar      => 0,

        # ensures $thing does these roles
        does       => [ ... ],

        # ensures $thing does not do these roles
        does_not   => [ ... ],

        # ...and all other options from validate_thing()
    );

=over 4

=item *

-subtest => 'subtest name...'

If set, all tests run will be wrapped in a subtest, the name of which will be
whatever C<-subtest> is set to.

=item *

immutable => 0|1

Checks the class to see if it is/isn't immutable.

=item *

class_metaroles => { $mop => [ $role, ... ], ... }

Checks metaclasses to ensure the given metaroles are applied.  See
L</does_metaroles_ok>.

=item *

no_class_metaroles => { $mop => [ $role, ... ], ... }

Checks metaclasses to ensure the given metaroles are applied.  See
L</does_not_metaroles_ok>.

=item *

class_metaclasses => { $mop => { ... }, ... }

Validates this class' metaclasses: that is, given a MOP type (e.g. role,
attribute, method, ...) and a hashref, find the associated metaclass of the
given type and invoke L</validate_thing> on it, using the hashref as options
for C<validate_thing()>.

e.g.

    validate_class 'TestClass' => (
        metaclasses  => {
            attribute => {
                isa  => [ 'Moose::Meta::Attribute' ],
                does => [ 'MetaRole::attribute'    ],
            },
        },
    );

...yields:

    ok 1 - TestClass has a metaclass
    ok 2 - TestClass is a Moose class
    # Subtest: Checking the attribute metaclass, Moose::Meta::Class::__ANON__::SERIAL::1
        ok 1 - TestClass's attribute metaclass has a metaclass
        ok 2 - TestClass's attribute metaclass is a Moose class
        ok 3 - TestClass's attribute metaclass isa Moose::Meta::Attribute
        ok 4 - TestClass's attribute metaclass does MetaRole::attribute
        1..4
    ok 3 - Checking the attribute metaclass, Moose::Meta::Class::__ANON__::SERIAL::1

=back

=head2 validate_attribute

C<validate_attribute()> allows you to test how an attribute looks once built
and attached to a class.

Let's say you have an attribute defined like this:

    has foo => (
        traits  => [ 'TestRole' ],
        is      => 'ro',
        isa     => 'Int',
        builder => '_build_foo',
        lazy    => 1,
    );

You can use C<validate_attribute()> to ensure that it's built out in the way
you expect:

    validate_attribute TestClass => foo => (

        # tests the attribute metaclass instance to ensure it does the roles
        -does => [ 'TestRole' ],
        # tests the attribute metaclass instance's inheritance
        -isa  => [ 'Moose::Meta::Attribute' ], # for demonstration's sake

        traits   => [ 'TestRole' ],
        isa      => 'Int',
        does     => 'Bar',
        handles  => { },
        reader   => 'foo',
        builder  => '_build_foo',
        default  => undef,
        init_arg => 'foo',
        lazy     => 1,
        required => undef,
    );

Options passed to C<validate_attribute()> prefixed with C<-> test the
attribute's metaclass instance rather than a setting on the attribute; that
is, C<-does> ensures that the metaclass does a particular role (e.g.
L<MooseX::AttributeShortcuts>), while C<does> tests the setting of the
attribute to require the value do a given role.

This function takes all the options L</attribute_options_ok> takes, as well as
the following:

=over 4

=item *

-subtest => 'subtest name...'

If set, all tests run will be wrapped in a subtest, the name of which will be
whatever C<-subtest> is set to.

=back

=head2 attribute_options_ok

Validates that an attribute is set up as expected; like
C<validate_attribute()>, but only concerns itself with attribute options.

Note that some of these options will skip if used against attributes defined
in a role.

=over 4

=item *

-subtest => 'subtest name...'

If set, all tests run (save the first, "does this thing even have this
attribute?" test) will be wrapped in a subtest, the name of which will be
whatever C<-subtest> is set to.

=item *

is => ro|rw

Tests for reader/writer options set as one would expect.

=item *

isa => ...

Validates that the attribute requires its value to be a given type.

=item *

does => ...

Validates that the attribute requires its value to do a given role.

=item *

builder => '...'

Validates that the attribute expects the method name given to be its builder.

=item *

default => ...

Validates that the attribute has the given default.

=item *

init_arg => '...'

Validates that the attribute has the given initial argument name.

=item *

lazy => 0|1

Validates that the attribute is/isn't lazy.

=item *

required => 0|1

Validates that setting the attribute's value is/isn't required.

=back

=for Pod::Coverage is_anon is_class is_not_anon is_role

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Test::Moose>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/RsrchBoy/Test-Moose-More/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 CONTRIBUTORS

=for stopwords Chad Granum Karen Etheridge

=over 4

=item *

Chad Granum <chad.granum@dreamhost.com>

=item *

Karen Etheridge <ether@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017, 2016, 2015, 2014, 2013, 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
