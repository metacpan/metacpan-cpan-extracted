package Valiant::Name;

use Moo;
use String::CamelCase 'decamelize';
use Text::Autoformat 'autoformat';
use Lingua::EN::Inflexion 'noun';
use Valiant::I18N ();

# These first few are permitted arguments

has class => (is=>'ro', required=>1);
has namespace => (is=>'ro', required=>0, predicate=>'has_namespace');

# Ok so when you have a namespace that means we want to localize the naming to under
# the namespace.   For example if you model is package MyApp::Model::Person you might
# like to have the namespace set to 'MyApp::Model'.  Right this code just uses it for
# determining the 'param_key' which is what we look for in a request to find this models
# data but we might need it for other stuff later.  Rails uses it for tons of stuff due
# to their 'convention over configuration' thing. 

has 'unnamespaced' => (
  is => 'ro',
  init_arg => undef,
  required => 0,
  lazy => 1,
  predicate => 'has_unnamespaced',
  default => sub { 
    my $self = shift;
    return unless $self->has_namespace;
    my $class = $self->class;
    my $ns = $self->namespace;
    $class =~s/^${ns}:://;
    return $class;
    return lc decamelize($class);
  },
);

has 'singular' => (
  is => 'ro',
  init_arg => undef,
  lazy => 1,
  required => 1,
  default => sub {
    my $self = shift;
    my $class = $self->class;
    $class = decamelize($class);
    $class =~ s/::/_/g;
    return lc noun($class)->singular; 
  },
);

has 'plural' => (
  is => 'ro',
  init_arg => undef,
  lazy => 1,
  required => 1,
  default => sub {
    my $self = shift;
    return noun($self->singular)->plural;
  },
);

has 'element' => (
  is => 'ro',
  init_arg => undef,
  lazy => 1,
  required => 1,
  default => sub {
    my $self = shift;
    my $class = $self->class;
    $class =~ s/^.+:://;
    $class = decamelize($class);
  },
);

has _human => (
  is => 'ro',
  init_arg => undef,
  lazy => 1,
  required => 1,
  default =>  sub {
    my $self = shift;
    my $name = $self->element;
    $name =~s/_/ /g;
    my $formated = autoformat $name, {case=>'title'};
    $formated=~s/\n//g; # some sort of bug in autoformat?
    return $formated;
  },
);

# This is the translation tag used to lookup a translated version of the model
# name.  This is only used via ->human if the consuming class does 'i18n_scope'. 
# For example if the i18n_scope is 'valiant' and class package is AbcDef::Ghi then
# the i18n_key is 'abc_def/ghi'.
 
has i18n_key => (
  is => 'ro',
  init_arg => undef,
  lazy => 1,
  required => 1,
  default =>  sub {
    my $self = shift;
    my $class = $self->class;
    $class =~s/::/\//g;
    return Valiant::I18N->make_tag(decamelize($class));
  },
);

sub i18n_class { 'Valiant::I18N' }

has 'i18n' => (
  is => 'ro',
  required => 1,
  default => sub { Module::Runtime::use_module(shift->i18n_class) },
);

has param_key => (
  is => 'ro',
  required => 1,
  lazy => 1,
  default => sub {
    my $self = shift;
    $self->has_namespace ? decamelize($self->unnamespaced) : $self->singular;
  },
);

sub human {
  my ($self, %options) = @_;

  return $self->_human unless $self->class->can('i18n_scope'); # Don't waste time if there's no lookup scope

  my @defaults = map {
    $_->model_name->i18n_key;
  } $self->class->i18n_lookup if $self->class->can('i18n_lookup');

  return $self->_human unless @defaults; # If $self doesn't do i18n_lookup then there's no tags to attempt translations
  
  push @defaults, delete $options{default} if exists $options{default};
  push @defaults, $self->_human; # The guessed named used by looking at the package name is the ultimate default


  %options = (
    scope => [$self->class->i18n_scope, 'models'],
    count => 1,
    default => \@defaults,
    %options,
  );

  $self->i18n->translate(shift(@defaults), %options);
}

package Valiant::Naming;

use Moo::Role;

sub name_class { 'Valiant::Name' }

my %_model_name = ();
sub model_name {
  my ($self) = @_;
  my $class = ref($self) || $self;

  return $_model_name{$class} ||= do {
    my %args = $self->prepare_model_name_args;
    Module::Runtime::use_module($self->name_class)->new(%args);
  };
}

sub prepare_model_name_args {
  my ($self) = @_;
  my $class = ref($self) || $self;
  my %args = (class => $class);
  $args{namespace} = $self->namespace if $self->can('namespace');

  return %args;
}

1;

=head1 NAME

Valiant::Naming - Standard naming information for your models

=head1 SYNOPSIS

    $model->model_name->human;
    $model->model_name->singular;
    $model->model_name->plural;
    $model->model_name->param_key;


=head1 DESCRIPTION

Exposes a method on your models called C<model_name> which returns an instance of
L<Valiant::Name>.  This object contains various attributes used for creating a standard
approach to naming or referencing your object.

If your object defines a method C<i18n_scope> that will be used as the base namespace
part to lookup your objects naming information from a set of defined translations.

=head1 METHODS

This component adds the following methods to your result classes.

=head2 model_name

An instance of L<Valiant::Name>.  This object exposes the following attributes:

=head2 human

A human readable name for your object.  This will either be inferred from the package 
name of the object or if C<i18n_scope> is defined will be looked up in translations.

=head2 singular

=head2 plural

Your model name in singular or plural form.

=head2 param_key

A name for your object that is suitable for serialization such as in an HTML form or
other serialization formats.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Valiant>

=head1 COPYRIGHT & LICENSE
 
Copyright 2020, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
