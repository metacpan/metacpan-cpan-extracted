{
  ##
  ## THIS IS HIGHLY EXPERIMENTAL TESTING CODE
  ##

  package Valiant::HTML::FormBuilderAdapter::Input;

  use Moo;

  has _fb => (is=>'ro', init_arg=>'fb', required=>1);
  has attribute_name => (is=>'ro', required=>1);
  has caller => (is=>'ro', required=>1);

  sub label {
    my ($self, @args) = @_;
    $self->_fb->label($self->attribute_name, @args);
  }
  sub input {
    my ($self, @args) = @_;
    $self->_fb->input($self->attribute_name, @args);
  }
  sub errors_for {
    my ($self, @args) = @_;
    $self->_fb->errors_for($self->attribute_name, @args);
  }

  sub default_cb {
    my $fb = shift;
    return $fb->label,
      $fb->input,
      $fb->errors_for;
  }

  package Valiant::HTML::FormBuilderAdapter::Password;

  use Moo;

  has _fb => (is=>'ro', init_arg=>'fb', required=>1);
  has attribute_name => (is=>'ro', required=>1);
  has caller => (is=>'ro', required=>1);

  sub label {
    my ($self, @args) = @_;
    $self->_fb->label($self->attribute_name, @args);
  }
  sub password {
    my ($self, @args) = @_;
    $self->_fb->password($self->attribute_name, @args);
  }
  sub errors_for {
    my ($self, @args) = @_;
    $self->_fb->errors_for($self->attribute_name, @args);
  }

  sub default_cb {
    my $fb = shift;
    return $fb->label,
      $fb->password,
      $fb->errors_for;
  }

  package Valiant::HTML::FormBuilderAdapter;

  use Moo::Role;
  use String::CamelCase 'camelize';
  use Sub::Util 'set_subname';
  use Module::Runtime 'use_module';
  use Valiant::HTML::SafeString 'safe_concat';

  has _fb => (is=>'rw');
  has model => (is=>'ro');
  
  sub ADAPTER_NS { 'Valiant::HTML::FormBuilderAdapter' }

  sub _build_adapters {
    my ($class) = @_;
    my %fields = $class->fields;

    foreach my $attr (keys %fields) {
      my $type = $fields{$attr}->{type};
      my $package_affix = camelize $type;
      my $method = set_subname "${class}::${attr}" => sub {
        my ($self, @args) = @_;
        my %args = (ref($args[0])||'') eq 'HASH' ? shift(@args) : ();
        my $adapter_class = $self->_find_adapter_class($package_affix);
        my $adapter = $self->_build_adapter($adapter_class, $attr, +{ %{$fields{$attr}}, %args });
        my $cb = ref($args[0]||'') eq 'CODE' ? shift(@args) : sub { $adapter->default_cb(shift) };
        return $self->_execute_cb($cb, $adapter);
      };
      no strict 'refs';
      *{"${class}::${attr}"} = $method;
    }
  }

  sub _find_adapter_class {
    my ($self, $package_affix) = @_;
    my $adapter_class = use_module("@{[ $self->ADAPTER_NS ]}::${package_affix}");
    return $adapter_class;
  }

  sub _build_adapter {
    my ($self, $adapter_class, $attr, $args) = @_;
    my $adapter = $adapter_class->new(attribute_name=>$attr, caller=>$self, fb=>$self->_fb, %$args);
    return $adapter;
  }

  sub _execute_cb {
    my ($self, $cb, $adapter) = @_;
    return safe_concat $cb->($adapter);
  }

  sub form {
    my ($self, @args) = @_;
    my $options = ((ref($args[0])||'') eq 'HASH') ? shift(@args) : +{};
    my $cb = shift(@args);

    $options = +{ $self->process_form_options(%$options) }
      if $self->can('process_form_options');

    ##return form_for $self->model, $options, $self->form_callback($cb, $options);
  }

  sub form_callback {
    my ($self, $cb, $options) = @_;
    return sub {
      my ($fb, $model, @args) = @_;
      $self->_fb($fb);
      return $cb->($self, $fb, @args),
    };  
  }

  package Catalyst::Model::Valiant::HTML::FormBuilderAdapter;

  use Moo;

  extends 'Catalyst::Model';
  with 'Valiant::HTML::FormBuilderAdapter';
  
  has ctx => (is=>'ro');

  sub COMPONENT {
    my ($class, $app, $args) = @_;
    $args = $class->merge_config_hashes($class->config, $args);
    $class->_build_adapters;
    return bless $args, $class;
  }

  sub ACCEPT_CONTEXT {
    my $self = shift;
    my $c = shift;
    my %args = (%$self, ctx=>$c, @_);  

    return ref($self)->new(%args);
  }

  sub process_form_options {
    my ($self, %options) = @_;
    return
      action => $self->ctx->req->uri, 
      csrf_token => $self->ctx->csrf_token,
      builder => 'Example::Utils::FormBuilder',
      %options,
  }
}

package Example::Model::RegistrationForm;

use Moose;
use Example::Syntax;

extends 'Catalyst::Model::Valiant::HTML::FormBuilderAdapter';

sub fields {
  return
    username => {type=>'input'},
    first_name => {type=>'input'},
    last_name => {type=>'input'},
    password => {type=>'password'},
    password_confirmation => {type=>'password'},
}

__PACKAGE__->meta->make_immutable();
