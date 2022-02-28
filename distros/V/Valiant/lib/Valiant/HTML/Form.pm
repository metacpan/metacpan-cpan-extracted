package Valiant::HTML::Form;

use warnings;
use strict;
use Exporter 'import'; # gives you Exporter's import() method directly
use Valiant::HTML::FormTags ();
use Scalar::Util (); 
use Module::Runtime ();
use URI;

our @EXPORT_OK = qw(form_for fields_for);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub _default_formbuilder_class { 'Valiant::HTML::FormBuilder' };
sub _DEFAULT_ID_DELIM { '_' }

# _instantiate_builder($object)
# _instantiate_builder($object, \%options)
# _instantiate_builder($name, $object)
# _instantiate_builder($name, $object, \%options)
sub _instantiate_builder {
  my $options = (ref($_[-1])||'') eq 'HASH' ? pop(@_) : +{};
  my $object = Scalar::Util::blessed($_[-1]) ? pop(@_) : die "Missing required object";
  my $model_name = scalar(@_) ? pop(@_) : _model_name_from_object_or_class($object)->param_key;
  my $builder = exists($options->{builder}) && defined($options->{builder}) ? $options->{builder} :  _default_formbuilder_class;
  $options->{builder} = $builder;
  
  my %args = (
    model => $object,
    name => $model_name,
    options => $options
  );

  $args{namespace} = $options->{namespace} if exists $options->{namespace};
  $args{id} = $options->{id} if exists $options->{id};
  $args{index} = $options->{index} if exists $options->{index};
  return Module::Runtime::use_module($builder)->new(%args);
}

sub _model_name_from_object_or_class {
  my $proto = shift;
  my $model = $proto->can('to_model') ? $proto->to_model : $proto;
  return $model->model_name;
}

sub _apply_form_options {
  my ($model, $options) = @_;
  $model = $model->to_model if $model->can('to_model');

  my $as = exists $options->{as} ? $options->{as} : undef;
  my $namespace = exists $options->{namespace} ? $options->{namespace} : undef;
  my ($action, $method) = @{ $model->can('in_storage') && $model->in_storage ? ['edit', 'patch']:['new', 'post'] };

  $options->{html} = Valiant::HTML::FormTags::_merge_attrs(
    ($options->{html} || +{}),
    +{
      class => $as ? "${action}_${as}" : _dom_class($model, $action),
      id => ( $as ? [ grep { defined $_ } $namespace, $action, $as ] : join('_', grep { defined $_ } ($namespace, _dom_id($model, $action))) ),
      method => $method,
    },
  );
}

sub _dom_class {
  my ($model, $prefix) = @_;
  my $singular = _model_name_from_object_or_class($model)->param_key;
  return $prefix ? "${prefix}@{[ _DEFAULT_ID_DELIM ]}${singular}" : $singular;
}

sub _dom_id {
  my ($model, $prefix) = @_;
  if(my $model_id = _model_id_for_dom_id($model)) {
    return "@{[ _dom_class($model, $prefix) ]}@{[ _DEFAULT_ID_DELIM ]}${model_id}";
  } else {
    $prefix ||= 'new';
    return _dom_class($model, $prefix)
  }
}

sub _model_id_for_dom_id {
  my $model = shift;
  return unless $model->can('id') && defined($model->id);
  return join '_', ($model->id);
}

# form_for $model, \%options, \&block
# form_for $model, \&block
#
# Where %options are:
# action: actual url the action.  not required
# method: default is POST
# namespace: additional prefix for form and element IDs for uniqueness.  not required
# html: additional hash of values for html attributes

sub form_for {
  my $model = shift; # required; at the start
  my $content_block_coderef = pop; # required; at the end
  my $options = @_ ? shift : +{};
  my $model_name = exists $options->{as} ? $options->{as} : _model_name_from_object_or_class($model)->param_key;
  
  _apply_form_options($model, $options);

  my $html_options = $options->{html};
  my @extra_classes = ();

  $html_options->{action} = $options->{action} if exists $options->{action} and !exists($html_options->{action});
  $html_options->{method} = $options->{method} if exists $options->{method} and !exists($html_options->{method});;
  $html_options->{method} = lc($html_options->{method}); # most common standards specify lowercase
  $html_options->{data} = $options->{data} if exists $options->{data};
  $html_options->{class} = join(' ', (grep { defined $_ } $html_options->{class}, $options->{class}, @extra_classes)) if exists($options->{class}) || @extra_classes;
  $html_options->{style} = join(' ', (grep { defined $_ } $html_options->{style}, $options->{style})) if exists $options->{style};

  if( ($html_options->{method} ne 'get') && ($html_options->{method} ne 'post') ) {
    my $uri = URI->new( $html_options->{action}||'' );
    my $params = $uri->query_form_hash;

    $params->{'x-tunneled-method'} = $html_options->{method} unless exists($params->{'x-tunneled-method'});
    $uri->query_form($params);

    $html_options->{action} = $uri;
    $html_options->{method} = 'post';
  }

  my $builder = _instantiate_builder($model_name, $model, $options);

  return Valiant::HTML::FormTags::form_tag $html_options, sub { 
    return Valiant::HTML::FormTags::capture($content_block_coderef, $builder);
  };
}

#fields_for($name, $model, $options, sub {

sub fields_for {
  my ($name, $model, $options, $block) = @_;
  my $builder = _instantiate_builder($name, $model, $options);
  return Valiant::HTML::FormTags::capture($block, $builder); 
}

1;

=head1 NAME

Valiant::HTML::Form - HTML Form 

=head1 SYNOPSIS

Given a model like:

    package Local::Person;

    use Moo;
    use Valiant::Validations;

    has first_name => (is=>'ro');
    has last_name => (is=>'ro');

    validates ['first_name', 'last_name'] => (
      length => {
        maximum => 20,
        minimum => 3,
      }
    );

Wrap a formbuilder object around it and generate HTML form field controls:

    use Valiant::HTML::Form 'form_for';

    my $person = Local::Person->new(first_name=>'J', last_name=>'Napiorkowski');
    $person->validate;

    form_for($person, sub($fb) {
      return  $fb->label('first_name'),
              $fb->input('first_name'),
              $fb->errors_for('first_name', +{ class=>'invalid-feedback' }),
              $fb->label('last_name'),
              $fb->input('last_name'),
              $fb->errors_for('last_name'+{ class=>'invalid-feedback' });
    });

Generates something like:

    <form accept-charset="UTF-8" id="new_person" method="post">
      <label for="person_first_name">First Name</label>
      <input id="person_first_name" name="person.first_name" type="text" value="John"/>
      <div class='invalid-feedback'>First Name is too short (minimum is 3 characters).</div>
      <label for="person_last_name">Last Name</label>
      <input id="person_last_name" name="person.last_name" type="text" value="Napiorkowski"/>
    </form>

=head1 DESCRIPTION

Export helper methods to properly create instances of L<Valiant::HTML::FormBuilder> that
will also wrap the builder in proper C<form> tags.

Its possible other methods will move here from L<Valiant::HTML::FormBuilder> to make it
easier for people to build form tags without needed to create a full on builder.   Please
make you requests and demonstrated use cases in a ticket.

=head1 REQUIRED MODEL API

This (and L<Valiant::HTML::FormBuilder>) wrap an object model that is expected to do the following
interface.

=head2 to_model

This is an optional method.  If this is supported, we call C<to_model> on the wrapped object
before using it on the form methods.  This allows you to delegate the required API to a secondard
object, which can result in a cleaner API depending on your designs and use cases.

=head2 in_storage

This is an optional method.  If your object has a backing storage solution (such as your object
is an instance of a DBIC Result Source) you can provide this method to influence how your object
form tags are created.   If provided this method should return a boolean when if true means that
the object is representing data which is stored in the backing storage solution.  Please note that
this does not mean that the object is synchronized with the backing storage since its possible that
the object has been changed by the user.

=head2 human_attribute_name

Optional.  If provided, uses the model to look up a displayable version of the attribute name, for
example used in a label for an input control.  If not present we use L<Valiant::HTML::FormTags\_humanize>
to create a displayable name from the attribute name.

=head2 errors

Optional. Should return an instances of L<Valiant::Errors>.  If present will be used to lookup model and
attribute errors.

Please note this currently is tried to behavior expected from L<Valiant::Errors> but in the future
we might try to make this tied to a defined interface rather than this concrete class.

=head2 has_errors

Optional if you don't use builder methods that are for displaying errors; required otherwise.  A boolean
that indicates if your model has errors or not.  Used to determined if C<error_classes> are merged into
C<class> and in a few similar places.

=head2 i18n

Optional. If provided should return an instance of L<Valiant::I18N>.   Used in a few places to support
translation tags.

=head2 model_name

Optional.  If provide should return an instance of L<Valiant::Name>.   Used in a few places where we
default a value to a human readable version of the model name.   If you don't have this method we
fall back to guessing something based on the string name of the model.

=head2 primary_columns 

Optional.  When a model does C<in_storage> and its a nested model, when this method exists we use it to
get a list of primary columns for the underlying storage and then add them as hidden fields.  This is
needed particularly with one - many style relationships so that we find the right record in the storage
model to update.

B<NOTE>: This method requirement is subject to change.  It feels a bit too tightly bound to the idea of
and ORM and to L<DBIx::Class> in particular. 

=head2 is_marked_for_deletion

Optional, but should be supported if your model supports a storage backend.  A boolean that indicates if
the model is currently marked for deletion upon successful validation.   Used for things like radio
and checkbox collections when the state should be 'unchecked' even if the model is still in storage.

=head1 EXPORTABLE FUNCTIONS

The following functions can be exported by this library

=head2 form_for

    form_for($person, sub($fb) {
      $fb->input('name');
      $fb->label('name');
    });

    # Generates something like:

    <form accept-charset="UTF-8" id="new_person" method="post">
      <label for="person_name">Name</label>
      <input id="person_name" name="person.name" type="text" value="John"/>
    </form>

Given a model as described above, wrap a L<Valiant::HTML::FormBuilder> instance around it which 
provides methods for generating valid HTML form output.  This provides a view logic centered
method for creating sensible and reusable form controls which include server generated error
output from validation.

See L<Valiant::HTML::FormBuilder> for more on the formbuilder API.

C<\%options> are used to influence the builder creation as well as pass attributes to the 
generated C<form> tag.   Options are as follows:

=over 4

=item as

Supplies the C<name> argument for L<Valiant::HTML::FormBuilder>.  This is generally used
to set the top namespace for your field IDs and C<name> attributes.

=item method

Sets the form attribute C<method>.   Generally defaults to C<post> or C<patch> (when C<in_storage>
is supported and the model is marked for updating of an existing model).  

=item action

Should be the URL that the form with post to.  

=item data

a hashref of HTML tag <data> attributes.

=item class

=item style

HTML attributes that get merged into the C<html> options (below)

=item html

a hashref of items that will get rendered as HTML attributes for the form.

=item namespace

Optional.  Can use used to prepend a namespace to your form IDs

=item index

Optional.  When processing a collection model this will be the index of the current
model.

=item builder

The form builder.   Defaults to L<Valiant::HTML::FormBuilder>.  You can set this if you
create your own formbuilder subclass and want to use that.

=back

The last argument should be a reference to a subroute that will receive the created formbuilder
object and should return a string, or array of strings that will be flattened and displayed as
your form elements.  Any strings returns not marked as C<safe> via L<Valiant::HTML::SafeString> will
be encoded and turned safe so be sure to mark any raw strings correctly unless you want double
encoding issues.

=head2 fields_for

    fields_for($sub_model_name, $model, $options, sub($fb) {
      $fb->input($field);
    });

Create an instance of a formbuilder that represents a sub model (that is a model with is associated
with a parent model under an attribute of that parent.

Unless you are doing very customized form generation you'll probably use this as a method of a formbuilder
such as L<Valiant::HTML::FormBuilder>.  However there was no reason for me to not expose the method
publically for users who need it.

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::HTML::FormBuilder>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
