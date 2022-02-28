package Valiant::Validates;

use Moo::Role;
use Module::Runtime 'use_module';
use String::CamelCase 'camelize';
use Scalar::Util 'blessed';
use Valiant::Util 'throw_exception', 'debug';
use namespace::autoclean -also => ['throw_exception', 'debug'];
use Valiant::Validations ();

with 'Valiant::Translation';

has _instance_validations => (is=>'rw', init_arg=>undef);

sub push_to_i18n_lookup {
  my ($class_or_self, @args) = @_;
  my $class = ref($class_or_self) ? ref($class_or_self) : $class_or_self;
  @args = $class unless @args;
  Valiant::Validations::_add_metadata($class, 'i18n', @args);
}

sub i18n_lookup { 
  my ($class_or_self, $arg) = @_;
  my $class = ref($class_or_self) ? ref($class_or_self) : $class_or_self;
  no strict "refs";
  my @proposed = @{"${class}::ISA"};
  push @proposed, $class_or_self->i18n_metadata if $class_or_self->can('i18n_metadata');
  return grep { $_->can('model_name') } ($class, @proposed);
}

sub validations {
  my ($class_or_self, $arg) = @_;
  my $class = ref($class_or_self) ? ref($class_or_self) : $class_or_self;

  my @existing = ();
  if(defined($arg)) {
    if(ref($class_or_self)) { # its $self
      my @existing = @{ $class_or_self->_instance_validations||[] };
      $class_or_self->_instance_validations([$arg, @existing]);
    } else {
      Valiant::Validations::_add_metadata($class_or_self, 'validations', $arg);
    }
  }
  @existing = @{ $class_or_self->_instance_validations||[] } if ref $class_or_self;
  my @validations = $class_or_self->validations_metadata if $class_or_self->can('validations_metadata');
  return @validations, @existing;
}

sub errors_class { 'Valiant::Errors' }

has 'errors' => (
  is => 'ro',
  init_arg => undef,
  lazy => 1,
  default => sub {
    return use_module($_[0]->errors_class)
      ->new(object=>$_[0], i18n=>$_[0]->i18n);
  },
);

sub has_errors {
  return shift->errors->size ? 1:0; 
}

sub no_errors {
  return !shift->has_errors;
}

has 'validated' => (is=>'rw', required=>1, init_args=>undef, default=>0);
has 'skip_validation' =>  (is=>'rw', required=>1, init_args=>undef, default=>0);
has '_context' => (is=>'rw', required=>0, predicate=>'has_context');

sub get_context { shift->_context }

sub context {
  my ($self, $args) = @_;
  $args = ref($args) ? $args : [$args];
  $self->_context($args);
  return $self;
}

sub skip_validate {
  my ($self) = @_;
  $self->skip_validation(1);
  return $self;
}
sub do_validate {
  my ($self) = @_;
  $self->skip_validation(0);
  return $self;
}

sub default_validator_namepart { 'Validator' }
sub default_collection_class { 'Valiant::Validator::Collection' }

sub read_attribute_for_validation {
  my ($self, $attribute) = @_;
  return unless defined $attribute;
  return my $value = $self->$attribute
    if $self->can($attribute);
}

sub _validates_coderef {
  my ($self, $coderef, %options) = @_;
  $self->validations([$coderef, \%options]);
  return $self;
}

sub _is_reserved_option_key {
  my ($key) = @_;
  return 1 if $key eq 'if' || $key eq 'unless' || $key eq 'on'
    || $key eq 'strict' || $key eq 'allow_blank' || $key eq 'allow_undef'
    || $key eq 'message' || $key eq 'list';
  return 0;
}

sub _prepare_validator_packages {
  my ($class, $key) = @_;
  my $camel = camelize($key);
  my @packages = $class->_normalize_validator_package($camel);

  return @packages if $camel =~/^\+/;

  push @packages, map {
    "${_}::${camel}";
  } $class->default_validator_namespaces;

  return @packages;
}

sub default_validator_namespaces {
  my ($self) = @_;
  return ('Valiant::ValidatorX', 'Valiant::Validator');
}

sub _validator_package {
  my ($self, $key) = @_;
  my @validator_packages = $self->_prepare_validator_packages($key);
  my ($validator_package, @rest) = grep {
    my $package_to_test = $_;
    eval { use_module $package_to_test } || do {
      # This regexp matches too much... We need to add the package
      # path here just the path delim will vary from platform to platform
      my $notional_filename = Module::Runtime::module_notional_filename($package_to_test);
      if($@=~m/^Can't locate $notional_filename/) {
        debug 1, "Can't find '$package_to_test' in \@INC";
        0;
      } else {
        throw_exception UnexpectedUseModuleError => (package => $package_to_test, err => $@);
      }
    }
  }  @validator_packages;
  throw_exception('NameNotValidator', name => $key, packages => \@validator_packages)
    unless $validator_package;
  debug 1, "Found $validator_package in \@INC";
  return $validator_package;
}

sub _create_validator {
  my ($self, $validator_package, $args) = @_;
  debug 1, "Trying to create validator from $validator_package";
  my $validator = $validator_package->new($args);
  return $validator;
}

sub validates {
  my ($self, @validation_proto) = @_;

  # handle a list of attributes with validations
  my $attributes = shift @validation_proto;
  $attributes = [$attributes] unless ref $attributes;
  my @options = @validation_proto;

  # We want to preserve the order of validators while stripping out global_options
  my (@validator_info, %global_options) = ();
  while(@options) {
    my $args;
    my $key = shift(@options);
    if(blessed($key) && $key->can('check')) { # This bit allows for Type::Tiny instead of a validator => \%params setup
      $args = { constraint => $key };
      $key = 'check';
      if((ref($options[0])||'') eq 'HASH') {
        my $base_args = shift(@options);
        $args = +{ %$args, %$base_args };
      }
    } elsif((ref($key)||'') eq 'CODE') { # This bit allows for callbacks instead of a validator => \%params setup
      $args = { cb => $key };
      $key = 'with';
      if((ref($options[0])||'') eq 'HASH') {
        my $base_args = shift(@options);
        $args = +{ %$args, %$base_args };
      }
    } else { # Otherwise its a normal validator with params
      $args = shift(@options);
    }

    if(_is_reserved_option_key($key)) {
      $global_options{$key} = $args;
    } else {
      push @validator_info, [$key, $args];
    }
  }

  my @validators = ();
  foreach my $info(@validator_info) {
    my ($package_part, $args) = @$info;
    my $validator_package = $self->_validator_package($package_part);

    unless((ref($args)||'') eq 'HASH') {
      $args = $validator_package->normalize_shortcut($args);
      throw_exception InvalidValidatorArgs => ( args => $args) unless ref($args) eq 'HASH';
    }

    # so strip out the reserved and if any wrap in a conditional that
    # way we can remove all that stuff from each

    # merge global options into args
    $args->{strict} = 1 if $global_options{strict} and !exists $args->{strict};
    $args->{allow_undef} = 1 if $global_options{allow_undef} and !exists $args->{allow_undef};
    $args->{allow_blank} = 1 if $global_options{allow_blank} and !exists $args->{allow_blank};
    $args->{message} = $global_options{message} if exists $global_options{message} and !exists $args->{message};

    foreach my $opt(qw(if unless on)) {
      next unless my $val = $global_options{$opt};
      my @val = (ref($val)||'') eq 'ARRAY' ? @$val : ($val);
      if(exists $args->{$opt}) {
        my $current = $args->{$opt};
        my @current = (ref($current)||'') eq 'ARRAY' ? @$current : ($current);
        @val = (@current, @val);
      }
      $args->{$opt} = \@val;
    }
    
    $args->{attributes} = $attributes;
    $args->{model_class} = $self;

    my $new_validator = $self->_create_validator($validator_package, $args);
    push @validators, $new_validator;
  }
  my $coderef = sub { $_->validate(@_) foreach @validators };
  $self->_validates_coderef($coderef, %global_options); 
}

sub _normalize_validator_package {
  my ($self, $with) = @_;
  my ($prefix, $package) = ($with =~m/^(\+?)(.+)$/);
  return $package if $prefix eq '+';

  my $class =  ref($self) || $self;
  my @parts = ((split '::', $class), $package);
  my @project_inc = ();
  while(@parts) {
    push @project_inc, join '::', (@parts, $class->default_validator_namepart, $package);
    pop @parts;
  }
  push @project_inc, join '::', $class->default_validator_namepart, $package; # Not sure we should allow (add flag?)
  return @project_inc;
}

sub _strip_reserved_options {
  my (%options) = @_;
  my %reserved = ();
  foreach my $key (keys %options) {
    if(_is_reserved_option_key($key)) {
      $reserved{$key} = delete $options{$key};
    }
  }
  return %reserved;
}

sub validates_with {
  my ($self, $validators_proto, %options) = @_;
  my %reserved = _strip_reserved_options(%options);
  my @with = ref($validators_proto) eq 'ARRAY' ? 
    @{$validators_proto} : ($validators_proto);

  my @validators = ();
  VALIDATOR_WITHS: foreach my $with (@with) {
    if( (ref($with)||'') eq 'CODE') {
      push @validators, [$with, \%options];
      next VALIDATOR_WITHS;
    }
    debug 1, "Trying to find a validator for '$with'";
    my @possible_packages = $self->_normalize_validator_package($with);
    foreach my $package(@possible_packages) {
      my $found_package = eval {
        use_module($package);
      } || do {
        my $notional_filename = Module::Runtime::module_notional_filename($package);
        if($@=~m/^Can't locate $notional_filename/) {
          debug 1, "Can't find '$package' in \@INC";
          0;
        } else {
          # Probably a syntax error in the code of $package
          throw_exception UnexpectedUseModuleError => (package => $package, err => $@);
        }
      };
      if($found_package) {
        debug 1, "Found '$found_package' in \@INC";
        push @validators, $package->new(%options);
        next VALIDATOR_WITHS; # Only load the first one found
      }
    }
    throw_exception General => (msg => "Failed to find validator for '$with' in \@INC");
  }
  my $collection = use_module($self->default_collection_class)
    ->new(validators=>\@validators, %reserved);
  $self->_validates_coderef(sub { $collection->validate(@_) }); 
}

sub valid {
  my $self = shift;
  $self->validate(@_) if @_ || !$self->validated;
  return $self->errors->size ? 0:1;
}

sub invalid { shift->valid(@_) ? 0:1 }

sub clear_validated {
  my $self = shift;
  $self->errors->clear;
  $self->validated(0);
}

sub validate {
  my ($self, %args) = @_;

  my $existing_context = $args{context} ? $args{context} : [];
  my @existing_context = ref($existing_context) ? @$existing_context : ($existing_context);
  push @existing_context, @{$self->_context} if $self->has_context;

  $args{context} = \@existing_context if @existing_context;

  return $self if $self->skip_validation;
  return $self if $self->{_inprocess};
  $self->{_inprocess} =1;

  $self->clear_validated if $self->validated;
  $self->_run_validations(%args);
  $self->_run_post_validations(%args);
  $self->validated(1);
  delete $self->{_inprocess};
  return $self;
}

sub _run_validations {
  my ($self, %args) = @_;
  foreach my $validation ($self->validations) {
    my %validation_args = (%{$validation->[1]}, %args);
    $validation->[0]($self, \%validation_args);
  }
}

sub _run_post_validations {
  my ($self, %args) = @_;
  return;
}

sub inject_attribute {
  my ($class, $attribute_to_inject) = @_;
  eval "package $class; has $attribute_to_inject => (is=>'ro');";
}

1;

=head1 NAME

Valiant::Validates - Role that adds class and instance methods supporting validations

=head1 SYNOPSIS

See L<Valiant>.

=head1 DESCRIPTION

This is a role that adds class level validations to you L<Moo> or L<Moose> classes.
The main point of entry for use and documentation currently is L<Valiant>. Here
we have API level documentation without details or examples.  You should read L<Valiant>
first and then you can refer to documentation her for further details.

In addition to methods this class provides, it also proves all methods from L<Valiant::Translation>

=head1 CLASS METHODS

=head2 validates

Used to declare validations on an attribute.  The first argument is either a scalar or arrayref of
scalars which should be attributes on your object:

    __PACKAGE__->validates( name => (...) );
    __PACKAGE__->validates( ['name', 'age'] => (...));

Following arguments should be in one of three forms: a coderef or subroutine reference that contains
validation rules, a key - value pair which is a validator class and its arguments or lastly you can
pass in a L<Type::Tiny> constraint directly.  You may also have key value pairs which are global
arguments for the validate set as a whole:

    package Local::Model::User;

    use Moo;
    use Valiant::Validations; # Importer that wraps Valiant::Validates
    use Types::Standard 'Int';

    has ['name', 'age'] => (is=>'ro);

    validates name => (
      length => { minimum => 5, maximum => 25 },
      format => { match => 'words' },
      sub {
        my ($self, $attribute, $value, $opts) = @_;
        $self->errors->add($attribute, "can't be Joe.  We hate Joe :)" ,$opts) if $value eq 'Joe';
      }, +{ arg1=>'1', arg2=>2 }, # args are optional for coderefs but are passed into $opts
      \&must_be_unique,
    );

    validates age => (
      Int->where('$_ >= 65'), +{
        message => 'A retiree must be at least 65 years old,
      },
      ..., # additional validations
    );

    sub must_be_unique {
      my ($self, $attribute, $value, $opts) = @_;
      # Some local validation to make sure the name is unique in storage (like a database).
    }

If you use a validator class name then the hashref of arguments that follows is not optional.  If you pass
an options hashref it should contain arguments that are defined for the validation type you are passing
or one of the global arguments: C<on>, C<message>, C<if> and C<unless>.  See L</"GLOBAL OPTIONS"> for more.

For subroutine reference and L<Type::Tiny> objects you can or not pass an options hashref depending on your
needs.  Additionally the three types can be mixed and matched within a single C<validates> clause.

When you use a validator class (such as C<length => { minimum => 5, maximum => 25 }>) we resolve the class
name C<length> in the following way.  We first camel case the name and then look for a 'Validator' package
in the current class namespace.  If we don't find a match we check each namespace up the hierarchy and
then check the two global namespaces C<Valiant::ValidatorX> and C<Validate::Validator>.  For example if
you declare validators as in the example class above C<Local::Model::User> we would look for the following:

    Local::Model::User::Validator::Length
    Local::Model:::Validator::Length
    Local::Validator::Length
    Validator::Length
    Valiant::ValidatorX::Length
    Valiant::Validator::Length

These get checked in the order above and loaded and instantiated once at setup time.

B<NOTE:> The namespace C<Valiant::Validator> is reserved for validators that ship with L<Valiant>.  The
C<Valiant::ValidatorX> namespace is reserved for additional validators on CPAN that are packaged separately
from L<Valiant>.  If you wish to share a custom validator that you wrote the proper namespace to use on
CPAN is C<Valiant::ValidatorX>.

You can also prepend your validator name with '+' which will cause L<Valiant> to ignore the namespace 
resolution and try to load the class directly.  For example:

    validates_with '+App::MyValidator';

Will try to load the class C<App::MyValidator> and use it as a validator directly (or throw an exception if
it fails to load).

=head2 validates_with

C<validates_with> is intended to process validations that are on the class as a whole, or which are very
complex and can't easily be assigned to a single attribute.  It accepts either a subroutine reference
with an optional hash of key value pair options (which are passed to C<$opts>) or a scalar name which
should be a stand alone validator class (basically a class that does the C<validates> method although
you should consume the L<Validate::Validator> role to enforce the contract).

    __PACKAGE__->validates_with(sub {
      my ($self, $opts) = @_;
      ...
    });

    __PACKAGE__->validates_with(\&check_object => (arg1=>'foo', arg2=>'bar'));

    sub check_object {
      my ($self, $opts) = @_;
      ...
    }

    __PACKAGE__->validates with('Custom' => (arg1=>'foo', arg2=>'bar'));

If you pass a string that is a validator class we resolve its namespace using the same approach as
detailed above for C<validates>.  Any arguments are passed to the C<new> method of the found class
excluding global options.

=head1 INSTANCE METHODS

=head2 validate

Run validation rules on the current object, optionally with arguments hash.  If validation has already
been run on this object, we clear existing errors and run validations again.  Currently the return
value of this method is not defined in the API.  Example:

    $object->validate(%args);

Currently the only arguments with defined meaning is C<context>, which is used to defined a validation
context.  All other arguments will be passed down to the C<$opts> hashref.

=head2 valid

=head2 invalid

Return true or false depending on if the current object state is valid or not.  If you call this method and
validations have not been run (via C<validate>) then we will first run validations and pass any arguments
to L</validates>.  If validations have already been run we just return true or false directly UNLESS you
pass arguments in which case we clear errors first and then rerun validations with the arguments before
returning true or false.

=head2 has_errors

Returns a boolean indicating if the object currently has errors.   This does not run a validation
check first (unlike C<valid> or C<invalid>).   So if you just want to check the current state of
the errors list and not tamper with that state you can use this.

=head2 clear_validated

Clears any errors and sets the object as though validations hd never been run.

=head2 do_validate

Sets C<skip_validation> to true and returns C<$self>

=head2 skip_validate

Sets C<skip_validation> to false and returns C<$self>

=head2 context

Set a validation context (or arrayref of contexts) that will be used on an following validations.ß

=head1 ATTRIBUTES

=head2 errors

An instance of L<Valiant::Errors>.  

=head2 validated

This attribute will be true if validations have already been been run on the current instance.  It
merely says if validations have been run or not, it does not indicate if validations have been passed
or failed see L</valid> pr L</invalid>

=head2 skip_validation

When true do not run validations, even if you call ->validate

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Valiant::Validations>

=head1 COPYRIGHT & LICENSE
 
Copyright 2020, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

