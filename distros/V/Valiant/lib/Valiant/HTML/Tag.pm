package Valiant::HTML::Tag;

use Moo;

# Not going to worry about @generate_indexed_names or @auto_index for now and
# just assume they are always false

has 'model_name' => (is=>'ro', coerce=>sub { $_[0]=~s/\[\]$// || $_[0]=~s/\[\]\]$/]/; $_[0]  }, required=>1);
has 'method_name' => (is=>'ro', required=>1);
has 'tag_helpers' => (is=>'ro', required=>1);
has 'options' => (is=>'ro', required=>1, default=>sub { +{} });

has 'model' => (
  is=>'ro',
  required => 1,
  lazy => 1,
  builder => '_build_model',
);

  sub _build_model {
    my $self = shift;
    $self->_retrieve_object(delete $self->options->{model});
  }

has 'skip_default_ids' => (
  is=>'ro',
  required => 1,
  lazy => 1,
  builder => '_skip_default_ids',
);

  sub _skip_default_ids { return delete($_[0]->options->{skip_default_ids}) ? 1:0 }

has 'allow_method_names_outside_model' => (
  is=>'ro',
  required => 1,
  lazy => 1,
  builder => '_allow_method_names_outside_model',
);

  sub _allow_method_names_outside_model { return delete($_[0]->options->{allow_method_names_outside_model}) ? 1:0 }

sub _retrieve_object {
  my ($self, $object) = @_;
  if ($object) {
    return $object;
  } elsif ($self->tag_helpers->attribute_for_view_exists($self->model_name)) {
    $object = $self->tag_helpers->read_attribute_for_view($self->model_name);
    return $object if defined($object);
    return bless +{}, 'Valiant::HTML::Tag::DefaultModel';
  }
}

sub render { die "Not implemented!" }

sub value {
  my $self = shift;
  my $method_name = $self->method_name;
  if($self->allow_method_names_outside_object){
    $self->model->$method_name if $self->has_model && $self->model->can($method_name);
  } else {
    $self->model->$method_name if $self->has_model;
  }
  return '';
}

1;

=head1 NAME

Valiant::HTML::Tag - Base class for tag objects

=head1 SYNOPSIS

    TBD

=head1 DESCRIPTION

    TBD

=head1 CLASS METHODS

This package exposes the folllowing class methods

=head1 ATTRIBUTES

This class has the following initialization attributes

=head2 skip_default_ids

Defaults to false.  Generally we create an html C<id> attribute for the field based
on a convention which includes the model name, index and method name.  Setting this
to true prevents that so you should set C<id> manually unless you don't want them.
Please note that even if this is false, you can always override the C<id> on a per
field basis by setting it manually.

=head2 allow_method_names_outside_model

Default is false.  Generally we expect C<method_name> to be an actual method on the
C<model> and if its not we expect an exception.  This helps to prevent typos from
leading to unexpected results.  However sometimes you may wish create a form field that
has a name that isn't on the model but still respects the current namespace and index.
These names would appear in the POST request body and could be used for things other than
updating or creating a model.


=head1 INSTANCE METHODS

This package exposes the folllowing instance methods


=head1 SEE ALSO
 
L<Valiant>, L<Valiant::HTML::FormBuilder>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
