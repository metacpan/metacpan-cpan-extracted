package HTML::SuperForm::Field;

use overload;
use strict;

use Carp;

our %accessors = map { $_ => 1 } qw(multiple selectable value default form disabled readonly sticky fallback well_formed values_as_labels);
our %mutators;

sub prepare {}
sub init {}

sub new {
    my $class = shift;

    my $form;
    if(UNIVERSAL::isa($_[0], "HTML::SuperForm")) {
        $form = shift;
    }

    my $config = {};
    if(ref($_[0]) eq "HASH") {
        $config = shift;
    } else {
        %$config = @_;
    }

    overload::OVERLOAD($class, '""' => \&{$class . "::to_html"});

    my $self = {
        _other_info => {}
    };

    $self->{_form} = $form;

    bless $self, $class;

    $self->init($config);

    $self->{_readonly} = delete $config->{readonly};
    $self->{_disabled} = delete $config->{disabled};
    $self->{_multiple} = delete $config->{multiple};

    my $labels = delete $config->{labels} || {};
    my $all_values = delete $config->{values} || [ keys %$labels ];

    if(ref($all_values) ne "ARRAY") {
        $all_values = [ $all_values ];
    }

    if( defined($config->{value}) && @$all_values == 0) {
        push(@{$all_values}, $config->{value});
    }

    if(exists($config->{label})) {
        $self->{_label} = delete $config->{label};
    }

    $self->{_labels} = $labels;

    $self->{_all_values} = $all_values;
    my %all_values_hash = map { $_ => 1 } @$all_values;

    my $default;
    if(exists($config->{default})) {
        $default = delete $config->{default};
    } 

    if(exists($config->{defaults})) {
        $default = delete $config->{defaults};
    } 

    $self->{_default} = $default;

    if(ref($self->{_default}) eq "ARRAY" && scalar(@{$self->{_default}}) == 0) {
        $self->{_default} = undef;
    }

    if(UNIVERSAL::isa($form, "HTML::SuperForm")) {
        $self->{_fallback} = $self->{_form}->fallback;
        $self->{_sticky} = $self->{_form}->sticky;
        $self->{_well_formed} = $self->{_form}->well_formed;
        $self->{_values_as_labels} = $self->{_form}->values_as_labels;
    } else {
        $self->{_fallback} = 0;
        $self->{_sticky} = 0;
        $self->{_well_formed} = 1;
        $self->{_values_as_labels} = 1;
    }

    if($self->{_disabled}) {
        $self->{_sticky} = 0;
    }

    for my $key (qw(fallback sticky well_formed values_as_labels)) {
        if(exists($config->{$key})) {
            $self->{'_' . $key} = delete $config->{$key};
        }
    }

    if(exists($config->{value_as_label})) {
        $self->{_values_as_labels} = delete $config->{value_as_label};
    }

    $self->{_attributes} = $config;

    if($self->{_multiple} || scalar(@{$self->{_all_values}}) > 0) {
        $self->{_selectable} = 1;
    }

    if( UNIVERSAL::isa($form, "HTML::SuperForm") && 
            $self->sticky()         && 
            (exists($config->{name}) &&
             $form->exists_param($config->{name}) || !$self->fallback)
      ) {
        $self->{_value} = $form->param($config->{name});
    } else {
        $self->{_value} = $self->default;
    }

    if(!$self->selectable && ref($self->{_value}) eq "ARRAY") {
        my $i = $self->{_form}->no_of_fields($self->name);
        $self->{_value} = $self->{_value}[$i];
    }

    $self->{_value} = $self->escape_html($self->{_value});

    my @select = ();
    if(ref($self->{_value}) eq "ARRAY") {
        @select = @{$self->{_value}};
    } else {
        if(defined($self->{_value})) {
            @select = ( $self->{_value} );
        }
    }

    for my $s (@select) {
        $self->{_selected}{$s} = 1 if $all_values_hash{$s}; 
    }

    $self->prepare();
    $self->update_form();

    return $self;
}

sub escape_html {
    my $self = shift;
    my $arg = shift;

    if(ref($arg) eq "ARRAY") {
        my $strings = $arg;
        $arg = [];
        for(0..$#$strings) {
            $arg->[$_] = $strings->[$_];
            $arg->[$_] =~ s/(["&<>])/'&#' . ord($1) . ';'/ge;
        }
    } else {
        $arg =~ s/(["&<>])/'&#' . ord($1) . ';'/ge;
    }

    return $arg;
}

sub name {
    my $self = shift;
    return $self->{_attributes}{name};
}

sub set {
    my $self = shift;

    my %hash;

    if(ref($_[0]) eq "HASH") {
        %hash = %{ shift() };
    } else {
        %hash = @_;
    }

    $self->{_other_info} = {
        %{$self->{_other_info}},
        %hash,
    };

    return;
}

sub get {
    my $self = shift;

    my @return;

    for my $key (@_) {
        if(exists($self->{_other_info}{$key})) {
            push(@return, $self->{_other_info}{$key});
        } else {
            carp "WARNING: nothing stored under key $key";
        }
    }

    return wantarray            ? @return    : 
        scalar(@return) == 1 ? $return[0] : \@return;
}

sub label {
    my $self = shift;
    my $key = shift;

    if(defined($key)) {
        my $label;
        if(exists($self->{_labels}{$key})) {
            $label = $self->{_labels}{$key};
        } elsif($self->values_as_labels) {
            $label = $key;
        }

        return $label;
    }

    if(exists($self->{_label})) {
        return $self->{_label};
    } elsif($self->selectable && $self->values_as_labels && scalar(@{$self->{_all_values}}) == 1) {
        return @{$self->{_all_values}}[0];
    }

    return;
}

sub has_label {
    my $self = shift;

    if(exists($self->{_label}) || ($self->selectable && $self->values_as_labels && scalar(@{$self->{_all_values}}) == 1)) {
        return 1;
    }

    return;
}

sub get_attribute {
    my $self = shift;
    my $key = shift;

    return $self->{_attributes}{$key};
}

sub selected {
    my $self = shift;
    my $key = shift;

    if(ref($key) eq "ARRAY") {
        for my $k (@$key) {
            if($self->{_selected}{$k}) {
                return 1;
            }
        }
        return 0;
    }

    return $self->{_selected}{$key};
}

sub selected_str {
    my $self = shift;
    my $key = shift;
    if($self->well_formed) {
        return $self->selected($key) ? ' selected="selected"' : '';
    }
    return $self->selected($key) ? ' selected' : '';
}

sub checked_str {
    my $self = shift;
    my $key = shift;
    if($self->well_formed) {
        return $self->selected($key) ? ' checked="checked"' : '';
    }
    return $self->selected($key) ? ' checked' : '';
}

sub multiple_str {
    my $self = shift;

    if($self->well_formed) {
        return $self->multiple ? ' multiple="' . $self->multiple . '"' : '';
    }
    return $self->multiple ? ' multiple' : '';
}

sub readonly_str {
    my $self = shift;

    if($self->well_formed) {
        return $self->readonly ? ' readonly="' . $self->readonly . '"' : '';
    }
    return $self->readonly ? ' readonly' : '';
}

sub disabled_str {
    my $self = shift;

    if($self->well_formed) {
        return $self->disabled ? ' disabled="' . $self->disabled . '"' : '';
    }
    return $self->disabled ? ' disabled' : '';
}

sub update_form {
    my $self = shift;

    return unless $self->name();
    return unless UNIVERSAL::isa($self->form, "HTML::SuperForm");

    if(defined($self->default) || !$self->selectable) {
        $self->form->add_default($self->name() => $self->default);
    } else {
        $self->form->set_default($self->name() => undef);
    }
}

sub attribute_str {
    my $self = shift;

    return " " . join(' ', map { qq|$_="$self->{_attributes}{$_}"| } 
            keys %{$self->{_attributes}});
}

sub values {
    my $self = shift;

    return $self->{_all_values};
}

sub AUTOLOAD {
    my $self = $_[0];

    my ($key) = ${*AUTOLOAD} =~ /::([^:]*)$/;

    {
        no strict "refs";
        if(exists($mutators{$key})) {
            *{"HTML::SuperForm::Field::$key"} = sub {
                my $self = shift;
                my $val = shift;

                if(defined($val)) {
                    $self->{'_' . $key} = $val;
                    return;
                }

                return $self->{'_' . $key};
            };
            goto &{"HTML::SuperForm::Field::$key"};
        }

        if(exists($accessors{$key})) {
            *{"HTML::SuperForm::Field::$key"} = sub {
                my $self = shift;

                return $self->{'_' . $key};
            };
            goto &{"HTML::SuperForm::Field::$key"};
        }

        if(exists($self->{_attributes}{$key})) {
            *{"HTML::SuperForm::Field::$key"} = sub {
                my $self = shift;
                return $self->{_attributes}{$key};
            };
            goto &{"HTML::SuperForm::Field::$key"};
        } else {
            croak "ERROR: attribute $key doesn't exist";
        }
    }

    return;
}

sub DESTROY {}

1;
__END__

=head1 NAME

HTML::SuperForm::Field - HTML form field base class

=head1 SYNOPSIS

    package myForm::SuperDuper;

    use base 'HTML::SuperForm::Field';

    sub init {}
    sub prepare {}

    sub to_html {
        my $self = shift;

        my $tag = qq|For some reason this text makes|;
           $tag.= qq|the field super duper|
           $tag.= qq|<input type="text" name="| . $self->name . '"';
           $tag.= qq| value="| . $self->value . '"';
           $tag.= '/' if $self->well_formed;
           $tag.= '>';

        return $tag;
    }

    1;

=head1 DESCRIPTION

This is the base class for all the HTML form field objects.

=head1 METHODS

=head2 CONSTRUCTOR

=over 4

=item I<new($form, %args)>, I<new($form, \%args)>, I<new(%args)>, I<new(\%args)>

$form is the HTML::SuperForm object to associate the field with. %args usually has 
the following (each is also a method to access its value):

=over 4

=item I<name()>

The name of the field.

=item I<default()>

The default value to use before data has been submitted or 
if the form isn't sticky.

=back

Other possible arguments include:

=over 4

=item I<sticky()>

Determines whether the field is sticky or not. Defaults to what the
form object's sticky flag is set to. If no form object is specified
it defaults to false.

=item I<fallback()>

Determines whether the field's value "falls back" to the default if the 
field is sticky but no data has been submitted for the field. Defaults 
to what the form object's fallback flag is set to. If no form object 
is specified it defaults to false.

=item I<well_formed()>

Determines whether the HTML generated is well-formed or not. If true,
a slash is added to the end of non-container tags (i.e. 
<input type="text name="my_text"/>). Attributes such as multiple,
readonly, disabled, selected, and checked are also set equal to true
values instead of being left alone (i.e. <input type="checkbox" checked="checked">
rather than just <input type="checkbox" checked>).

=item I<values_as_labels()>, I<value_as_label()>

Determines whether the value specifed by value or values is used as a label
if no label is specified. Default is true.

=item I<disabled()>

Determines whether the field is disabled or not.

=back

Arguments not used by all the fields also include:

=over 4

=item I<multiple()>

Determines whether a field can have multiple values selected.
Only Select uses this feature.

=item I<readonly()>

Determines whether a field is readonly. Used by fields such as Text and Textarea.

=back

=back

=item I<init($config)>

This method is the very first thing called in HTML::SuperForm::Field's constructor.
Subclasses of HTML::SuperForm::Field should override this method to manipulate the
parameters passed in before processing them. An example is in HTML::SuperForm::Field::Checkbox.

=item I<prepare()>

This method is the very last thing called in HTML::SuperForm::Field's constructor.
Subclasses of HTML::SuperForm::Field should override this method to add extra information
to the object for later use. An example of its use is in the documentation for 
HTML::SuperForm under the section EXAMPLES.

=item I<to_html()>

This method returns the string representation of your field. When the object is used in
string context this method is called to generate the string.
Subclasses of HTML::SuperForm::Field should override this method display a default layout.
All of the basic fields that come with HTML::SuperForm have this method, so look at them
for examples. The Counter example in HTML::SuperForm's documentation could also be helpful.

=head1 SEE ALSO

 HTML::SuperForm::Field::Text, 
 HTML::SuperForm::Field::Textarea, 
 HTML::SuperForm::Field::Select, 
 HTML::SuperForm::Field::Checkbox, 
 HTML::SuperForm::Field::Radio, 
 HTML::SuperForm::Field::CheckboxGroup, 
 HTML::SuperForm::Field::RadioGroup

=head1 AUTHOR

John Allwine E<lt>jallwine86@yahoo.comE<gt>

=cut
