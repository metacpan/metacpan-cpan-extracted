package Valiant::HTML::FormBuilder::RadioButton;

use Moo;
extends 'Valiant::HTML::FormBuilder';

has 'parent_builder' => (is=>'ro', required=>1);

sub default_theme {
  my $self = shift;
  return $self->parent_builder->can('default_theme') ?
    $self->parent_builder->default_theme :
    +{};
}

sub text { 
  my $self = shift;
  return $self->tag_value_for_attribute($self->options->{label_method});
}

sub value { 
  my $self = shift;
  return $self->tag_value_for_attribute($self->options->{value_method});
}

sub checked {
  my $self = shift;
  return $self->options->{checked};
}

around 'label', sub {
  my ($orig, $self, $attrs) = @_;
  $attrs = +{} unless defined($attrs);
  return $self->$orig($self->value, $attrs, $self->text);
};

around 'radio_button', sub {
  my ($orig, $self, $attrs) = @_;
  $attrs = +{} unless defined($attrs);
  $attrs->{name} = $self->name;
  $attrs->{checked} = $self->checked;
  $attrs->{id} = $self->tag_id_for_attribute($self->value);
  $attrs = $self->merge_theme_field_opts(radio_button=>$attrs->{attribute}, $attrs);

  my $has_error = 0;
  if(my $errors = $self->options->{errors}) {
    foreach my $error(@$errors) {
      $has_error = 1 if $error->bad_value eq $self->value;
    }
  }

  my $errors_classes = exists($attrs->{errors_classes}) ? delete($attrs->{errors_classes}) : undef;
  $attrs->{class} = join(' ', (grep { defined $_ } $attrs->{class}, $errors_classes))
    if $errors_classes && $has_error;

  return $self->$orig($self->options->{attribute}, $self->value, $attrs);
};

1;

=head1 NAME

Valiant::HTML::FormBuilder::RadioButton - A custom formbuilder for radio button content

=head1 SYNOPSIS

  $fb_profile->collection_radio_buttons('state_id', $states, id=>'name', +{ errors_classes=>'is-invalid'}, sub (
    my $fb_state = shift;
    $fb_state->radio_button(+{class=>"form-check-input"});
    $fb_state->label(+{class=>"form-check-label"});
  });

=head1 DESCRIPTION

This is a custom subclass of L<Valiant::HTML::FormBuilder> that modifies the C<label> and
C<radio_button> method so that it is already aware of the the field values, if its checked or
not, etc.   It also addes three methods, C<text> which is the text value of the collection;
C<value>, which is its value and C<checked> which is a boolean indicated if the checkbox is 'checked'
or not.

Generally you use this inside a C<collection_radio_button> when you want to have some custom 
HTML and attributes on the radio button and label elements (typically for styling as in the 
example shown.

Chances are you won't use this stand alone but rather from inside a parent builder.

=head1 SEE ALSO
 
L<Valiant::HTML::FormBuilder>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut

