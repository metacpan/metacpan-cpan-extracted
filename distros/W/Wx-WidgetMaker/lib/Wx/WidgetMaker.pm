package Wx::WidgetMaker;

require 5.006;

our $VERSION = '0.11';


use strict;
use warnings;
use Carp qw(carp confess);

use Wx qw(:everything);

use fields qw(_parent);

# Some constants for consistency's sake
use constant wxDefaultID     => -1;
use constant wxDefaultWidth  => -1;
use constant wxDefaultHeight => -1;
use constant wxDefaultX      => -1;
use constant wxDefaultY      => -1;
use constant wxDefaultStyle  => 0;
# Pointsize corresponding to h1, h2, etc.
use constant POINTSIZE => {
    1 => 20, 2 => 16, 3 => 12, 4 => 10, 5 => 9, 6 => 8,
};
# Prefix added to some widget names so that params can avoid them
use constant MAGICPREFIX => '!!!#!!##!###';


sub new {
    my $class = shift;
    my ($parent) = _rearrange([qw(PARENT)], @_);

    _require_param_type(\$parent, 'Wx::Window', '-parent');

    my $self = bless {}, $class;
    $self->{'_parent'} = $parent;

    return $self;
}


sub h1 {
    my ($self, $text) = @_;
    return $self->_h($text, 1);
}
sub h2 {
    my ($self, $text) = @_;
    return $self->_h($text, 2);
}
sub h3 {
    my ($self, $text) = @_;
    return $self->_h($text, 3);
}
sub h4 {
    my ($self, $text) = @_;
    return $self->_h($text, 4);
}
sub h5 {
    my ($self, $text) = @_;
    return $self->_h($text, 5);
}
sub h6 {
    my ($self, $text) = @_;
    return $self->_h($text, 6);
}


sub textfield {
    my $self = shift;
    my ($name, $default, $width, $maxlength, $id) =
        _rearrange(['NAME', [qw(DEFAULT VALUE)], 'SIZE', 'MAXLENGTH', 'ID'], @_);
    my ($textfield, $size);

    _require_param(\$name, '-name');
    _init_param(\$default, '');
    _init_param(\$id, wxDefaultID);

    if (defined $width) {
        if ($width =~ /^\d+$/) {
            $size = wxSIZE($width, wxDefaultHeight);
        } else {
            carp '-size argument ignored (not a whole number)';
        }
    }
    _init_param(\$size, wxDefaultSize);

    # XXX: maxlength not implemented yet, need to set a validator

    $textfield = Wx::TextCtrl->new(
        $self->{'_parent'}, $id, $default,
        wxDefaultPosition, $size,
        wxNO_BORDER, wxDefaultValidator, $name
    );

    return $textfield;
}


sub password_field {
    my $self = shift;
    my ($name, $default, $width, $maxlength, $id) =
        _rearrange(['NAME', [qw(DEFAULT VALUE)], 'SIZE', 'MAXLENGTH', 'ID'], @_);
    my ($password_field, $size);

    _require_param(\$name, '-name');
    _init_param(\$default, '');
    _init_param(\$id, wxDefaultID);

    if (defined $width) {
        if ($width =~ /^\d+$/) {
            $size = wxSIZE($width, wxDefaultHeight);
        } else {
            carp '-size argument ignored (not a whole number)';
        }
    }
    _init_param(\$size, wxDefaultSize);

    # XXX: maxlength not implemented yet, need to set a validator

    $password_field = Wx::TextCtrl->new(
        $self->{'_parent'}, $id, $default,
        wxDefaultPosition, $size,
        wxTE_PASSWORD, wxDefaultValidator, $name
    );

    return $password_field;
}


sub textarea {
    my $self = shift;
    my ($name, $default, $rows, $columns, $id) =
        _rearrange(['NAME',[qw(DEFAULT VALUE)],'ROWS',[qw(COLS COLUMNS)], 'ID'], @_);
    my ($textarea, $size);

    _require_param(\$name, '-name');
    _init_param(\$default, '');
    _init_param(\$id, wxDefaultID);

    if (defined $rows && defined $columns) {
        unless ($rows =~ /^\d+$/) {
            carp '-rows argument ignored (not a whole number)';
        }
        unless ($columns =~ /^\d+$/) {
            carp '-columns argument ignored (not a whole number)';
        }
        if ($rows =~ /^\d+$/ && $columns =~ /^\d+$/) {
            $size = wxSIZE($columns, $rows);
        }
    }
    _init_param(\$size, wxSIZE(100, 50));

    $textarea = Wx::TextCtrl->new(
        $self->{'_parent'}, $id, $default,
        wxDefaultPosition, $size,
        wxTE_MULTILINE, wxDefaultValidator, $name
    );

    return $textarea;
}


sub popup_menu {
    my $self = shift;
    my ($name, $values, $default, $labels, $id) =
        _rearrange(
            ['NAME', [qw(VALUES VALUE)], [qw(DEFAULT DEFAULTS)], 'LABELS', 'ID'],
            @_
        );
    my ($popup_menu);

    _require_param(\$name, '-name');
    _require_param_type(\$values, 'ARRAY', '-values');
    _init_param(\$default, $values->[0]);
    _init_param(\$id, wxDefaultID);

    $popup_menu = Wx::Choice->new(
        $self->{'_parent'}, $id, wxDefaultPosition, wxDefaultSize,
        _make_labels($values, $labels),
        wxDefaultStyle, wxDefaultValidator, $name
    );
    for (my $i = 0; $i < @$values; $i++) {
        $popup_menu->SetClientData($i, $values->[$i]);
    }
    $popup_menu->SetStringSelection($default);

    return $popup_menu;
}


sub scrolling_list {
    my $self = shift;
    my ($name, $values, $default, $height, $multiple, $labels, $id) =
        _rearrange(
            ['NAME', [qw(VALUE VALUES)], [qw(DEFAULT DEFAULTS)],
             'SIZE', 'MULTIPLE', 'LABELS', 'ID'],
            @_
        );
    my ($scrolling_list, @labels, $style, $size);

    _require_param(\$name, '-name');
    _require_param_type(\$values, 'ARRAY', '-values');
    _init_param(\$default, $values->[0]);
    _init_param(\$id, wxDefaultID);

    if (defined $height) {
        if ($height =~ /^\d+$/) {
            $size = wxSIZE(wxDefaultWidth, $height);
        } else {
            carp '-size argument ignored (not a whole number)';
        }
    }
    _init_param(\$size, wxSIZE(wxDefaultWidth, 50));

    if (defined $multiple && $multiple) {
        $style = wxLB_EXTENDED|wxLB_MULTIPLE;
    } else {
        $style = wxDefaultStyle;
    }

    $scrolling_list = Wx::ListBox->new(
        $self->{'_parent'}, $id, wxDefaultPosition, $size,
        _make_labels($values, $labels),
        wxCB_READONLY|$style, wxDefaultValidator, $name
    );

    for (my $i = 0; $i < @$values; $i++) {
        $scrolling_list->SetClientData($i, $values->[$i]);
    }
    $scrolling_list->SetStringSelection($default);

    return $scrolling_list;
}


sub checkbox_group {
    my $self = shift;
    my ($name, $values, $defaults, $linebreak, $labels, $rows, $columns,
        $rowheaders, $colheaders, $nolabels) =
            _rearrange(
                ['NAME', [qw(VALUE VALUES)], [qw(DEFAULT DEFAULTS)],
                 'LINEBREAK', 'LABELS', 'ROWS', [qw(COLUMNS COLS)],
                 'ROWHEADERS', 'COLHEADERS', 'NOLABELS'],
                @_
            );

    confess 'method not yet implemented';
}


sub checkbox {
    my $self = shift;
    my ($name, $checked, $value, $label, $id) =
        _rearrange(['NAME', [qw(CHECKED SELECTED ON)], 'VALUE', 'LABEL', 'ID'], @_);
    my ($checkbox);

    _require_param(\$name, '-name');
    _init_param(\$checked, 0);
    _init_param(\$label, $name);
    _init_param(\$id, wxDefaultID);

    $checkbox = Wx::CheckBox->new(
        $self->{'_parent'}, $id, $label,
        wxDefaultPosition, wxDefaultSize,
        wxDefaultStyle, wxDefaultValidator, $name
    );

    return $checkbox;
}


sub radio_group {
    my $self = shift;
    my ($name, $values, $default, $linebreak, $labels,
        $rows, $columns, $rowheaders, $colheaders, $nolabels,
        $caption, $id) =
            _rearrange(
                ['NAME', [qw(VALUES VALUE)], 'DEFAULT', 'LINEBREAK',
                 'LABELS', 'ROWS', [qw(COLUMNS COLS)],
                 'ROWHEADERS', 'COLHEADERS', 'NOLABELS', 'CAPTION', 'ID'],
                @_
            );
    my ($radio_group, $style, @labels, $major_dimension);

    _require_param(\$name, '-name');
    _require_param_type(\$values, 'ARRAY', '-values');
    _init_param(\$default, $values->[0]);
    _init_param(\$id, wxDefaultID);

    if (defined $nolabels && $nolabels) {
        @labels = map {''} @labels;
    } else {
        @labels = @{ _make_labels($values, $labels) };
    }

    _init_param(\$caption, '');

    _init_param(\$rows, 1);
    _init_param(\$columns, 1);
    if (defined $linebreak && $linebreak) {
        $style = wxRA_SPECIFY_COLS;
        $major_dimension = $columns;
    } else {
        $style = wxRA_SPECIFY_ROWS;
        $major_dimension = $rows;
    }

    $radio_group = Wx::RadioBox->new(
        $self->{'_parent'}, $id, $caption,
        wxDefaultPosition, wxDefaultSize,
        \@labels, $major_dimension,
        $style, wxDefaultValidator, $name
    );

    return $radio_group;
}


sub submit {
    my $self = shift;
    my ($name, $value, $id) = _rearrange(['NAME', [qw(VALUE LABEL)], 'ID'], @_);
    my ($button);

    _require_param(\$name, '-name');
    _init_param(\$value, 'Submit');
    _init_param(\$id, wxDefaultID);

    $button = Wx::Button->new(
        $self->{'_parent'}, $id, $value,
        wxDefaultPosition, wxDefaultSize, wxDefaultStyle,
        wxDefaultValidator, $name
    );

    return $button;
}


sub image_button {
    my $self = shift;
    my ($name, $src, $id) = _rearrange([qw(NAME SRC ID)], @_);
    my ($button, $bitmap);

    _require_param(\$name, '-name');
    _require_param(\$src, '-src');
    _init_param(\$id, wxDefaultID);

    $bitmap = _bitmap($src);
    $button = Wx::BitmapButton->new(
        $self->{'_parent'}, $id, $bitmap,
        wxDefaultPosition, wxDefaultSize, wxDefaultStyle,
        wxDefaultValidator, $name
    );

    return $button;
}


sub print {
    my $self = shift;
    my ($add, $sizer, $option, $flag, $border) =
        _rearrange([qw(ADD SIZER OPTION FLAG BORDER)], @_);

    _init_param(\$add, '');
    _init_param(\$option, 0);
    _init_param(\$flag, 0);
    _init_param(\$border, 0);

    if (defined $sizer) {
        _require_param_type(\$sizer, 'Wx::Sizer', '-sizer');

        if (ref($add) eq 'ARRAY') {
            foreach my $control (@$add) {
                _require_param_type(\$control, ['Wx::Control', 'Wx::Sizer']);
                $sizer->Add($control, $option, $flag, $border);
            }
        } else {
            _require_param_type(\$add, ['Wx::Control', 'Wx::Sizer']);
            $sizer->Add($add, $option, $flag, $border);
        }

        return;    # should be void context anyway
    } else {
        my $name = MAGICPREFIX . 'print';
        return Wx::StaticText->new(
            $self->{'_parent'}, wxDefaultID, $add,
            wxDefaultPosition, wxDefaultSize, wxDefaultStyle,
            $name
        );
    }
}


sub param {
    my $self = shift;
    my ($name) = _rearrange([qw(NAME)], @_);
    my (@children);

    _init_param(\$name);

    @children = $self->{'_parent'}->GetChildren();

    if (defined $name) {
        foreach my $child (@children) {
            if ($child->GetName() eq $name) {
                my $data = $self->_get_form_data($child);

                if (ref($data) eq 'ARRAY') {
                    if (wantarray) {
                        return @$data;
                    } else {
                        return $data->[0];
                    }
                } else {
                    return $data;
                }
            }
        }
    } else {
        my $prefix = MAGICPREFIX;
        return grep {!/^$prefix/} map {$_->GetName()} @children;
    }
}


### PRIVATE ###

sub _get_form_data {
    my ($self, $child) = @_;
    my ($value);

    local *isa = \&UNIVERSAL::isa;
    undef $value;

    # XXX: should check if $child->Get* doesn't return a value
    if (isa($child, 'Wx::TextCtrl')) {
        $value = $child->GetValue();
    } elsif (isa($child, 'Wx::Choice')) {
        $value = $child->GetClientData($child->GetSelection());
    } elsif (isa($child, 'Wx::ListBox')) {
        $value = [ $child->GetClientData($child->GetSelections()) ];
    } elsif (isa($child, 'Wx::RadioBox')) {
        $value = $child->GetStringSelection();
    } elsif (isa($child, 'Wx::CheckBox')) {
        $value = $child->GetValue() || '';
    } elsif (isa($child, 'Wx::Button') || isa($child, 'Wx::BitmapButton')) {
        $value = $child->GetLabel();
    }

    return $value;
}

sub _page_width {
    my $self = shift;
    return $self->{'_parent'}->GetSize()->GetWidth();
}

# Does h1, h2, ..., h6
sub _h {
    my $self = shift;
    my ($text, $num) = @_;
    my ($textctrl, $font, $name);

    $name = MAGICPREFIX . "h$num";
    $textctrl = Wx::StaticText->new(
        $self->{'_parent'}, wxDefaultID, $text,
        wxDefaultPosition, wxSIZE($self->_page_width(), wxDefaultHeight),
        wxALIGN_LEFT, $name
    );

    $font = Wx::Font->new(POINTSIZE->{$num}, wxDEFAULT, wxNORMAL, wxBOLD);
    $textctrl->SetFont($font);

    return $textctrl;
}


# Note that the following are not class or object methods.
# There is no $self argument.


# Verify that the variable pointed to by reference $ptr
# is defined (i.e. was given as an argument in
# the calling subroutine. If $$ptr is undef,
# set $$ptr to $default (or undef if $default isn't
# supplied).
sub _init_param {
    my ($ptr, $default) = @_;
    undef $default unless defined $default;
    $$ptr = $default unless defined $$ptr;
}

# Verify that the variable pointed to by reference $ptr is
# an object of class $class. If $$ptr is undef or not an
# object of $class and $default is supplied, set $$ptr
# to $default (or undef if $default isn't supplied).
# Optional $arg is used for named parameters and only
# in the warning message to help with debugging.
sub _init_param_class {
    my ($ptr, $default, $class, $arg) = @_;
    undef $default unless defined $default;
    _init_param(\$arg, '');

    if (defined $$ptr) {
        unless (UNIVERSAL::isa($$ptr, $class)) {
            carp "argument $arg ignored (not a $class)";
            undef $$ptr;
        }
    }
    _init_param($ptr, $default);
}

# Require $$ptr to have been given as an argument
sub _require_param {
    my ($ptr, $arg) = @_;
    _init_param(\$arg, '');

    confess "$arg argument missing" unless defined $$ptr;
}

# Require $$ptr to have been given and to be of type $types.
# $types can be an arrayref, in which case $$ptr has to
# be one of the types in the array.
sub _require_param_type {
    my ($ptr, $types, $arg) = @_;
    _init_param(\$arg, '');

    $types = [$types] unless ref($types) eq 'ARRAY';

    if (defined $$ptr) {
        foreach my $type (@$types) {
            return if UNIVERSAL::isa($$ptr, $type);
        }
    }

    confess "$arg argument invalid (not a '", join(" or '", @$types), "')";
}

sub _no_op {
    # No operation, in case you use something
    # like `start_form' out of habit.
}

# Convenience function for making labels from values
# (for things like popup_menu, radio_group, ...)
sub _make_labels {
    my ($values, $labels) = @_;
    my (@labels);

    foreach my $value (@$values) {
        $labels->{$value} = $value unless defined $labels->{$value};
    }
    for (my $i = 0; $i < @$values; $i++) {
        push @labels, $labels->{$values->[$i]};
    }

    return \@labels;
}

# This is CGI::Util::rearrange, swiped almost directly from CGI.pm.
# If the first parameter begins with '-', it rearranges the
# parameters so that you can use named parameters; otherwise,
# you pass the parameters in order.
# I didn't want to load CGI::Util just for this function,
# plus I removed the part where leftover arguments are
# made into HTML attributes.
sub _rearrange {
    my ($order, @param) = @_;
    my ($i, %pos, @result);

    return () unless @param;

    if (ref($param[0]) eq 'HASH') {
        @param = %{ $param[0] };
    } else {
        return @param
            unless defined($param[0]) && substr($param[0],0,1) eq '-';
    }

    # map parameters into positional indices
    $i = 0;
    foreach (@$order) {
        foreach (ref($_) eq 'ARRAY' ? @$_ : $_) { $pos{lc($_)} = $i; }
        $i++;
    }

    $#result = $#$order;  # preextend
    while (@param) {
        my $key = lc(shift(@param));
        $key =~ s/^\-//;
        if (exists $pos{$key}) {
            $result[$pos{$key}] = shift(@param);
        }
    }

    return @result;
}

# Make a Bitmap from a filename
sub _bitmap {
    my $filename = shift;
    my ($type);

    carp "bitmap file not found" unless -r $filename;

    if ($filename =~ /\.bmp$/i) {
        $type = wxBITMAP_TYPE_BMP;
    } elsif ($filename =~ /\.gif$/i) {
        $type = wxBITMAP_TYPE_GIF;
    } elsif ($filename =~ /\.xbm$/i) {
        $type = wxBITMAP_TYPE_XBM;
    } elsif ($filename =~ /\.xpm$/i) {
        $type = wxBITMAP_TYPE_XPM;
    } elsif ($filename =~ /\.jpg$/i || $filename =~ /\.jpeg$/i) {
        $type = wxBITMAP_TYPE_JPEG;
    } elsif ($filename =~ /\.png$/i) {
        $type = wxBITMAP_TYPE_PNG;
    } elsif ($filename =~ /\.pcx$/i) {
        $type = wxBITMAP_TYPE_PCX;
    } elsif ($filename =~ /\.pnm$/i) {
        $type = wxBITMAP_TYPE_PNM;
    } elsif ($filename =~ /\.tif$/i || $filename =~ /\.tiff$/i) {
        $type = wxBITMAP_TYPE_TIF;
    } else {
        undef $type;   # well, we tried
    }

    return Wx::Bitmap->new($filename, $type);
}



1;

__END__



=head1 NAME

Wx::WidgetMaker - a CGI.pm-like library for wxPerl

=head1 SYNOPSIS

    use Wx::WidgetMaker;

    $dialog = Wx::Dialog->new(...);
    $q = Wx::WidgetMaker->new(-parent => $dialog);

    # The dialog "page"
    $pagesizer = Wx::BoxSizer->new(wxVERTICAL);

    # A "row" in the page
    $rowsizer = Wx::BoxSizer->new(wxHORIZONTAL);

    # "print" a control to a row
    $ctrl = $q->h1('H1 text');
    $q->print($ctrl, $rowsizer);

    # Add the row to the page
    $q->print($rowsizer, $pagesizer);

    # A new row
    $rowsizer = Wx::BoxSizer->new(wxHORIZONTAL);

    # print a label and textfield in an array
    $ctrl2 = $q->password_field(
        -name => 'password',
        -default => 'blue',
        -size => 50,         # window width, not number of chars
        -maxlength => 30,
    );
    $q->print([$q->print('Password: '), $ctrl2], $rowsizer);

    # Add the row to the page
    $q->print($rowsizer, $pagesizer);

    # Add some buttons
    $rowsizer = Wx::BoxSizer->new(wxHORIZONTAL);

    $okbutton = $q->submit('ok', 'OK', wxID_OK);
    $cancelbutton = $q->submit('cancel', 'Cancel', wxID_CANCEL);
    $q->print([$okbutton, $cancelbutton], $rowsizer);

    $q->print($rowsizer, $pagesizer);

    # Put widgets in the dialog as normal
    $dialog->SetAutoLayout(1);
    $dialog->SetSizer($pagesizer);
    $pagesizer->Fit($dialog);

    # Get dialog data
    if ($dialog->ShowModal() == wxID_OK) {
        $password = $q->param('password');
    }
    $dialog->Destroy();

=head1 DESCRIPTION

When starting to learn wxPerl, it can be frustrating
trying to figure out which widgets handle what functionality.
If you've ever done CGI development, you soon realize why
it's not a bad idea to leverage the web browser as a graphical
user interface: it can be complicated to implement functionality
that you take for granted as an HTML/CGI developer.

This module tries to make implementing wxPerl dialogs friendlier
to a Perl CGI programmer by using an API similar to CGI.pm.
(Specifically, it supports what I consider to be a
useful/relevant subset of CGI.pm's :standard export tags.)
It tries to adhere as faithfully as reasonable to the CGI
API where applicable, and otherwise to try to do something
intuitive.

Every form-related method (popup_menu, textfield, etc.) requires
a -name parameter. It serves the same purpose as in CGI.pm.
The values the user has entered/selected on the form are accessible
through $q->param('somename') where 'somename' was given as a
-name argument.

=head1 METHODS

Here is a reference for the API. Generally methods either
take named parameters (-name => 'first') or unnamed parameters
passed in the order listed. Optional parameters have
their default value listed to the right in parentheses;
otherwise, the parameter is required.

=head2 new

The constructor.

I<Parameters>

=over 4

=item * -parent

The parent window (must be a Wx::Window).

=back

I<Returns>

A new Wx::WidgetMaker object.

=head2 h1, h2, h3, h4, h5, h6

Analogous to the HTML tags with the same names.
These methods display their string parameter in bold font
in various sizes, C<h1> using the largest and C<h6> the
smallest. Note that unlike the HTML tags, there are no
linebreaks before or after the text, so you have to
explicitly put them on their own row (e.g. by adding to
a wxHORIZONTAL BoxSizer).

I<Parameters>

=over 4

=item * a text string

=back

I<Returns>

A Wx::StaticText object.

=head2 textfield

I<Parameters>

=over 4

=item * -name

A name for the textfield.

=item * -default, -value     ('')

Default text for the textfield.

=item * -size                (-1)

The size (width) of the textfield.

=item * -maxlength           (unimplemented)

The maximum number of characters that the user
can put in the textfield. This is currently unimplemented.

=item * -id                  (wxDefaultID)

Sets the ID argument for the Wx::TextCtrl.

=back

I<Returns>

A Wx::TextCtrl object.

=head2 password_field

I<Parameters>

=over 4

=item * -name

A name for the password field.

=item * -default, -value     ('')

Default text for the password field.

=item * -size                (-1)

The size (width) of the password field.

=item * -maxlength           (unimplemented)

The maximum number of characters that the user
can put in the password field.

=item * -id                  (wxDefaultID)

Sets the ID argument for the Wx::TextCtrl.

=back

I<Returns>

A Wx::TextCtrl object.

=head2 textarea

I<Parameters>

=over 4

=item * -name

A name for the textarea.

=item * -default, -value     ('')

Default text for the textarea.

=item * -rows                (50)

Height in pixels (XXX: would prefer it to be number of rows of text).

=item * -columns, -cols      (100)

Width in pixels (XXX: would prefer it to be the width in chars).

=item * -id                  (wxDefaultID)

Sets the ID argument for the Wx::TextCtrl.

=back

I<Returns>

A Wx::TextCtrl object.

=head2 popup_menu

I<Parameters>

=over 4

=item * -name

A name for the popup_menu.

=item * -value, -values

A reference to a array of values for the menu.

=item * -default, -defaults     (first element of -value aref)

The menu value initially selected.

=item * -labels                 (from -value)

A hash reference associating each value in -values
with a text label.

=item * -id                     (wxDefaultID)

Sets the ID argument for the Wx::Choice.

=back

I<Returns>

A Wx::Choice object.

=head2 scrolling_list

I<Parameters>

=over 4

=item * -name

A name for the scrolling_list.

=item * -value, -values

A reference to an array of values for the menu.

=item * -default, -defaults            (first element of -value aref)

The menu value initially selected.

=item * -size                          (50)

The height of the window.
(XXX: would prefer it to be the number of items to show at once)

=item * -multiple                      (false => default style)

True if the user can select multiple menu items.

=item * -labels                        (from -value)

A hash reference associating each value in -values
with a text label.

=item * -id                            (wxDefaultID)

Sets the ID argument for the Wx::ListBox.

=back

I<Returns>

A Wx::ListBox object.

=head2 checkbox_group

B<This method is not implemented yet.>

I<Parameters>

=over 4

=item * -name

A name for the checkbox_group.

=item * -value, -values

A reference to an array of values for the underlying checkbox values.

=item * -default, -defaults              (no boxes checked)

A value which is initially checked.

=item * -linebreak                       (false => horizontal)

Set this to a true value in order to display the checkboxes
vertically. See the -rows and -cols entries for details.

=item * -labels                          (from -value)

A hash reference associating each value in -values
with a text label.

=item * -rows                            (1)

If -linebreak is false, the value of -rows is the
maximum number of rows to display.

=item * -cols (or -columns)              (1)

If -linebreak is true, the value of -cols is the
maximum number of cols to display.

=item * -rowheaders

This parameter is not yet implemented.

=item * -colheaders

This parameter is not yet implemented.

=item * -nolabels                        (false => display labels)

Set this to true to not display any labels (more precisely,
to display '' for all labels).

=back

=head2 checkbox

I<Parameters>

=over 4

=item * -name

A required name for the checkbox.

=item * -checked, -selected, -on         (false => not checked)

Set any of these optional parameters to a true value in order
for the checkbox to be checked initially.

=item * -value

This parameter does nothing. In CGI.pm, you could use
it to set a value associated with the checkbox being 'on',
but in wxPerl that value is TRUE if the checkbox
is checked and FALSE if it is not checked.

=item * -label                           (-name argument)

An optional label displayed to the user.

=item * -id                              (wxDefaultID)

Sets the ID argument for the Wx::CheckBox.

=back

I<Returns>

A Wx::CheckBox object.

=head2 radio_group

I<Parameters>

=over 4

=item * -name

A required name for the radio_group.

=item * -value, -values

A reference to an array of values. These values will be
displayed as the radio button labels. See also -labels.

=item * -default                     (none selected)

A value which is initially checked.

=item * -linebreak                   (false => horizontal)

Set this to a true value in order to display the checkboxes
vertically. See the -rows and -cols entries for details.

=item * -labels                      (use -values)

A synonym for -values. In CGI.pm, -values gives each radio button
a value, while -labels gives the labels. For wxPerl, the radio
buttons have no associated values, so using either -values or
-labels is equivalent. If both are given, -labels takes precedence.

=item * -rows                        (1)

If -linebreak is false (or not given), the value of -rows
is the (maximum) number of rows to display.

=item * -cols (or -columns)          (1)

If -linebreak is true, the value of -cols is the
(maximum) number of cols to display.

=item * -rowheaders

This parameter is not yet implemented.

=item * -colheaders

This parameter is not yet implemented.

=item * -nolabels                    (false)

Set this to true to not display any labels.

=item * -caption                     ('')

This parameter is additional to CGI.pm but is useful here because
there is a StaticBox put arround the group of radio buttons
(whether you like it or not, Wx::RadioBox does this).
Use the -caption option to specify the label for the StaticBox.
At some point I might implement the radio_group using
individual RadioBoxes and give the option to not surround
the radio_group with a StaticBox; this would also allow
implementing -rowheaders and -colheaders.

=item * -id                          (wxDefaultID)

Sets the ID argument for the Wx::RadioBox.

=back

I<Returns>

A Wx::RadioBox object.

=head2 submit

Makes a button with text on it. Note that this is not like the
submit button in a CGI form because there is no event handler
attached to the button, so by default clicking on the button
does nothing.

I<Parameters>

=over 4

=item * -name

A required name for the submit button. Unlike CGI.pm, this name
will not be displayed as the button label. It is the window name.
Otherwise, this -name parameter would be inconsistent with
other methods.

=item * -value, -label            ('Submit')

In CGI.pm, -value (or -label) gives the button an associated string
"underneath" to pass to the application when the button is pressed.
Here, instead, the -value will be the button label. Note that
you can retrieve the label string with $button->GetLabel().

=item * -id                       (wxDefaultID)

Sets the ID argument for the Wx::Button, for example
wxID_OK or wxID_CANCEL.

=back

I<Returns>

A Wx::Button object.

=head2 image_button

I<Parameters>

=over 4

=item * -name

A required name for the button.

=item * -src

A filename giving the location of the bitmap on the button.
You have to give either the absolute filename or the
filename relative to the current working directory.
Currently, filenames with the folling suffixes
are supported (assuming your wxWindows has it compiled in):
.bmp, .gif, .xbm, .xpm, .jpg, .jpeg, .png, .pcx, .pnm, .tif, .tiff.
Otherwise, it will probably segfault.

=item * -align

This parameter is not implemented.

=item * -id                  (wxDefaultID)

Sets the ID argument for the Wx::BitmapButton.

=back

I<Returns>

A Wx::BitmapButton object.

=head2 print

This isn't a CGI.pm method (though it _is_ an Apache.pm method :),
but is handy for either creating a StaticText object or adding
Control or Sizer objects to a Sizer.

I<Parameters>

=over 4

=item * -add

This parameter is overloaded depending on context. If the argument
is a plain string, a StaticText object will be returned (XXX: maybe
this should be part of textfield, instead). If the
argument is a Wx::Control (something returned by one of
the other Wx::WidgetMaker methods, like TextCtrl, Choice, etc..)
or a Wx::Sizer (BoxSizer, for example) or an array reference of
these types of objects, and the -sizer argument is a Wx::Sizer,
the control or sizer will be added directly to the sizer.
See the -sizer parameter description for details.

=item * -sizer     (undef)

If the -add argument is a Wx::Control or Wx::Sizer object,
the object will be added to the Wx::Sizer specified by the
-sizer argument with $sizer->Add($control). If the -add argument
is an array reference of Wx::Control objects, all of the objects
will be added sequentially to the $sizer.

=item * -option    (0)

The `option' parameter to Wx::Sizer::Add.

=item * -flag      (0)

The `flag' parameter to Wx::Sizer::Add.

=item * -border    (0)

The `border' parameter to Wx::Sizer::Add.

=back

I<Returns>

Either a Wx::StaticText object if -text is a string,
or some Wx::Control subclass if -sizer is given.

=head2 param

I<Parameters>

=over 4

=item * either zero or one string

Note that there is no "setter" version of param.

=back

I<Returns>

If no arguments are passed, returns a list of all the child
controls' names (assuming they have a name, which they will
if they were created with this module). If a name is passed,
in list context returns a list of the selected values,
while in scalar context returns the first value found.

=head1 AUTHOR

Copyright 2002-2004, Scott Lanning <lannings@who.int>.
All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

The L<Wx|Wx> and L<CGI|CGI> PODs.

The wxPerl mailing list.

=cut
