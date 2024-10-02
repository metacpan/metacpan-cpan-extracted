package DBIx::Class::Valiant::Result::HTML::FormFields;

use base 'DBIx::Class';

use warnings;
use strict;

## TODO add cache=>1 for simple memory caching of the resultset

__PACKAGE__->mk_classdata( __select_options_rs_for => {} );
__PACKAGE__->mk_classdata( __checkbox_rs_for => {} );
__PACKAGE__->mk_classdata( __radio_button_rs_for => {} );
__PACKAGE__->mk_classdata( __radio_buttons_for => {} );
__PACKAGE__->mk_classdata( __field_attribute_for => {} );

__PACKAGE__->mk_classdata( __tags_by_column => {} );
__PACKAGE__->mk_classdata( __columns_by_tag => {} );

sub register_column {
    my ($self, $column, $info, @rest) = @_;
    $self->next::method($column, $info, @rest);

    my $tag_info = exists $info->{tag}
      ? $info->{tag}
      : exists $info->{tags}
        ? $info->{tags}
        : undef;

    return unless $tag_info;

    my @tags = (ref($tag_info)||'') eq 'ARRAY'
      ? @{$tag_info}
      : ($tag_info);

    $self->__tags_by_column->{$column} = \@tags;
    
    foreach my $tag (@tags) {
      push @{$self->__columns_by_tag->{$tag}}, $column;
    }
}

sub tags_by_column {
  my ($self, $column) = @_;
  return @{$self->__tags_by_column->{$column}||[]};
}

sub columns_by_tag {
  my ($self, $tag) = @_;
  return @{$self->__columns_by_tag->{$tag}||[]};
}

sub add_select_options_rs_for {
  my ($class, $column, $code) = @_;
  $class->__select_options_rs_for->{$column} = $code;
}

sub select_options_rs_for {
  my ($self, $column, %options) = @_;
  my $code = $self->__select_options_rs_for->{$column};
  my $rs = $code->($self, %options);
  my ($value_method, $label_method) = sub {
    my $class = shift->result_source->result_class;
    my ($value_method) = $class->columns_by_tag('option_value');
    my ($label_method) = $class->columns_by_tag('option_label');
    return ($value_method, $label_method);
  }->($rs);

  return $rs, $label_method, $value_method;
}

sub select_options_for {
  my ($self, $column, %options) = @_;
  my ($rs, $label_method, $value_method) = $self->select_options_rs_for($column, %options);
  my @options = map {[ $_->$label_method, $_->$value_method ]} $rs->all;
  return \@options;
}

sub add_checkbox_rs_for {
  my ($class, $column, $code) = @_;
  $class->__checkbox_rs_for->{$column} = $code;
}

sub checkbox_rs_for {
  my ($self, $column, %options) = @_;
  my $code = $self->__checkbox_rs_for->{$column};
  my $rs = $code->($self, %options);
  my ($value_method, $label_method) = sub {
    my $class = shift->result_source->result_class;
    my ($value_method) = $class->columns_by_tag('checkbox_value');
    my ($label_method) = $class->columns_by_tag('checkbox_label');
    return ($value_method, $label_method);
  }->($rs);

  return $rs, $label_method, $value_method;
}

sub checkboxes_for {
  my ($self, $column, %options) = @_;
  my ($rs, $label_method, $value_method) = $self->checkbox_rs_for($column, %options);
  my @options = map {[ $_->$label_method, $_->$value_method ]} $rs->all;
  return \@options;
}

sub add_radio_button_rs_for {
  my ($class, $column, $code) = @_;
  $class->__radio_button_rs_for->{$column} = $code;
}

sub radio_button_rs_for {
  my ($self, $column, %options) = @_;
  my $code = $self->__radio_button_rs_for->{$column};
  my $rs = $code->($self, %options);
  my ($value_method, $label_method) = sub {
    my $class = shift->result_source->result_class;
    my ($value_method) = $class->columns_by_tag('radio_value');
    my ($label_method) = $class->columns_by_tag('radio_label');
    return ($value_method, $label_method);
  }->($rs);

  return $rs, $label_method, $value_method;
}

sub add_radio_buttons_for {
  my ($class, $column, $code) = @_;
  $class->__radio_buttons_for->{$column} = $code;
}
sub radio_buttons_for {
  my ($self, $column, %options) = @_;
  my $code = $self->__radio_buttons_for->{$column};
  my @buttons = $code->($self, %options);
  return @buttons;
}

# $class->add_form_field_for($column);
# $class->add_form_field_for($column, \&code);
# $class->add_form_field_for($column, \%options);
# $class->add_form_field_for($column, \%options, \&code);

sub add_form_field_for {
  my ($class, $column) = (shift(@_), shift(@_));
  my $options = (ref($_[0])||'') eq 'HASH' ? shift(@_) : +{};
  my $code = (ref($_[0])||'') eq 'CODE' ? shift(@_) : sub { $class->_auto_read_attribute_for_html($column) };

  $class->__field_attribute_for->{$column} = [$code, $options];
}

# __PACKAGE__->add_form_field_for(
#   'user',
#   sub ($self) { $self->user},
#   { label=>..., type=>..., context=>'admin' } );

# add 'context' to this so that you can have different forms for same
# TODO maybe need to add way to wrap getting label and errors...

sub has_form_fields {
  my ($self) = @_;
  return scalar keys %{$self->__field_attribute_for};
}

sub has_form_field {
  my ($self, $column) = @_;
  return exists $self->__field_attribute_for->{$column};
}

sub read_form_field_for {
  my ($self, $column) = @_;
  die "Can't find a form field for column '$column'" unless $self->has_form_field($column);
  return $self->_read_form_field_for($column);
}

sub _read_form_field_for {
  my ($self, $column) = @_;
  my ($code, $options) = @{$self->__field_attribute_for->{$column}};
  return $code->($self, $column);
}


sub read_attribute_for_html {
  my ($self, $attribute) = @_;
  die "'attribute' is required argument" unless defined $attribute;

  # If at least one form field is defined for this class, that means the
  # author wanted fine grained control over the form fields so we'll use that
  # and only that.  Otherwise we'll fall back to the auto reading method

  if($self->has_form_fields) {
    return $self->_read_form_field_for($attribute) if $self->has_form_field($attribute);
  } else {
    return $self->_auto_read_attribute_for_html($attribute);
  }
}

sub _auto_read_attribute_for_html {
  my ($self, $attribute) = @_;

  # Handle special case for 'delete' attribute and 'add' attribute
  return $self->is_marked_for_deletion if $attribute eq '_delete';
  return 1 if $attribute eq '_add';

  # First fallback to the normal DBIC way of getting a column value
  return $self->get_column($attribute) if $self->result_source->has_column($attribute);

  # Second just look for a method that matches the attribute name
  return $self->$attribute if $self->can($attribute); 

  # Permit getting the value of a relationship if it's a single relationship
  if($self->has_relationship($attribute)) {
    my $rel_data = $self->relationship_info($attribute);
    my $rel_type = $rel_data->{attrs}{accessor};
    return $self->$attribute if($rel_type eq 'single');
  }

  die "Can't find a value for attribute '$attribute'";
}

1;

=head1 NAME

DBIx::Class::Valiant::Result::HTML::FormFields - Map DBIC Fields to HTML Form Fields

=head1 SYNOPSIS

    package Example::Schema::Result::Person;

    use base 'DBIx::Class::Core';

    __PACKAGE__->load_components('Valiant::Result::HTML::FormFields');

Or just add to your base Result class:

    package Example::Schema::Result;

    use strict;
    use warnings;
    use base 'DBIx::Class::Core';

    __PACKAGE__->load_components('Valiant::Result::HTML::FormFields');

=head1 DESCRIPTION

This module extends DBIx::Class to provide functionality for mapping database fields to HTML form fields. It allows for easy generation and handling of form elements based on the schema's result class.

=head1 METHODS

=head2 register_column

    $self->register_column($column, $info, @rest);

Registers a column with additional tag information. This method is overridden to add tag metadata for columns, which can be used for form generation.

Example:

    __PACKAGE__->register_column('status', { data_type => 'varchar', size => 255, tags => ['select', 'option_value'] });

=head2 tags_by_column

    my @tags = $self->tags_by_column($column);

Returns an array of tags associated with a column.

Example:

    my @tags = $result->tags_by_column('status');

=head2 columns_by_tag

    my @columns = $self->columns_by_tag($tag);

Returns an array of columns associated with a tag.

Example:

    my @columns = $result->columns_by_tag('select');

=head2 add_select_options_rs_for

    $class->add_select_options_rs_for($column, $code);

Adds a result set generator code reference for a select field.

Example:

    __PACKAGE__->add_select_options_rs_for('status', sub {
        my ($self, %options) = @_;
        return $self->result_source->schema->resultset('Status')->search({}, \%options);
    });

=head2 select_options_rs_for

    my ($rs, $label_method, $value_method) = $self->select_options_rs_for($column, %options);

Returns a result set, label method, and value method for a select field.

Example:

    my ($rs, $label_method, $value_method) = $result->select_options_rs_for('status');

=head2 select_options_for

    my @options = $self->select_options_for($column, %options);

Returns a list of select options for a column.  This is a array of arrayrefs where the first element is the label and the second element is the value.

Example:

    my @options = $result->select_options_for('status');

=head2 add_checkbox_rs_for

    $class->add_checkbox_rs_for($column, $code);

Adds a result set generator code reference for a checkbox field.

Example:

    __PACKAGE__->add_checkbox_rs_for('roles', sub {
        my ($self, %options) = @_;
        return $self->result_source->schema->resultset('Role')->search({}, \%options);
    });

=head2 checkbox_rs_for

    my $rs = $self->checkbox_rs_for($column, %options);

Returns a result set for a checkbox field.

Example:

    my $rs = $result->checkbox_rs_for('roles');

=head2 checkboxes_for

    my @checkboxes = $self->checkboxes_for($column, %options);

Returns a list of checkboxes for a column.  This is an array of arrayrefs where the first element is the label and the second element is the value.

=head2 add_radio_button_rs_for

    $class->add_radio_button_rs_for($column, $code);

Adds a result set generator code reference for a radio button field.

Example:

    __PACKAGE__->add_radio_button_rs_for('gender', sub {
        my ($self, %options) = @_;
        return $self->result_source->schema->resultset('Gender')->search({}, \%options);
    });

=head2 radio_button_rs_for

    my $rs = $self->radio_button_rs_for($column, %options);

Returns a result set for a radio button field.

Example:

    my $rs = $result->radio_button_rs_for('gender');

=head2 add_radio_buttons_for

    $class->add_radio_buttons_for($column, $code);

Add an array of radio button labels
Example:

    __PACKAGE__->add_radio_buttons_for('status', sub($self, %options) {
      return $self->status_list;
    });

    sub status_list($self) { return qw( pending active inactive ) }

=head2 radio_buttons_for

    my @buttons = $self->radio_buttons_for($column, %options);

Returns a list of radio buttons for a column.

Example:

    my @buttons = $result->radio_buttons_for('preferences');

=head2 add_form_field_for
  
      $class->add_form_field_for($column, $code); 

Adds a form field generator code reference for a column.

Example:

    __PACKAGE__->add_form_field_for('first_name', sub {
        my ($self, $column) = @_;
        return $self->first_name;
    });

B<Note:> If no form field is defined for a column, 
the module will automatically read the value of the column via the C<_auto_read_attribute_for_html> method.

=head2 has_form_fields

    my $bool = $self->has_form_fields;

Checks if the result class has form fields.

=head2 has_form_field

    my $bool = $self->has_form_field($attribute);

Checks if the result class has a form field for an attribute.

=head2 read_form_field_for

    my $value = $self->read_form_field_for($attribute);

Reads the value of a form field for an attribute.

=head2 read_attribute_for_html

    my $value = $self->read_attribute_for_html($attribute);

Reads the value of an attribute for HTML.

=head2 _auto_read_attribute_for_html

    my $value = $self->_auto_read_attribute_for_html($attribute);

Automatically reads the value of an attribute for HTML.

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>

=head1 SEE ALSO

L<Valiant>, L<DBIx::Class>

=head1 COPYRIGHT & LICENSE

Copyright 2020, John Napiorkowski L<email:jjnapiork@cpan.org>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut


