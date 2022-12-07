package Valiant::Error;

use Moo;
use Text::Autoformat 'autoformat';
use Module::Runtime;
use FreezeThaw;
use Scalar::Util ();

# These groups are often present in the options hash and need to be removed 
# before passing options onto other classes in some cases

my @CALLBACKS_OPTIONS = (qw(if unless on allow_undef allow_blank strict));
my @MESSAGE_OPTIONS = (qw(message));

# object is the underlying object that has an error.  This object
# must do the 'validatable' role.

has 'object' => (
  is => 'ro',
  required => 1,
  weak_ref => 1, # not sure about this...
);

# The type of the error, a string
has ['type', 'raw_type'] => (
  is => 'ro',
  required => 1,
);

# The attribute that has the error.  If undef that means its
# a model error (an error on the model itself in general).
has attribute => (is=>'ro', required=>0, predicate=>'has_attribute');

# The value which caused the error.
has bad_value => (is=>'ro', required=>1);

# A hashref of extra meta info (it is allowed to be an empty hash)
has options => (is=>'ro', required=>1);

# holds a local reference to the i18n object
has i18n => (is=>'ro', required=>1);

# Easier to override for subclassers.  Do we want to check the options attribute
# to make it easier to set without subclassing?  Something to think about.
sub i18n_class { 'Valiant::I18N' } 
sub default_format { '{{attribute}} {{message}}' }

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my $options = $class->$orig(@args);

  # Pull the main attributes out of the options hashref
  my ($object, $attribute, $type, $i18n, $set_options, $bad_value) = delete @{$options}{qw/object attribute type i18n options bad_value/};

  # Get the i18n from options if passed, otherwise from the model if the model so
  # defines it, lastly just make one if we need it.
  $i18n ||= $object->can('i18n') ?
    $object->i18n :
    Module::Runtime::use_module($class->i18n_class);

  # set a default error type
  unless(defined($type)) {
    $type = $i18n->make_tag('invalid');
  }

  unless(defined($bad_value)) {
    if($attribute) {
      $bad_value = $object->read_attribute_for_validation($attribute);
    } else {
      $bad_value = $object; # Its a model error
    }
  }

  return +{
    object => $object,
    attribute => $attribute,
    type => $type,
    i18n => $i18n,
    raw_type => $type,
    bad_value => $bad_value,
    options => +{
      %{$options||{}}, 
      %{$set_options||{}}
    },
  }
};

# This takes an already translated error message part and creates a full message
# by combining it with the attribute human name (which itself needs to be translated
# if translation info exists for it) using a template 'format'.  You can have a format
# for each attribute or model/attribute combination or use a default format.

sub full_message {
  my $self = shift;

  # We need to do this dance since full_message needs to be called with two
  # different signatures.  In some places we even call it as a class method
  # (that's why we do the i18n dance below as well)
  my ($attribute, $message, $object, $i18n) = @_;
  $attribute ||= $self->attribute if $self->has_attribute;
  $message ||= $self->message;
  $object ||= $self->object;
  $i18n ||= Scalar::Util::blessed($self) ?
    $self->i18n :
    Module::Runtime::use_module($self->i18n_class);

  return $message unless defined($attribute);

  my @defaults = ();
  if($object->can('i18n_scope')) {
    $attribute =~s/\.\d+//g;
    my $i18n_scope = $object->i18n_scope;
    my @parts =  split '\.', $attribute; # For nested attributes
    #TODO remove array indexes [\d]
    my $attribute_name = pop @parts;
    my $namespace = join '/', @parts if @parts;
    my $attributes_scope = "${i18n_scope}.errors.models";
    if($namespace) {
      @defaults = map {
        my $class = $_;
        "${attributes_scope}.${\$class->model_name->i18n_key}/${namespace}.attributes.${attribute_name}.format/@{[ $self->type ]}",
        "${attributes_scope}.${\$class->model_name->i18n_key}/${namespace}.attributes.${attribute_name}.format",
        "${attributes_scope}.${\$class->model_name->i18n_key}/${namespace}.format";      
      } grep { $_->model_name->can('i18n_key') } $object->i18n_lookup;
    } else {
      @defaults = map {
        my $class = $_;
        "${attributes_scope}.${\$class->model_name->i18n_key}.attributes.${attribute_name}.format/@{[ $self->type ]}",
        "${attributes_scope}.${\$class->model_name->i18n_key}.attributes.${attribute_name}.format",
        "${attributes_scope}.${\$class->model_name->i18n_key}.format";    
      } grep { $_->model_name->can('i18n_key') } $object->i18n_lookup;
    }
  }

  @defaults = map { $i18n->make_tag($_) } @defaults;

  push @defaults, $i18n->make_tag("errors.format.attributes.${attribute}"); # This isn't in Rails but I find it useful
  push @defaults, $i18n->make_tag("errors.format");

  # This last one 
  push @defaults, $self->default_format;

  # We do this dance to cope with nested attributes like 'user.name'.
  my $attr_name = do {
    my $human_attr = $attribute;
    $human_attr =~s/\./ /g;
    $human_attr =~s/_id$//; # remove trailing _id
    $human_attr =~s/_/ /g;
    $human_attr = autoformat $human_attr, {case=>'title'};
    $human_attr =~s/[\n]//g; # Is this a bug in Text::Autoformat???
    $human_attr;
  };
  
  $attr_name = $object->human_attribute_name($attribute, +{default=>$attr_name});

  return my $translated = $i18n->translate(
    shift @defaults,
    default => \@defaults,
    attribute => $attr_name,
    message => $message
  );
}

# Generates a message part which is a text message of the error
# without the attribute or other bits. In rails this is a class
# method; I preserved the given API for now but for the most
# part you should just call ->message which does the right
# thing for this error (or ->full_message).  

sub generate_message {
  my ($self, $attribute, $type, $object, $options, $i18n) = @_;
  $i18n ||= Scalar::Util::blessed($self) ?
    $self->i18n :
    Module::Runtime::use_module($self->i18n_class);

  $options ||= +{};
  $type = delete $options->{message} if $i18n->is_i18n_tag($options->{message}||'');

  # There's only a value associated with this error if there is an attribute
  # as well.  Otherwise its just an error on the model as a whole
  my $value = defined($attribute) ? 
    $object->read_attribute_for_validation($attribute) :
    undef;

  my %options = (
    model => $object->model_name->human,
    attribute => defined($attribute) ? $object->human_attribute_name($attribute, $options) : undef,
    value => $value,
    object => $object,
    %{$options||+{}},
  );

  my @defaults = ();
  if($object->can('i18n_scope')) {
    my $i18n_scope = $object->i18n_scope;
    my $local_attribute;
    if(defined $attribute) {
      $local_attribute = $attribute if defined $attribute;
      $local_attribute =~s/\[\d+\]//g;
    }

    @defaults = map {
      my $class = $_;
      (defined($local_attribute) ? "${i18n_scope}.errors.models.${\$class->model_name->i18n_key}.attributes.${local_attribute}.${$type}" : ()),
      "${i18n_scope}.errors.models.${\$class->model_name->i18n_key}.${$type}";      
    } grep {
      $_->model_name->can('i18n_key')
    } $object->i18n_lookup if $object->can('i18n_lookup');
    push @defaults, "${i18n_scope}.errors.messages.${$type}";
  }

  push @defaults, "errors.attributes.${attribute}.${$type}" if defined($attribute);
  push @defaults, "errors.messages.${$type}";

  @defaults = map { $i18n->make_tag($_) } @defaults;

  my $key = shift(@defaults);
  if($options->{message}) {
    my $message = delete $options->{message};
    @defaults = ref($message) ? @$message : ($message);
  }
  $options{default} = \@defaults;
  return my $translated = $i18n->translate($key, %options);
}

sub message {
  my $self = shift;
  my $type = exists($self->options->{message}) ? $self->options->{message} : $self->raw_type;
  
  if($self->i18n->is_i18n_tag($type)) {
    my %options = %{$self->options};
    delete @options{@CALLBACKS_OPTIONS};
    return $self->generate_message($self->attribute, $type, $self->object, \%options);
  } elsif((ref($type)||'') eq 'CODE') {
    my $attribute = $self->attribute;
    my $value = defined($attribute) ? $self->object->read_attribute_for_validation($attribute) : undef;
    my %options = (
      model => $self->object->model_name->human,
      attribute => defined($attribute) ? $self->object->human_attribute_name($attribute, $self->options) : undef,
      value => $value,
      object => $self->object,
      %{$self->options||+{}},
    );
    delete @options{@CALLBACKS_OPTIONS, @MESSAGE_OPTIONS};
    my $return = $type->($self->object, $attribute, $value, \%options);
    # Allow a coderef to either return a straight up string or a translation tag
    return $self->i18n->is_i18n_tag($return) ?
      $self->generate_message($self->attribute, $return, $self->object, \%options) :
      $return;
  } elsif((ref($type)||'') eq 'SCALAR') {
    my $attribute = $self->attribute;
    my $value = defined($attribute) ? $self->object->read_attribute_for_validation($attribute) : undef;
    my %options = (
      model => $self->object->model_name->human,
      attribute => defined($attribute) ? $self->object->human_attribute_name($attribute, $self->options) : undef,
      value => $value,
      object => $self->object,
      %{$self->options||+{}},
    );
    delete @options{@CALLBACKS_OPTIONS, @MESSAGE_OPTIONS};

    my $translated = $$type;
    $translated =~ s/\{\{([^}]+)\}\}/ defined($options{$1}) ? $options{$1} : '' /gex;
    return $translated;
  } else {
    # Its just a plain string
    return $type;
  }
}

sub detail {
  my $self = shift;
  my %options = %{$self->options};
  delete @options{@CALLBACKS_OPTIONS, @MESSAGE_OPTIONS};
  return +{
    error => $self->raw_type,
    %options,
  };
}

# This match returns true if at least some bits match
sub match {
  my ($self, $attribute, $type, $options) = @_;
  if(
    ($attribute||'') ne ($self->attribute||'')
    ||
    ($type && ($self->type ne $type))
  ) {
    return 0;
  }

  # only the passed options need to match.  So if there's options
  # in the error object that are not in the passed options its
  # still ok to match.
  foreach my $key (%{$options||+{}}) {
    if( ($self->options->{$key}||'') ne ($options->{$key}||'')) {
      return 0;
    }
  }
  return 1;
}

sub clone {
  my $self = shift;
  my $class = ref $self;
  return $class->new(
    object => $self->object,
    attribute => $self->attribute,
    type => $self->type,
    i18n => $self->i18n,
    options => $self->options,
  );
}

sub strict_match {
  my ($self, $attribute, $type, $options) = @_;
  return 0 unless $self->match($attribute, $type);

  # This is different from match because ALL the keys/values in options need to match
  # exactly.  Its possible my approach here is suspect around object comparisons.
  my %options = %{$self->options};
  delete @options{@CALLBACKS_OPTIONS, @MESSAGE_OPTIONS};

  return FreezeThaw::cmpStr(\%options, $options) == 0 ? 1:0;
}

# Are two errors the same?
sub equals {
  my ($self, $target) = @_;

  return 0 unless ref($self) eq ref($target);

  my $a = FreezeThaw::freeze $self->attributes_for_hash;
  my $b = FreezeThaw::freeze $target->attributes_for_hash;

  return $a eq $b;
}

sub hash {
  my $self = shift;
  return +{ $self->attributes_for_hash };
}

sub attributes_for_hash {
  my $self = shift;
  my %options = %{$self->options};
  delete @options{@CALLBACKS_OPTIONS};

  return (
    object => $self->object,
    attribute => $self->attribute,
    raw_type => $self->raw_type,
    map { $_ => $options{$_} } sort keys %options, # This needs sorting to support checking equality
  );
}

=head1 NAME

Valiant::Error - A single error encountered during validation.

=head1 SYNOPSIS

    This won't be used standalone.  Its always a collection of Error objects
    inside the Valiant::Errors module.

=head1 DESCRIPTION

A Single Error.

This is generally an internal class and you are unlikely to use it directly.  For
the most part its used by L<Valiant::Errors>.

=head1 ATTRIBUTES

This class defines the following attributes

=head2 type

Either a translation tag or text string of the error

=head2 attribute

The attribute which is associated with the error or undef if the error
is for the model

=head1 METHODS

This class exposes the following methods for public users.

=head2 match ($attribute, $type, $options)

Returns true of the error matches (has the same parameters) as the arguments 
passed.  This differs from L</strict_match> in that C<$options> don't need to
be completely identical; it must ony be the case that the C<$options> passed
in the arguments intersects with that actual options of the error (that is
the error has to have everything in C<$options> BUT it can have more things.

=head2 strict_match ($attribute, $type, $options)

Same as L</match> except <$options> must exactly match and not just intersect.

=head2 equals ($error)

Returna a boolean based on if C<$error> is functionally equal.  By this it is meant
that it has the same attribute values (not that it is the same error instance).

This includes C<options> matching.

=head2 clone

Create a new copy of the error.

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::Errors>.

=head1 AUTHOR
 
See L<Valiant>  
    
=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut

1;
