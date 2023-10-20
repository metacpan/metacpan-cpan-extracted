package Valiant::HTML::Util::Pager;

use Moo;
use Scalar::Util;
use Module::Runtime;
use Valiant::Naming;
use Carp;

extends 'Valiant::HTML::Util::FormTags';

has 'context' => (is=>'ro', required=>0, predicate=>'has_context');
has 'controller' => (is=>'ro', required=>0, predicate=>'has_controller');

has 'pager_builder_class' => (
  is => 'ro',
  required => 1,
  lazy => 1,
  builder => '_default_pager_builder_class',
);

  sub _default_pager_builder_class {
    my $self = shift;
    return $self->view->pager_builder_class if $self->view->can('pager_builder_class');
    return 'Valiant::HTML::PagerBuilder';
  };

sub _to_model {
  my ($self, $model) = @_;
  croak "No model provided" unless $model;
  confess "Model is not an object: $model" unless Scalar::Util::blessed($model);
  return $model->to_model if $model->can('to_model');
  return $model;
}

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

sub _model_name_from_object_or_class {
  my ($self, $proto) = @_;
  my $model = $self->_to_model($proto);
  return $model->result_class->model_name if $model->can('model_name');
  return Valiant::Name->new(Valiant::Naming::prepare_model_name_args($model));
}

sub _object_from_record_proto {
  my ($self, $proto) = @_;
  croak "First argument can't be undef or empty string" unless defined($proto) && length($proto);
  return $proto->[-1] if ((ref($proto)||'') eq 'ARRAY');
  return $proto;
}

# ->pager_for($model|\@model_path, \%options, \&block)
# ->pager_for($model|\@model_path, \&block)
#
# Where %options are:
# as: 'name' # Use this name for the pager
# pager: the pager object (derived from model if not provided)

sub pager_for {
  my $self = shift;
  my $proto = shift; # required; at the start
  my $content_block_coderef = pop; # required; at the end

  my $empty_block_coderef;
  if(ref($_[-1]||'') eq 'CODE') {
    # ok so the second is for empty
    $empty_block_coderef = $content_block_coderef;
    $content_block_coderef = pop
  }

  my $options = ref($_[-1]||'') eq 'HASH' ? pop : +{};

  croak "You must provide a content block to pager_for" unless ref($content_block_coderef) eq 'CODE';

  my ($model, $object_name);

  if( ref(\$proto) eq 'SCALAR') {
    $object_name = $proto;  
    if(@_) {
      $model = shift;  # form_for 'name', $model, \%options, \&block
    } else {
      # Support form_for 'attribute_name', \%options, \&block 
      $model = $self->view->read_attribute_for_html($object_name)
        if $self->view->attribute_exists_for_html($object_name);
      die "Can't find model from view @{[ $self->view ]} for attribute '$object_name'" unless $model;
    }

    $options->{as} ||= $object_name if defined $model;

  } else {
    my $object = $self->_object_from_record_proto($proto); # Is either arrayref or object

    croak "First argument can't be undef or empty string" unless defined($object) && length($object);
    $model = $proto; # Is either arrayref or object
    $object_name = exists $options->{as} ?
      $options->{as} : $self->_model_name_from_object_or_class($object)->param_key;
    $self->_apply_pager_for_options($object, $options);
  }

  $options->{model} = $model;
  $options->{name} = $object_name;
  $options->{class} ||= $self->_dom_class($model, 'pager');
  $options->{id} ||= $self->_dom_id($model, 'pager');

  my $scope = exists $options->{scope} ?
    delete $options->{scope} :
    $self->_model_name_from_object_or_class($model)->param_key;
  my $model_path = ((ref($options->{model})||'') eq 'ARRAY') ? $options->{model} : [$options->{model}];
  $options->{uri_base} ||= $self->_polymorphic_path_for_model($model_path, $object_name, $options);

  my $builder = $self->_instantiate_builder($scope, $model, $options);
  if($builder->pager->total_entries > 0) {
    my $output = $self->join_tags(
      $self->tags->div(+{}, sub {
        my @form_node = $content_block_coderef->($self->view, $builder, $model);
        return $builder->view->safe_concat(@form_node);
      })
    );
    return $output;
  } else {
    if($empty_block_coderef) {
      return $self->tags->div(+{}, sub {
        my @node = $empty_block_coderef->($self->view, $model);
        return $builder->view->safe_concat(@node);
      });

    } else {
      return $self->tags->div(+{}, 'No entries found');
    }
  }
}

sub _polymorphic_path_for_model {
  my ($self, $model_path, $scope, $options) = @_;
  my $model = $model_path->[-1];
  my $scoped_method = "list_${scope}_uri";
  my $controller_method = "list_uri";

  return $self->view->list_uri_for_model($model_path, $scope) if $self->view->can('list_uri_for_model');
  return $self->controller->list_uri_for_model($model_path, $scope) if $self->has_controller && $self->controller->can('list_uri_for_model');
  return $self->context->list_uri_for_model($model_path, $scope) if $self->has_context && $self->context->can('list_uri_for_model');
  return $self->view->$scoped_method($model_path) if $self->view->can($scoped_method);
  return $self->controller->$scoped_method($model_path) if $self->has_controller && $self->controller->can($scoped_method);
  return $self->controller->$controller_method($model_path) if $self->has_controller && $self->controller->can($controller_method);

  return undef;
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
      $self->pager_builder_class;

  my %args = (
    tag_helpers => $self,
    model => $object,
    name => $model_name,
    uri_base => $options->{uri_base},
    options => $options
  );

  $options->{builder} = $builder;
  $self->_merge_attrs(\%args, $options, qw(id index parent_builder));

  if( exists($options->{parent_builder}) && exists($options->{parent_builder}{theme}) ) {
    $args{theme} = +{ %{$args{theme}||+{}}, %{$options->{parent_builder}{theme}} };
  }

  return Module::Runtime::use_module($builder)->new(%args);
}


1;

=head1 NAME

Valiant::HTML::Util::Pager- HTML pager 

=head1 SYNOPSIS

    TBD

=head1 DESCRIPTION

    TBF

=head1 INHERITED METHODS

This class inherits all methods from L<Valiant::HTML::Util::TagBuilder> and 
L<Valiant::HTML::Util::FormTags>.

=head1 CLASS METHODS

    TBD

=head2 Generating a URL for the action attribure

The following methods are used to generate the URL for the C<action> attribute of the form tag.  They
are tried in the following order:

    TBD

=head1 INSTANCE METHODS 

The following public instance methods are provided by this class.

    TBD


=head1 SEE ALSO
 
L<Valiant>, L<Valiant::HTML::PagerBuilder>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
