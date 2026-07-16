package Valiant::Translation;

use Moo::Role;
use Text::Autoformat 'autoformat';
use Valiant::Util 'debug';

with 'Valiant::Naming';

sub i18n_class { 'Valiant::I18N' }

has 'i18n' => (
  is => 'ro',
  required => 1,
  lazy => 1,
  default => sub { Module::Runtime::use_module(shift->i18n_class) },
);

sub i18n_scope { 'valiant' }

sub human_attribute_name {
  my ($self, $attribute, $options) = @_;
  return undef unless defined($attribute);
  debug 1, "Begin building human name for  attribute '$attribute'";

  # TODO I think we need to clean $option here so I don't need to manually
  # set count=>1 as I do below.
  #

  my @defaults = ();
  my $i18n_scope = $self->i18n_scope;
  my @parts = split /\./, $attribute;
  my $attribute_name = pop @parts;
  my $namespace = join '/', @parts if @parts;
  my $attributes_scope = "${i18n_scope}.attributes";

  if($self->can('i18n_lookup')) {
    debug 2, "Building defaults for attributes '$attribute'";
    if($namespace) {
      @defaults = map {
        my $class = $_;
        "${attributes_scope}.${\$class->model_name->i18n_key}/${namespace}.${attribute_name}"
      } grep { $_->model_name->can('i18n_key') } $self->i18n_lookup;
    } else {
      @defaults = map {
        my $class = $_;
        "${attributes_scope}.${\$class->model_name->i18n_key}.${attribute}"    
      } grep { $_->model_name->can('i18n_key') } $self->i18n_lookup;
    }
  }

  @defaults = map { $self->i18n->make_tag($_) } (@defaults, "attributes.${attribute}");

  # Not sure if this should move up above the preceeding map...

  if(exists $options->{default}) {
    my $default = delete $options->{default};
    my @default = ref($default) ? @$default : ($default);
    push @defaults, @default;
  }
  # The final default is just our best attempt to make a name out of the actual
  # attribute name.  This is passed as a plain string so we don't actually try
  # to localize it.
  push @defaults, $self->_humanize_attribute($attribute);

  my $key = shift @defaults;
  $options->{default} = \@defaults;
  $options->{count} = 1 unless exists $options->{count};

  return  my $localized = $self->i18n->translate($key, %{$options||+{}});
}

sub human_label_name {
  my ($self, $attribute, $options) = @_;
  return undef unless defined($attribute);
  debug 1, "Begin building human name for label '$attribute'";

  # TODO I think we need to clean $option here so I don't need to manually
  # set count=>1 as I do below.
  #

  my @defaults = ();
  my $i18n_scope = $self->i18n_scope;
  my @parts = split /\./, $attribute;
  my $attribute_name = pop @parts;
  my $namespace = join '/', @parts if @parts;
  my $attributes_scope = "${i18n_scope}.labels";

  if($self->can('i18n_lookup')) {
    debug 2, "Building defaults for labels '$attribute'";
    if($namespace) {
      @defaults = map {
        my $class = $_;
        "${attributes_scope}.${\$class->model_name->i18n_key}/${namespace}.${attribute_name}"
      } grep { $_->model_name->can('i18n_key') } $self->i18n_lookup;
    } else {
      @defaults = map {
        my $class = $_;
        "${attributes_scope}.${\$class->model_name->i18n_key}.${attribute}"    
      } grep { $_->model_name->can('i18n_key') } $self->i18n_lookup;
    }
  }

  @defaults = map { $self->i18n->make_tag($_) } (@defaults, "labels.${attribute}");

  # Not sure if this should move up above the preceeding map...

  if(exists $options->{default}) {
    my $default = delete $options->{default};
    my @default = ref($default) ? @$default : ($default);
    push @defaults, @default;
  }
  
  # The final default is just our best attempt to make a name out of the actual
  # attribute name.  This is passed as a plain string so we don't actually try
  # to localize it.
  push @defaults, $self->_humanize_label($attribute);

  my $key = shift @defaults;
  $options->{default} = \@defaults;
  $options->{count} = 1 unless exists $options->{count};

  return  my $localized = $self->i18n->translate($key, %{$options||+{}});
}

sub _humanize_label { shift->_humanize(@_) }
sub _humanize_attribute { shift->_humanize(@_) }

sub _humanize {
  my ($self, $text) = @_;
  my $humanized = $text;

  $humanized =~s/_id$//; # remove trailing _id
  $humanized =~s/_/ /g;
  $humanized = autoformat($humanized, +{case=>'title'});
  $humanized =~s/[\n]//g;  # Is this a bug in Text::Autoformat???

  return $humanized;
}

1;

=head1 NAME

Valiant::Translation - Localized, human readable names for models and attributes

=head1 DESCRIPTION

A role providing the translation glue between your model and L<Valiant::I18N>:
it turns attribute names into localized, human readable strings for error
messages and form labels.  You won't usually consume this role directly; it is
composed into your class via L<Valiant::Validates>.  Documented here is the
public API it adds to your class.

=head1 ATTRIBUTES

=head2 i18n

An instance of the class named by L</i18n_class>, lazily built.  You can pass
your own at construction if you need custom translation behavior.

=head1 METHODS

=head2 i18n_class

The class used for translation.  Defaults to C<Valiant::I18N>.  Override this
method in your class to use a different translation backend.

=head2 i18n_scope

The top level namespace under which translation keys are looked up.  Defaults
to C<valiant>.  Override to relocate your translations.

=head2 human_attribute_name ($attribute, \%options)

Returns a human readable, localized version of an attribute name, used when
building full error messages.  Looks for translations under
C<< {i18n_scope}.attributes.{model}.{attribute} >> across the class hierarchy,
falling back to any C<default> tags passed in C<\%options> and finally to a
title cased version of the attribute name itself (with any trailing C<_id>
removed and underscores turned into spaces).

=head2 human_label_name ($attribute, \%options)

The same lookup as L</human_attribute_name> but under the C<labels> scope
rather than C<attributes>; used by the form generation code to build field
labels so labels can be localized separately from error messages.

=head1 SEE ALSO

L<Valiant>, L<Valiant::I18N>, L<Valiant::Validates>.

=head1 AUTHOR

See L<Valiant>

=head1 COPYRIGHT & LICENSE

See L<Valiant>

=cut
