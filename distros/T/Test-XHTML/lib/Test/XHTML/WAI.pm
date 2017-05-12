package Test::XHTML::WAI;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.13';

#----------------------------------------------------------------------------

=head1 NAME

Test::XHTML::WAI - Basic WAI compliance checks.

=head1 SYNOPSIS

    my $txw = Test::XHTML::WAI->new();

    $txw->validate($content);       # run compliance checks
    my $results = $txw->results();  # retrieve results

    $txw->clear();                  # clear all current errors and results
    $txw->errors();                 # all current errors reported
    $txw->errstr();                 # basic error message

    $txw->logfile($file);           # logfile for verbose messages
    $txw->logclean(1);              # 1 = overwrite, 0 = append (default)

=head1 DESCRIPTION

This module attempts to check WAI compliance. Currently only basic checks are
implemented, but more comprehensive checks are planned.

=cut

# -------------------------------------
# Library Modules

use base qw(Class::Accessor::Fast);
use File::Basename;
use File::Path;
use HTML::TokeParser;
use Data::Dumper;

# -------------------------------------
# Variables

my @RESULTS = qw( PASS FAIL );

my $FIXED = $HTML::TokeParser::VERSION >= 3.69 ? 1 : 0;

# For a full list of valid W3C DTD types, please see 
# http://www.w3.org/QA/2002/04/valid-dtd-list.html
my %declarations = (
    'xhtml1-strict.dtd'         => 2,
    'xhtml1-transitional.dtd'   => 2,
    'xhtml1-frameset.dtd'       => 2,
    'html401-strict.dtd'        => 1,
    'html401-loose.dtd'         => 1,
    'html401-frameset.dtd'      => 1,
);

my @TAGS = (
    # list taken from http://www.w3schools.com/tags/default.asp
    'a', 'abbr', 'acronym', 'address', 'applet', 'area',
    'b', 'base', 'basefont', 'bdo', 'big', 'blockquote', 'body', 'br', 'button',
    'caption', 'center', 'cite', 'code', 'col', 'colgroup',
    'dd', 'del', 'dfn', 'dir', 'div', 'dl', 'dt',
    'em',
    'fieldset', 'font', 'form', 'frame', 'framset',
    'head', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hr', 'html',
    'i', 'iframe', 'img', 'input', 'ins',
    'kbd',
    'label', 'legend', 'li', 'link',
    'map', 'menu', 'meta',
    'noframes', 'noscript',
    'object', 'ol', 'optgroup', 'option',
    'p', 'param', 'pre',
    'q',
    's', 'samp', 'script', 'select', 'small', 'span', 'strike', 'strong', 'style', 'sub',
    'table', 'tbody', 'td', 'textarea', 'tfoot', 'th', 'thead', 'title', 'tr', 'tt',
    'u', 'ul',
    'var',

    '/form'
);

# -------------------------------------
# Public Methods

sub new {
    my $proto = shift; # get the class name
    my $class = ref($proto) || $proto;

    # private data
    my $self  = {level => 1, dtdtype => 0};
    $self->{RESULTS}{$_} = 0    for(@RESULTS);

    bless ($self, $class);
    return $self;
}

sub DESTROY {
    my $self = shift;
}

__PACKAGE__->mk_accessors(qw( logfile logclean ));

sub validate    { _process_checks(@_);  }
sub results     { _process_results(@_); }

sub clear       { my $self = shift; $self->{ERRORS} = undef; $self->_reset_results(); }
sub errors      { my $self = shift; return $self->{ERRORS}; }
sub errstr      { my $self = shift; return $self->_print_errors(); }

sub level       {
    my ($self,$level) = @_;
    $self->{level} = $level if(defined $level && $level =~ /^[123]$/);
    return $self->{level};
}

# -------------------------------------
# Private Methods

sub _process_results {
    my $self = shift;
    my %results = map {$_ => $self->{RESULTS}{$_}} @RESULTS;
    $self->_log( sprintf "%8s%d\n", "$_:", $results{$_} ) for(@RESULTS);
    return \%results;
}

sub _reset_results {
    my $self = shift;
    $self->{RESULTS}{$_} = 0    for(@RESULTS);
}

sub _print_errors {
    my $self = shift;
    my $str = "\nErrors:\n" ;
    my $i = 1;
    for my $error (@{$self->{ERRORS}}) {
        $str .= "$i. $error->{error}: $error->{message}";
        $str .= " [$error->{ref}]"                              if($error->{ref});
        $str .= " [row $error->{row}, column $error->{col}]"    if($error->{row} && $error->{col} && $FIXED);
        $str .= "\n";
        $i++;
    }
    return $str;
}

# -------------------------------------
# Subroutines

# TODO
# (AA) check for absolute rather than relative table cell values
# (A)  label associated with each input id

sub _process_checks {
    my $self = shift;
    my $html = shift;

    # clear data from previous tests.
    $self->{$_} = undef for(qw(input label form links));

    #push @{ $self->{ERRORS} }, {
    #    error => "debug",
    #    message => "VERSION=$HTML::TokeParser::VERSION, FIXED=$FIXED"
    #};

    #use Data::Dumper;
    #print STDERR "#html=".Dumper($html);

    if($html) {
        my $p = $FIXED
                    ? HTML::TokeParser->new( \$html,
                            start => "'S',tagname,attr,attrseq,text,line,column",
                            end   => "'E',tagname,text,line,column"
                      )
                    : HTML::TokeParser->new( \$html );

        #print STDERR "#p=".Dumper($p);

        # determine declaration and the case requirements
        my $token = $p->get_token();
        if($token && $token->[0] eq 'D') {
            my $declaration = $token->[1];
            $declaration =~ s/\s+/ /sg;
            for my $type (keys %declarations) {
                if($declaration =~ /$type/) {
                    $self->{dtdtype} = $declarations{$type};
                    last;
                }
            }
        } else {
            $p->unget_token($token);
        }

        while( my $tag = $p->get_tag( @TAGS ) ) {

            # force lower case
            $tag->[0] = lc $tag->[0];

            if($tag->[0] eq 'form') {
                $self->{form} = { id => ($tag->[1]{id} || $tag->[1]{name}) };
            } elsif($tag->[0] eq '/form') {
                $self->_check_form($tag);
                $self->{form} = undef;

            } elsif($tag->[0] eq 'input') {
                $self->_check_form_submit($tag);
                $self->_check_form_control($tag);
            } elsif($tag->[0] =~ /^(select|textarea)$/) {
                $self->_check_form_control($tag);
            } elsif($tag->[0] eq 'label') {
                $self->_check_label($tag);

            } elsif($tag->[0] eq 'object') {
                $self->_check_object($tag,$p);
            } elsif($tag->[0] eq 'img') {
                $self->_check_image($tag);
            } elsif($tag->[0] eq 'a') {
                $self->_check_link($tag);
            } elsif($tag->[0] =~ /^(i|b)$/) {
                $self->_check_format($tag);

            # need to confirm
            #} elsif($tag->[0] eq 'map') {
            #    $self->_check_title($tag);

            } elsif($tag->[0] eq 'table') {
                $self->_check_title_summary($tag);
                $self->_check_width($tag);
                $self->_check_height($tag);
            } elsif($tag->[0] =~ /^(th|td)$/) {
                $self->_check_width($tag);
                $self->_check_height($tag);
            }
        }

        $self->_check_labelling();

    } else {
        push @{ $self->{ERRORS} }, {
            #ref     => 'Best Practices Recommedation only',
            error   => "missing content",
            message => 'no XHTML content found'
        };
    }

    if($self->{ERRORS}) {
        $self->_log( "FAIL\n" );
        $self->{RESULTS}{FAIL}++;
    } else {
        $self->_log( "PASS\n" );
        $self->{RESULTS}{PASS}++;
    }
}

# -------------------------------------
# Private Methods : Check Routines

sub _check_form {
    my ($self,$tag) = @_;

    if(!$self->{form}{submit}) {
        push @{ $self->{ERRORS} }, {
            ref     => 'WCAG v2 3.2.2 (A)', #E872
            error   => "W001",
            message => 'no submit button in form (' . ( $self->{form}{id} || '' ) . ')',
            row     => $tag->[2],
            col     => $tag->[3]
        };
    }
}

sub _check_form_control {
    my ($self,$tag) = @_;

    if($tag->[1]{id}) {
        if($self->{input}{ $tag->[1]{id} }) {
            push @{ $self->{ERRORS} }, {
                ref     => 'WCAG v2 4.1.1 (A)', #894
                error   => "W002",
                message => "all <$tag->[0]> tags require a unique id ($tag->[1]{id})",
                row     => $tag->[4],
                col     => $tag->[5]
            };
        } else {
            $self->{input}{ $tag->[1]{id} }{type}   = ($tag->[0] =~ /select|textarea/ ? $tag->[0] : $tag->[1]{type});
            $self->{input}{ $tag->[1]{id} }{title}  = $tag->[1]{title};
            $self->{input}{ $tag->[1]{id} }{row}    = $tag->[4];
            $self->{input}{ $tag->[1]{id} }{column} = $tag->[5];
            $self->{input}{ $tag->[1]{id} }{active} = ($tag->[1]{disabled} || $tag->[1]{readonly} ? 0 : 1);
        }

    } elsif($tag->[1]{type} && $tag->[1]{type} =~ /hidden|submit|reset|button/) {
        return;

    #} elsif($tag->[1]{disabled} || $tag->[1]{readonly}) {
    #    return;

    } elsif(!$tag->[1]{title}) {
        push @{ $self->{ERRORS} }, {
            ref     => 'WCAG v2 1.1.1 (A)', #E866
            error   => "W003",
            message => "all <$tag->[0]> tags require a <label> or a title attribute ($tag->[1]{name})",
            row     => $tag->[4],
            col     => $tag->[5]
        };
    }
}

sub _check_form_submit {
    my ($self,$tag) = @_;

    if($tag->[1]{type} && $tag->[1]{type} eq 'submit') {
        if(%{$self->{form}}) {
            $self->{form}{submit} = 1;
        } else {
            push @{ $self->{ERRORS} }, {
                #ref     => 'Best Practices Recommedation only',
                error   => "CW001",
                message => 'submit button should be associated with a form',
                row     => $tag->[4],
                col     => $tag->[5]
            };
        }
    }
}

sub _check_label {
    my ($self,$tag) = @_;

    if($tag->[1]{for}) {
        if($self->{label}{ $tag->[1]{for} }) {
            push @{ $self->{ERRORS} }, {
                #ref     => 'Best Practices Recommedation only',
                error   => "CW002",
                message => "all <$tag->[0]> tags should reference a unique id ($tag->[1]{for})",
                row     => $tag->[4],
                col     => $tag->[5]
            };
        } else {
            $self->{label}{ $tag->[1]{for} }{type}   = 'label';
            $self->{label}{ $tag->[1]{for} }{row}    = $tag->[4];
            $self->{label}{ $tag->[1]{for} }{column} = $tag->[5];
        }
    } else {
        push @{ $self->{ERRORS} }, {
            ref     => 'WCAG v2 1.3.1 (A)', #885
            error   => "W004",
            message => "all <$tag->[0]> tags must reference an <input> tag id",
            row     => $tag->[4],
            col     => $tag->[5]
        };
    }
}

sub _check_image {
    my ($self,$tag) = @_;

    return  if(defined $tag->[1]{alt});

    push @{ $self->{ERRORS} }, {
        ref     => 'WCAG v2 1.1.1 (A)', #E860
        error   => "W005",
        message => "no alt attribute in <$tag->[0]> tag ($tag->[1]{src})",
        row     => $tag->[4],
        col     => $tag->[5]
    };
}

sub _check_link {
    my ($self,$tag) = @_;

    return  unless(defined $tag->[1]{href});    # ignore named anchors

    if($tag->[1]{title}) {
        if($self->{links}{ $tag->[1]{href} } && $self->{links}{ $tag->[1]{href} } ne $tag->[1]{title}) {
            push @{ $self->{ERRORS} }, {
                ref     => 'WCAG v2 2.4.4 (A)', #E898
                error   => "W006",
                message => "repeated links should use the same titles ($tag->[1]{href}, '$self->{links}{ $tag->[1]{href} }' => '$tag->[1]{title}')",
                row     => $tag->[4],
                col     => $tag->[5]
            };
        } else {
            $self->{links}{ $tag->[1]{href} } = $tag->[1]{title};
        }
        return;
    }

    push @{ $self->{ERRORS} }, {
        ref     => 'WCAG v2 1.1.1 (A)', #E871
        error   => "W007",
        message => "no title attribute in a tag ($tag->[1]{href}, '$tag->[3]')",
        row     => $tag->[4],
        col     => $tag->[5]
    };
}

sub _check_format {
    my ($self,$tag) = @_;

    my %formats = (
        'i' => 'em',
        'b' => 'strong'
    );

    return  unless($formats{$tag->[0]});

    push @{ $self->{ERRORS} }, {
        ref     => 'WCAG v2 1.3.1 (A)', #E892
        error   => "W008",
        message => "use CSS for presentation effects, or use <$formats{$tag->[0]}> for emphasis not <$tag->[0]> tag",
        row     => $tag->[4],
        col     => $tag->[5]
    };
}

sub _check_title {
    my ($self,$tag) = @_;

    return  if(defined $tag->[1]{title});

    push @{ $self->{ERRORS} }, {
        #ref     => 'WCAG v2 1.1.1 (A)',
        error   => "W009",
        message => "no title attribute in <$tag->[0]> tag",
        row     => $tag->[4],
        col     => $tag->[5]
    };
}

sub _check_title_summary {
    my ($self,$tag) = @_;

    return  if(defined $tag->[1]{title} || defined $tag->[1]{summary});

    push @{ $self->{ERRORS} }, {
        ref     => 'WCAG v2 1.3.1 (A)', #E879
        error   => "W010",
        message => "no title or summary attribute in <$tag->[0]> tag",
        row     => $tag->[4],
        col     => $tag->[5]
    };
}

sub _check_width {
    my ($self,$tag) = @_;

    return  unless($self->{level} > 1);
    return  unless(defined $tag->[1]{width} && $tag->[1]{width} =~ /^\d+$/);

    push @{ $self->{ERRORS} }, {
        ref     => 'WCAG v2 1.4.4 (AA)',    #E910
        error   => "W011",
        message => "use relative (or CSS), rather than absolute units for width attribute in <$tag->[0]> tag",
        row     => $tag->[4],
        col     => $tag->[5]
    };
}

sub _check_height {
    my ($self,$tag) = @_;

    return  unless($self->{level} > 1);
    return  unless(defined $tag->[1]{height} && $tag->[1]{height} =~ /^\d+$/);

    push @{ $self->{ERRORS} }, {
        ref     => 'WCAG v2 1.4.4 (AA)',    #E910
        error   => "W012",
        message => "use relative (or CSS), rather than absolute units for height attribute in <$tag->[0]> tag",
        row     => $tag->[4],
        col     => $tag->[5]
    };
}

sub _check_object {
    my ($self,$tag,$p) = @_;

    # do we have simple text?
    my $x = $p->get_text();
    $x =~ s/\s+//gs;
    return  if($x);

    my @token;
    my $found;
    while( my $t = $p->get_token() ) {
        unshift @token, $t;
        next    unless($t->[0] eq 'S' || $t->[0] eq 'E');

        if($t->[0] eq 'E' && $t->[1] eq 'object') {
            last;
        } elsif($t->[0] eq 'S' && $t->[1] eq 'p') {
            $x = $p->get_text();
            $x =~ s/\s+//gs;
            $found = 1  if($x);
        } elsif($t->[0] eq 'S' && $t->[1] eq 'img') {
            $found = 1  if($t->[2]{alt});
        }

        last    if($found);
    }

    # put back tokens
    $p->unget_token($_) for(@token);

    return  if($found);

    push @{ $self->{ERRORS} }, {
        ref     => 'WCAG v2 1.1.1 (A)', #E865
        error   => "W013",
        message => qq{No alternative text (e.g. <p> or <img alt="">) found for <object> tag},
        row     => $tag->[4],
        col     => $tag->[5]
    };
}

sub _check_labelling {
    my ($self) = @_;

    for my $input (keys %{$self->{input}}) {
        next    if($self->{input}{$input}{type} && $self->{input}{$input}{type} =~ /hidden|submit|reset|button/);
        next    if($self->{label}{$input});
        next    if($self->{input}{$input}{title});
        #next    if($self->{input}{$input}{active} == 0);

        push @{ $self->{ERRORS} }, {
            ref     => 'WCAG v2 1.1.1 (A)', #E866
            error   => "W014",
            message => "all <$self->{input}{$input}{type}> tags require a unique <label> tag or a title attribute ($input)",
            row     => $self->{input}{$input}{row},
            col     => $self->{input}{$input}{column}
        };
    }

    for my $input (keys %{$self->{label}}) {
        next    if($self->{input}{$input});

        push @{ $self->{ERRORS} }, {
            ref     => 'WCAG v2 1.3.1 (A)', #E895
            error   => "W015",
            message => "all <label> tags should reference a unique <input> tag ($input)",
            row     => $self->{label}{$input}{row},
            col     => $self->{label}{$input}{column}
        };
    }
}

# -------------------------------------
# Private Methods : Other

sub _log {
    my $self = shift;
    my $log = $self->logfile or return;
    mkpath(dirname($log))   unless(-f $log);

    my $mode = $self->logclean ? 'w+' : 'a+';
    $self->logclean(0);

    my $fh = IO::File->new($log,$mode) or die "Cannot write to log file [$log]: $!\n";
    print $fh @_;
    $fh->close;
}

1;

__END__

=head1 METHODS

=head2 Constructor

Enables test object to retain content, results and errors as appropriate.

=over 4

=item new()

Creates and returns a Test::XHTML::WAI object.

=back

=head2 Public Methods

=over 4

=item level(LEVEL)

Level of compliance required to be checked. Valid levels are: 1 (A Level), 2
(AA Level) and 3 (AAA Level). Default level is 1. Invalid level are ignored.

=item validate(CONTENT)

Checks given content for basic compliance.

=item results()

Record results to log file (if given) and returns a hashref.

=item errors()

Returns all the current errors reported as XML::LibXML::Error objects.

=item errstr()

Returns all the current errors reported as a single string.

=item clear()

Clear all current errors and results.

=item logfile(FILE)

Set output log file for verbose messages.

=item logclean(STATE)

Set STATE to 1 (create/overwrite) or 0 (append - the default)

=back

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to barbie@cpan.org.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 SEE ALSO

L<HTML::TokeParser>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2008-2015 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
