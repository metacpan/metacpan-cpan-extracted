package Valiant::Errors;

use Moo;
use Data::Perl::Collection::Array;
use Valiant::NestedError;
use Valiant::Util 'throw_exception';

use overload (
  bool  => sub { shift->size ? 1:0 },
);

has 'object' => (
  is => 'ro',
  required => 1,
  weak_ref => 1,
);

has errors => (
  is => 'ro',
  init_arg => undef,
  lazy => 1,
  required => 1,
  default => sub { Data::Perl::Collection::Array->new() },
  handles => {
    size => 'count',
    count => 'count',
    clear => 'clear',
    blank => 'is_empty',
    empty => 'is_empty',
  }
);

sub i18n_class { 'Valiant::I18N' }

has 'i18n' => (
  is => 'ro',
  required => 1,
  default => sub { Module::Runtime::use_module(shift->i18n_class) },
);

sub error_class { 'Valiant::Error' }

# return a flat list of all errors with duplicated removed. To we probably
# need to make use the the equals method on Valiant::Error
sub uniq { die 'todo' }

sub any {
  my ($self, $code) = @_;
  $code ||= sub { $_ };
  foreach my $error ($self->errors->all) {
    local $_ = $error;
    return 1 if $code->($error);
  }
  return 0;
}

sub copy {
  my ($self, $other) = @_;
  my $errors = $other
    ->errors
    ->map(sub {
      my $class = ref $_;
      my $new = $class->new(
        object => $self->object,
        attribute => $_->attribute,
        type => $_->type,
        i18n => $_->i18n,
        options => $_->options,
      );
      return $new;
    });
  $self->errors->clear;
  $self->errors->push($errors->all);
}

sub import_error {
  my ($self, $error, $options) = @_;
  $self->errors->push(
    Valiant::NestedError->new(
      object => $self->object,
      inner_error => $error,
      %{ $options||+{} },
    )
  );
}

sub merge {
  my ($self, $other) = @_;
  foreach my $error ($other->errors->all) {
    $self->import_error($error);
  }
}

sub where {
  my $self = shift;
  my ($attribute, $type, $options) = $self->_normalize_arguments(@_);
  return $self->errors->grep(sub {
    $_->match($attribute, $type, $options);
  })->all;
}

sub _normalize_arguments {
  my ($self, $attribute, $type, $options) = @_;
  if(ref($type) && ref($type) eq 'CODE') {
    $type = $type->($self->object, $options);
  }
  return (
    $attribute,
    $type,
    $options,
  );
}

# Returns +true+ if the error messages include an error for the given key
# +attribute+, +false+ otherwise.
sub include {
  my ($self, $attribute) = @_;
  return scalar($self->any(sub {
      $_->match($attribute);
  }));
}
*has_key = \&include;

# Delete messages for +key+. Returns the deleted messages.
sub delete {
  my $self = shift;
  my ($attribute, $type, $options) = $self->_normalize_arguments(@_);
  my @deleted = ();
  my $idx = 0;
  foreach my $error($self->errors->all) {
    if($error->match($attribute, $type, $options)) {
      push @deleted, $self->errors->delete($idx);
    } else {
      $idx++
    }
  }
  return @deleted;
}

sub each {
  my ($self, $block) = @_;
  foreach my $error($self->errors->all) {
    $block->((defined($error->attribute) ? $error->attribute : '*'), $error->message);
  }
}

sub model_errors {
  my $self = shift;
  my @errors;
  foreach my $error($self->errors->all) {
    push @errors, $error if !$error->has_attribute || !defined($error->attribute);
  }
  return @errors;
}

sub model_messages {
  my ($self, $full_messages_flag) = @_;
  return map {
    # AFAIK the full_messages_flag does nothing for model errors
    $full_messages_flag ? $_->full_message : $_->message
  } $self->model_errors;
}

sub attribute_errors {
  my $self = shift;
  my @errors;
  foreach my $error($self->errors->all) {
    push @errors, $error if $error->has_attribute and defined($error->attribute);
  }
  return @errors;
}

sub attribute_messages {
  my ($self) = @_;
  return map {
    $_->message;
  } $self->attribute_errors;
}

sub full_attribute_messages {
  my ($self) = @_;
  return map {
    $_->full_message;
  } $self->attribute_errors;
}


sub group_by_attribute {
  my $self = shift;
  my %attributes;
  foreach my $error($self->errors->all) {
    next unless $error->has_attribute;
    push @{$attributes{$error->attribute||'*'}}, $error;
  }
  return %attributes;
}

# Returns a Hash of attributes with their error messages. If +full_messages+
# is +true+, it will contain full messages (see +full_message+).
sub to_hash {
  my ($self, $full_messages_flag) = @_;
  my %hash = ();
  my %grouped = $self->group_by_attribute;
  foreach my $attr (keys %grouped) {
    $hash{$attr} = [
      map {
        $full_messages_flag ? $_->full_message : $_->message
      } @{ $grouped{$attr}||[] }
    ];
  }
  return %hash;
}

sub as_json {
  my ($self, %options) = @_;
  return $self->to_hash(exists $options{full_messages});
}

sub TO_JSON { shift->as_json(@_) }

# Adds +message+ to the error messages and used validator type to +details+ on +attribute+.
# More than one error can be added to the same +attribute+.
sub add {
  my ($self, $attribute, $type, $options) = @_;
  unless(defined($type)) {
    $type = $self->i18n->make_tag('invalid');
  }
  $options ||= +{};
  ($attribute, $type, $options) = $self->_normalize_arguments($attribute, $type, $options);

  my $error = $self->error_class
    ->new(
      object => $self->object,
      attribute => $attribute,
      type => $type,
      i18n => $self->i18n,
      options => $options,
    );

  if(my $exception = $options->{strict}) {
    my $message = $error->full_message;
    throw_exception('Strict' => (msg=>$message)) if $exception == 1;
    $exception->throw($message); # If not 1 then assume its a package name.
  }
 
  $self->errors->push($error);
  return $error;
}

# Returns +true+ if an error on the attribute with the given message is
# present, or +false+ otherwise. +message+ is treated the same as for +add+.  ~
sub added {
  my ($self, $attribute, $type, $options) = @_;

  ## TODO ok so if the $attribute refers to an object which can->errors maybe we
  ## need to call $self->$attribute->errors->add(undef, $type, $options) instead
  ## so that any global errors to a nested object end in in the right place?
  ## Afterwards we need to associate the nested object errors to $self so that
  ## we know errors exist (for stuff like to_hash and all_errors, etc.

  $type ||= $self->i18n->make_tag('invalid');
  ($attribute, $type, $options) = $self->_normalize_arguments($attribute, $type, $options);
  if($self->i18n->is_i18n_tag($type)) {
    return $self->any(sub {
      $_->strict_match($attribute, $type, $options);
    });
  } else {
    return scalar(grep {
      $_ eq $type;
    } $self->messages_for($attribute)) ? 1:0
  }
}

# Similar to ->added except we don't care about options 
sub of_kind {
  my ($self, $attribute, $type) = @_;
  $type ||= $self->i18n->make_tag('invalid');
  ($attribute, $type) = $self->_normalize_arguments($attribute, $type);
  if($self->i18n->is_i18n_tag($type)) {
    return $self->any(sub {
      $_->strict_match($attribute, $type);
    });
  } else {
    return scalar(grep {
      $_ eq $type;
    } $self->messages_for($attribute)) ? 1:0
  }
}

sub messages { map { $_->message } shift->errors->all }
  
sub full_messages {
  my $self = shift;
  $self->full_messages_collection->all;
}

sub full_messages_collection {
  my $self = shift;
  return $self->errors->map(sub { $_->full_message });
}


sub full_messages_for {
  my ($self, $attribute) = @_;
  return map {
    $_->full_message
  } $self->where($attribute);
}

sub messages_for {
  my ($self, $attribute) = @_;
  return map {
    $_->message
  } $self->where($attribute)
}

sub full_message {
  my ($self, $attribute, $message) = @_;
  $self->error_class->full_message(
    $attribute,
    $message,
    $self->object,
    $self->i18n);
}

sub generate_message {
  my ($self, $attribute, $type, $options) = @_;
  $type ||= $self->i18n->make_tag('invalid');
  return $self->error_class->generate_message(
    $attribute,
    $type,
    $self->object,
    $options,
    $self->i18n);
}

sub _dump {
  require Data::Dumper;
  return Data::Dumper::Dumper( +{shift->to_hash(full_messages=>1)} );
}

1;

=head1 NAME

Valiant::Errors - A collection of errors associated with an object

=head1 SYNOPSIS

=head1 DESCRIPTION

A collection of errors (each instances of L<Valiant::Error>) associated with attributes
or a model.  This class provides methods for adding, retrieving and introspecting 
error, typically via a L<Valiant::Validator> or L<Valiant::Validator::Each> subclass.

The goal of this class is to make it as easy as possible to work with and understand
errors that have been added to your instance.  In general you will never make an instance
of this directly since it will be used via the L<Valiant::Validates> role.

=head1 ATTRIBUTES

This class defined the following attributes

=head2 object

This is a weak reference to the object which the errors belong to.

=head2 errors

This is an instance of L<Data::Perl::Collection::Array> which in a collection of
L<Valiant::Error> objects added by validators.

=head2 i18n

The internationalization and translation class.  Generally this is an instance of
L<Valiant::I18N>.  You won't need to supply this as it normally is built automatically.

=head1 METHODS

The class defines the following methods

=head2 count 

=head2 size

The number of errors collected.  If there are no errors then the size is 0.

=head2 empty

=head2 blank

Returns true if there are no errors collected.

=head2 any(\&code)

Accepts a coderef that will receive each error object in the collect and return true
if any of the coderef calls return true.  Used to determine if the errors collection
contains at least one type of error.

    my $has_invalids = $user1->errors->any(sub {
      ${\$_->type} eq 'invalid';
    });

=head2 copy

Copy an errors collection into the current (replacing any existing).  The copies are
new instances of L<Valiant::Error>, not references to the original objects.

=head2 import_error ($error)

Given a single L<Valiant::Error> inport it into the current errors collection

=head2 merge ($collectio)

Given a L<Valiant::Errors> collection, merge it into the current one.

=head2 where ($attribute, $message, \%options)

return all the L<Valiant::Error> objects in the current collection which match criteria.

=head2 include ($attribute)

Returns +true+ if the error messages include an error for the given key
+attribute+, +false+ otherwise.

=head2 delete ($attribute)

Delete messages for +key+. Returns the deleted messages.

=head2 each ($coderef)

Iterates through each error key, value pair in the error messages hash.
Yields the attribute and the error for that attribute. If the attribute
has more than one error message, yields once for each error message.

    $object->errors->each*(sub {
      my ($attribute, $message) = @_;
    });

If the error is a model error then C<$attribute> will be '*'.

=head2 model_messages

Returns an array of all the errors that are associated with the model (Localized
if needed).

=head2 attribute_messages

Returns an array of all the errors that are associated with attributes (localized if needed).

=head2 full_attribute_messages

Returns an array of the full messages of all attributes (localized if needed).

=head2 to_hash (?$flag)

Returns a hash where each key is an attribute (or '*' for the model) and
each value is an arrayref of errors.  C<?$flag> when true will return
the full messages for each error.

=head2 add ($attribute|undef, $message, \%opts)

Add a new error message to the object.  Error can be associated with an attribute
or with the object itself. C<$message> can be one of:

=over 14

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

=head2 added  ($attribute|undef, $message, \%opts)

Return true if the error has already been created.

=head2 of_kind  ($attribute|undef, $message)

Similar to <added> expect we don't need to match options

=head2 messages

An array of the error messages.  All translation tags will be translated to strings in the
expected local langauge.

=head2 full_messages

An array of the full messages (localized if needed).

=head2 messages_for ($attribute)

An array of all the messages for the given attribute (localized if needed).

=head2 full_messages_for ($attribute)

An array of all the full messages for the given attribute (localized if needed).

=head1 JSONification

This class provides a C<TO_JSON> method suitable for use in some of the common
JSON serializers.  When supported it will delegate the job of turning the object
into a hash that can be serialized to JSON to the C<to_hash> method.

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::Error>.

=head1 AUTHOR
 
See L<Valiant>  
    
=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut

1;
