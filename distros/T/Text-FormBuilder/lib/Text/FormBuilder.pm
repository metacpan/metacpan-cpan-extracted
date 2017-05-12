package Text::FormBuilder;

use strict;
use warnings;

use base qw(Exporter Class::ParseText::Base);
use vars qw($VERSION @EXPORT);

$VERSION = '0.14';
@EXPORT = qw(create_form);

use Carp;
use Text::FormBuilder::Parser;
use CGI::FormBuilder;

use Data::Dumper;
$Data::Dumper::Terse = 1;           # don't dump $VARn names
$Data::Dumper::Quotekeys = 0;       # don't quote simple string keys

# the static default options passed to CGI::FormBuilder->new
my %DEFAULT_OPTIONS = (
    method => 'GET',
    keepextras => 1,
);

# the built in CSS for the template
my $DEFAULT_CSS = <<END;
table { padding: 1em; }
td table { padding: 0; } /* exclude the inner checkbox tables */
#author, #footer { font-style: italic; }
caption h2 { padding: .125em .5em; background: #ccc; text-align: left; }
fieldset { margin: 1em 0; border: none; border-top: 2px solid #999; }
legend { font-size: 1.25em; font-weight: bold; background: #ccc; padding: .125em .25em; border: 1px solid #666; }
th { text-align: left; }
th h2 { padding: .125em .5em; background: #eee; font-size: 1.25em; }
.label { font-weight: normal; text-align: right; vertical-align: top; }
td ul { list-style: none; padding-left: 0; margin-left: 0; }
.note { background: #eee; padding: .5em 1em; }
.sublabel { color: #999; }
.invalid { background: red; }
END

# default messages that can be localized
my %DEFAULT_MESSAGES = (
    text_author   => 'Created by %s',
    text_madewith => 'Made with %s version %s',
    text_required => 'Fields that are <strong>highlighted</strong> are required.',
    text_invalid  => 'Missing or invalid value.',
);

my $DEFAULT_CHARSET = 'iso-8859-1';

# options to clean up the code with Perl::Tidy
my $TIDY_OPTIONS = '-nolq -ci=4 -ce';

my $HTML_EXTS   = qr/\.html?$/;
my $MODULE_EXTS = qr/\.pm$/;
my $SCRIPT_EXTS = qr/\.(pl|cgi)$/;

# superautomagical exported function
sub create_form {
    my ($source, $options, $destination) = @_;
    my $parser = __PACKAGE__->parse($source);
    $parser->build(%{ $options || {} });
    if ($destination) {
        if (ref $destination) {
            croak '[' . (caller(0))[3] . "] Don't know what to do with a ref for $destination";
            #TODO: what DO ref dests mean?
        } else {
            # write webpage, script, or module
            if ($destination =~ $MODULE_EXTS) {
                $parser->write_module($destination, 1);
            } elsif ($destination =~ $SCRIPT_EXTS) {
                $parser->write_script($destination, 1);
            } else {
                $parser->write($destination);
            }
        }
    } else {
        defined wantarray ? return $parser->form : $parser->write;
    }
}

# subclass of Class::ParseText::Base
sub init {
    my $self = shift;
    $self->{parser}         = Text::FormBuilder::Parser->new;
    $self->{start_rule}     = 'form_spec';
    $self->{ensure_newline} = 1;
    return $self;
}

# this is where a lot of the magic happens
sub build {
    my ($self, %options) = @_;
    
    # our custom %options:
    # form_only: use only the form part of the template
    my $form_only = $options{form_only};
    
    # css, extra_css: allow for custom inline stylesheets
    #   neat trick: css => '@import(my_external_stylesheet.css);'
    #   will let you use an external stylesheet
    #   CSS Hint: to get multiple sections to all line up their fields,
    #   set a standard width for th.label
    # external_css: scalar for a single external stylesheet; array for
    #   multiple sheets; prepended to the beginning of the CSS as @import
    #   statetments
    my $css;
    $css = $options{css} || $DEFAULT_CSS;
    if ($options{external_css}) {
        my $ref = ref $options{external_css};
        if ($ref eq 'ARRAY') {
            # loop over the list of external sheets
            my $external_sheets = join("\n", map { "\@import url($_);" } @{ $options{external_css} });
            $css = "$external_sheets\n$css";
        } elsif ($ref) {
            croak '[' . (caller(0))[3] . "] Don't know how to handle $ref reference as an argument to external_css";
        } else {
            $css = "\@import url($options{external_css});\n$css";
        }
    }
    $css .= $options{extra_css} if $options{extra_css};
    
    # messages
    # code pulled (with modifications) from CGI::FormBuilder
    if ($options{messages}) {
        # if its a hashref, we'll just pass it on to CGI::FormBuilder
        
        if (my $ref = ref $options{messages}) {
            # hashref pass on to CGI::FormBuilder
            croak "[Text::FormBuilder] Argument to 'messages' option must be a filename or hashref" unless $ref eq 'HASH';
            while (my ($key,$value) = each %DEFAULT_MESSAGES) {
                $options{messages}{$key} ||= $DEFAULT_MESSAGES{$key};
            }
        } else {
            # filename, just *warn* on missing, and use defaults
            if (-f $options{messages} && -r _ && open(MESSAGES, "< $options{messages}")) {
                $options{messages} = { %DEFAULT_MESSAGES };
                while(<MESSAGES>) {
                    next if /^\s*#/ || /^\s*$/;
                    chomp;
                    my($key,$value) = split ' ', $_, 2;
                    ($options{messages}{$key} = $value) =~ s/\s+$//;
                }
                close MESSAGES;
            } else {
                carp '[' . (caller(0))[3] . "] Could not read messages file $options{messages}: $!";
            }
        }
    } else {
        $options{messages} = { %DEFAULT_MESSAGES };
    }
    
    # character set
    my $charset = $options{charset};
    
    # save the build options so they can be used from write_module
    $self->{build_options} = { %options };
    
    # remove our custom options before we hand off to CGI::FormBuilder
    delete $options{$_} foreach qw(form_only css extra_css charset);
    
    # expand groups
    if (my %groups = %{ $self->{form_spec}{groups} || {} }) {        
        for my $section (@{ $self->{form_spec}{sections} || [] }) {
            foreach (grep { $$_[0] eq 'group' } @{ $$section{lines} }) {
                $$_[1]{group} =~ s/^\%//;       # strip leading % from group var name
                
                if (exists $groups{$$_[1]{group}}) {
                    my @fields; # fields in the group
                    push @fields, { %$_ } foreach @{ $groups{$$_[1]{group}} };
                    for my $field (@fields) {
                        $$field{label} ||= ucfirst $$field{name};
                        $$field{name} = "$$_[1]{name}_$$field{name}";                
                    }
                    $_ = [
                        'group',
                        {
                            label => $$_[1]{label} || ucfirst(join(' ',split('_',$$_[1]{name}))),
                            comment => $$_[1]{comment},
                            group => \@fields,
                        },
                    ];
                }
            }
        }
    }
    
    # the actual fields that are given to CGI::FormBuilder
    # make copies so that when we trim down the sections
    # we don't lose the form field information
    $self->{form_spec}{fields} = [];
    
    for my $section (@{ $self->{form_spec}{sections} || [] }) {
        for my $line (@{ $$section{lines} }) {
            if ($$line[0] eq 'group') {
                push @{ $self->{form_spec}{fields} }, { %{$_} } foreach @{ $$line[1]{group} };
            } elsif ($$line[0] eq 'field') {
                #die $$line[1] unless ref $$line[1];
                push @{ $self->{form_spec}{fields} }, { %{$$line[1]} };
            }
        }
    }
    
    # substitute in custom validation subs and pattern definitions for field validation
    my %patterns = %{ $self->{form_spec}{patterns} || {} };
    my %subs = %{ $self->{form_spec}{subs} || {} };
    
    foreach (@{ $self->{form_spec}{fields} }) {
        if ($$_{validate}) {
            if (exists $patterns{$$_{validate}}) {
                $$_{validate} = $patterns{$$_{validate}};
            # TODO: need the Data::Dumper code to work for this
            # for now, we just warn that it doesn't work
            } elsif (exists $subs{$$_{validate}}) {
                warn '[' . (caller(0))[3] . "] validate coderefs don't work yet";
                delete $$_{validate};
##                 $$_{validate} = $subs{$$_{validate}};
            }
        }
    }
    
    # get user-defined lists; can't make this conditional because
    # we need to be able to fall back to CGI::FormBuilder's lists
    # even if the user didn't define any
    my %lists = %{ $self->{form_spec}{lists} || {} };
    
    # substitute in list names
    foreach (@{ $self->{form_spec}{fields} }) {
        next unless $$_{list};
        
        $$_{list} =~ s/^\@//;   # strip leading @ from list var name
        
        # a hack so we don't get screwy reference errors
        if (exists $lists{$$_{list}}) {
            my @list;
            push @list, { %$_ } foreach @{ $lists{$$_{list}} };
            $$_{options} = \@list;
        } else {
            # assume that the list name is a builtin 
            # and let it fall through to CGI::FormBuilder
            $$_{options} = $$_{list};
        }
    } continue {
        delete $$_{list};
    }
    
    # special case single-value checkboxes
    foreach (grep { $$_{type} && $$_{type} eq 'checkbox' } @{ $self->{form_spec}{fields} }) {
        unless ($$_{options}) {
            $$_{options} = [ { $$_{name} => $$_{label} || ucfirst join(' ',split(/_/,$$_{name})) } ];
        }
    }
    
    # use columns for displaying checkbox fields larger than 2 items
    foreach (@{ $self->{form_spec}{fields} }) {
        if (ref $$_{options} and @{ $$_{options} } >= 3) {
            $$_{columns} = int(@{ $$_{options} } / 8) + 1;
        }
    }
    
    # remove extraneous undefined values
    # also check for approriate version of CGI::FormBuilder
    # for some advanced options
    my $FB_version = CGI::FormBuilder->VERSION;
    for my $field (@{ $self->{form_spec}{fields} }) {
        defined $$field{$_} or delete $$field{$_} foreach keys %{ $field };
        
        unless ($FB_version >= '3.02') {
            for (qw(growable other)) {
                if ($$field{$_}) {
                    warn '[' . (caller(0))[3] . "] '$_' fields not supported by FB $FB_version (requires 3.02)";
                    delete $$field{$_};
                }
            }
        }
    }
    
    # assign the field names to the sections
    foreach (@{ $self->{form_spec}{sections} }) {
        for my $line (@{ $$_{lines} }) {
            if ($$line[0] eq 'field') {
                $$line[1] = $$line[1]{name};
            }
        }
    }
    
    my %fb_params;
    if ($self->{form_spec}->{fb_params}) {
        require YAML;
        eval { %fb_params = %{ YAML::Load($self->{form_spec}->{fb_params}) } };
        if ($@) {
            warn '[' . (caller(0))[3] . "] Bad !fb parameter block:\n$@";
        }
    }
    
    # gather together all of the form options
    $self->{form_options} = {
        %DEFAULT_OPTIONS,
        # need to explicity set the fields so that simple text fields get picked up
        fields   => [ map { $$_{name} } @{ $self->{form_spec}{fields} } ],
        required => [ map { $$_{name} } grep { $$_{required} } @{ $self->{form_spec}{fields} } ],
        title => $self->{form_spec}{title},
        text  => $self->{form_spec}{description},
        # use 'defined' so we are able to differentiate between 'submit = 0' (no submit button)
        # and 'submit = undef' (use default submit button)
        ( defined $self->{form_spec}{submit} ? (submit => $self->{form_spec}{submit}) : () ),
        reset => $self->{form_spec}{reset},
        template => {
            type => 'Text',
            engine => {
                TYPE       => 'STRING',
                SOURCE     => $form_only ? $self->_form_template : $self->_template($css, $charset),
                DELIMITERS => [ qw(<% %>) ],
            },
            data => {
                #TODO: make FB aware of sections
                sections    => $self->{form_spec}{sections},
                author      => $self->{form_spec}{author},
                description => $self->{form_spec}{description},
            },
        },
        #TODO: fields in fb_params are not getting recognized
        %fb_params,     # params from the formspec file
        %options,       # params from this method invocation
    };
    
    # create the form object
    $self->{form} = CGI::FormBuilder->new(%{ $self->{form_options} });
    
    # ...and set up its fields
    $self->{form}->field(%{ $_ }) foreach @{ $self->{form_spec}{fields} };
    
    # mark structures as built
    $self->{built} = 1;
    
    return $self;
}

sub write {
    my ($self, $outfile) = @_;
    
    # automatically call build if needed to
    # allow the new->parse->write shortcut
    $self->build unless $self->{built};
    
    if ($outfile) {
        open FORM, "> $outfile";
        print FORM $self->form->render;
        close FORM;
    } else {
        print $self->form->render;
    }
}

# dump the form options as eval-able code
sub _form_options_code {
    my $self = shift;
    my $d = Data::Dumper->new([ $self->{form_options} ], [ '*options' ]);
    return keys %{ $self->{form_options} } > 0 ? $d->Dump : '';    
}
# dump the field setup subs as eval-able code
# pass in the variable name of the form object
# (defaults to '$form')
# TODO: revise this code to use the new 'fieldopts'
# option to the FB constructor (requires FB 3.02)
sub _field_setup_code {
    my $self = shift;
    my $object_name = shift || '$form';
    return join(
        "\n", 
        map { $object_name . '->field' . Data::Dumper->Dump([$_],['*field']) . ';' } @{ $self->{form_spec}{fields} }
    );
}

sub as_module {
    my ($self, $package, $use_tidy) = @_;

    croak '[' . (caller(0))[3] . '] Expecting a package name' unless $package;
    
    # remove a trailing .pm
    $package =~ s/\.pm$//;

    # auto-build
    $self->build unless $self->{built};

    my $form_options = $self->_form_options_code;
    my $field_setup = $self->_field_setup_code('$self');
    
    # old style of module
    # TODO: how to keep this (as deprecated method)
    my $old_module = <<END;
package $package;
use strict;
use warnings;

use CGI::FormBuilder;

sub get_form {
    my \$q = shift;

    my \$self = CGI::FormBuilder->new(
        $form_options,
        \@_,
    );
    
    $field_setup
    
    return \$self;
}

# module return
1;
END

    # new style of module
    my $module = <<END;
package $package;
use strict;
use warnings;

use base qw(CGI::FormBuilder);

sub new {
    my \$invocant = shift;
    my \$class = ref \$invocant || \$invocant;
    
    my \$self = CGI::FormBuilder->new(
        $form_options,
        \@_,
    );
    
    $field_setup
    
    # re-bless into this class
    bless \$self, \$class;
}

# module return
1;
END

    $module = _tidy_code($module, $use_tidy) if $use_tidy;
    
    return $module;
}

sub write_module {
    my ($self, $package, $use_tidy) = @_;
    
    my $module = $self->as_module($package, $use_tidy);
    
    my $outfile = (split(/::/, $package))[-1];
    $outfile .= '.pm' unless $outfile =~ /\.pm$/;
    _write_output_file($module, $outfile);
    return $self;
}

sub as_script {
    my ($self, $use_tidy) = @_;
    
    # auto-build
    $self->build unless $self->{built};
    
    my $form_options = $self->_form_options_code;
    my $field_setup = $self->_field_setup_code('$form');

    my $script = <<END;
#!/usr/bin/perl
use strict;
use warnings;

use CGI::FormBuilder;

my \$form = CGI::FormBuilder->new(
    $form_options
);

$field_setup
    
unless (\$form->submitted && \$form->validate) {
    print \$form->render;
} else {
    # do something with the entered data
}
END
    $script = _tidy_code($script, $use_tidy) if $use_tidy;
    
    return $script;
}
    
sub write_script {
    my ($self, $script_name, $use_tidy) = @_;

    croak '[' . (caller(0))[3] . '] Expecting a script name' unless $script_name;

    my $script = $self->as_script($use_tidy);
    
    _write_output_file($script, $script_name);   
    return $self;
}

sub _tidy_code {
    my ($source_code, $use_tidy) = @_;
    eval 'use Perl::Tidy';
    carp '[' . (caller(0))[3] . "] Can't tidy the code: $@" and return $source_code if $@;
    
    # use the options string only if it begins with '_'
    my $options = ($use_tidy =~ /^-/) ? $use_tidy : undef;
    
    my $tidy_code;
    Perl::Tidy::perltidy(source => \$source_code, destination => \$tidy_code, argv => $options || $TIDY_OPTIONS);
    
    return $tidy_code;
}


sub _write_output_file {
    my ($source_code, $outfile) = @_;    
    open OUT, "> $outfile" or croak '[' . (caller(1))[3] . "] Can't open $outfile for writing: $!";
    print OUT $source_code;
    close OUT;
}


sub form {
    my $self = shift;
    
    # automatically call build if needed to
    # allow the new->parse->write shortcut
    $self->build unless $self->{built};

    return $self->{form};
}

sub _form_template {
    my $self = shift;
    my $msg_required = $self->{build_options}{messages}{text_required};
    my $msg_invalid = $self->{build_options}{messages}{text_invalid};
    return q{<% $description ? qq[<p id="description">$description</p>] : '' %>
<% (grep { $_->{required} } @fields) ? qq[<p id="instructions">} . $msg_required . q{</p>] : '' %>
<% $start %>
<%
    # drop in the hidden fields here
    $OUT = join("\n", map { $$_{field} } grep { $$_{type} eq 'hidden' } @fields);
%>} .
q[
<%
    SECTION: while (my $section = shift @sections) {
        $OUT .= qq[<fieldset>\n];
        $OUT .= qq[  <legend>$$section{head}</legend>] if $$section{head};
        $OUT .= qq[<table id="] . ($$section{id} || '_default') . qq[">\n];
        #$OUT .= qq[  <caption><h2 class="sectionhead">$$section{head}</h2></caption>] if $$section{head};
        TABLE_LINE: for my $line (@{ $$section{lines} }) {
            if ($$line[0] eq 'head') {
                $OUT .= qq[  <tr><th class="subhead" colspan="2"><h2>$$line[1]</h2></th></tr>\n]
            } elsif ($$line[0] eq 'note') {
                $OUT .= qq[  <tr><td class="note" colspan="2">$$line[1]</td></tr>\n]
            } elsif ($$line[0] eq 'field') {
                local $_ = $field{$$line[1]};
                
                # skip hidden fields in the table
                next TABLE_LINE if $$_{type} eq 'hidden';
                
                $OUT .= $$_{invalid} ? qq[  <tr class="invalid">] : qq[  <tr>];
                
                # special case single value checkboxes
                if ($$_{type} eq 'checkbox' && @{ $$_{options} } == 1) {
                    $OUT .= qq[<td></td>];
                } else {
                    $OUT .= '<td class="label">' . ($$_{required} ? qq[<strong class="required">$$_{label}</strong>] : "$$_{label}") . '</td>';
                }
                
                # mark invalid fields
                if ($$_{invalid}) {
                    $OUT .= qq[<td>$$_{field} <span class="comment">$$_{comment}</span> $$_{error}</td>];
                } else {
                    $OUT .= qq[<td>$$_{field} <span class="comment">$$_{comment}</span></td>];
                }
                
                $OUT .= qq[</tr>\n];
                
            } elsif ($$line[0] eq 'group') {
                my @group_fields = map { $field{$_} } map { $$_{name} } @{ $$line[1]{group} };
                $OUT .= (grep { $$_{invalid} } @group_fields) ? qq[  <tr class="invalid">\n] : qq[  <tr>\n];
                
                $OUT .= '    <td class="label">';
                $OUT .= (grep { $$_{required} } @group_fields) ? qq[<strong class="required">$$line[1]{label}</strong>] : "$$line[1]{label}";
                $OUT .= qq[</td>\n];
                
                $OUT .= qq[    <td><span class="fieldgroup">];
                $OUT .= join(' ', map { qq[<small class="sublabel">$$_{label}</small> $$_{field} $$_{comment}] } @group_fields);
                if (my @invalid = grep { $$_{invalid} } @group_fields) {
                    $OUT .= ' ' . join('; ', map { $$_{error} } @invalid);
                }                
                $OUT .= qq[ <span class="comment">$$line[1]{comment}</span></span></td>\n];
                $OUT .= qq[  </tr>\n];
            }   
        }
        # close the table if there are sections remaining
        # but leave the last one open for the submit button
        if (@sections) {
            $OUT .= qq[</table>\n];
            $OUT .= qq[</fieldset>\n];
        }
    }
%>
  <tr><th></th><td style="padding-top: 1em;"><% $submit %> <% $reset %></td></tr>
</table>
</fieldset>
<% $end %>
];
}

# usage: $self->_pre_template($css, $charset)
sub _pre_template {
    my $self = shift;
    my $css = shift || $DEFAULT_CSS;
    my $charset = shift || $DEFAULT_CHARSET;
    my $msg_author = 'sprintf("' . quotemeta($self->{build_options}{messages}{text_author}) . '", $author)';
    return 
q[<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=] . $charset . q[" />
  <title><% $title %><% $author ? ' - ' . ucfirst $author : '' %></title>
  <style type="text/css">
] . $css . q[  </style>
  <% $jshead %>
</head>
<body>

<h1><% $title %></h1>
<% $author ? qq[<p id="author">] . ] . $msg_author . q{ . q[</p>] : '' %>
};
}

sub _post_template {
    my $self = shift;
    my $msg_madewith = 'sprintf("' . quotemeta($self->{build_options}{messages}{text_madewith}) .
        '", q[<a href="http://formbuilder.org/">CGI::FormBuilder</a>], CGI::FormBuilder->VERSION)';
    
    return qq[<hr />
<div id="footer">
  <p id="creator"><% $msg_madewith %></p>
</div>
</body>
</html>
];
}

# usage: $self->_template($css, $charset)
sub _template {
    my $self = shift;
    return $self->_pre_template(@_) . $self->_form_template . $self->_post_template;
}

sub dump { 
    eval "use YAML;";
    unless ($@) {
        print YAML::Dump(shift->{form_spec});
    } else {
        warn '[' . (caller(0))[3] . "] Can't dump form spec structure using YAML: $@";
    }
}


# module return
1;

=head1 NAME

Text::FormBuilder - Create CGI::FormBuilder objects from simple text descriptions

=head1 SYNOPSIS

    use Text::FormBuilder;
    
    my $parser = Text::FormBuilder->new;
    $parser->parse($src_file);
    
    # returns a new CGI::FormBuilder object with
    # the fields from the input form spec
    my $form = $parser->form;
    
    # write a My::Form module to Form.pm
    $parser->write_module('My::Form');

=head1 REQUIRES

L<Parse::RecDescent>,
L<CGI::FormBuilder>,
L<Text::Template>,
L<Class::Base>

You will also need L<YAML>, if you want to use the L<C<dump>|/dump>
method, or the L<C<!fb>|/!fb> directive in your formspec files.

=head1 DESCRIPTION

This module is intended to extend the idea of making it easy to create
web forms by allowing you to describe them with a simple langauge. These
I<formspecs> are then passed through this module's parser and converted
into L<CGI::FormBuilder> objects that you can easily use in your CGI
scripts. In addition, this module can generate code for standalone modules
which allow you to separate your form design from your script code.

A simple formspec looks like this:

    name//VALUE
    email//EMAIL
    language:select{English,Spanish,French,German}
    moreinfo|Send me more information:checkbox
    interests:checkbox{Perl,karate,bass guitar}

This will produce a required C<name> text field, a required C<email> text
field that must look like an email address, an optional select dropdown
field C<language> with the choices English, Spanish, French, and German,
an optional C<moreinfo> checkbox labeled ``Send me more information'', and
finally a set of checkboxes named C<interests> with the choices Perl,
karate, and bass guitar.

=head1 METHODS

=head2 new

    my $parser = Text::FormBuilder->new;

=head2 parse

    # parse a file (regular scalar)
    $parser->parse($filename);
    
    # or pass a scalar ref to parse a literal string
    $parser->parse(\$string);
    
    # or an array ref to parse lines
    $parser->parse(\@lines);

Parse the file or string. Returns the parser object. This method,
along with all of its C<parse_*> siblings, may be called as a class
method to construct a new object.

=head2 parse_file

    $parser->parse_file($src_file);
    
    # or as a class method
    my $parser = Text::FormBuilder->parse($src_file);

=head2 parse_text

    $parser->parse_text($src);

Parse the given C<$src> text. Returns the parser object.

=head2 parse_array

    $parser->parse_array(@lines);

Concatenates and parses C<@lines>. Returns the parser object.

=head2 build

    $parser->build(%options);

Builds the CGI::FormBuilder object. Options directly used by C<build> are:

=over

=item C<form_only>

Only uses the form portion of the template, and omits the surrounding html,
title, author, and the standard footer. This does, however, include the
description as specified with the C<!description> directive.

=item C<css>, C<extra_css>

These options allow you to tell Text::FormBuilder to use different
CSS styles for the built in template. A value given a C<css> will
replace the existing CSS, and a value given as C<extra_css> will be
appended to the CSS. If both options are given, then the CSS that is
used will be C<css> concatenated with C<extra_css>.

If you want to use an external stylesheet, a quick way to get this is
to set the C<css> parameter to import your file:

    css => '@import(my_external_stylesheet.css);'

=item C<external_css>

If you want to use multiple external stylesheets, or an external stylesheet
in conjunction with the default styles, use the C<external_css> option:

    # single external sheet
    external_css => 'my_styles.css'
    
    # mutliple sheets
    external_css => [
        'my_style_A.css',
        'my_style_B.css',
    ]

=item C<messages>

This works the same way as the C<messages> parameter to 
C<< CGI::FormBuilder->new >>; you can provide either a hashref of messages
or a filename.

The default messages used by Text::FormBuilder are:

    text_author       Created by %s
    text_madewith     Made with %s version %s
    text_required     (Required fields are marked in <strong>bold</strong>.)
    text_invalid      Missing or invalid value.

Any messages you set here get passed on to CGI::FormBuilder, which means
that you should be able to put all of your customization messages in one
big file.

=item C<charset>

Sets the character encoding for the generated page. The default is ISO-8859-1.

=back

All other options given to C<build> are passed on verbatim to the
L<CGI::FormBuilder> constructor. Any options given here override the
defaults that this module uses.

The C<form>, C<write>, and C<write_module> methods will all call
C<build> with no options for you if you do not do so explicitly.
This allows you to say things like this:

    my $form = Text::FormBuilder->new->parse('formspec.txt')->form;

However, if you need to specify options to C<build>, you must call it
explictly after C<parse>.

=head2 form

    my $form = $parser->form;

Returns the L<CGI::FormBuilder> object. Remember that you can modify
this object directly, in order to (for example) dynamically populate
dropdown lists or change input types at runtime.

=head2 write

    $parser->write($out_file);
    # or just print to STDOUT
    $parser->write;

Calls C<render> on the FormBuilder form, and either writes the resulting
HTML to a file, or to STDOUT if no filename is given.

=head2 as_module

    my $module_code = $parser->as_module($package, $use_tidy);

=head2 write_module

I<B<Note:> The code output from the C<write_*> methods may be in flux for
the next few versions, as I coordinate with the B<FormBuilder> project.>

    $parser->write_module($package, $use_tidy);

Takes a package name, and writes out a new module that can be used by your
CGI script to render the form. This way, you only need CGI::FormBuilder on
your server, and you don't have to parse the form spec each time you want 
to display your form. The generated module is a subclass of L<CGI::FormBuilder>,
that will pass along any constructor arguments to FormBuilder, and set up
the fields for you.

First, you parse the formspec and write the module, which you can do as a one-liner:

    $ perl -MText::FormBuilder -e"Text::FormBuilder->parse('formspec.txt')->write_module('My::Form')"

And then, in your CGI script, use the new module:

    #!/usr/bin/perl -w
    use strict;
    
    use CGI;
    use My::Form;
    
    my $q = CGI->new;
    my $form = My::Form->new;
    
    # do the standard CGI::FormBuilder stuff
    if ($form->submitted && $form->validate) {
        # process results
    } else {
        print $q->header;
        print $form->render;
    }

If you pass a true value as the second argument to C<write_module>, the parser
will run L<Perl::Tidy> on the generated code before writing the module file.

    # write tidier code
    $parser->write_module('My::Form', 1);

If you set C<$use_tidy> to a string beginning with `-' C<write_module> will
interpret C<$use_tidy> as the formatting option switches to pass to Perl::Tidy.

=head2 as_script

    my $script_code = $parser->as_script($use_tidy);

=head2 write_script

    $parser->write_script($filename, $use_tidy);

If you don't need the reuseability of a separate module, you can have
Text::FormBuilder write the form object to a script for you, along with
the simplest framework for using it, to which you can add your actual
form processing code.

The generated script looks like this:

    #!/usr/bin/perl
    use strict;
    use warnings;
    
    use CGI::FormBuilder;
    
    my $form = CGI::FormBuilder->new(
        # lots of stuff here...
    );
    
    # ...and your field setup subs are here
    $form->field(name => '...');
        
    unless ($form->submitted && $form->validate) {
        print $form->render;
    } else {
        # do something with the entered data
    }

Like C<write_module>, you can optionally pass a true value as the second
argument to have Perl::Tidy make the generated code look nicer.

=head2 dump

Uses L<YAML> to print out a human-readable representation of the parsed
form spec.

=head1 EXPORTS

There is one exported function, C<create_form>, that is intended to ``do the
right thing'' in simple cases.

=head2 create_form

    # get a CGI::FormBuilder object
    my $form = create_form($source, $options, $destination);
    
    # or just write the form immediately
    create_form($source, $options, $destination);

C<$source> accepts any of the types of arguments that C<parse> does. C<$options>
is a hashref of options that should be passed to C<build>. Finally, C<$destination>
is a simple scalar that determines where and what type of output C<create_form>
should generate.

    /\.pm$/             ->write_module($destination)
    /\.(cgi|pl)$/       ->write_script($destination)
    everything else     ->write($destination)

For anything more than simple, one-off cases, you are usually better off using the
object-oriented interface, since that gives you more control over things.

=head1 DEFAULTS

These are the default settings that are passed to C<< CGI::FormBuilder->new >>:

    method => 'GET'
    keepextras => 1

Any of these can be overriden by the C<build> method:

    # use POST instead
    $parser->build(method => 'POST')->write;

=head1 LANGUAGE

    # name field_size growable label hint type other default option_list validate
    
    field_name[size]|descriptive label[hint]:type=default{option1[display string],...}//validate
    
    !title ...
    
    !author ...
    
    !description {
        ...
    }
    
    !pattern NAME /regular expression/
    
    !list NAME {
        option1[display string],
        option2[display string],
        ...
    }
    
    !group NAME {
        field1
        field2
        ...
    }
    
    !section id heading
    
    !head ...
    
    !note {
        ...
    }
    
    !submit label, label 2, ...
    
    !reset label

=head2 Directives

All directives start with a C<!> followed by a keyword. There are two types of
directives:

=over

=item Line directives

Line directives occur all on one line, and require no special punctuation. Examples
of line directives are L<C<!title>|/!title> and L<C<!section>|/!section>.

=item Block directives

Block directives consist of a directive keyword followed by a curly-brace delimited
block. Examples of these are L<C<!group>|/!group> and L<C<!description>|/!description>.
Some of these directives have their own internal structure; see the list of directives
below for an explanation.

=back

And here is the complete list of directives

=over

=item C<!pattern>

Defines a validation pattern.

=item C<!list>

Defines a list for use in a C<radio>, C<checkbox>, or C<select> field.

=item C<!group>

Define a named group of fields that are displayed all on one line. Use with
the C<!field> directive.

=item C<!field>

B<DEPRECATED> Include a named instance of a group defined with C<!group>. See
L<Field Groups|/Field Groups> for an explanation of the new way to include
groups.

=item C<!title>

Line directive containing the title of the form.

=item C<!author>

Line directive naming the author of the form.

=item C<!description>

A block directive containing a brief description of the form. Appears at the top of the form. Suitable for 
special instructions on how to fill out the form. All of the text within the
block is folded into a single paragraph. If you add a second !description, it will override the first.

=item C<!section id Your section text goes here>

A line directive that starts a new section. Each section has its own heading
and id, which by default are rendered into separate tables.

=item C<!head>

A line directive that inserts a heading between two fields. There can only be
one heading between any two fields; the parser will warn you if you try to put
two headings right next to each other.

=item C<!note>

A block directive containing a text note that can be inserted as a row in the
form. This is useful for special instructions at specific points in a long form.
Like L<C<!description>|/!description>, the text content is folded into a single
paragraph.

=item C<!submit>

A line directive with  one or more submit button labels in a comma-separated list.
Each label is a L<string|/Strings>. Multiple instances of this directive may be
used; later lists are simply appended to the earlier lists. All the submit buttons
are rendered together at the bottom of the form. See L<CGI::FormBuilder> for an
explanation of how the multiple submit buttons work together in a form.

To disable the display of any submit button, use C<!submit 0>

=item C<!reset>

Line directive giving a label for the a reset button at the end of the form. No 
reset button will be rendered unless you use this directive.

=item C<!fb>

The C<!fb> block directive allows you to include any parameters you want passed
directly to the CGI::FormBuilder constructor. The block should be a hashref of
parameters serialized as L<YAML>. Be sure to place the closing of the block on
its own line, flush to the left edge, and to watch your indentation. Multiple
C<!fb> blocks are concatenated, and the result is interpeted as one big chunk
of YAML code.

    !fb{
    method: POST
    action: '/custom/action'
    javascript: 0
    }

=back

=head2 Strings

Anywhere that it says that you may use a multiword string, this means you can
do one of two things. For strings that consist solely of alphanumeric characters 
(i.e. C<\w+>) and spaces, the string will be recognized as is:

    field_1|A longer label

If you want to include non-alphanumerics (e.g. punctuation), you must 
single-quote the string:

    field_2|'Dept./Org.'

To include a literal single-quote in a single-quoted string, escape it with
a backslash:

    field_3|'\'Official\' title'

Quoted strings are also how you can set the label for a field to be blank:

    unlabeled_field|''

=head2 Fields

Form fields are each described on a single line. The simplest field is
just a name (which cannot contain any whitespace):

    color

This yields a form with one text input field of the default size named `color'.
The generated label for this field would be ``Color''. To add a longer or more
descriptive label, use:

    color|Favorite color

The descriptive label can be a multiword string, as described above. So if you
want punctuation in the label, you should single quote it:

    color|'Fav. color'

To add a descriptive hint that should appear to the right of the form field,
put the hint in square brackets after the label, but before the field type:

    # hint for a field without a label
    color[select from a list]

    # hint together with a label
    color|Favorite color[select from this list]

To use a different input type:

    color|Favorite color:select{red,blue,green}

Recognized input types are the same as those used by CGI::FormBuilder:

    text        # the default
    textarea
    password
    file
    checkbox
    radio
    select
    hidden
    static

For multi-select fields, append a C<*> to the field type:

    colors:select*

To change the size of the input field, add a bracketed subscript after the
field name (but before the descriptive label):

    # for a single line field, sets size="40"
    title[40]:text
    
    # for a multiline field, sets rows="4" and cols="30"
    description[4,30]:textarea

To also set the C<maxlength> attribute for text fields, add a C<!> after
the size:

    # ensure that all titles entered are 40 characters or less
    title[40!]:text

This currently only works for single line text fields.

To create a growable field, add a C<*> after the name (and size, if
given). Growable fields have a button that allows the user to add a
copy of the field input. Currently, this only works for C<text> and
C<file> fields, and you must have L<CGI::FormBuilder> 3.02 or higher.
Growable fields also require JavaScript to function correctly.

    # you can have as many people as you like
    person*:text

To set a limit to the maximum number of inputs a field can grow to, add
a number after the C<*>:

    # allow up to 5 musicians
    musician*5:text

To create a C<radio> or C<select> field that includes an "other" option,
append the string C<+other> to the field type:

    position:select+other

Or, to let FormBuilder decide whether to use radio buttons or a dropdown:

    position+other

Like growable fields, 'other' fields require FormBuilder 3.02 or higher.

For the input types that can have options (C<select>, C<radio>, and
C<checkbox>), here's how you do it:

    color|Favorite color:select{red,blue,green}

Values are in a comma-separated list of single words or multiword strings
inside curly braces. Whitespace between values is irrelevant.

To add more descriptive display text to a value in a list, add a square-bracketed
``subscript,'' as in:

    ...:select{red[Scarlet],blue[Azure],green[Olive Drab]}

If you have a list of options that is too long to fit comfortably on one line,
you should use the C<!list> directive:

    !list MONTHS {
        1[January],
        2[February],
        3[March],
        # and so on...
    }
    
    month:select@MONTHS

If you want to have a single checkbox (e.g. for a field that says ``I want to
recieve more information''), you can just specify the type as checkbox without
supplying any options:

    moreinfo|I want to recieve more information:checkbox

In this case, the label ``I want to recieve more information'' will be
printed to the right of the checkbox.

You can also supply a default value to the field. To get a default value of
C<green> for the color field:

    color|Favorite color:select=green{red,blue,green}

Default values can also be either single words or multiword strings.

To validate a field, include a validation type at the end of the field line:

    email|Email address//EMAIL

Valid validation types include any of the builtin defaults from L<CGI::FormBuilder>,
or the name of a pattern that you define with the C<!pattern> directive elsewhere
in your form spec:

    !pattern DAY /^([1-3][0-9])|[1-9]$/
    
    last_day//DAY

If you just want a required value, use the builtin validation type C<VALUE>:

    title//VALUE

By default, adding a validation type to a field makes that field required. To
change this, add a C<?> to the end of the validation type:

    contact//EMAIL?

In this case, you would get a C<contact> field that was optional, but if it
were filled in, would have to validate as an C<EMAIL>.

=head2 Field Groups

You can define groups of fields using the C<!group> directive:

    !group DATE {
        month:select@MONTHS//INT
        day[2]//INT
        year[4]//INT
    }

You can also use groups in normal field lines:

    birthday|Your birthday:DATE

This will create a line in the form labeled ``Your birthday'' which contains
a month dropdown, and day and year text entry fields. The actual input field
names are formed by concatenating the C<!field> name (e.g. C<birthday>) with
the name of the subfield defined in the group (e.g. C<month>, C<day>, C<year>).
Thus in this example, you would end up with the form fields C<birthday_month>,
C<birthday_day>, and C<birthday_year>.

The only (currently) supported pieces of a fieldspec that may be used with a
group in this notation are name, label, and hint.

The old method of using field groups was with the C<!field> directive:

    !field %DATE birthday

This format is now B<deprecated>, and although it still works, the parser will
warn you if you use it.

=head2 Comments

    # comment ...

Any line beginning with a C<#> is considered a comment. Comments can also appear
after any field line. They I<cannot> appear between items in a C<!list>, or on
the same line as any of the directives.

=head1 TODO

=head2 Documentation/Tests

Document use of the parser as a standalone module

Make sure that the docs match the generated code.

Better tests!

=head2 Language/Parser

Pieces that wouldn't make sense in a group field: size, row/col, options,
validate. These should cause C<build> to emit a warning before ignoring them.

C<!include> directive to include external formspec files

Better recovery from parse errors

=head2 Code generation/Templates

Revise the generated form constructing code to use the C<fieldopts>
option to C<< FB->new >>; will require FB 3.02 to run.

Better integration with L<CGI::FormBuilder>'s templating system; rely on the
FB messages instead of trying to make our own.

Allow for custom wrappers around the C<form_template>

Maybe use HTML::Template instead of Text::Template for the built in template
(since CGI::FormBuilder users may be more likely to already have HTML::Template)

=head1 BUGS

Placing C<fields> in a C<!fb> directive does not behave as expected (i.e. they
don't show up). This is not a big issue, since you should be defining your fields
in the body of the formspec file, but for completeness' sake I would like to get
this figured out.

I'm sure there are more in there, I just haven't tripped over any new ones lately. :-)

Suggestions on how to improve the (currently tiny) test suite would be appreciated.

=head1 SEE ALSO

L<CGI::FormBuilder>, L<http://formbuilder.org>

=head1 THANKS

Thanks to eszpee for pointing out some bugs in the default value parsing,
as well as some suggestions for i18n/l10n and splitting up long forms into
sections.

To Ron Pero for a documentation patch, and for letting me know that software
I wrote several years ago is still of use to people.

And of course, to Nathan Wiger, for giving us CGI::FormBuilder in the
first place. Thanks Nate!

=head1 AUTHOR

Peter Eichman C<< <peichman@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright E<copy>2004-2005 by Peter Eichman.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
