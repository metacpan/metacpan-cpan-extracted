package Widget::Meta;

use strict;
$Widget::Meta::VERSION = '0.06';

=head1 Name

Widget::Meta - Metadata for user interface widgets

=head1 Synopsis

  use Widget::Meta;

  my @wms;
  push @wms, Widget::Meta->new(
    name => 'foo',
    type => 'text',
    tip  => 'Fill me in',
    size => 32,
  );

  push @wms, Widget::Meta->new(
    name => 'bar',
    type => 'select',
    tip  => 'Pick a number from 1 to 3',
    options => [[1 => 'One'], [2 => 'Two'], [3 => 'Three']],
  );

  # And later, assuming functions for generating UI fields...
  for my $wm (@wms) {
      if ($wm->type eq 'text')
          output_text_field($wm);
      } elsif ($wm->type eq 'select') {
          output_select_list($wm);
      } else {
          die "Huh, wha?";
      }
  }

=head1 Description

This class specifies simple objects that describe UI widgets. The idea is to
associate Widget::Meta objects with the attributes of a class in order to
automate the generation of UI widgets for instances of the class. At its core,
this class a very simple module that stores value and returns them on
demand. The assigning of values to its attributes and checking the validity of
those attributes happens entirely in the C<new()> constructor. Its attributes
are read-only; the C<options> attribute is actually a code reference, the
return value of which is returned for every call to the C<options()> accessor.

=head1 Class Interface

=head2 Constructor

=head3 new

  my $wm = Widget::Meta->new(%params);

Constructs and returns a new Widget::Meta object. The attributes of the Widget::Meta
object can be set via the following parameters:

=over

=item type

The type of widget for which the Widget::Meta object provides meta data. This
can be any string, but typically is "text", "textarea", "checkbox", and the
like. Defaults to "text".

=item name

The name of the widget. Defaults to an empty string.

=item value

The default value to use in the widget. Defaults to C<undef>.

=item tip

A tip to be used in the display of the widget describing what it's data will be
used for. This may be provides as minor help text in a UI, such as a "tooltip".
Defaults to an empty string.

=item size

The size of the widget. This can be used in any number of ways, such as to define
the display size of a text box. Must be an integer. Defaults to 0.

=item length

The length of the widget. This is usually used to limit the lenght of a string
to be entered into a widge such as a text box. Must be an integer. Defaults to
0.

=item rows

The number of rows to be used in a widget, such as a textarea widget. Must be
an integer. Defaults to 0.

=item cols

The number of columns to be used in a widget, such as a textarea widget. Must
be an integer. Defaults to 0.

=item checked

A boolean indicating whether a widget such as a radio button or checkbox
should be checked by default when it displays. Defaults to a false value.

=item options

An array of array references or a code reference describing the possible
values for a widget such as a select list. If an array is passed, each item of
the array must be a two-item array reference, the first item being the value
and the second item being the label to be used for the value. If a code
reference is passed, it must return an array or array references in the same
format when executed.

=back

=cut

my $error_handler = sub {
    require Carp;
    Carp::croak(@_);
};

my $defopt = sub {[]};
sub new {
    my $class = shift;
    $error_handler->("Odd number of parameters in call to new() when named "
                     . "parameters were expected" ) if @_ % 2;

    # Get the parameters. Default value to undef.
    my %self = ( value => undef, @_);

    # Set the default type of widget.
    $self{type} ||= 'text';

    # Set empty string defaults.
    for my $p (qw(tip name)) {
        $self{$p} = '' unless defined $self{$p};
    }

    # Set integer defaults to 0.
    for my $p (qw(rows cols length size)) {
        if (defined $self{$p}) {
            $error_handler->(ucfirst($p) . " parameter must be an integer")
              unless $self{$p} =~ /^\d+$/;
        } else {
            $self{$p} = 0;
        }
    }

    # Set checked to boolean value.
    $self{checked} = $self{checked} ? 1 : 0;

    # Set up options code reference.
    if (my $opt = $self{options}) {
        my $ref = ref $opt;
        if ($ref eq 'ARRAY') {
            $self{options} = sub { $opt };
        } else {
            $error_handler->("Options must be either an array of arrays or a "
                           . "code reference")
              unless $ref eq 'CODE';
        }
    } else {
        $self{options} = $defopt;
    }

    # Make it so!
    return bless \%self, $class;
}

##############################################################################

=head2 Accessors

=head3 type

  my $type = $wm->type;

Returns the string defining the type of widget to be created.

=cut

sub type    { shift->{type}    }

##############################################################################

=head3 name

  my $name = $wm->name;

Returns the name of the widget to be created.

=cut

sub name    { shift->{name}    }

##############################################################################

=head3 value

  my $value = $wm->value;

Returns the value to be displayed in the widget.

=cut

sub value   { shift->{value}   }

##############################################################################

=head3 tip

  my $tip = $wm->tip;

Returns the helpful tip to be displayed in the widget.

=cut

sub tip     { shift->{tip}     }

##############################################################################

=head3 size

  my $size = $wm->size;

Returns the display size of the widget. Useful for "text" or "password"
widgets, among others.

=cut

sub size    { shift->{size}    }

##############################################################################

=head3 length

  my $length = $wm->length;

Returns the maximum lenght of the value allowed in the widget. Useful for
"text" or "textarea" widgets, among others.

=cut

sub length  { shift->{length}  }

##############################################################################

=head3 rows

  my $rows = $wm->rows;

Returns the number of rows to be used to display the widget, for example for a
"textarea" widget.

=cut

sub rows    { shift->{rows}    }

##############################################################################

=head3 cols

  my $cols = $wm->cols;

Returns the number of columns to be used to display the widget, for example
for a "textarea" widget.

=cut

sub cols    { shift->{cols}    }

##############################################################################

=head3 checked

  my $checked = $wm->checked;

Returns true if the widget should be checked, and false if it should not. Used
for "checkbox" and "radio button" widgets and the like.

=cut

sub checked { shift->{checked} }

##############################################################################

=head3 options

  my $options = $wm->options;
  for my $opt (@$options) {
      print "Value: $opt->[0]\nLabel: $opt->[1]\n\n";
  }

Returns an array reference of two-item array references. Each of these
two-item array references represents a possible value for the widget, with the
first item containing the value and the second item containing its label.
Returns an empty array if there are no options. Usefull for select lists,
pulldowns, and the like.

=cut

sub options {
    my $code = shift->{options};
    return $code->(@_);
}

1;
__END__

=head1 Coverage

 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 File                           stmt branch   cond    sub    pod   time  total
 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 blib/lib/Widget/Meta.pm       100.0  100.0  100.0  100.0  100.0  100.0  100.0
 Total                         100.0  100.0  100.0  100.0  100.0  100.0  100.0
 ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 Support

This module is stored in an open L<GitHub
repository|http://github.com/theory/widget-meta/>. Feel free to fork and
contribute!

Please file bug reports via L<GitHub
Issues|http://github.com/theory/widget-meta/issues/> or by sending mail to
L<bug-Widget-Meta@rt.cpan.org|mailto:bug-Widget-Meta@rt.cpan.org>.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2004-2011 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms asx Perl itself.

=cut
