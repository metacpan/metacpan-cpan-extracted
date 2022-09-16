package Valiant::HTML::FormBuilder::Checkbox;

use Moo;
extends 'Valiant::HTML::FormBuilder';

has 'parent_builder' => (is=>'ro', required=>1);

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
  return $self->$orig($self->options->{attribute_value_method}, $attrs, $self->text);
};

around 'checkbox', sub {
  my ($orig, $self, $attrs) = @_;
  $attrs = +{} unless defined($attrs);
  $attrs->{name} = $self->tag_name_for_attribute($self->options->{attribute_value_method});
  $attrs->{id} = $self->tag_id_for_attribute($self->options->{attribute_value_method});
  $attrs->{include_hidden} = 0;
  $attrs->{checked} = $self->checked;

  return $self->$orig($self->options->{value_method}, $attrs, $self->value);
};


1;

=head1 NAME

Valiant::HTML::Formbuilder::Checkbox - A custom formbuilder for checkbox content

=head1 SYNOPSIS

    $fb->collection_checkbox({person_roles => 'role_id'}, $roles, id=>'label', sub {
      my $fb_roles = shift;
      $fb_roles->checkbox({class=>'form-check-input'});
      $fb_roles->label({class=>'form-check-label'});
    });

=head1 DESCRIPTION

This is a custom subclass of L<Valiant::HTML::FormBuilder> that modifies the C<label> and
C<checkbox> method so that it is already aware of the the field values, if its checked or
not, etc.   It also addes three methods, C<text> which is the text value of the collection;
C<value>, which is its value and C<checked> which is a boolean indicated if the checkbox is 'checked'
or not.

Generally you use this inside a C<collection_checkbox> when you want to have some custom 
HTML and attributes on the checkbox and label elements (typically for styling as in the 
example shown.

Chances are you won't use this stand alone but rather from inside a parent builder.

=head1 SEE ALSO
 
L<Valiant::HTML::FormBuilder>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut

