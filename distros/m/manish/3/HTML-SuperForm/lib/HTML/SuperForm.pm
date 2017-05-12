package HTML::SuperForm;

use strict;
use HTML::SuperForm::Field;
use Carp;

our $VERSION = 1.04;

my %fields = map { $_ => 1 } qw(textarea text checkbox select radio checkbox_group radio_group password hidden submit);
my %mutators    = map { $_ => 1 } qw(well_formed sticky fallback values_as_labels);
my %accessors    = map { $_ => 1 } qw(field_object params);

sub new {
    my $class = shift;
    my $arg = shift;
    my $field_object = shift || "HTML::SuperForm::Field";

    my $params = {};
    my $method = $ENV{REQUEST_METHOD};
    my $content_type = $ENV{CONTENT_TYPE};
    my $parameters_from = '';

    if(UNIVERSAL::isa($arg, "Apache") && eval("require Apache::Request")) {
        my $apr;
        if(UNIVERSAL::isa($arg, "Apache::Request")) {
            $apr = $arg;
        } else {
            $apr = Apache::Request->instance($arg);
        }
        my @ps = $apr->param();
        for my $p (@ps) {
            my @values = $apr->param($p);

            if(scalar(@values) > 1) {
                $params->{$p} = \@values;
            } else {
                $params->{$p} = $values[0];
            }
        }
        $parameters_from = 'Apache::Request';
    } elsif(ref($arg) eq "HASH") {
        $params = $arg;
        $parameters_from = 'hash reference';
    } elsif(UNIVERSAL::isa($arg, "CGI")) {
        my $vars = $arg->Vars();
        for my $key (keys %$vars) {
            if($vars->{$key} =~ /\0/) {
                $params->{$key} = [ split('\0', $vars->{$key}) ];
            } else {
                $params->{$key} = $vars->{$key};
            }
        }
        $parameters_from = 'CGI';
    } elsif($ENV{CONTENT_TYPE} eq 'application/x-www-form-urlencoded') {
        my $query = $ENV{QUERY_STRING};

        my @pairs = split(/[&;]/, $query);

        if($method eq 'POST') {
            my $len = $ENV{CONTENT_LENGTH};
            my $pquery;
            sysread STDIN, $pquery, $len;

            push(@pairs, split(/[&;]/, $pquery));
        }

        for my $pair (@pairs) {
            my ($key, $value) = split('=', $pair);
            $key =~ tr/+/ /;
            $key =~ s/%([0-9A-Za-z]{2})/chr(hex($1))/ge;
            $value =~ tr/+/ /;
            $value =~ s/%([0-9A-Za-z]{2})/chr(hex($1))/ge;
            if(exists($params->{$key})) {
                if(ref($params->{$key}) eq "ARRAY") {
                    push(@{$params->{$key}}, $value);
                } else {
                    $params->{$key} = [ $params->{$key}, $value ];
                }
            } else {
                $params->{$key} = $value;
            }
        }
        $parameters_from = 'ENV';
    }

    my $self = { 
        _params => $params,
        _method => $method,
        _sticky => 0,
        _fallback => 0,
        _well_formed => 1,
        _values_as_labels => 1,
        _field_object => $field_object,
        _attributes => {
            method => "POST"
        },
        _other_info => {},
        _parameters_from => $parameters_from
    };

    bless $self, $class;

    return $self;
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

    return wantarray         ? @return    : 
        scalar(@return) == 1 ? $return[0] : \@return;
}

sub start_form {
    my $self = shift;

    my $config = {};

    if(ref($_[0]) eq "HASH") {
        $config = shift;
    } else {
        %$config = @_;
    }

    $self->{_attributes} = {
        %{$self->{_attributes}},
        %$config,
    };

    my $tag = "<form";

    my $attrib_str = join(' ', map { qq|$_="$self->{_attributes}{$_}"| } 
            keys %{$self->{_attributes}});

    $tag .= " $attrib_str" if $attrib_str;
    $tag .= ">";

    if(lc($self->{_attributes}{method}) eq lc($self->{_method})) {
        $self->set_sticky(1);
    }

    return $tag;
}

sub end_form {
    my $self = shift;

    return "</form>";
}

sub set_sticky {
    my $self = shift;
    $self->sticky(shift);
}

sub no_of_fields {
    my $self = shift;
    my $name = shift;

    if(exists($self->{_defaults}{$name})) {
        if(ref($self->{_defaults}{$name}) eq "ARRAY") {
            return scalar(@{$self->{_defaults}{$name}});
        } else {
            return 1;
        }
    }
    return 0;
}

sub trim_params {
    my $self = shift;

    for my $key (keys %{$self->{_params}}) {
        $self->{_params}{$key} =~ s/^\s+//;
        $self->{_params}{$key} =~ s/\s+$//;
    }
}

sub param {
    my $self = shift;

    if(ref($_[0]) eq "HASH") {
        for my $key (keys %{$_[0]}) {
            $self->{_params}{$key} = $_[0]->{$key};
        }
        return;
    } elsif(scalar(@_) > 1) {
        my %hash = @_;
        for my $key (keys %hash) {
            $self->{_params}{$key} = $hash{$key};
        }
        return;
    }

    return $self->{_params}{$_[0]};
}

sub add_default {
    my $self = shift;

    my %hash;

    if(ref($_[0]) eq "HASH") {
        %hash = %{$_[0]};
    } else {
        %hash = @_;
    }

    while(my ($key, $value) = each %hash) {
        if(exists($self->{_defaults}{$key})) {
            if(ref($self->{_defaults}{$key}) eq "ARRAY") {
                push(@{$self->{_defaults}{$key}}, $value);
            } else {
                $self->{_defaults}{$key} = [ $self->{_defaults}{$key}, $value ];
            }
        } else {
            $self->{_defaults}{$key} = $value;
        }
    }

    return;
}

sub defaults {
    my $self = shift;

    my $defaults = {};

    for my $key (keys %{$self->{_defaults}}) {
        if(ref($self->{_defaults}) eq "ARRAY") {
            $defaults->{$key} = [ @{$self->{_defaults}{$key}} ];
        } else {
            $defaults->{$key} = $self->{_defaults}{$key};
        }
    }

    return $defaults;
}

sub set_default {
    my $self = shift;

    my %hash;

    if(ref($_[0]) eq "HASH") {
        %hash = %{$_[0]};
    } else {
        %hash = @_;
    }

    while( my ($key, $value) = each %hash) {
        $self->{_defaults}{$key} = $value;
    }

    return;
}

sub exists_param {
    my $self = shift;
    my $key = shift;

    return exists($self->{_params}{$key});
}

sub AUTOLOAD {
    my $self = $_[0];

    my ($key) = ${*AUTOLOAD} =~ /::([^:]*)$/;

    {
        no strict "refs";
        if(exists($fields{$key})) {
            my $field_name = ucfirst($key);
            $field_name =~ s/_(\w)/\U$1/g;

            my $object = $self->{_field_object} . "::" . $field_name;

            eval "require $object";
            *{"HTML::SuperForm::$key"} = sub {
                return $object->new(@_);
            };
            goto &{"HTML::SuperForm::$key"};
        }

        if(exists($mutators{$key})) {
            *{"HTML::SuperForm::$key"} = sub {
                my $self = shift;
                my $val = shift;

                if(defined($val)) {
                    $self->{'_' . $key} = $val;
                    return;
                }
                return $self->{'_' . $key};
            };
            goto &{"HTML::SuperForm::$key"};
        }

        if(exists($accessors{$key})) {
            *{"HTML::SuperForm::$key"} = sub {
                my $self = shift;
                return $self->{'_' . $key};
            };
            goto &{"HTML::SuperForm::$key"};
        }

        if(exists($self->{attributes}{$key})) {
            *{"HTML::SuperForm::$key"} = sub {
                my $self = shift;
                return $self->{_attributes}{$key};
            };
            goto &{"HTML::SuperForm::$key"};
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

HTML::SuperForm - HTML form generator

=head1 SYNOPSIS

    use HTML::SuperForm;
    use Apache::Constants qw(OK);

    sub handler {
        my $r = shift;

        my $form = HTML::SuperForm->new($r);

        my $text = $form->text(name => 'text',
                               default => 'Default Text');

        my $textarea = $form->textarea(name => 'textarea',
                                       default => 'More Default Text');

        my $select = $form->select(name => 'select',
                                   default => 2,
                                   values => [ 0, 1, 2, 3],
                                   labels => {
                                       0 => 'Zero',
                                       1 => 'One',
                                       2 => 'Two',
                                       3 => 'Three'
                                   });

        my $output = <<"END_HTML";
    <html>
    <body>
        <form>
        Text Field: $text<br>
        Text Area: $textarea<br>
        Select: $select
        </form>
    </body>
    </html>
    END_HTML


        $r->content_type('text/html');
        $r->send_http_header;

        $r->print($output);
        return OK;
    }

    OR

    #!/usr/bin/perl

    my $form = HTML::SuperForm->new();

    my $text = $form->text(name => 'text',
                           default => 'Default Text');

    my $textarea = $form->textarea(name => 'textarea',
                                   default => 'More Default Text');

    my $select = $form->select(name => 'select',
                               default => 2,
                               values => [ 0, 1, 2, 3],
                               labels => {
                                   0 => 'Zero',
                                   1 => 'One',
                                   2 => 'Two',
                                   3 => 'Three'
                               });

    my $output = <<"END_HTML";
    <html>
    <body>
        <form>
        Text Field: $text<br>
        Text Area: $textarea<br>
        Select: $select
        </form>
    </body>
    </html>
    END_HTML

    print "Content-Type: text/html\n\n";
    print $output;

=head1 DESCRIPTION

Used in its basic form, this module provides an interface for generating basic HTML form 
elements much like HTML::StickyForms does. The main difference is HTML::SuperForm returns 
HTML::SuperForm::Field objects rather than plain HTML. This allows for more flexibilty 
when generating forms for a complex application. 

To get the most out of this module, use it as a base (Super) class for your own form 
object which generates your own custom fields. If you don't use it this way, I guess 
there's really nothing Super about it.  Example are shown later in the document.
 
The interface was designed with mod_perl and the Template Toolkit in mind, but it works 
equally well in any cgi environment.

=head1 METHODS

=head2 CONSTRUCTOR

=over 4

=item I<new($r, $field_object)>, I<new($r)>, I<new()>

Creates a new HTML::SuperForm object.

If $arg is an Apache object then an Apache::Request object will be
created from it to retrieve the parameters. If you don't have
Apache::Request installed then it behaves as if $arg is undef.

If $arg is an Apache::Request object, CGI object or a hash
reference, then it is used to retrieve the parameters. If no
argument is given or the argument isn't an instance or subclass of
the objects mentioned above then the parameters are retreived
through the environment variables. If called in a non-cgi
environment, no stickyness is applied.

It is recommended to use CGI or Apache::Request because the
parameter parsing included in HTML::SuperForm doesn't include the
complexities that CGI and Apache::Request take in to account and
only works with application/x-www-form-urlencoded forms.

If you pass $field_object, then HTML::SuperForm will use that object
instead of HTML::SuperForm::Field. See *field_object()* below and
HTML::SuperForm::Field for more on this.

=back

=head2 ACCESSORS AND MUTATORS

These methods get and set values contained in the form object.

=over 4

=item I<set_sticky($flag)>, I<sticky($flag)>

=item I<set_sticky()>,      I<sticky()>

Returns the state of the sticky flag. If an argument is given
the sticky flag is set to that value. The sticky flag defaults
to false. The flag determines whether the form uses the default
values (false) or submitted values (true).

=item I<fallback($flag)>, I<fallback()>

Sets whether the form's fields "fall back" to their default values
if the form is sticky and no data has been submitted for those fields. 
Defaults to false.

=item I<values_as_labels($flag)>, I<values_as_labels()>

Returns the state of the values_as_labels flag. If an argument 
is given flag is set to that value. The values_as_labels flag 
defaults to true. The flag determines whether select fields,
checkboxes and radio buttons use their values as labels if
no labels are given.

=item I<well_formed($flag)>, I<well_formed()>

Returns the state of the well_formed flag. If an argument 
is given flag is set to that value. The well_formed flag 
defaults to true. The flag determines whether the HTML
generated is also well-formed XML.

=item I<start_form(%args)>, I<start_form(\%args)>

Returns the starting HTML form tag with all the attributes
you pass it. These are some arguments you might give (each
is also a method that returns its value):

=over 4

=item I<name()>

The name of the form.

=item I<method()>

The method in which the form is submitted (GET or POST).
The default is POST.

If the method set in I<start_form()> equals the method 
that is detected from the current request then the 
form is set to sticky.


=item I<action()>

The url to which the form is submitted.

=back

Any other attribute you specify can be accessed by calling
its method (i.e. if you pass in ( target => 'newWindow',
onSubmit => 'CheckForm()' ), $form->target will return 'newWindow',
and $form->onSubmit will return 'CheckForm()'). The names
are case sensitive so be consistent.

=item I<no_of_fields($name)>

Returns the number of fields which have the given name.

=item I<param(%args)>, I<param(\%args)>, I<param($name)>

Gets the parameters with name $name or sets parameters with names equal
to the keys of %args and values equal to the values of %args.  The 
parameters are used by the form object as if they were submitted values.

=item I<exists_param($name)>

Returns true if a value exists for the parameter named $name. 
Otherwise, returns false.

=item I<params()>

Returns a reference to a hash of the submitted parameters.

=back

=head2 GET AND SET

Since I intended HTML::SuperForm's main use to be as a base
class, I made these methods so subclasses can store information
within the object without worrying about overriding important
keys in the object. 

=over 4

=item I<set(%args)>, I<set(\%args)>

Stores infomation in form for later retrieval by get().

=item I<get(@keys)>

When called in list context, returns an array of values
that were previously stored with set(). When called in scalar
context, returns a reference to an array of values or, if only
one key is given, the corresponding single value.

=back

=head2 INTERNAL METHODS

You probably won't ever need to use these methods unless
you are in a subclass of HTML::SuperForm or 
HTML::SuperForm::Field.

=over 4

=item I<set_default(%args)>, I<set_default(\%args)>

Sets default values in form for each key/value pair in %args.

=item I<add_default(%args)>, I<add_default(\%args)>

Adds default values to form for each key/value pair in %args.

=item I<field_object()>

Returns the field object (the string, not an actual object)
that is the base class of all the field objects. 

This will almost always be HTML::SuperForm::Field. 
If you subclass HTML::SuperForm::Field (as a replacement for 
HTML::SuperForm::Field, not as a field like Text or 
Select etc.) then you have to tell the form object to use it. 
Also, if you do that, make sure you write your own field 
classes (Text, Select etc.).  Consult documentation 
for HTML::SuperForm::Field for more on this.

=back

=head2 FIELD METHODS

These methods return objects with their string operators
overloaded to output HTML.

=over 4

=item I<text(%args)>, I<text(\%args)>

Returns an HTML::SuperForm::Field::Text object.

=item I<textarea(%args)>, I<textarea(\%args)>

Returns an HTML::SuperForm::Field::Textarea object.

=item I<hidden(%args)>, I<hidden(\%args)>

Returns an HTML::SuperForm::Field::Hidden object.

=item I<password(%args)>, I<password(\%args)>

Returns an HTML::SuperForm::Field::Password object.

=item I<select(%args)>, I<select(\%args)>

Returns an HTML::SuperForm::Field::Select object.

=item I<checkbox(%args)>, I<checkbox(\%args)>

Returns an HTML::SuperForm::Field::Checkbox object.

=item I<radio(%args)>, I<radio(\%args)>

Returns an HTML::SuperForm::Field::Radio object.

=item I<checkbox_group(%args)>, I<checkbox_group(\%args)>

Returns an HTML::SuperForm::Field::CheckboxGroup object.

=item I<radio_group(%args)>, I<radio_group(\%args)>

Returns an HTML::SuperForm::Field::RadioGroup object.

=item I<submit(%args)>, I<submit(\%args)>

Returns an HTML::SuperForm::Field::Submit object.

=back

=head1 EXAMPLES

This example shows how to make a form object that can
generate a counter field along with all the other basic
fields. A counter field consists of a text field, an 
increment button and a decrement button. Consult the 
documentation for HTML::SuperForm::Field for more 
information about field inheritance.

    package myForm;

    use strict;
    use myForm::Counter;

    use base 'HTML::SuperForm';

    sub counter {
        return myForm::Counter->new(@_);
    }

    sub javascript {
        my $js = <<END_JAVASCRIPT;
    <script language="JavaScript">
    function Increment(field) {
        field.value++;
    }

    function Decrement(field) {
        field.value--;
    }
    </script>
    END_JAVASCRIPT

        return $js;
    }

    1;

    package myForm::Counter;

    use strict;
    use base 'HTML::SuperForm::Field';

    use HTML::SuperForm::Field::Text;

    sub prepare {
        my $self = shift;

        my $form_name = $self->form->name;
        my $field_name = $self->name;

        my $js_name = "document.$form_name.$field_name";

        my $text = HTML::SuperForm::Field::Text->new(name => $self->name, default => $self->value, size => 4);

        $self->set(text => $text);
        $self->set(inc => qq|<a style="cursor: pointer" onmouseup="Increment($js_name)"><img src="/icons/up.gif" border=0></a>|);
        $self->set(dec => qq|<a style="cursor: pointer" onmouseup="Decrement($js_name)"><img src="/icons/down.gif" border=0></a>|);
    }

    sub inc {
        my $self = shift;

        return $self->get('inc');
    }

    sub dec {
        my $self = shift;

        return $self->get('dec');
    }

    sub text {
        my $self = shift;

        return $self->get('text');
    }

    sub arrows_right {
        my $self = shift;

        my ($text, $inc, $dec) = $self->get('text', 'inc', 'dec');

        my $tag = "<table>\n";
        $tag .= qq|    <tr>\n|;
        $tag .= qq|        <td align="center">$text</td>\n|;
        $tag .= qq|        <td align="center">$inc<br/>$dec</td>\n|;
        $tag .= qq|    </tr>\n|;
        $tag .= "</table>\n";
        
        return $tag;
    }

    sub arrows_left {
        my $self = shift;

        my ($text, $inc, $dec) = $self->get('text', 'inc', 'dec');

        my $tag = "<table>\n";
        $tag .= qq|    <tr>\n|;
        $tag .= qq|        <td align="center">$inc<br/>$dec</td>\n|;
        $tag .= qq|        <td align="center">$text</td>\n|;
        $tag .= qq|    </tr>\n|;
        $tag .= "</table>\n";
        
        return $tag;
    }

    sub default_layout {
        my $self = shift;

        my ($text, $inc, $dec) = $self->get('text', 'inc', 'dec');

        my $tag = "<table>\n";
        $tag .= qq|    <tr><td align="center">$inc</td></tr>\n|;
        $tag .= qq|    <tr><td align="center">$text</td></tr>\n|;
        $tag .= qq|    <tr><td align="center">$dec</td></tr>\n|;
        $tag .= "</table>\n";

        return $tag;
    }

    sub to_html {
        my $self = shift;

        my $tag = $self->default_layout;

        return $tag;
    }

    1;

This might seem complex but by using it this way you get the 
following functionality:

    package myHandler;

    use strict;
    use myForm;
    use Apache::Constants qw(OK);
    use Template;
    
    sub handler($$) {
        my $self = shift;
        my $r = shift;

        my $form = myForm->new($r);

        my $tt = Template->new(INCLUDE_PATH => '/my/template/path');

        my $output;

        $tt->process('my_template.tt', { form => $form }, \$output);

        $r->content_type('text/html');
        $r->send_http_header();

        $r->print($output);

        return OK;
    }

    1;

    my_template.tt:

    <html>
        <head>
        <title>Flexibility with HTML::SuperForm</title>
        [% form.javascript %]
        </head>
        <body>
        [% form.start_form %]
        Default Counter Layout: [% form.counter(name => 'counter1', default => 0) %] <br/>
        Counter with increment/decrement buttons on the left: [% form.counter(name => 'counter2', default => 0).arrows_left %] <br/>
        Counter with increment/decrement buttons on the right: [% form.counter(name => 'counter3', default => 0).arrows_right %] <br/>
        Counter with multiple increment/decrement buttons wherever you want: <br/>
        [% counter = form.counter(name => 'counter4', default => 0) %]
        <table>
            <tr><td>[% counter.inc %]</td><td></td><td>[% counter.inc %]</tr>
            <tr><td></td><td></td>[% counter.text %]<td></tr>
            <tr><td>[% counter.dec %]</td><td></td><td>[% counter.dec %]</tr>
        </table>
        [% form.submit %]
        [% form.end_form %]
        </body>
    </html>

=head1 SEE ALSO

 HTML::SuperForm::Field, 
 HTML::SuperForm::Field::Text, 
 HTML::SuperForm::Field::Textarea, 
 HTML::SuperForm::Field::Select, 
 HTML::SuperForm::Field::Checkbox, 
 HTML::SuperForm::Field::Radio, 
 HTML::SuperForm::Field::CheckboxGroup, 
 HTML::SuperForm::Field::RadioGroup

TODO

    Document its usage for fully. 
    Give more examples.

=head1 AUTHOR

John Allwine E<lt>jallwine86@yahoo.comE<gt>

=cut
