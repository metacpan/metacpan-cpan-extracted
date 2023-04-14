package Valiant::HTML::Util::Form;

use Moo;
use Scalar::Util;
use Module::Runtime;
use Valiant::Naming;
use Carp;

extends 'Valiant::HTML::Util::FormTags';

has 'context' => (is=>'ro', required=>0, predicate=>'has_context');  # For the future
has 'controller' => (is=>'ro', required=>0);  # For the future

has 'form_with_generates_ids' => (
  is => 'ro', 
  required => 1,
  builder => '_form_with_generates_ids'
);

  sub _form_with_generates_ids { 0 }

has 'formbuilder_class' => (
  is => 'ro',
  required => 1,
  lazy => 1,
  builder => '_default_formbuilder_class',
);

  sub _default_formbuilder_class {
    my $self = shift;
    return $self->view->formbuilder_class if $self->view->can('formbuilder_class');
    return 'Valiant::HTML::FormBuilder';
  };

# for class and subclasses

sub _DEFAULT_ID_DELIM { '_' }

sub _dom_class {
  my ($self, $model, $prefix) = @_;
  my $singular = $self->_model_name_from_object_or_class($model)->param_key;
  return $prefix ? "${prefix}@{[ _DEFAULT_ID_DELIM ]}${singular}" : $singular;
}

sub _dom_id {
  my ($self, $model, $prefix) = @_;
  if(my $model_id = _model_id_for_dom_id($model)) {
    return "@{[ $self->_dom_class($model, $prefix) ]}@{[ _DEFAULT_ID_DELIM ]}${model_id}";
  } else {
    $prefix ||= 'new';
    return $self->_dom_class($model, $prefix)
  }
}

sub _model_id_for_dom_id {
  my $model = shift;
  return unless $model->can('id') && defined($model->id);
  return join '_', ($model->id);
}

sub _to_model {
  my ($self, $model) = @_;
  return $model->to_model if $model->can('to_model');
  return $model;
}


sub _model_name_from_object_or_class {
  my ($self, $proto) = @_;
  my $model = $self->_to_model($proto);
  return $model->model_name if $model->can('model_name');
  return Valiant::Name->new(Valiant::Naming::prepare_model_name_args($model));
}

sub _apply_form_options {
  my ($self, $model, $options) = @_;
  $model = $self->_to_model($model);

  my $as = exists $options->{as} ? $options->{as} : undef;
  my $namespace = exists $options->{namespace} ? $options->{namespace} : undef;
  my ($action, $method) = @{ $self->model_persisted($model) ? ['edit', 'patch']:['new', 'post'] };

  $options->{html} = $self->_merge_attrs(
    ($options->{html} || +{}),
    +{
      class => $as ? "${action}_${as}" : $self->_dom_class($model, $action),
      id => join(_DEFAULT_ID_DELIM, ( $as ? (grep { defined $_ } $namespace, $action, $as)  :  (grep { defined $_ } ($namespace, $self->_dom_id($model, $action))) )),
      method => $method,
    },
  );

  return $options;
}

# public methods

sub model_persisted {
  my ($self, $model) = @_;
  return $model->persisted if $model->can('persisted');
  return $model->in_storage if $model->can('in_storage');
  return 0;
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
  my $self = shift;
  my $proto = shift; # required; at the start
  my $content_block_coderef = pop; # required; at the end
  my $options = ref($_[-1]||'') eq 'HASH' ? pop : +{};

  carp "You must provide a content block to form_for" unless ref($content_block_coderef) eq 'CODE';

  my ($model, $object_name);
  if( ref(\$proto) eq 'SCALAR') {
    $object_name = $proto;
    if(@_) {
      $model = shift;
    } else {
    $model = $self->view->read_attribute_for_html($object_name)
      if $self->view->attribute_exists_for_html($object_name);
    }
  } elsif(Scalar::Util::blessed($proto)) {
    $model = $proto;
    $object_name = exists $options->{as} ?
      $options->{as} :
        $self->_model_name_from_object_or_class($model)->param_key;
  }

  $options->{model} = $model;
  $options->{scope} = $object_name;
  $options->{skip_default_ids} = 0;
  $options->{allow_method_names_outside_object} = exists $options->{allow_method_names_outside_object} ?
    $options->{allow_method_names_outside_object} : 0;

  return $self->form_with($options, $content_block_coderef);
}

sub form_with {
  my $self = shift;
  my $content_block_coderef = pop; # required; at the end
  my $options = @_ ? shift : +{};
  my $scope = exists $options->{scope} ? $options->{scope} : undef;

  $options->{allow_method_names_outside_object} = 1;
  $options->{skip_default_ids} = 0;

  my ($model, $url);
  if($options->{model}) {
    $model = $self->_to_model(delete $options->{model});
    $scope = exists $options->{scope} ?
      delete $options->{scope} :
        $self->_model_name_from_object_or_class($model)->param_key;

    $options->{as} = $scope unless exists $options->{as};

    $self->_apply_form_options($model, $options);
  
    # TODO: This it where we need to be able to get a url from the model
    # for the builder.  Either the model itself should have a way to do
    # this or possible the controller ($url = $self->controller->url_for_model($model))
    # this method should DTRT in generating a url for a new or existing model and
    # should be able to be overridden by args passed.
  }

  $url ||= delete $options->{url} if exists $options->{url};

  my $builder = $self->_instantiate_builder($scope, $model, $options);
  my $html_options = $self->_html_options_for_form_with($url, $model, $options);
  my $output = $self->join_tags(
    $self->form_tag($html_options, sub {
      my @form_node = $content_block_coderef->($self->view, $builder, $model);
      return $builder->view->safe_concat(@form_node);
    })
  );

  return $output;
}

# _instantiate_builder($object)
# _instantiate_builder($object, \%options)
# _instantiate_builder($name, $object)
# _instantiate_builder($name, $object, \%options)

sub _instantiate_builder {
  my $self = shift;
  my $options = (ref($_[-1])||'') eq 'HASH' ? pop(@_) : +{};
  my $object = Scalar::Util::blessed($_[-1]) ? pop(@_) : bless +{}, 'Valiant::HTML::FormBuilder::DefaultModel';
  my $model_name = scalar(@_) ? shift(@_) : $self->_model_name_from_object_or_class($object)->param_key;
  my $builder = exists($options->{builder}) && defined($options->{builder}) ? 
    $options->{builder} :
      $self->formbuilder_class;

  my %args = (
    tag_helpers => $self,
    model => $object,
    name => $model_name,
    options => $options
  );

  $options->{builder} = $builder;
  $self->_merge_attrs(\%args, $options, qw(namespace id index parent_builder theme));

  if( exists($options->{parent_builder}) && exists($options->{parent_builder}{theme}) ) {
    $args{theme} = +{ %{$args{theme}||+{}}, %{$options->{parent_builder}{theme}} };
  }

  return Module::Runtime::use_module($builder)->new(%args);
}

sub _html_options_for_form_with {
  my ($self, $url, $model, $options) = @_;  
  my $html_options = $options->{html} || +{};

  $self->_merge_attrs($html_options, $options, qw(action method data id csrf_token class style));

  $html_options->{action} = $url if $url;
  $html_options->{csrf_token} ||= $self->view->csrf_token if $self->view->can('csrf_token');
  $html_options->{csrf_token} ||= $self->context->csrf_token if $self->has_context && $self->context->can('csrf_token');
  $html_options->{tunneled_method} = 1 unless exists $html_options->{tunneled_method};
  $html_options->{method} = lc($html_options->{method}||'post'); # most common standards specify lowercase

  # This is what Rails does but not sure I want to force that.  It might break a
  # lot of existing code people try to shoehorn this stuff into.  
  # $html_options->{enctype} ||= $html_options->{method} eq 'get' ?
  #  'application/x-www-form-urlencoded' :
  #    'multipart/form-data';

  return $html_options;
}

sub fields_for {
  my $self = shift;
  my ($name, $model);
  my $proto = shift;

  if( Scalar::Util::blessed $proto ) {
    $model = $proto;
  } else {
    $name = $proto;
    if( @_ && Scalar::Util::blessed($_[0]) ) {
      $model = shift;
    } else {
      $model = $self->view->read_attribute_for_html($proto)
        if $self->view->attribute_exists_for_html($proto);
    }
  }
  my $block = pop @_;
  my $options = @_ ? shift(@_) : +{};

  $options = {
    model => $model, 
    allow_method_names_outside_object => 0, 
    skip_default_ids => 0, 
    %$options
  };

  return $self->fields($name, $options, $block);
}

sub _object_for_form_builder {
  my ($self, $object) = @_;
  return $object if Scalar::Util::blessed($object);
  ## in Rails this returns a single model object when $object is an arrayref
  ## but I don't think that makes sense here at least for the moment.
  die "Missing required object";
}

sub fields {
  my ($self, $scope, $options, $block) = @_;

  $options = {
    allow_method_names_outside_object => 1, 
    skip_default_ids => $self->form_with_generates_ids, 
    %{$options||+{}},
 };

  if ($options->{model}) {
    my $model = $self->_to_model($self->_object_for_form_builder($options->{model}));
    $scope ||= $self->_model_name_from_object_or_class($model)->param_key;
  }

  my $builder = $self->_instantiate_builder($scope, $options->{model}, $options);
  my $output = $self->join_tags($block->($self->view, $builder));

  return $output;
}

1;

=head1 NAME

Valiant::HTML::Util::Form - HTML Form 

=head1 SYNOPSIS

Given a model like:

    package Person;

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

    use Valiant::HTML::Util::Form;

    my $f = Valiant::HTML::Util::Form->new()
    my $person = Local::Person->new(first_name=>'J', last_name=>'Napiorkowski');
    $person->validate;

    $f->form_for($person, sub($fb, $person) {
      return  $fb->label('first_name'),
              $fb->input('first_name'),
              $fb->errors_for('first_name', +{ class=>'invalid-feedback' }),
              $fb->label('last_name'),
              $fb->input('last_name'),
              $fb->errors_for('last_name'+{ class=>'invalid-feedback' });
    });

Generates something like:

    <form accept-charset="UTF-8" class="new_person" enctype="multipart/form-data" id="new_person" method="post">
      <label for="person_first_name">First Name</label>
      <input id="person_first_name" name="person.first_name" type="text" value="John"/>
      <div class='invalid-feedback'>First Name is too short (minimum is 3 characters).</div>
      <label for="person_last_name">Last Name</label>
      <input id="person_last_name" name="person.last_name" type="text" value="Napiorkowski"/>
    </form>

=head1 DESCRIPTION

Builds on L<Valiant::HTML::Util::TagBuilder> and L<Valiant::HTML::Util::FormTags> to provide a
wrapper around a model object that can be used to generate HTML form controls via a formbuilder
such as L<Valliant::HTML::FormBuilder>. or a subclass thereof.

Like its parent classes, you can provide a view context to the constructor and it will be used
to provide attribute values as well as methods used to create safe strings.  This is documented
extensively in L<Valiant::HTML::Util::TagBuilder> which you should review if you are creating 
your own view integration.  You can see an example view context in L<Valiant::HTML::Util::View>.

=head1 INHERITED METHODS

This class inherits all methods from L<Valiant::HTML::Util::TagBuilder> and 
L<Valiant::HTML::Util::FormTags>.

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

=head2 is_attribute_changed

    $model->is_attribute_changed($attr); # true or false

Optional method.  If provided returns a boolean if the attribute has been changed from its initial state,
as defined by either being different from the backing store (if it exists) or being changed from its default
value when created as a new model.

=head2 human_attribute_name

    $model->human_attribute_name('user'); # User 

Optional.  If provided, uses the model to look up a displayable version of the attribute name, for
example used in a label for an input control.  If not present we use L<Valiant::HTML::FormTags\_humanize>
to create a displayable name from the attribute name.

=head2 read_attribute_for_html

    $model->read_attribute_for_html('user'); # User 

Optional.  If provided must access the string name of the field or attribute and should return the model
value for that attribute suitable for HTML form display.  You might wish to use this as a way to deflate
or otherwise stringify non string values.  If not provided we just use the attribute name and call it as an
accessor against the model.

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

=head1 INSTANCE METHODS 

The following public instance methods are provided by this class.

=head2 form_for

    $f->form_for($name, $model, \%options, \&block);
    $f->form_for($model, \%options, \&block);
    $f->form_for($model, \&block);
    $f->form_for($name, \%options, \&block);
    $f->form_for($name, \&block);

Canonical xample.  C<$person> is either an object or the name of an attribute on the C<$view> that
will supply the object.

    $f->form_for($person, sub($fb, $person) {
      return  $fb->label('name'),
              $fb->input('name');
    });

    # Generates something like:

    <form accept-charset="UTF-8" class="new_person" enctype="multipart/form-data" id="new_person" method="post">
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
create your own formbuilder subclass and want to use that.  If you don't provide a value
we also check the attached view object for a C<formbuilder_class> method and use that if it
exists.

=item csrf_token

Optional.  If provided, will be used to generate a hidden field with the name C<csrf_token>.
This is useful for CSRF protection.  If you don't provide a value we will try to use the
C<csrf_token> method on the current view object.  If that doesn't exist we will try to use
the C<csrf_token> method on the current context object (if one exists).  If you are using
L<Catalyst> with this you can use L<Catalyst::Plugin::CSRFToken> to generate a token.

=back

The last argument should be a reference to a subroute that will receive the created formbuilder
object and should return a string, or array of strings that will be flattened and displayed as
your form elements.  Any strings returns not marked as C<safe> via L<Valiant::HTML::SafeString> will
be encoded and turned safe so be sure to mark any raw strings correctly unless you want double
encoding issues.

You can also provide a string as the first argument to this method and it will be used to set the
overall scope of the formbuilder.  This is useful if you want to use the same formbuilder for
multiple models.  For example:

    $f->form_for('person', sub($fb, $person) {
      $fb->input('name');
    });

    $f->form_for('address', sub($fb, $address) {
      $fb->input('street');
    });

    # Generates something like:

    <form accept-charset="UTF-8" class="new_person" enctype="multipart/form-data" id="new_person" method="post">
      <input id="person_name" name="person.name" type="text" value="John"/>
    </form>

    <form accept-charset="UTF-8" class="new_address" enctype="multipart/form-data" id="new_address" method="post">
      <input id="address_street" name="address.street" type="text" value="123 Main St"/>
    </form>

If the string name refers to an attribute on the current view object that attribute will be used
to provide model data.   Lastly you can pass both a string name and a model object and the string
name will be used to set the scope of the formbuilder and the model object will be used to provide
the model data.

Example:

    $f->form_for('foo', $person, sub($fb, $person) {
      return  $fb->label('name'),
              $fb->input('name');
    });

    # Generates something like:

    <form accept-charset="UTF-8" class="new_foo" enctype="multipart/form-data" id="new_foo" method="post">
      <label for="foo_name">Name</label>
      <input id="foo_name" name="foo.name" type="text" value="John"/>
    </form>

=head2 fields_for

    $f->fields_for($name, $model, \%options, \&block);
    $f->fields_for($model, \%options, \&block);
    $f->fields_for($model, \&block);
    $f->fields_for($name, \%options, \&block);
    $f->fields_for($name, \&block);

Create an instance of a formbuilder that represents a model or a namespace in which to build
form elements.  Its basically <form_for> without the C<form> tag.  This is useful for building
nested forms or for building forms that are not the top level form.

Examples:

    $f->fields_for($person, sub {
      my ($fb) = @_;
      return $fb->input('first_name'),
    });

    # <input id="person_first_name" name="person.first_name" type="text" value="aa"/>

    # Assume that the view has a $person attribute
    $f->fields_for('person', sub {
      my ($fb) = @_;
      return $fb->input('first_name'),
    });

    # <input id="person_first_name" name="person.first_name" type="text" value="aa"/>

    $f->fields_for('foo', $person, sub {
      my ($fb) = @_;
      return $fb->input('first_name'),
    });

    # <input id="foo_first_name" name="foo.first_name" type="text" value="aa"/>

    # In this case there is no model for the values or errors, we're just using the
    # formbuilder to generate the correct names and ids for an empty form.

    $f->fields_for('foo', sub {
      my ($fb) = @_;
      return $fb->input('first_name'),
    });

    # <input id="foo_first_name" name="foo.first_name" type="text" value=""/>
}

done_testing;

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::HTML::FormBuilder>, L<Valiant::HTML::Util::FormTags>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
