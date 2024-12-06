package Valiant::JSON::JSONBuilder;

use Moo;
use Carp;
use Scalar::Util 'blessed';
use Module::Runtime 'use_module';
use Cpanel::JSON::XS ();
use Valiant::HTML::Util::Collection;
use Valiant::Naming;
use Valiant::HTML::FormBuilder::DefaultModel;

has model => (is=>'rw', required=>1);
has has_custom_view => ( is=>'ro', required=>1);
has view => ( is=>'ro', required=>1);

has namespace => (is=>'ro', required=>1, default=>'');

has data => (is=>'rw', required=>1, default=>sub { +{ data => +{}} });
has index => (is=>'rw', clearer=>1, predicate=>1);

has data_pointer => (
  is => 'rw', 
  required => 1, 
  lazy => 1,
  builder => 1,
  clearer => 1,
  predicate => 1,
);
  sub _build_data_pointer {
    my ($self) = @_;
    my $ns = $self->namespace;
    if($ns eq '') {
      return [ $self->data->{data} ];
    } else {
      $self->data(+{ data => { $ns => +{} }});
      return [ $self->data->{data}{$ns} ];
    }
  }

has 'json_args' => (
  is => 'ro',
  required => 1,
  default => sub { +{} },
);

has 'json' => (
  is => 'ro', 
  required => 1, 
  lazy => 1,
  default => sub {
    my %args = %{ shift->json_args };
    return Cpanel::JSON::XS->new(%args, utf8=>1, pretty=>1);
  },
  handles => {
    encode_json => 'encode',
  },
);

sub reset {
  my ($self) = @_;
  $self->data(+{ data => +{} });
  $self->clear_data_pointer;
  $self->clear_index;
  return $self;
}

sub json_true { Cpanel::JSON::XS::true() } 
sub json_false { Cpanel::JSON::XS::false() }

sub render_json {
  my ($self) = @_;
  return my $json = $self->encode_json($self->render_perl);
}

sub render_perl {
  my ($self) = @_;
  $self->data_pointer unless $self->has_data_pointer;
  return $self->data->{data};
}

sub push_model {
  my ($self, $model) = @_;
  $self->model([@{$self->model}, $model]);
  return $self;
}

sub pop_model {
  my ($self) = @_;
  my @models = @{ $self->model };
  my $discard = pop @models;
  $self->model(\@models);
  return $self;
}

sub push_pointer {
  my ($self, $key, $type, %opts) = @_;
  my $ns = exists $opts{namespace} ? $opts{namespace} : $key;

  $type ||= +{};
  $self->current_data->{$ns} = $type;
  $self->data_pointer([
    @{$self->data_pointer},
    $self->current_data->{$ns},
  ]);
  $self->index(0) if ref($type) eq 'ARRAY';
  return $self;
}

sub pop_pointer {
  my ($self) = @_;
  my @pointers = @{ $self->data_pointer };
  my $discard = pop @pointers;
  $self->data_pointer(\@pointers);
  return $self;
}

sub inc_index {
  my ($self) = @_;
  $self->index($self->index + 1);
  return $self;
}

sub _to_model {
  my ($self, $model) = @_;
  croak "No model provided" unless $model;
  confess "Model is not an object: $model" unless Scalar::Util::blessed($model);
  return $model->to_model if $model->can('to_model');
  return $model;
}

sub _model_name_from_object_or_class {
  my ($self, $proto) = @_;
  my $model = $self->_to_model($proto);
  return $model->model_name if $model->can('model_name');
  return Valiant::Name->new(Valiant::Naming::prepare_model_name_args($model));
}

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my $options = $class->$orig(@args);
  my $model_name = '';

  $options->{has_custom_view} = exists($options->{view}) ? 1:0;
  $options->{view} ||= Module::Runtime::use_module('Valiant::HTML::Util::View')->new;
  $options->{model} ||= bless +{}, 'Valiant::HTML::FormBuilder::DefaultModel';

  if(blessed $options->{model}) {
    $model_name = $class->_model_name_from_object_or_class($options->{model})->param_key;
    $options->{namespace} = $model_name unless exists($options->{namespace})
  } else {
    $model_name = $options->{model};
    if($options->{view}->can('get_model_for_json')) {
      $options->{model} = $options->{view}->get_model_for_json($model_name);
    } elsif($options->{view}->can($model_name)){
      $options->{model} = $options->{view}->$model_name;
    } else {
      croak "Can't find model '$model_name' in view";
    }
    $options->{namespace} = $model_name unless exists($options->{namespace})
  }

  $options->{model} = [$options->{model}]
    unless ref $options->{model} eq 'ARRAY';

  return $options;
};

sub get_attribute_for_json {
  my ($self, $name) = @_;
  my $model = $self->model->[-1];
  return my $value = $model->get_attribute_for_json($name) if $model->can('get_attribute_for_json');
  return $model->$name if $model->can($name);
  croak "Can't find attribute '$name' for model '$model'";
}

sub has_attribute_for_json {
  my ($self, $name) = @_;
  my $model = $self->model->[-1];
  return my $value = $model->has_attribute_for_json($name) if $model->can('has_attribute_for_json');
  return $self->view->has_attribute_for_json($model, $name) if $self->view->can('has_attribute_for_json');
  my $predicate = $self->view->can('build_predicate') ? $self->view->build_predicate($model, $name) : "has_${name}";
  return $model->$predicate if $model->can($predicate);
  croak "Can't find attribute '$name' for model '$model'";
}

sub current_data {
  my ($self) = @_;
  my $what = $self->data_pointer->[-1];
  return $what;
}

sub current_model {
  my ($self) = @_;
  my $model = $self->model->[-1];
  return $model;  
}

sub set_current_data {
  my ($self, $key, $value, %opts) = @_;
  return $self if $opts{omit_undef} && !defined($value);
  return $self if $opts{omit_empty} && (ref($value)||'') eq 'ARRAY' && !@$value;
  return $self if $opts{omit_empty} && (ref($value)||'') eq 'HASH' && !%$value;
  return $self if $opts{omit_empty} && !$self->has_attribute_for_json($key);;

  $key = $opts{name} if exists $opts{name};
  if($self->has_index) {
    $self->current_data->[$self->index]{$key} = $value;
  } else {
    $self->current_data->{$key} = $value;
  }
  return $self;
}

sub TO_JSON {
  my ($self) = @_;
  return $self->render_perl;
}

sub _normalize_opts {
  my ($self, @args) = @_;
  return () unless @args;
  if(@args == 1) {
    my $arg = $args[0];
    return %$arg if ref($arg) eq 'HASH';
    return (cb => $arg ) if ref($arg) eq 'CODE';
    return (value => $arg); # assume scalar
  } elsif(@args == 2) {
    carp 'Arg 1 must be hashref if passing 2 args to FormBuilder methods' if ref($args[0]) ne 'HASH';
    carp 'Arg 2 must be coderef if passing 2 args to FormBuilder methods' if ref($args[1]) ne 'CODE';
    return (%{$args[0]}, cb => $args[1]);
  } else {
    croak "Invalid options: @args";
  }
}

sub _normalize_value {
  my ($self, $key, %opts) = @_;
  my $cb =  exists $opts{cb} ? $opts{cb} : undef;

  my $return_value;
  if($cb) {
    my $value = exists $opts{value} ? $opts{value} : $self->get_attribute_for_json($key);
    $return_value = $cb->($self->has_custom_view ? ($self->view, $self, $value) : ($self, $value));
  } else {
    $return_value = exists $opts{value} ? $opts{value} : $self->get_attribute_for_json($key);
  }
  return $return_value;
}

# type handlers

sub value {
  my ($self, $value) = @_;
  $value = "$value" if blessed($value);
  if($self->has_index) {
    $self->current_data->[$self->index] = $value;
  } else {
    $self->current_data = $value;
  }
  return $self;
}

sub string {
  my $self = shift;
  my $key = shift;
  my %opts = $self->_normalize_opts(@_);
  my $value = $self->_normalize_value($key, %opts);
  $self->set_current_data($key, $value, %opts);
  return $self;
}

sub boolean {
  my $self = shift;
  my $key = shift;
  my %opts = $self->_normalize_opts(@_);
  my $raw_value = $self->_normalize_value($key, %opts);
  $raw_value = 0 if !defined($raw_value) && $opts{coerce_undef};

  my $boolean_value = $raw_value;
  if(defined $raw_value) {
    $boolean_value = $raw_value ?
      $self->json_true :
        $self->json_false;
  }

  $self->set_current_data($key, $boolean_value, %opts);
  return $self;
}

sub number {
  my $self = shift;
  my $key = shift;
  my %opts = $self->_normalize_opts(@_);
  my $raw_value = $self->_normalize_value($key, %opts);
  my $num_value = defined($raw_value) ? 0+$raw_value : $raw_value;
  $self->set_current_data($key, $num_value, %opts);
  return $self;
}

sub object {
  my $self = shift;
  my $key = shift;
  my $cb = pop;
  my %opts = $self->_normalize_opts(@_);

  croak "You must provide a callback for '$key' to object" unless ref($cb) eq 'CODE';
  
  my $model;
  if(blessed $key) {
    $model = $key;
    $key = $self->_model_name_from_object_or_class($model)->param_key;
  } else {
    $model = $self->get_attribute_for_json($key);
  }

  $self->push_model($model);
  $self->push_pointer($key, +{}, %opts);
  $cb->($self->has_custom_view ? ($self->view, $self, $model) : ($self, $model));
  $self->pop_model;
  $self->pop_pointer;

  my $ns = exists($opts{namespace}) ? $opts{namespace} : $key;
  delete $self->current_data->{$ns} if $opts{omit_empty} && !%{$self->current_data->{$ns}};


  return $self;
}

sub skip { return bless {}, 'Valiant::JSON::Util::Skip'}

sub array {
  my $self = shift;
  my $key = shift;
  my $cb = pop;

  croak "You must provide a callback for '$key' to array" unless ref($cb) eq 'CODE';

  my %opts = $self->_normalize_opts(@_);
  
  my $collection;
  if( ((ref($key)||'') eq 'ARRAY') || blessed($key)) {
    $collection = $key;
    $key = $opts{namespace};
  } else {
    $collection = $self->get_attribute_for_json($key);
  } 
  
  $collection = Valiant::HTML::Util::Collection->new(@$collection)
    if ref($collection) eq 'ARRAY';

  $self->push_pointer($key, [], %opts);
  while(my $model = $collection->next) {
    $self->push_model($model);
    my $return = $cb->($self->has_custom_view ? ($self->view, $self, $model) : ($self, $model));
    $self->pop_model;
    $self->inc_index unless ((ref($return)||'') eq 'Valiant::JSON::Util::Skip');
  }
  $self->pop_pointer;
  $self->clear_index;
  $collection->reset if $collection->can('reset');

  my $ns = exists($opts{namespace}) ? $opts{namespace} : $key;
  delete $self->current_data->{$ns} if $opts{omit_empty} && !@{$self->current_data->{$ns}};

  return $self;
}

sub if {
  my ($self, $cond, $cb) = @_;
  croak 'You must provide a callback to if' unless ref($cb) eq 'CODE';

  $cond = $cond->($self->has_custom_view ? ($self->view, $self) : ($self)) if ref($cond) eq 'CODE';
  $cb->($self->has_custom_view ? ($self->view, $self) : $self) if $cond;

  return $self;
}

sub with_model {
  my ($self, $model, $cb) = @_;
  $self->push_model($model);
  $cb->($self->has_custom_view ? ($self->view, $self, $model) : ($self, $model));
  $self->pop_model;
  return $self;
}

sub errors {
  my $self = shift;
  my @errors = $self->_errors_for($self->current_model, $self->namespace);
  return $self unless scalar(@errors);
  $self->data->{errors} = \@errors; 
  return $self;
}

sub _errors_for {
  my ($self, $model, $ns) = @_;
  carp "model $model does not support the errors API" unless $model->can('errors');

  $ns ||= $model->model_name->param_key if $model->can('model_name');

  # 'multipart/form-data' 
  my ($content_type, @params) = $self->view->ctx->req->content_type;
  my $cb;
  if(
    ($content_type eq 'application/x-www-form-urlencoded')
      ||
    ($content_type eq 'multipart/form-data')
  ) {
    $cb = sub {
      my $field = shift;
      return +{ parameter => $field };
    };
  } elsif($content_type eq 'application/json') {
    $cb = sub {
      my $field = shift;
      $field =~ s/\./\//g;
      $field =~ s/\[/\//g;
      $field =~ s/\]//g;
      return +{ pointer => $field };
    };
  }

  my %errors = $model->errors->to_hash(1);
  my @errors = ();
  foreach my $field (keys %errors) {
    my @error_messages = $errors{$field};
    foreach my $error_message (@error_messages) {
      my $info = +{ detail => $error_message };
      if($field eq '*') {
        $info->{source} = $cb->("${ns}");
      } else {
        $info->{source} = $cb->("${ns}.${field}");
      }
      push @errors, $info;
    }
  }
  return @errors; 
}

1;

=head1 NAME

Valiant::JSON::JSONBuilder - Wraps a model with a JSON builder

=head1 SYNOPSIS

Given an object defined like this:

    package Local::Test::User;

    use Moo;

    has username => (is=>'ro');
    has active => (is=>'ro');
    has age => (is=>'ro');

Create an instance of the object and then use the JSONBuilder to render it:

    my $user = Local::Test::User->new(
      username => 'bob',
      active => 1,
      age => 42,
    );

    my $jb = Valiant::JSON::JSONBuilder->new(model=>$user);
    my $json = $jb->string('username')
      ->boolean('active')
      ->number('age')
      ->render_json;

    say $json;

Response is:

   "local_test_user" : {
      "username" : "bob",
      "age" : 42,
      "active" : true
   }

You can control value the top level field of the rendered JSON or remove it:

    my $jb = Valiant::JSON::JSONBuilder->new(model=>$user, namespace=>'');
    my $json = $jb->string('username')
      ->boolean('active')
      ->number('age')
      ->render_json;

    say $json;

Response is:

    {
        "username" : "bob",
        "age" : 42,
        "active" : true
    }

It can also work with a view object, see below for details.

=head1 DESCRIPTION

Serializing an object into a JSON string is a common task.  This module
provides a simple way to do that using a JSON builder pattern.  It is
intended to be used with L<Valiant> but can be used with any object.

There's tons of different patterns for serializing objects into JSON.  One common
approach is to add a C<TO_JSON> method to your object.  This is a fine approach
but it has a few drawbacks the biggest of which is that it forces you into a
single serialization pattern for the object.   This might be ok for using serialization
for saving an object to a database but it is less than ideal for rendering an object
into a JSON response for an API.  For example you might want to render the object
differently depending on the user's role or depending on the API version, or for any
other reason I'm sure you can think of.

Another approach is to just write some bespoke code to turn your object into a perl
data structure suitable for passing to a JSON encoder such as L<JSON::MaybeXS>.  This
is also a fine approach but it can be a bit tedious to write and maintain.  It's also
easy to mess up handling of nested objects and arrays or in situations when you want to make
sure a scalar is coerced into a string or a number.  The purpose behind this module is
to encapsulate some basic patterns for serializing objects into JSON and to make it easy
to extend and customize.  Although this works well with simple cases I think it really
shines when you have a complex object with nested objects and arrays contained within it
as well as when you need to inject extra fields and values into the JSON response that are
not part of the object itself.  You can even include other objects in the response and
the API includes some basic conditional logic to smooth over very complex cases.

=head1 ATTRIBUTES

This class defines the follwoing attributes.

=head2 model

This is the object to be serialized.  It can be any object but it has some extensions to play
nice with objects that are using L<Valiant> for validation.

This value should be either a blessed object or the scalar name of the object which refers to
an attribute on the view object (which must then be provided, see below)

=head2 namespace

This is the top level field name to use when rendering the object.  If not specified it will
use the C<model_name> of the object if it has one.  If the object does not have a C<model_name>
then it will use the class name of the object.  If you want to render the object without a
top level field then set this to an empty string.

=head2 view

This is an optional view object.  If provided we can use view attributes to provide models.

=head2 json_args

This is an optional hashref of options which is passed to the L<JSON::MaybeXS> encoder.

=head1 METHODS

This class defines the following methods.

=head2 reset

Clears any previously defined JSON field and value definitions but preserves the model and related
attributes.  Useful if you want to reuse the same builder object to render representations of the
same model, but I mostly used it for testing and saw no reason to mark it private.

=head2 json_true

=head2 json_false

Returns an object representing a JSON boolean value for serialization.  Useful since Perl doesn't
have a native boolean type.

=head2 render_perl

Returns a perl data structure representing the current defined JSON structure.  Useful for testing
but I see no reason to mark it private

=head2 render_json

A JSON encoded string representing the current defined JSON structure.

=head2 string

Renders an object attribute as a string.

    $jb->string('username', \%options);

The options hashref is optional and can contain the following keys:

=over 4

=item name

The name of the field to render.  Generally this is an attribute on the model object (or the
model has the C<get_attribute_for_json> method defined).  You can use a non attribute value
here if you need to inject a field that isn't in the model (for example a CSRF token) but
if you do so you must prove a C<value> option.

=item value

If provided use this value instead of the value of the attribute.

=item omit_undef

If true then the field will not be rendered if the value is undefined.

=item omit_empty

If true then the field will not be rendered if the value is an empty string.  For this to work
the model should support C<has_attribute_for_json> or provide a method called C<has_$attribute>

=back

=head2 number

Same as L</string> but coerces the value into a number instead.  Same options supported

=head2 boolean

Same as L</string> but coerces the value into a boolean instead.  Same options supported.
Coerces into s JSON boolean value (true/false) not a Perl boolean value (1/0).  See L</json_true>
and L</json_false>.

Supports one additional option: C<coerce_undef> which if true will coerce an undefined value
into a false value.  By default an undefined value will be rendered as a JSON null value unless
C<omit_undef> is true.  Same thing if the value is not present, that will render as null unless
C<omit_empty> is true.

=head2 value

This returns the value of the current field directly.  Useful when you want to render a simple
array of values

    package Local::Test::List;

    use Moo;

    has numbers => (is=>'ro');

    my $list_of_numbers = Local::Test::List->new(numbers=>[1,2,3]);
    my $jb = Valiant::JSON::JSONBuilder->new(model=>$list_of_numbers);
    my $json = $jb->array([1,2,3], {namespace=>'numbers'}, sub {
      my ($jb, $item) = @_;
      $jb->value($item);
    })->render_json;

response is:

    {
      "local_test_list" : {
          "numbers" : [
            "1",
            "2",
            "3"
          ]
      }
    }

=head2 array


=head1 METHODS FOR OBJECTS

Although not required, if the model object provides these methods they can be used to customize
how we render the object.

=head2 get_attribute_for_json

When requesting that a model provide a value for an attribute, if this method is defined it will
be called with the attribute name and be expected to return the value to be used for the attribute.
this can be useful if you want to do some custom processing on the value before it is rendered or
if you want to create virtual attributs jsut for JSON.

If the method doesn't exist we expect to find a method on the object that matches the attribute name.

=head2 has_attribute_for_json

When requesting that a model provide a value for an attribute, if this method is defined it will
be called with the attribute name and be expected to return a boolean value indicating if the attributes
exists or not.  If this method is not provided we expect to find a method on the object that matches
"has_$attribute_name", which is the common convention on L<Moo> and L<Moose> objects.  If neither method
exists you will get a runtime error.

This method is called if you use the C<omit_empty> option on a builder method so you need to remember to
provide the correct model API to support checking an attribute exists.

=head1 USING WITH A VIEW

=head1 SEE ALSO
 
L<Valiant>, L<JSON::MaybeXS>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
