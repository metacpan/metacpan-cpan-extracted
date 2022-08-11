package Valiant::HTML::Components;

use Moo;
use Module::Pluggable::Object;
use Module::Runtime 'use_module';
use Class::Method::Modifiers;
use Moo::_Utils;

has _components => (is=>'ro', required=>1, init_arg=>undef, default=>sub { +{} });
has namespace => (is=>'ro', required=>1, lazy=>1, default=>sub { [ref shift] });
has constructor =>(is=>'ro', predicate=>'has_constructor');

my $_self;
my @NS;

sub add_namespace {
  my ($class, @ns) = @_;
  push @NS, @ns;
}

sub inflate_namespace {
  my $self = shift;
  my @ns = @_ ? @_ : (ref($self));
  foreach my $ns (@ns) {
    my @packages = Module::Pluggable::Object->new(
      search_path => $ns,
    )->plugins;
    foreach my $package (@packages) {
     my ($name) = ($package=~/^$ns\:\:(.+)$/);
      $self->add($name => {class=>$package});
    }
  }
}

sub import {
  my $class = shift;
  my $target = caller;
  $class->import_components($target, @_);
}


sub import_components {
  my ($class, $target, @components) = @_;
  foreach my $component (@components) {
    $class->import_component($target, $component);
  }
}

sub import_component {
  my ($class, $target, $component) = @_;
  Moo::_Utils::_install_tracked($target, $component, sub {
    my @args = @_;
    my $class = $_self->get_class_for_component($component);

    @args = $class->prepare_args(@args) if $class->can('prepare_args');

    my $attrs = (ref($args[0])||'') eq 'HASH' ? shift(@args) : +{};
    my $content = shift(@args) if $_self->has_content($component);

    $attrs->{container} =  $Valiant::HTML::BaseComponent::SELF
      if $Valiant::HTML::BaseComponent::SELF;

    

    my $component = $_self->create($component, $attrs, $content);
    return @args ? ($component, @args) : ($component);
  });
}

sub BUILD {
  my $self = shift;
  $self->inflate_namespace(@NS, @{$self->namespace});
  $_self ||= $self;
}

sub _self { $_self }

sub component_names {
  my $self = shift;
  return keys %{$self->_components};
}

sub get_class_for_component {
  my ($self, $comp_name) = @_;
  my $component_args = $self->_components->{$comp_name} || die "Component '$comp_name' does not exist";
  return $component_args->{class};
}

sub add {
  my ($self, $comp_name, $args) = @_;
  die "Component '$comp_name' already added" if exists $self->_components->{$comp_name};
  use_module($args->{class});
  return $self->_components->{$comp_name} = $args;
}

sub create {
  my ($self, $comp_name, $args, $inner) = @_;
  
  my $component_args = $self->_components->{$comp_name} || die "Component '$comp_name' does not exist";

  if(my $class = $component_args->{class}) {
    my $init = $component_args->{constructor} ||= $self->component_constructor;
    return $init->($self, $comp_name, $class, %$args, (defined($inner) ? (content => $inner) : ()));
  } elsif(my $cb = $component_args->{callback} ) {
    ## TODO This needs a class proxy, probably based on ContentComponent
    return $cb->(%$args, (defined($inner) ? (content => $inner) : ()));
  }
}

sub component_constructor {
  my $self = shift;
  return $self->constructor if $self->has_constructor;
  return sub {
    my ($self, $comp_name, $class, %args) = @_;
    return $class->new(%args);
  };
}

sub has_content {
  my ($self, $comp_name) = @_;
  my $component_args = $self->_components->{$comp_name} || die "Component '$comp_name' does not exist";
  return $component_args->{class}->can('content') ? 1:0;
}

1;
