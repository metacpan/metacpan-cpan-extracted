package Valiant::HTML::FormBuilder::Model;

use Moo;

has attribute_name => (is=>'ro', required=>1);

has model => (is=>'ro', required=>1);

has formbuilder => (
  is=>'ro',
  required=>1,
  handles=>[qw(
    tag_id_for_attribute
    tag_name_for_attribute
    tag_value_for_attribute
  )],
);

has _options => (
  is => 'ro',
  init_arg => 'value',
  required => 1,
  lazy => 1,
  builder => '_build_options',
);

  sub _build_options { return +{} }
  sub options { return shift->_options }


around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);

  return $args;
};






has _enabled => (
  is => 'ro',
  init_arg => 'enabled',
  required => 1,
  lazy => 1,
  builder => '_build_enabled',
);

  sub _build_enabled { return 1 }
  sub enabled { return shift->_enabled }

has _id => (
  is => 'ro',
  init_arg => 'id',
  required => 1,
  lazy => 1,
  builder => '_build_id',
);

  sub _build_id { return $_[0]->tag_id_for_attribute($_[0]->attribute_name) }
  sub id { return shift->_id }

has _name => (
  is => 'ro',
  init_arg => 'name',
  required => 1,
  lazy => 1,
  builder => '_build_name',
);

  sub _build_name { return $_[0]->tag_name_for_attribute($_[0]->attribute_name)  }
  sub name { return shift->_name }

has _value => (
  is => 'ro',
  init_arg => 'value',
  required => 1,
  lazy => 1,
  builder => '_build_value',
);

  sub _build_value { return $_[0]->tag_value_for_attribute($_[0]->attribute_name) }
  sub value { return shift->_value }


sub type { return 'text' }

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);

  ## Do stuff with $args->{options};
  return $args;
};

use Valiant::HTML::FormBuilder::Model::TextField;

sub text_field {
  my ($self, $attribute, $options) = (shift, shift, (@_ ? shift : +{}));

  $options = $self->process_options_for_errors($attribute, $options);
  $options = $self->merge_theme_field_opts('text_field', $attribute, $options);

  my $field_model = Valiant::HTML::FormBuilder::Model::TextField->new(
    formbuilder => $self,
    attribute => $attribute,
    model => ($self->model->can('to_model') ? $self->model->to_model : $self->model),
    options => $options,
  );

  my $rendered_field = Valiant::HTML::FormBuilder::Renderer::TextField->new(field_model=>$field);

  return $rendered_field;
}

sub process_options_for_errors {
  my ($self, $attribute, $options) = @_;
  return $options unless $self->attribute_has_errors($attribute);

  # Add any errors_classes to class
  my $errors_classes = exists($options->{errors_classes}) ? delete($options->{errors_classes}) : undef;
  $options->{class} = join(' ', (grep { defined $_ } $options->{class}, $errors_classes))
    if $errors_classes;

  # merge any general error condition attributes 
  if( my $errors_attrs = delete $options->{errors_attrs} ) {
    foreach my $key(keys %$errors_attrs) {
      if(exists $options->{$key}) {
        if( ($key eq 'data') || ($key eq 'aria') ) {
          $options->{$key} = +{ %{$options->{$key}}, %{$errors_attrs->{$key}} };
        } elsif($key eq 'class') {
          $options->{$key} .= " $errors_attrs->{$key}";
        } else {
          $options->{$key} .= $errors_attrs->{$key};
        }
      } else {
        $options->{$key} = $errors_attrs->{$key};
      }
    }
  }
  
  return $options;
}



sub input {
  my ($self, $attribute, $options) = (shift, shift, (@_ ? shift : +{}));
  $options = $self->merge_theme_field_opts($options->{type} || 'input', $attribute, $options);
  my $errors_classes = exists($options->{errors_classes}) ? delete($options->{errors_classes}) : undef;
  my $model = $self->model->can('to_model') ? $self->model->to_model : $self->model;
 
  $options->{class} = join(' ', (grep { defined $_ } $options->{class}, $errors_classes))
    if $errors_classes && $model->can('errors') && $model->errors->where($attribute);

  set_unless_defined(type => $options, 'text');
  set_unless_defined(id => $options, $self->tag_id_for_attribute($attribute));
  set_unless_defined(name => $options, $self->tag_name_for_attribute($attribute));
  $options->{value} = $self->tag_value_for_attribute($attribute) unless defined($options->{value});

  return Valiant::HTML::FormTags::input_tag $attribute, $self->process_options($attribute, $options);
}

1;

=head1 NAME

Valiant::HTML::FormBuilder::Model::TextField - An HTML Input Text Model

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO
 
L<Valiant::HTML::FormBuilder>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut

__END__


# DBIC Result
#

__PACKAGE__->

package Example::HTML::AccountForm;

use Valiant::HTML::Model::Form;


