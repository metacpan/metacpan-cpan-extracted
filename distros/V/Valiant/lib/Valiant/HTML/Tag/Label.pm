package Valiant::HTML::Tag;

use Moo;

has 'model_name' => (is=>'ro', coerce=>sub { $_[0]=~s/\[\]$// || $_[0]=~s/\[\]\]$/]/; $_[0]  }, required=>1);
has 'method_name' => (is=>'ro', required=>1);
has 'view' => (is=>'ro', required=>1);
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


has 'allow_method_names_outside_object' => (
  is=>'ro',
  required => 1,
  lazy => 1,
  builder => '_allow_method_names_outside_object',
);

  sub _allow_method_names_outside_object { return delete($_[0]->options->{allow_method_names_outside_object}) ? 1:0 }


sub _retrieve_object {
  my ($self, $object) = @_;
  if ($object) {
    return $object;
  } elsif ($self->view->can("read_attribute_for_view")) {
    $object = $self->view->read_attribute_for_view($self->model_name);
    return $object if defined($object);
    die "Can't find model '@{[ $self->model_name ]}' in options or in view.";
  }
}

1;

=head1 NAME

Valiant::HTML::Tag - Base class for tag objects

=head1 SYNOPSIS

    TBD

=head1 DESCRIPTION

    TBD

=head1 CLASS METHODS

This class exposes the folllowing class methods

=head1 ATTRIBUTES

This class has the following initialization attributes

=head2 skip_default_ids

Defaults to false.  Generally we create an html C<id> attribute for the field based
on a convention which includes the model name, index and method name.  Setting this
to true prevents that so you should set C<id> manually unless you don't want them.
Please note that even if this is false, you can always override the C<id> on a per
field basis by setting it manually.

=head2 allow_method_names_outside_object

Default is false.  Generally we expect C<method_name> to be an actual method on the
C<model> and if its not we expect an exception.  This helps to prevent typos from
leading to unexpected results.  However sometimes you may wish create a form field that
has a name that isn't on the model but still respects the current namespace and index.
These names would appear in the POST request body and could be used for things other than
updating or creating a model.
<D-c><D-c><D-c>

=head1 INSTANCE METHODS

This class exposes the folllowing instance methods


=head1 SEE ALSO
 
L<Valiant>, L<Valiant::HTML::FormBuilder>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
