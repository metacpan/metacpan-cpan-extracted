# ABSTRACT: Data Validation Engine for Validation::Class Classes

package Validation::Class::Prototype;

use 5.10.0;
use strict;
use warnings;

use Validation::Class::Configuration;
use Validation::Class::Directives;
use Validation::Class::Listing;
use Validation::Class::Mapping;
use Validation::Class::Params;
use Validation::Class::Fields;
use Validation::Class::Errors;
use Validation::Class::Util;

our $VERSION = '7.900057'; # VERSION

use List::MoreUtils 'uniq', 'firstval';
use Hash::Flatten 'flatten', 'unflatten';
use Module::Runtime 'use_module';
use Module::Find 'findallmod';
use Scalar::Util 'weaken';
use Hash::Merge 'merge';
use Carp 'confess';
use Clone 'clone';


my $_registry = Validation::Class::Mapping->new; # prototype registry


hold 'attributes' => sub { Validation::Class::Mapping->new };


hold 'builders' => sub { Validation::Class::Listing->new };


hold 'configuration' => sub { Validation::Class::Configuration->new };


hold 'directives' => sub { Validation::Class::Mapping->new };


hold 'documents' => sub { Validation::Class::Mapping->new };


hold 'errors' => sub { Validation::Class::Errors->new };


hold 'events' => sub { Validation::Class::Mapping->new };


hold 'fields' => sub { Validation::Class::Fields->new };


has 'filtering' => 'pre';


hold 'filters' => sub { Validation::Class::Mapping->new };


has 'ignore_failure' => '1';


has 'ignore_intervention' => '0';


has 'ignore_unknown' => '0';


hold 'messages' => sub { Validation::Class::Mapping->new };


hold 'methods' => sub { Validation::Class::Mapping->new };


hold 'mixins' => sub { Validation::Class::Mixins->new };


hold 'package' => sub { undef };


hold 'params' => sub { Validation::Class::Params->new };


hold 'profiles' => sub { Validation::Class::Mapping->new };


hold 'queued' => sub { Validation::Class::Listing->new };


has 'report_failure' => 0;


has 'report_unknown' => 0;


hold 'settings' => sub { Validation::Class::Mapping->new };


has 'validated' => 0;

has 'stashed' => sub { Validation::Class::Mapping->new };

Hash::Merge::specify_behavior(
    {
        'SCALAR' => {
            'SCALAR'  => sub {
                $_[1]
            },
            'ARRAY'   => sub {
                [$_[0], @{$_[1]}]
            },
            'HASH'    => sub {
                $_[1]
            },
        },
        'ARRAY' => {
            'SCALAR'  => sub {
                [@{$_[0]}, $_[1]]
            },
            'ARRAY'   => sub {
                [@{$_[0]}, @{$_[1]}]
            },
            'HASH'    => sub {
                [@{$_[0]}, $_[1]]
            },
        },
        'HASH' => {
            'SCALAR'  => sub {
                $_[1]
            },
            'ARRAY'   => sub {
                $_[1]
            },
            'HASH'    => sub {
                Hash::Merge::_merge_hashes($_[0], $_[1])
            },
        },
    },
    # based on RIGHT_PRECEDENT, STORAGE_PRECEDENT and RETAINMENT_PRECEDENT
    # ... this is intended to DWIM in the context of role-settings-merging
    'ROLE_PRECEDENT'
);

sub new {

    my $class = shift;

    my $arguments = $class->build_args(@_);

    confess
        "The $class class must be instantiated with a parameter named package ".
        "whose value is the name of the associated package" unless defined
        $arguments->{package} && $arguments->{package} =~ /\w/
    ;

    my $self = bless $arguments, $class;

    $_registry->add($arguments->{package}, $self);

    return $self;

}

sub apply_filter {

    my ($self, $filter, $field) = @_;

    my $name = $field;

    $field  = $self->fields->get($field);
    $filter = $self->filters->get($filter);

    return unless $field && $filter;

    if ($self->params->has($name)) {

        if (isa_coderef($filter)) {

            if (my $value = $self->params->get($name)) {

                if (isa_arrayref($value)) {
                    foreach my $el (@{$value}) {
                        $el = $filter->($el);
                    }
                }
                else {
                    $value = $filter->($value);
                }

                $self->params->add($name, $value);

            }

        }

    }

    return $self;

}


sub apply_filters {

    my ($self, $state) = @_;

    $state ||= 'pre'; # state defaults to (pre) filtering

    # check for and process input filters and default values
    my $run_filter = sub {

        my ($name, $spec) = @_;

        if ($spec->filtering) {

            if ($spec->filtering eq $state) {

                # the filters directive should always be an arrayref
                $spec->filters([$spec->filters]) unless isa_arrayref($spec->filters);

                # apply filters
                $self->apply_filter($_, $name) for @{$spec->filters};

            }

        }

    };

    $self->fields->each($run_filter);

    return $self;

}

sub apply_mixin {

    my ($self, $field, $mixin) = @_;

    return unless $field && $mixin;

    $field = $self->fields->get($field);

    $mixin ||= $field->mixin;

    return unless $mixin && $field;

    # mixin values should be in arrayref form

    my $mixins = isa_arrayref($mixin) ? $mixin : [$mixin];

    foreach my $name (@{$mixins}) {

        my $mixin = $self->mixins->get($name);

        next unless $mixin;

        $self->merge_mixin($field->name, $mixin->name);

    }

    return $self;

}

sub apply_mixin_field {

    my ($self, $field_a, $field_b) = @_;

    return unless $field_a && $field_b;

    $self->check_field($field_a);
    $self->check_field($field_b);

    # some overwriting restricted

    my $fields = $self->fields;

    $field_a = $fields->get($field_a);
    $field_b = $fields->get($field_b);

    return unless $field_a && $field_b;

    my $name  = $field_b->name if $field_b->has('name');
    my $label = $field_b->label if $field_b->has('label');

    # merge

    $self->merge_field($field_a->name, $field_b->name);

    # restore

    $field_b->name($name)   if defined $name;
    $field_b->label($label) if defined $label;

    $self->apply_mixin($name, $field_a->mixin) if $field_a->can('mixin');

    return $self;

}

sub apply_validator {

    my ( $self, $field_name, $field ) = @_;

    # does field have a label, if not use field name (e.g. for errors, etc)

    my $name  = $field->{label} ? $field->{label} : $field_name;
    my $value = $field->{value} ;

    # check if required

    my $req = $field->{required} ? 1 : 0;

    if (defined $field->{'toggle'}) {

        $req = 1 if $field->{'toggle'} eq '+';
        $req = 0 if $field->{'toggle'} eq '-';

    }

    if ( $req && ( !defined $value || $value eq '' ) ) {

        my $error = defined $field->{error} ?
            $field->{error} : "$name is required";

        $field->errors->add($error);

        return $self; # if required and fails, stop processing immediately

    }

    if ( $req || $value ) {

        # find and process all the validators

        foreach my $key (keys %{$field}) {

            my $directive = $self->directives->{$key};

            if ($directive) {

                if ($directive->{validator}) {

                    if ("CODE" eq ref $directive->{validator}) {

                        # execute validator directives
                        $directive->{validator}->(
                            $field->{$key}, $value, $field, $self
                        );

                    }

                }

            }

        }

    }

    return $self;

}

sub check_field {

    my ($self, $name) = @_;

    my $directives = $self->directives;

    my $field = $self->fields->get($name);

    foreach my $key ($field->keys) {

        my $directive = $directives->get($key);

        unless (defined $directive) {
            $self->pitch_error( sprintf
                "The %s directive supplied by the %s field is not supported",
                $key, $name
            );
        }

    }

    return 1;

}

sub check_mixin {

    my ($self, $name) = @_;

    my $directives = $self->directives;

    my $mixin = $self->mixins->get($name);

    foreach my $key ($mixin->keys) {

        my $directive = $directives->get($key);

        unless (defined $directive) {
            $self->pitch_error( sprintf
                "The %s directive supplied by the %s mixin is not supported",
                $key, $name
            );
        }

    }

    return 1;

}


sub class {

    my $self = shift;

    my ($name, %args) = @_;

    return unless $name;

    my @strings;

    @strings = split /\//, $name;
    @strings = map { s/[^a-zA-Z0-9]+([a-zA-Z0-9])/\U$1/g; $_ } @strings;
    @strings = map { /\w/ ? ucfirst $_ : () } @strings;

    my $class = join '::', $self->{package}, @strings;

    return unless $class;

    my @attrs = qw(

        ignore_failure
        ignore_intervention
        ignore_unknown
        report_failure
        report_unknown

    );  # to be copied (stash and params copied later)

    my %defaults = ( map { $_ => $self->$_ } @attrs );

    $defaults{'stash'}  = $self->stashed;     # copy stash
    $defaults{'params'} = $self->get_params;  # copy params

    my %settings = %{ merge \%args, \%defaults };

    use_module $class;

    for (keys %settings) {

        delete $settings{$_} unless $class->can($_);

    }

    return unless $class->can('new');
    return unless $self->registry->has($class); # isa validation class

    my $child = $class->new(%settings);

    {

        my $proto_method =
            $child->can('proto') ? 'proto' :
            $child->can('prototype') ? 'prototype' : undef
        ;

        if ($proto_method) {

            my $proto = $child->$proto_method;

            if (defined $settings{'params'}) {

                foreach my $key ($proto->params->keys) {

                    if ($key =~ /^$name\.(.*)/) {

                        if ($proto->fields->has($1)) {

                            push @{$proto->fields->{$1}->{alias}}, $key;

                        }

                    }

                }

            }

        }

    }

    return $child;

}


sub clear_queue {

    my $self = shift;

    my @names = $self->queued->list;

    for (my $i = 0; $i < @names; $i++) {

        $names[$i] =~ s/^[\-\+]{1}//;
        $_[$i] = $self->params->get($names[$i]);

    }

    $self->queued->clear;

    return @_;

}


sub clone_field {

    my ($self, $field, $new_field, $directives) = @_;

    $directives ||= {};

    $directives->{name} = $new_field unless $directives->{name};

    # build a new field from an existing one during runtime

    $self->fields->add(
        $new_field => Validation::Class::Field->new($directives)
    );

    $self->apply_mixin_field($new_field, $field);

    return $self;

}


sub does {

    my ($self, $role) = @_;

    my $roles = $self->settings->get('roles');

    return $roles ? (firstval { $_ eq $role } @{$roles}) ? 1 : 0 : 0;

}


sub error_count {

    my ($self) = @_;

    my $i = $self->errors->count;

    $i += $_->errors->count for $self->fields->values;

    return $i;

}


sub error_fields {

    my ($self, @fields) = @_;

    my $failed = {};

    @fields = $self->fields->keys unless @fields;

    foreach my $name (@fields) {

        my $field = $self->fields->{$name};

        if ($field->{errors}->count) {

            $failed->{$name} = [$field->{errors}->list];

        }

    }

    return $failed;

}


sub errors_to_string {

    my $self = shift;

    # combine class and field errors

    my $errors = Validation::Class::Errors->new([]);

    $errors->add($self->errors->list);

    $errors->add($_->errors->list) for ($self->fields->values);

    return $errors->to_string(@_);

}

sub flatten_params {

    my ($self, $hash) = @_;

    if ($hash) {

        $hash = Hash::Flatten::flatten($hash);

        $self->params->add($hash);

    }

    return $self->params->flatten->hash || {};

}


sub get_errors {

    my ($self, @criteria) = @_;

    my $errors = Validation::Class::Errors->new([]); # combined errors

    if (!@criteria) {

        $errors->add($self->errors->list);

        $errors->add($_->errors->list) for ($self->fields->values);

    }

    elsif (isa_regexp($criteria[0])) {

        my $query = $criteria[0];

        $errors->add($self->errors->grep($query)->list);
        $errors->add($_->errors->grep($query)->list) for $self->fields->values;

    }

    else {

        $errors->add($_->errors->list)
            for map {$self->fields->get($_)} @criteria;

    }

    return ($errors->list);

}


sub get_fields {

    my ($self, @fields) = @_;

    return () unless @fields;

    return (map { $self->fields->get($_) || undef } @fields);

}


sub get_hash {

    my ($self) = @_;

    return { map { $_ => $self->get_values($_) } $self->fields->keys };

}


sub get_params {

    my ($self, @params) = @_;

    my $params = $self->params->hash || {};

    if (@params) {

        return @params ?
            (map { defined $params->{$_} ? $params->{$_} : undef } @params) :
            ()
        ;

    }

    else {

        return $params;

    }

}


sub get_values {

    my ($self, @fields) = @_;

    return () unless @fields;
    return (
        map {
            my $field = $self->fields->get($_);
            my $param = $self->params->get($_);
                $field->readonly ?
                    $field->default || undef :
                    $field->value   || $param
                ;
        }   @fields
    );

}


sub is_valid {

    my ($self) = @_;

    return $self->error_count ? 0 : 1;

}

sub merge_field {

    my ($self, $field_a, $field_b) = @_;

    return unless $field_a && $field_b;

    my $directives = $self->directives;

    $field_a = $self->fields->get($field_a);
    $field_b = $self->fields->get($field_b);

    return unless $field_a && $field_b;

    # keep in mind that in this case we're using field_b as a mixin

    foreach my $pair ($field_b->pairs) {

        my ($key, $value) = @{$pair}{'key', 'value'};

        # skip unless the directive is mixin compatible

        next unless $directives->get($key)->mixin;

        # do not override existing keys but multi values append

        if ($field_a->has($key)) {

            next unless $directives->get($key)->multi;

        }

        if ($directives->get($key)->field) {

            # can the directive have multiple values, merge array

            if ($directives->get($key)->multi) {

                # if field has existing array value, merge unique

                if (isa_arrayref($field_a->{$key})) {

                    my @values = isa_arrayref($value) ? @{$value} : ($value);

                    push @values, @{$field_a->{$key}};

                    @values = uniq @values;

                    $field_a->{$key} = [@values];

                }

                # simple copy

                else {

                    $field_a->{$key} = isa_arrayref($value) ? $value : [$value];

                }

            }

            # simple copy

            else {

                $field_a->{$key} = $value;

            }

        }

    }

    return $self;

}

sub merge_mixin {

    my ($self, $field, $mixin) = @_;

    return unless $field && $mixin;

    my $directives = $self->directives;

    $field = $self->fields->get($field);
    $mixin = $self->mixins->get($mixin);

    foreach my $pair ($mixin->pairs) {

        my ($key, $value) = @{$pair}{'key', 'value'};

        # do not override existing keys but multi values append

        if ($field->has($key)) {

            next unless $directives->get($key)->multi;

        }

        if ($directives->get($key)->field) {

            # can the directive have multiple values, merge array

            if ($directives->get($key)->multi) {

                # if field has existing array value, merge unique

                if (isa_arrayref($field->{$key})) {

                    my @values = isa_arrayref($value) ? @{$value} : ($value);

                    push @values, @{$field->{$key}};

                    @values = uniq @values;

                    $field->{$key} = [@values];

                }

                # merge copy

                else {

                    my @values = isa_arrayref($value) ? @{$value} : ($value);

                    push @values, $field->{$key} if $field->{$key};

                    @values = uniq @values;

                    $field->{$key} = [@values];

                }

            }

            # simple copy

            else {

                $field->{$key} = $value;

            }

        }

    }

    return $field;

}


sub normalize {

    my ($self, $context) = @_;

    # we need context

    confess

        "Context object ($self->{package} class instance) required ".
        "to perform validation" unless $self->{package} eq ref $context

    ;

    # stash the current context object
    $self->stash->{'normalization.context'} = $context;

    # resets

    $self->validated(0);

    $self->reset_fields;

    # validate mixin directives

    foreach my $key ($self->mixins->keys) {

        $self->check_mixin($key);

    }

    # check for and process a mixin directive

    foreach my $key ($self->fields->keys) {

        my $field = $self->fields->get($key);

        next unless $field;

        $self->apply_mixin($key, $field->{mixin})
            if $field->can('mixin') && $field->{mixin};

    }

    # check for and process a mixin_field directive

    foreach my $key ($self->fields->keys) {

        my $field = $self->fields->get($key);

        next unless $field;

        $self->apply_mixin_field($key, $field->{mixin_field})
            if $field->can('mixin_field') && $field->{mixin_field}
        ;

    }

    # execute normalization events

    foreach my $key ($self->fields->keys) {

        $self->trigger_event('on_normalize', $key);

    }

    # alias checking, ... for duplicate aliases, etc

    my $mapper = {};
    my @fields = $self->fields->keys;

    foreach my $name (@fields) {

        my $field = $self->fields->get($name);
        my $label = $field->{label} ? $field->{label} : "The field $name";

        if (defined $field->{alias}) {

            my $aliases = "ARRAY" eq ref $field->{alias}
                ? $field->{alias} : [$field->{alias}];

            foreach my $alias (@{$aliases}) {

                if ($mapper->{$alias}) {

                    my $alt_field =
                        $self->fields->get($mapper->{$alias})
                    ;

                    my $alt_label = $alt_field->{label} ?
                        $alt_field->{label} : "the field $mapper->{$alias}"
                    ;

                    my $error =
                        qq($label contains the alias $alias which is
                        also an alias on $alt_label)
                    ;

                    $self->throw_error($error);

                }

                if ($self->fields->has($alias)) {

                    my $error =
                        qq($label contains the alias $alias which is
                        the name of an existing field)
                    ;

                    $self->throw_error($error);

                }

                $mapper->{$alias} = $name;

            }

        }

    }

    # final checkpoint, validate field directives

    foreach my $key ($self->fields->keys) {

        $self->check_field($key);

    }

    # delete the stashed context object
    delete $self->stash->{'normalization.context'};

    return $self;

}


sub param {

    my  ($self, $name, $value) = @_;

    if (defined $value) {
        $self->params->add($name, $value);
        return $value;
    }
    else {
        return unless $self->params->has($name);
        return $self->params->get($name);
    }

}

sub pitch_error {

    my ($self, $error_message) = @_;

    $error_message =~ s/\n/ /g;
    $error_message =~ s/\s+/ /g;

    if ($self->ignore_unknown) {

        if ($self->report_unknown) {
            $self->errors->add($error_message);
        }

    }

    else {
        $self->throw_error($error_message);
    }

    return $self;

}


sub plugin {

    my ($self, $name) = @_;

    return unless $name;

    # transform what looks like a shortname

    my @strings;

    @strings = split /\//, $name;
    @strings = map { s/[^a-zA-Z0-9]+([a-zA-Z0-9])/\U$1/g; $_ } @strings;
    @strings = map { /\w/ ? ucfirst $_ : () } @strings;

    my $class = join '::', 'Validation::Class::Plugin', @strings;

    eval { use_module $class };

    return $class->new($self);

}

sub proxy_methods {

    return qw{

        class
        clear_queue
        error
        error_count
        error_fields
        errors
        errors_to_string
        get_errors
        get_fields
        get_hash
        get_params
        get_values
        fields
        filtering
        ignore_failure
        ignore_intervention
        ignore_unknown
        is_valid
        param
        params
        plugin
        queue
        report_failure
        report_unknown
        reset_errors
        reset_fields
        reset_params
        set_errors
        set_fields
        set_params
        stash

    }

}

sub proxy_methods_wrapped {

    return qw{

        validate
        validates
        validate_document
        document_validates
        validate_method
        method_validates
        validate_profile
        profile_validates

    }

}


sub queue {

    my $self = shift;

    push @{$self->queued}, @_;

    return $self;

}

sub register_attribute {

    my ($self, $attribute, $default) = @_;

    my $settings;

    no strict 'refs';
    no warnings 'redefine';

    confess "Error creating accessor '$attribute', name has invalid characters"
        unless $attribute =~ /^[a-zA-Z_]\w*$/;

    confess "Error creating accessor, default must be a coderef or constant"
        if ref $default && ref $default ne 'CODE';

    $default = ($settings = $default)->{default} if isa_hashref($default);

    my $check;
    my $code;

    if ($settings) {
        if (defined $settings->{isa}) {
            $settings->{isa} = 'rw'
                unless defined $settings->{isa} and $settings->{isa} eq 'ro'
            ;
        }
    }

    if (defined $default) {

        $code = sub {

            if (@_ == 1) {
                return $_[0]->{$attribute} if exists $_[0]->{$attribute};
                return $_[0]->{$attribute} = ref $default eq 'CODE' ?
                    $default->($_[0]) : $default;
            }
            $_[0]->{$attribute} = $_[1]; $_[0];

        };

    }

    else {

        $code = sub {

            return $_[0]->{$attribute} if @_ == 1;
            $_[0]->{$attribute} = $_[1]; $_[0];

        };

    }

    $self->set_method($attribute, $code);
    $self->configuration->attributes->add($attribute, $code);

    return $self;

}

sub register_builder {

    my ($self, $code) = @_;

    $self->configuration->builders->add($code);

    return $self;

}

sub register_directive {

    my ($self, $name, $code) = @_;

    my $directive = Validation::Class::Directive->new(
        name      => $name,
        validator => $code
    );

    $self->configuration->directives->add($name, $directive);

    return $self;

}

sub register_document {

    my ($self, $name, $data) = @_;

    $self->configuration->documents->add($name, $data);

    return $self;

}

sub register_ensure {

    my ($self, $name, $data) = @_;

    my $package = $self->{package};
    my $code    = $package->can($name);

    confess
        "Error creating pre/post condition(s) ".
        "around method $name on $package: method does not exist"
            unless $code
    ;

    $data->{using}     = $code;
    $data->{overwrite} = 1;

    $self->register_method($name, $data);

    return $self;

}

sub register_field {

    my ($self, $name, $data) = @_;

    my $package = $self->package;
    my $merge   = 0;

    $merge   = 2 if $name =~ s/^\+{2}//;
    $merge   = 1 if $name =~ s/^\+{1}//;

    confess "Error creating field $name, name is not properly formatted"
        unless $name =~ /^(?:[a-zA-Z_](?:[\w\.]*\w|\w*)(?:\:\d+)?)$/;

    if ($merge) {
        if ($self->configuration->fields->has($name) && $merge == 2) {
            $self->configuration->fields->get($name)->merge($data);
            return $self;
        }

        if ($self->configuration->fields->has($name) && $merge == 1) {
            $self->configuration->fields->delete($name);
            $self->configuration->fields->add($name, $data);
            return $self;
        }
    }

    confess "Error creating accessor $name on $package: attribute collision"
        if $self->fields->has($name);

    confess "Error creating accessor $name on $package: method collision"
        if $package->can($name);

    $data->{name} = $name;

    $self->configuration->fields->add($name, $data);

    my $method_name = $name;

    $method_name =~ s/\W/_/g;

    my $method_routine = sub {

        my $self = shift @_;

        my $proto  = $self->proto;
        my $field  = $proto->fields->get($name);

        if (@_ == 1) {
            $proto->params->add($name, $_[0]);
            $field->value($_[0]);
        }

        return $proto->params->get($name);

    };

    $self->set_method($method_name, $method_routine);

    return $self;

}

sub register_filter {

    my ($self, $name, $code) = @_;

    $self->configuration->filters->add($name, $code);

    return $self;

}

sub register_message {

    my ($self, $name, $template) = @_;

    $self->messages->add($name, $template);

    return $self;

}

sub register_method {

    my ($self, $name, $data) = @_;

    my $package = $self->package;

    unless ($data->{overwrite}) {

        confess
            "Error creating method $name on $package: ".
            "collides with attribute $name"
                if $self->attributes->has($name)
        ;
        confess
            "Error creating method $name on $package: ".
            "collides with method $name"
                if $package->can($name)
        ;

    }

    my @output_keys = my @input_keys = qw(
        input input_document input_profile input_method
    );

    s/input/output/ for @output_keys;

    confess
        "Error creating method $name, requires " .
        "at-least one pre or post-condition option, e.g., " .
        join ', or ', map { "'$_'" } sort @input_keys, @output_keys
            unless grep { $data->{$_} } @input_keys, @output_keys
    ;

    $data->{using} ||= $package->can("_$name");
    $data->{using} ||= $package->can("_process_$name");

    confess
        "Error creating method $name, requires the " .
        "'using' option and a coderef or subroutine which conforms ".
        "to the naming conventions suggested in the documentation"
            unless "CODE" eq ref $data->{using}
    ;

    $self->configuration->methods->add($name, $data);

    # create method

    no strict 'refs';

    my $method_routine = sub {

        my $self  = shift;
        my @args  = @_;

        my $i_validator;
        my $o_validator;

        my $input_type  = firstval { defined $data->{$_} } @input_keys;
        my $output_type = firstval { defined $data->{$_} } @output_keys;
        my $input  = $input_type  ? $data->{$input_type}  : '';
        my $output = $output_type ? $data->{$output_type} : '';
        my $using  = $data->{'using'};
        my $return = undef;

        if ($input and $input_type eq 'input') {

            if (isa_arrayref($input)) {
                $i_validator = sub {$self->validate(@{$input})};
            }

            elsif ($self->proto->profiles->get($input)) {
                $i_validator = sub {$self->validate_profile($input, @args)};
            }

            elsif ($self->proto->methods->get($input)) {
                $i_validator = sub {$self->validate_method($input, @args)};
            }

            else {
                confess "Method $name has an invalid input specification";
            }

        }

        elsif ($input) {

            my $type           = $input_type;
               $type           =~ s/input_//;

            my $type_list      = "${type}s";
            my $type_validator = "validate_${type}";

            if ($type && $type_list && $self->proto->$type_list->get($input)) {
                $i_validator = sub {$self->$type_validator($input, @args)};
            }

            else {
                confess "Method $name has an invalid input specification";
            }

        }

        if ($output and $output_type eq 'output') {

            if (isa_arrayref($output)) {
                $o_validator = sub {$self->validate(@{$output})};
            }

            elsif ($self->proto->profiles->get($output)) {
                $o_validator = sub {$self->validate_profile($output, @args)};
            }

            elsif ($self->proto->methods->get($output)) {
                $o_validator = sub {$self->validate_method($output, @args)};
            }

            else {
                confess "Method $name has an invalid output specification";
            }

        }

        elsif ($output) {

            my $type           = $output_type;
               $type           =~ s/output_//;

            my $type_list      = "${type}s";
            my $type_validator = "validate_${type}";

            if ($type && $type_list && $self->proto->$type_list->get($output)) {
                $o_validator = sub {$self->$type_validator($output, @args)};
            }

            else {
                confess "Method $name has an invalid output specification";
            }

        }

        if ($using) {

            if (isa_coderef($using)) {

                my $error = "Method $name failed to validate";

                # execute input validation
                if ($input) {
                    unless ($i_validator->(@args)) {
                        confess $error. " input, ". $self->errors_to_string
                            if !$self->ignore_failure;
                        unshift @{$self->errors}, $error
                            if $self->report_failure;
                        return $return;
                    }
                }

                # execute routine
                $return = $using->($self, @args);

                # execute output validation
                if ($output) {
                    confess $error. " output, ". $self->errors_to_string
                        unless $o_validator->(@args);
                }

                # return
                return $return;

            }

            else {

                confess "Error executing $name, invalid coderef specification";

            }

        }

        return $return;

    };

    $self->set_method($name, $method_routine);

    return $self;

};

sub register_mixin {

    my ($self, $name, $data) = @_;

    my $mixins = $self->configuration->mixins;
    my $merge  = 0;

    $merge     = 2 if $name =~ s/^\+{2}//;
    $merge     = 1 if $name =~ s/^\+{1}//;

    $data->{name} = $name;

    if ($mixins->has($name) && $merge == 2) {
        $mixins->get($name)->merge($data);
        return $self;
    }

    if ($mixins->has($name) && $merge == 1) {
        $mixins->delete($name);
        $mixins->add($name, $data);
        return $self;
    }

    $mixins->add($name, $data);

    return $self;

}

sub register_profile {

    my ($self, $name, $code) = @_;

    $self->configuration->profiles->add($name, $code);

    return $self;

}

sub register_settings {

    my ($self, $data) = @_;

    my @keys;

    my $name = $self->package;

    # grab configuration settings, not instance settings

    my $settings = $self->configuration->settings;

    # attach classes
    @keys = qw(class classes);
    if (my $alias = firstval { exists $data->{$_} } @keys) {

        $alias = $data->{$alias};

        my @parents;

        if ($alias eq 1 && !ref $alias) {

            push @parents, $name;

        }

        else {

            push @parents, isa_arrayref($alias) ? @{$alias} : $alias;

        }

        foreach my $parent (@parents) {

            my $relatives = $settings->{relatives}->{$parent} ||= {};

            # load class children and create relationship map (hash)

            foreach my $child (findallmod $parent) {

                my $name  = $child;
                   $name  =~ s/^$parent\:://;

                $relatives->{$name} = $child;

            }

        }

    }

    # attach requirements
    @keys = qw(requires required requirement requirements);
    if (my $alias = firstval { exists $data->{$_} } @keys) {

        $alias = $data->{$alias};

        my @requirements;

        push @requirements, isa_arrayref($alias) ? @{$alias} : $alias;

        foreach my $requirement (@requirements) {

            $settings->{requirements}->{$requirement} = 1;

        }

    }

    # attach roles
    @keys = qw(base role roles bases);
    if (my $alias = firstval { exists $data->{$_} } @keys) {

        $alias = $data->{$alias};

        my @roles;

        if ($alias) {

            push @roles, isa_arrayref($alias) ? @{$alias} : $alias;

        }

        if (@roles) {

            no strict 'refs';

            foreach my $role (@roles) {

                eval { use_module $role };

                # is the role a validation class?

                unless ($self->registry->has($role)) {
                    confess sprintf
                        "Can't apply the role %s to the " .
                        "class %s unless the role uses Validation::Class",
                            $role,
                            $self->package
                    ;
                }

                my $role_proto = $self->registry->get($role);;

                # check requirements

                my $requirements =
                    $role_proto->configuration->settings->{requirements};
                ;

                if (defined $requirements) {

                    my @failures;

                    foreach my $requirement (keys %{$requirements}) {
                        unless ($self->package->can($requirement)) {
                            push @failures, $requirement;
                        }
                    }

                    if (@failures) {
                        confess sprintf
                            "Can't use the class %s as a role for ".
                            "use with the class %s while missing method(s): %s",
                                $role,
                                $self->package,
                                join ', ', @failures
                        ;
                    }

                }

                push @{$settings->{roles}}, $role;

                my @routines =
                    grep { defined &{"$role\::$_"} } keys %{"$role\::"};

                if (@routines) {

                    # copy methods

                    foreach my $routine (@routines) {

                        eval {

                            $self->set_method($routine, $role->can($routine));

                        }   unless $self->package->can($routine);

                    }

                    # merge configurations

                    my $self_profile = $self->configuration->profile;
                    my $role_profile = $role_proto->configuration->profile;

                    # manually merge profiles with list/map containers

                    foreach my $attr ($self_profile->keys) {

                        my $lst = 'Validation::Class::Listing';
                        my $map = 'Validation::Class::Mapping';

                        my $sp_attr = $self_profile->{$attr};
                        my $rp_attr = $role_profile->{$attr};

                        if (ref($rp_attr) and $rp_attr->isa($map)) {
                            $sp_attr->merge($rp_attr->hash);
                        }

                        elsif (ref($rp_attr) and $rp_attr->isa($lst)) {
                            $sp_attr->add($rp_attr->list);
                        }

                        else {

                            # merge via spec-based merging for standard types

                            Hash::Merge::set_behavior('ROLE_PRECEDENT');

                            $sp_attr = merge $sp_attr => $rp_attr;

                            Hash::Merge::set_behavior('LEFT_PRECEDENT');

                        }

                    }

                }

            }

        }

    }

    return $self;

}

sub registry {

    return $_registry;

}


sub reset {

    my  $self = shift;

        $self->queued->clear;

        $self->reset_fields;

        $self->reset_params;

    return $self;

}


sub reset_errors {

    my $self = shift;

    $self->errors->clear;

    foreach my $field ($self->fields->values) {

        $field->errors->clear;

    }

    return $self;

}


sub reset_fields {

    my $self = shift;

    foreach my $field ( $self->fields->values ) {

        # set default, special directives, etc
        $field->{name}  = $field->name;
        $field->{value} = '';

    }

    $self->reset_errors();

    return $self;

}


sub reset_params {

    my $self = shift;

    my $params = $self->build_args(@_);

    $self->params->clear;

    $self->params->add($params);

    return $self;

}


sub set_errors {

    my ($self, @errors) = @_;

    $self->errors->add(@errors) if @errors;

    return $self->errors->count;

}


sub set_fields {

    my $self = shift;

    my $fields = $self->build_args(@_);

    $self->fields->add($fields);

    return $self;

}

sub set_method {

    my ($self, $name, $code) = @_;

    # proto and prototype methods cannot be overridden

    confess "Error creating method $name, method already exists"
        if ($name eq 'proto' || $name eq 'prototype')
        && $self->package->can($name)
    ;

    # place routines on the calling class

    no strict   'refs';
    no warnings 'redefine';

    return *{join('::', $self->package, $name)} = $code;

}


sub set_params {

    my $self = shift;

    $self->params->add(@_);

    return $self;

}


sub set_values {

    my $self = shift;

    my $values = $self->build_args(@_);

    while (my($name, $value) = each(%{$values})) {

        my $param = $self->params->get($name);
        my $field = $self->fields->get($name);

        next if $field->{readonly};

        $value ||= $field->{default};

        $self->params->add($name => $value);

        $field->value($value);

    }

    return $self;

}

sub snapshot {

    my ($self) = @_;

    # reset the stash

    $self->stashed->clear;

    # clone configuration settings and merge into the prototype
    # ... which makes the prototype kind've a snapshot of the configuration

    if (my $config = $self->configuration->configure_profile) {

        my @clonable_configuration_settings = qw(
            attributes
            directives
            documents
            events
            fields
            filters
            methods
            mixins
            profiles
            settings
        );

        foreach my $name (@clonable_configuration_settings) {

            my $settings = $config->$name->hash;

            $self->$name->clear->merge($settings);

        }

        $self->builders->add($config->builders->list);

    }

    return $self;

}


sub stash {

    my $self = shift;

    return $self->stashed->get($_[0]) if @_ == 1 && ! ref $_[0];

    $self->stashed->add($_[0]->hash) if @_ == 1 && isa_mapping($_[0]);
    $self->stashed->add($_[0])       if @_ == 1 && isa_hashref($_[0]);
    $self->stashed->add(@_)          if @_ > 1;

    return $self->stashed;

}

sub throw_error {

    my $error_message = pop;

    $error_message =~ s/\n/ /g;
    $error_message =~ s/\s+/ /g;

    confess $error_message ;

}

sub trigger_event {

    my ($self, $event, $field) = @_;

    return unless $event;
    return unless $field;

    my @order;
    my $directives;
    my $process_all = $event eq 'on_normalize' ? 1 : 0;
    my $event_type  = $event eq 'on_normalize' ? 'normalization' : 'validation';

    $event = $self->events->get($event);
    $field = $self->fields->get($field);

    return unless defined $event;
    return unless defined $field;

    # order events via dependency resolution

    $directives = Validation::Class::Directives->new(
        {map{$_=>$self->directives->get($_)}(sort keys %{$event})}
    );
    @order = ($directives->resolve_dependencies($event_type));
    @order = keys(%{$event}) unless @order;

    # execute events

    foreach my $i (@order) {

        # skip if the field doesn't have the subscribing directive
        unless ($process_all) {
            next unless exists $field->{$i};
        }

        my $routine   = $event->{$i};
        my $directive = $directives->get($i);

        # something else might fudge with the params so we wait
        # until now to collect its value
        my $name  = $field->name;
        my $param = $self->params->has($name) ? $self->params->get($name) : undef;

        # execute the directive routine associated with the event
        $routine->($directive, $self, $field, $param);

    }

    return $self;

}

sub unflatten_params {

    my ($self) = @_;

    return $self->params->unflatten->hash || {};

}


sub has_valid { goto &validate } sub validates { goto &validate } sub validate {

    my ($self, $context, @fields) = @_;

    confess

        "Context object ($self->{package} class instance) required ".
        "to perform validation" unless $self->{package} eq ref $context

    ;

    # normalize/sanitize

    $self->normalize($context);

    # create alias map manually if requested
    # ... extremely-deprecated but it remains for back-compat and nostalgia !!!

    my $alias_map;

    if (isa_hashref($fields[0])) {

        $alias_map = $fields[0]; @fields = (); # blank

        while (my($name, $alias) = each(%{$alias_map})) {

            $self->params->add($alias => $self->params->delete($name));

            push @fields, $alias;

        }

    }

    # include queued fields

    if (@{$self->queued}) {

        push @fields, @{$self->queued};

    }

    # include fields from field patterns

    @fields = map { isa_regexp($_) ? (grep { $_ } ($self->fields->sort)) : ($_) }
    @fields;

    # process toggled fields

    foreach my $field (@fields) {

        my ($switch) = $field =~ /^([+-])./;

        if ($switch) {

            # set field toggle directive

            $field =~ s/^[+-]//;

            if (my $field = $self->fields->get($field)) {

                $field->toggle(1) if $switch eq '+';
                $field->toggle(0) if $switch eq '-';

            }

        }

    }

    # determine what to validate and how

    if (@fields && $self->params->count) {
        # validate all parameters against only the fields explicitly
        # requested to be validated
    }

    elsif (!@fields && $self->params->count) {
        # validate all parameters against all defined fields because no fields
        # were explicitly requested to be validated, e.g. not explicitly
        # defining fields to be validated effectively allows the parameters
        # submitted to dictate what gets validated (may not be dangerous)
        @fields = ($self->params->keys);
    }

    elsif (@fields && !$self->params->count) {
        # validate fields specified although no parameters were submitted
        # will likely pass validation unless fields exist with a *required*
        # directive or other validation logic expecting a value
    }

    else {
        # validate all defined fields although no parameters were submitted
        # will likely pass validation unless fields exist with a *required*
        # directive or other validation logic expecting a value
        @fields = ($self->fields->keys);
    }

    # establish the bypass validation flag
    $self->stash->{'validation.bypass_event'} = 0;

    # stash the current context object
    $self->stash->{'validation.context'} = $context;

    # report fields requested that do not exist and are not aliases
    for my $f (grep {!$self->fields->has($_)} uniq @fields) {
        next if grep {
                if ($_->has('alias')) {
                    my @aliases = isa_arrayref($_->get('alias')) ?
                        @{$_->get('alias')} : ($_->get('alias'))
                    ;
                    grep { $f eq $_ } @aliases;
                }
            }
            $self->fields->values
        ;
        $self->pitch_error("Data validation field $f does not exist");
    }

    # stash fields targeted for validation
    $self->stash->{'validation.fields'} =
        [grep {$self->fields->has($_)} uniq @fields]
    ;

    # execute on_before_validation events
    $self->trigger_event('on_before_validation', $_)
        for @{$self->stash->{'validation.fields'}}
    ;

    # execute on_validate events
    unless ($self->stash->{'validation.bypass_event'}) {
        $self->trigger_event('on_validate', $_)
            for @{$self->stash->{'validation.fields'}}
        ;
        $self->validated(1);
        $self->validated(2) if $self->is_valid;
    }

    # execute on_after_validation events
    $self->trigger_event('on_after_validation', $_)
        for @{$self->stash->{'validation.fields'}}
    ;

    # re-establish the bypass validation flag
    $self->stash->{'validation.bypass_event'} = 0;

    # restore params from alias map manually if requested
    # ... extremely-deprecated but it remains for back-compat and nostalgia !!!

    if ( defined $alias_map ) {

        while (my($name, $alias) = each(%{$alias_map})) {

            $self->params->add($name => $self->params->delete($alias));

        }

    }

    return $self->validated == 2 ? 1 : 0;

}


sub document_validates { goto &validate_document } sub validate_document {

    my ($self, $context, $ref, $data, $options) = @_;

    my $name;

    my $documents = clone $self->documents->hash;

    my $_fmap     = {}; # ad-hoc fields

    if ("HASH" eq ref $ref) {

        $ref  = clone $ref;

        $name = "DOC" . time() . ($self->documents->count + 1);

        # build document on-the-fly from a hashref
        foreach my $rules (values %{$ref}) {

            next unless "HASH" eq ref $rules;

            my  $id = uc "$rules";
                $id =~ s/\W/_/g;
                $id =~ s/_$//;

            $self->fields->add($id => $rules);
            $rules = $id;
            $_fmap->{$id} = 1;

        }

        $documents->{$name} = $ref;

    }

    else {

        $name = $ref;

    }

    my $fields = { map { $_ => 1 } ($self->fields->keys) };

    confess "Please supply a registered document name to validate against"
        unless $name
    ;

    confess "The ($name) document is not registered and cannot be validated against"
        unless $name && exists $documents->{$name}
    ;

    my $document = $documents->{$name};

    confess "The ($name) document does not contain any mappings and cannot ".
          "be validated against" unless keys %{$documents}
    ;

    $options ||= {};

    # handle sub-document references

    for my $key (keys %{$document}) {

        $document->{$key} = $documents->{$document->{$key}} if
            $document->{$key} && exists $documents->{$document->{$key}} &&
            ! $self->fields->has($document->{$key})
        ;

    }

    $document = flatten $document;

    my $signature = clone $document;

    # create document signature

    for my $key (keys %{$signature}) {

        (my $new = $key) =~ s/\\//g;

        $new =~ s/\*/???/g;
        $new =~ s/\.@/:0/g;

        $signature->{$new} = '???';

        delete $signature->{$key} unless $new eq $key;

    }

    my $overlay = clone $signature;

    $_ = undef for values %{$overlay};

    # handle regex expansions

    for my $key (keys %{$document}) {

        my  $value = delete $document->{$key};

        my  $token;
        my  $regex;

            $token  = '\.\@';
            $regex  = ':\d+';
            $key    =~ s/$token/$regex/g;

            $token  = '\*';
            $regex  = '[^\.]+';
            $key    =~ s/$token/$regex/g;

        $document->{$key} = $value;

    }

    my $_dmap = {};
    my $_pmap = {};
    my $_xmap = {};

    my $_zata = flatten $data;
    my $_data = merge $overlay, $_zata;

    # remove overlaid patterns if matching nodes exist

    for my $key (keys %{$_data}) {

        if ($key =~ /\?{3}/) {

            (my $regex = $key) =~ s/\?{3}/\\w+/g;

            delete $_data->{$key}
                if grep { $_ =~ /$regex/ && $_ ne $key } keys %{$_data};

        }

    }

    # generate validation rules

    for my $key (keys %{$_data}) {

        my  $point = $key;
            $point =~ s/\W/_/g;
        my  $label = $key;
            $label =~ s/\:/./g;

        my  $match = 0;

        my  $switch;

        for my $regex (keys %{$document}) {

            if (exists $_data->{$key}) {

                my  $field  = $document->{$regex};

                if ($key =~ /^$regex$/) {

                    $switch = $1 if $field =~ s/^([+-])//;

                    my $config = {label => $label};

                    $config->{mixin} = $self->fields->get($field)->mixin
                        if $self->fields->get($field)->can('mixin')
                    ;

                    $self->clone_field($field, $point => $config);

                    $self->apply_mixin($point => $config->{mixin})
                        if $config->{mixin}
                    ;

                    $_dmap->{$key}   = 1;
                    $_pmap->{$point} = $key;

                    $match = 1;

                }

            }

        }

        $_xmap->{$point} = $key;

        # register node as a parameter
        $self->params->add($point => $_data->{$key}) unless ! $match;

        # queue node and requirement
        $self->queue($switch ? "$switch$point" : "$point") unless ! $match;

        # prune unnecessary nodes
        delete $_data->{$key} if $options->{prune} && ! $match;

    }

    # validate

    $self->validate($context);

    $self->clear_queue;

    my @errors = $self->get_errors;

    for (sort @errors) {

        my ($message) = $_ =~ /field (\w+) does not exist/;

        next unless $message;

        $message = $_xmap->{$message};

        next unless $message;

        $message  =~ s/\W/./g;

        # re-format unknown parameter errors
        $_ = "The parameter $message was not expected and could not be validated";

    }

    $_dmap = unflatten $_dmap;

    while (my($point, $key) = each(%{$_pmap})) {

        $_data->{$key} = $self->params->get($point); # prepare data

        $self->fields->delete($point) unless $fields->{$point}; # reap clones

    }

    $self->fields->delete($_) for keys %{$_fmap}; # reap ad-hoc fields

    $self->reset_fields;

    $self->set_errors(@errors) if @errors; # report errors

    $_[3] = unflatten $_data if defined $_[2]; # restore data

    return $self->is_valid;

}


sub method_validates { goto &validate_method } sub validate_method {

    my  ($self, $context, $name, @args) = @_;

    confess
        "Context object ($self->{package} class instance) required ".
        "to perform method validation" unless $self->{package} eq ref $context;

    return 0 unless $name;

    $self->normalize($context);
    $self->apply_filters('pre');

    my $method_spec = $self->methods->{$name};
    my $input       = $method_spec->{input};

    if ($input) {

        my $code   = $method_spec->{using};
        my $output = $method_spec->{output};

        weaken $method_spec->{$_} for ('using', 'output');

        $method_spec->{using}  = sub { 1 };
        $method_spec->{output} = undef;

        $context->$name(@args);

        $method_spec->{using}  = $code;
        $method_spec->{output} = $output;

    }

    return $self->is_valid ? 1 : 0;

}


sub profile_validates { goto &validate_profile } sub validate_profile {

    my  ($self, $context, $name, @args) = @_;

    confess
        "Context object ($self->{package} class instance) required ".
        "to perform profile validation" unless $self->{package} eq ref $context
    ;

    return 0 unless $name;

    $self->normalize($context);
    $self->apply_filters('pre');

    if (isa_coderef($self->profiles->{$name})) {

        return $self->profiles->{$name}->($context, @args);

    }

    return 0;

}

1;

__END__

=pod

=head1 NAME

Validation::Class::Prototype - Data Validation Engine for Validation::Class Classes

=head1 VERSION

version 7.900057

=head1 DESCRIPTION

Validation::Class::Prototype is the validation engine used by proxy via
L<Validation::Class> whose methods are aliases to the methods defined here.
Please see L<Validation::Class::Simple> for a quick introduction on how to get
started.

=head1 ATTRIBUTES

=head2 attributes

The attributes attribute provides access to simple attributes registered on the
the calling class. This attribute is a L<Validation::Class::Mapping> object
containing hashref objects and CANNOT be overridden.

=head2 builders

The builders attribute provides access to coderefs registered to hook into the
instantiation process of the calling class. This attribute is a
L<Validation::Class::Listing> object containing coderef objects and CANNOT be
overridden.

=head2 configuration

The configuration attribute provides the default configuration profile.
This attribute is a L<Validation::Class::Configuration> object and CANNOT be
overridden.

=head2 directives

The directives attribute provides access to defined directive objects.
This attribute is a L<Validation::Class::Mapping> object containing
hashrefs and CANNOT be overridden.

=head2 documents

The documents attribute provides access to defined document models.
This attribute is a L<Validation::Class::Mapping> object and CANNOT be
overridden.

=head2 errors

The errors attribute provides access to class-level error messages.
This attribute is a L<Validation::Class::Errors> object, may contain
error messages and CANNOT be overridden.

=head2 events

The events attribute provides access to validation events and the directives
that subscribe to them. This attribute is a L<Validation::Class::Mapping> object
and CANNOT be overridden.

=head2 fields

The fields attribute provides access to defined fields objects.
This attribute is a L<Validation::Class::Fields> object containing
L<Validation::Class::Field> objects and CANNOT be overridden.

=head2 filtering

The filtering attribute (by default set to 'pre') controls when incoming data
is filtered. Setting this attribute to 'post' will defer filtering until after
validation occurs which allows any errors messages to report errors based on the
unaltered data. Alternatively, setting the filtering attribute to 'off' will
bypass all filtering unless explicitly defined at the field-level.

=head2 filters

The filters attribute provides access to defined filters objects.
This attribute is a L<Validation::Class::Mapping> object containing
code references and CANNOT be overridden.

=head2 ignore_failure

The ignore_failure boolean determines whether your application will live or die
upon failing to validate a self-validating method defined using the method
keyword. This is on (1) by default, method validation failures will set errors
and can be determined by checking the error stack using one of the error message
methods. If turned off, the application will die and confess on failure.

=head2 ignore_intervention

The ignore_intervention boolean determines whether validation will short-circuit
if required fields are not present. This is off (0) by default; The logic behind
this decision is that, for example, in the case of a required field, if the
field was not submitted but was required, there is no need to perform additional
validation. This is a type-of short-circuiting which reduces validation
overhead. If you would like to emit all applicable validation errors you can
enable this option.

=head2 ignore_unknown

The ignore_unknown boolean determines whether your application will live or
die upon encountering unregistered field directives during validation. This is
off (0) by default, attempts to validate unknown fields WILL cause the program
to die.

=head2 messages

The messages attribute provides access to class-level error message overrides.
This attribute is a L<Validation::Class::Mapping> object containing scalar values.

=head2 methods

The methods attribute provides access to self-validating code references.
This attribute is a L<Validation::Class::Mapping> object containing
code references.

=head2 mixins

The mixins attribute provides access to field templates. This attribute is
a L<Validation::Class::Mapping> object and CANNOT be overridden.

The package attribute contains the namespace of the instance object currently
using this module.

=head2 params

The params attribute provides access to input parameters.
This attribute is a L<Validation::Class::Mapping> object and CANNOT be
overridden.

=head2 profiles

The profiles attribute provides access to validation profile.
This attribute is a L<Validation::Class::Mapping> object containing
hash references and CANNOT be overridden.

=head2 queued

The queued attribute returns an arrayref of field names for validation and
CANNOT be overridden. It represents a list of field names stored to be used in
validation later. If the queued attribute contains a list, you can omit
arguments to the validate method.

=head2 report_failure

The report_failure boolean determines whether your application will report
self-validating method failures as class-level errors. This is off (0) by default,
if turned on, an error messages will be generated and set at the class-level
specifying the method which failed in addition to the existing messages.

=head2 report_unknown

The report_unknown boolean determines whether your application will report
unregistered fields as class-level errors upon encountering unregistered field
directives during validation. This is off (0) by default, attempts to validate
unknown fields will NOT be registered as class-level variables.

=head2 settings

The settings attribute provides access to settings specific to the associated
class, not to be confused with settings which exist in the prototype's
configuration. This attribute is a L<Validation::Class::Mapping> object and
CANNOT be overridden.

=head2 validated

The validated attribute simply denotes whether the validation routine has been
executed since the last normalization process (which occurs at instantiation
and before validation). It's values will either be 0 (not validated),
1 (validated with errors), or 2 (validated without errors). You can simply check
this attribute for truth when you need to know if validation has occurred.

=head1 METHODS

=head2 apply_filters

The apply_filters method can be used to run the currently defined parameters
through the filters defined in their matching fields.

    $self = $self->apply_filters;

    # apply filters to fields where filtering is set to 'post' filtering
    $self = $self->apply_filters('post');

=head2 class

This method instantiated and returns the validation class specified , existing
parameters and configuration options are passed to the constructor of the
validation class (including the stash object). You can prevent/override
arguments from being copied to the new class object by supplying the them as
arguments to this method.

The class method is also quite handy in that it will detect parameters that are
prefixed with the name of the class being fetched, and automatically create
aliases on the matching rules (if any) to allow validation to occur seamlessly.

    package Class;

    use Validation::Class;

    load classes => 1; # load child classes e.g. Class::*

    package main;

    my $input = Class->new(params => $params);

    my $child1  = $input->class('Child');      # loads Class::Child;
    my $child2  = $input->class('StepChild');  # loads Class::StepChild;

    my $child3  = $input->class('child');      # loads Class::Child;
    my $child4  = $input->class('step_child'); # loads Class::StepChild;

    # intelligently detecting and mapping parameters to child class

    my $params = {

        'my.name'    => 'Guy Friday',
        'child.name' => 'Guy Friday Jr.'

    };

    $input->class('child'); # child field *name* mapped to param *child.name*

    # without copying params from class

    my $child = $input->class('child', params => {});

    1;

=head2 clear_queue

The clear_queue method resets the queue container, see the queue method for more
information on queuing fields to be validated. The clear_queue method has yet
another useful behavior in that it can assign the values of the queued
parameters to the list it is passed, where the values are assigned in the same
order queued.

    my $self = Class->new(params => $params);

    $self->queue(qw(name +email));

    # ... additional logic

    $self->queue(qw(+login +password));

    if ($self->validate) {

        $self->clear_queue(my($name, $email));

        print "Name is $name and email is $email";

    }

=head2 clone_field

The clone_field method is used to create new fields (rules) from existing fields
on-the-fly. This is useful when you have a variable number of parameters being
validated that can share existing validation rules. Please note that cloning a
field does not include copying and/or processing of any mixins on the original
field to the cloned field, if desired, this must be done manually.

    package Class;

    use Validation::Class;

    field 'phone' => {
        label => 'Your Phone',
        required => 1
    };

    package main;

    my $self = Class->new(params => $params);

    # clone phone rule at run-time to validate dynamically created parameters
    $self->clone_field('phone', 'phone2', { label => 'Phone A', required => 0 });
    $self->clone_field('phone', 'phone3', { label => 'Phone B', required => 0 });
    $self->clone_field('phone', 'phone4', { label => 'Phone C', required => 0 });

    $self->validate(qw/phone phone2 phone3 phone4/);

    1;

=head2 does

The does method is used to determine whether the current prototype is composed
using the role specified. Return true if so, false if not.

    package Class;

    use Validation::Class;

    set role => 'Class::Root';

    package main;

    my $self = Class->new(params => $params);

    return 1 if $self->proto->does('Class::Root');

=head2 error_count

The error_count method returns the total number of errors set at both the class
and field level.

    my $count = $self->error_count;

=head2 error_fields

The error_fields method returns a hashref containing the names of fields which
failed validation and an arrayref of error messages.

    unless ($self->validate) {

        my $failed = $self->error_fields;

    }

    my $suspects = $self->error_fields('field2', 'field3');

=head2 errors_to_string

The errors_to_string method stringifies the all error objects on both the class
and fields using the specified delimiter (defaulting to comma-space (", ")).

    return $self->errors_to_string("\n");
    return $self->errors_to_string(undef, sub{ ucfirst lc shift });

    unless ($self->validate) {

        return $self->errors_to_string;

    }

=head2 get_errors

The get_errors method returns a list of combined class-and-field-level errors.

    # returns all errors
    my @errors = $self->get_errors;

    # filter errors by fields whose name starts with critical
    my @critical = $self->get_errors(qr/^critical/i);

    # return errors for field_a and field_b specifically
    my @specific_field_errors = $self->get_errors('field_a', 'field_b');

=head2 get_fields

The get_fields method returns the list of L<Validation::Class::Field> objects
for specific fields and returns an empty list if no arguments are passed. If a
field does not match the name specified it will return undefined.

    my ($a, $b) = $self->get_fields('field_a', 'field_b');

=head2 get_hash

The get_hash method returns a hashref consisting of all fields with their
absolute values (i.e. default value or matching parameter value). If a
field does not have an absolute value its value will be undefined.

    my $hash = $self->get_hash;

=head2 get_params

The get_params method returns the values of the parameters specified (as a list,
in the order specified). This method will return a list of key/value pairs if
no parameter names are passed.

    if ($self->validate) {

        my ($name) = $self->get_params('name');

        my ($name, $email, $login, $password) =
            $self->get_params(qw/name email login password/);

        # you should note that if the params don't exist they will return
        # undef meaning you should check that it is defined before doing any
        # comparison checking as doing so would generate an error, e.g.

        if (defined $name) {

            if ($name eq '') {
                print 'name parameter was passed but was empty';
            }

        }

        else {
            print 'name parameter was never submitted';
        }

    }

    # alternatively ...

    my $params = $self->get_params; # return hashref of parameters

    print $params->{name};

=head2 get_values

The get_values method returns the absolute value for a given field. This method
executes specific logic which returns the value a field has based on a set of
internal conditions. This method always returns a list, field names that do not
exist are returned as undefined.

    my ($value) = $self->get_values('field_name');

    # equivalent to

    my $param = $self->params->get('field_name');
    my $field = $self->fields->get('field_name');
    my $value;

    if ($field->{readonly}) {
        $value = $field->{default} || undef;
    }
    else {
        $value = $field->{value} || $param;
    }

=head2 is_valid

The is_valid method returns a boolean value which is true if the last validation
attempt was successful, and false if it was not (which is determined by looking
for errors at the class and field levels).

    return "OK" if $self->is_valid;

=head2 normalize

The normalize method executes a set of routines that conditions the environment
filtering any parameters present whose matching field has its filtering
directive set to 'pre'. This method is executed automatically at instantiation
and again just before each validation event.

    $self->normalize;

=head2 param

The param method gets/sets a single parameter by name. This method returns the
value assigned or undefined if the parameter does not exist.

    my $value = $self->param('name');

    $self->param($name => $value);

=head2 plugin

The plugin method returns an instantiated plugin object which is passed the
current prototype object. Note: This functionality is somewhat experimental.

    package Class;

    use Validation::Class;

    package main;

    my $input = Class->new(params => $params);

    my $formatter = $input->plugin('telephone_format');
    # ... returns a Validation::Class::Plugin::TelephoneFormat object

=head2 queue

The queue method is a convenience method used specifically to append the
queued attribute allowing you to *queue* fields to be validated. This method
also allows you to set fields that must always be validated.

    $self->queue(qw/name login/);
    $self->queue(qw/email email2/) if $input->param('change_email');
    $self->queue(qw/login login2/) if $input->param('change_login');

=head2 reset

The reset method clears all errors, fields and queued field names, both at the
class and individual field levels.

    $self->reset();

=head2 reset_errors

The reset_errors method clears all errors, both at the class and individual
field levels. This method is called automatically every time the validate()
method is triggered.

    $self->reset_errors();

=head2 reset_fields

The reset_fields method set special default directives and clears all errors and
field values, both at the class and individual field levels. This method is
executed automatically at instantiation.

    $self->reset_fields();

=head2 reset_params

The reset_params method is responsible for completely removing any existing
parameters and adding those specified. This method returns the class object.
This method takes a list of key/value pairs or a single hashref.

    $self->reset_params($new_params);

=head2 set_errors

The set_errors method pushes its arguments (error messages) onto the class-level
error stack and returns a count of class-level errors.

    my $count = $self->set_errors('...', '...');

=head2 set_fields

The set_fields method is responsible setting/overriding registered fields.
This method returns the class object. This method takes a list of key/value
pairs or a single hashref whose key should be a valid field name and whose
value should be a hashref that is a valid field configuration object.

    $self->set_fields($name => $config); # accepts hashref also

=head2 set_params

The set_params method is responsible for setting/replacing parameters. This
method returns the class object. This method takes a list of key/value pairs or
a single hashref whose keys should match field names and whose value should
be a scalar or arrayref of scalars.

    $self->set_params($name => $value); # accepts a hashref also

=head2 set_value

The set_value method assigns a value to the specified field's parameter
unless the field is readonly. This method returns the class object.

    $self->set_values($name => $value);

=head2 stash

The stash method provides a container for context/instance specific information.
The stash is particularly useful when custom validation routines require insight
into context/instance specific operations.

    package MyApp::Person;

    use Validation::Class;

    field 'email' => {

        validation => sub {

            my ($self) = @_;

            my $db = $self->stash('database');

            return 0 unless $db;
            return $db->find(...) ? 0 : 1 ; # email exists

        }

    };

    package main;

    #  store the database object for use in email validation
    $self->stash(database => $database_object);

=head2 validate

The validate method (or has_valid, or validates) returns true/false depending on
whether all specified fields passed validation checks. Please consider, if this
method is called without any parameters, the list of fields to be validated
will be assumed/deduced, making the execution strategy conditional, which may
not be what you want.

    use MyApp::Person;

    my $input = MyApp::Person->new(params => $params);

    # validate specific fields
    unless ($input->validate('login','password')){
        return $input->errors_to_string;
    }

    # validate fields based on a regex pattern
    unless ($input->validate(qr/^setting(\d+)?/)){
        return $input->errors_to_string;
    }

    # validate existing parameters
    # however, if no parameters exist, ...
    # validate all fields, which will return true unless a field exists
    # with a required directive
    unless ($input->validate){
        return $input->errors_to_string;
    }

    # validate all fields period, obviously
    unless ($input->validate($input->fields->keys)){
        return $input->errors_to_string;
    }

    # implicitly validate parameters which don't explicitly match a field
    my $parameter_map = {
        user => 'login',
        pass => 'password'
    };
    unless ($input->validate($parameter_map)){
        return $input->errors_to_string;
    }

Another cool trick the validate() method can perform is the ability to
temporarily alter whether a field is required or not during validation. This
functionality is often referred to as the *toggle* function.

This method is important when you define a field as required or non and want to
change that per validation. This is done by calling the validate() method with
a list of fields to be validated and prefixing the target fields with a plus or
minus respectively as follows:

    use MyApp::Person;

    my $input = MyApp::Person->new(params => $params);

    # validate specific fields, force name, email and phone to be required
    # regardless of the field directives ... and force the age, sex
    # and birthday to be optional

    my @spec = qw(+name +email +phone -age -sex -birthday);

    unless ($input->validate(@spec)){
        return $input->errors_to_string;
    }

=head2 validate_document

The validate_document method (or document_validates) is used to validate the
specified hierarchical data against the specified document declaration. This is
extremely valuable for validating serialized messages passed between machines.
This method requires two arguments, the name of the document declaration to be
used, and the data to be validated which should be submitted in the form of a
hashref. The following is an example of this technique:

    my $boolean = $self->validate_document(foobar => $data);

Additionally, you may submit options in the form of a hashref to further control
the validation process. The following is an example of this technique:

    # the prune option removes non-matching parameters (nodes)
    my $boolean = $self->validate_document(foobar => $data, { prune => 1 });

Additionally, to support the validation of ad-hoc specifications, you may pass
this method two hashrefs, the first being the document notation schema, and the
second being the hierarchical data you wish to validate.

=head2 validate_method

The validate_method method (or method_validates) is used to determine whether a
self-validating method will be successful. It does so by validating the methods
input specification. This is useful in circumstances where it is advantageous to
know in-advance whether a self-validating method will pass or fail. It
effectively allows you to use the methods input specification as a
validation profile.

    if ($self->validate_method('password_change')) {

        # password_change will pass validation

        if ($self->password_change) {
            # password_change executed
        }

    }

=head2 validate_profile

The validate_profile method (or profile_validates) executes a stored validation
profile, it requires a profile name and can be passed additional parameters
which get forwarded into the profile routine in the order received.

    unless ($self->validate_profile('password_change')) {

        print $self->errors_to_string;

    }

    unless ($self->validate_profile('email_change', $dbi_handle)) {

        print $self->errors_to_string;

    }

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
