package Test::XHTML::Critic;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.13';

#----------------------------------------------------------------------------

=head1 NAME

Test::XHTML::Critic - Basic critique checks.

=head1 SYNOPSIS

    my $txw = Test::XHTML::Critic->new();

    $txw->validate($content);       # run compliance checks
    my $results = $txw->results();  # retrieve results

    $txw->clear();                  # clear all current errors and results
    $txw->errors();                 # all current errors reported
    $txw->errstr();                 # basic error message

    $txw->logfile($file);           # logfile for verbose messages
    $txw->logclean(1);              # 1 = overwrite, 0 = append (default)

=head1 DESCRIPTION

This module attempts to check content for deprecated elements or missing 
recommend elements. Some checks are based on W3C standards, while others are
from recognised usability resources.

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
    '<!DOCTYPE html>'           => 3,   # HTML5
    'xhtml1-strict.dtd'         => 2,
    'xhtml1-transitional.dtd'   => 2,
    'xhtml1-frameset.dtd'       => 2,
    'html401-strict.dtd'        => 1,
    'html401-loose.dtd'         => 1,
    'html401-frameset.dtd'      => 1,
);

# For a list of deprecated tags and attributes, please see the following:
# * http://www.w3.org/TR/html4/index/attributes.html
# * http://www.w3.org/TR/2011/WD-html5-diff-20110525/
# * http://www.w3.org/TR/html5/obsolete.html#non-conforming-features

my %deprecated = (
    'a'             => { 2 => { attr => [qw(charset coords datafld datasrc methods name rev shape urn)] } },
    'acronym'       => { 0 => { tag  => [qw(abbr)] } },
    'applet'        => { 0 => { tag  => [qw(object)] },
                         1 => { attr => [qw(align alt archive code codebase height hspace name object vspace width)] },
                         2 => { attr => [qw(datafld datasrc)] } },
    'area'          => { 2 => { attr => [qw(nohref)] } },
    'b'             => { 0 => { tag  => [qw(strong)] } },
    'basefont'      => { 0 => { css  => [qw(font color)] },
                         1 => { attr => [qw(color face size)] } },
    'big'           => { 0 => { css  => [qw(font-size)] } },
    'blockquote'    => { 0 => { css  => [qw(margin)] } },
    'body'          => { 1 => { attr => [qw(alink background bgcolor link text vlink)] },
                         2 => { attr => [qw(alink background bgcolor link marginbottom marginheight marginleft marginright margintop marginwidth text vlink)] } },
    'br'            => { 1 => { attr => [qw(clear)] } },
    'button'        => { 2 => { attr => [qw(datafld dataformatas datasrc)] } },
    'caption'       => { 1 => { attr => [qw(align)] },
                         2 => { attr => [qw(align)] } },
    'center'        => { 0 => { css  => [qw(text-align)] } },
    'col'           => { 2 => { attr => [qw(align char charoff valign width)] } },
    'dir'           => { 0 => { tag  => [qw(ul)] },
                         1 => { attr => [qw(compact)] } },
    'div'           => { 1 => { attr => [qw(align)] },
                         2 => { attr => [qw(align datafld dataformatas datasrc)] } },
    'dl'            => { 1 => { attr => [qw(compact)] },
                         2 => { attr => [qw(compact)] } },
    'embed'         => { 0 => { tag  => [qw(object)] },
                         2 => { attr => [qw(align hspace name vspace)] },
                         3 => { tag  => [qw(embed)] } },       # reinstated in HTML5
    'fieldset'      => { 2 => { attr => [qw(datafld)] } },
    'font'          => { 0 => { css  => [qw(font color)] },
                         1 => { attr => [qw(color face size)] } },
    'form'          => { 2 => { attr => [qw(name)] } },
    'frame'         => { 0 => { tag  => [qw(iframe)] },
                         2 => { attr => [qw(datafld datasrc name)] } },
    'frameset'      => { 0 => { tag  => [qw(iframe)] } },
    'h1'            => { 1 => { attr => [qw(align)] } },
    'h2'            => { 1 => { attr => [qw(align)] } },
    'h3'            => { 1 => { attr => [qw(align)] } },
    'h4'            => { 1 => { attr => [qw(align)] } },
    'h5'            => { 1 => { attr => [qw(align)] } },
    'h6'            => { 1 => { attr => [qw(align)] } },
    'head'          => { 2 => { attr => [qw(profile)] } },
    'hr'            => { 1 => { attr => [qw(align noshade size width)] },
                         2 => { attr => [qw(color)] } },
    'html'          => { 1 => { attr => [qw(version)] } },
    'i'             => { 0 => { css  => [qw(font-style)] } },
    'iframe'        => { 1 => { attr => [qw(align)] },
                         2 => { attr => [qw(align allowtransparency datafld datasrc frameborder hspace longdesc marginheight marginwidth name scrolling vspace)] } },
    'img'           => { 1 => { attr => [qw(align border hspace vspace)] },
                         2 => { attr => [qw(datafld datasrc longdesc lowsrc name)] } },
    'input'         => { 1 => { attr => [qw(align)] },
                         2 => { attr => [qw(datafld dataformatas datasrc hspace usemap vspace)] } },
    'isindex'       => { 0 => { tag  => [qw(input)] },
                         1 => { attr => [qw(prompt)] } },
    'label'         => { 2 => { attr => [qw(datafld dataformatas datasrc)] } },
    'layer'         => { 0 => { css  => [qw(position)] } },
    'legend'        => { 1 => { attr => [qw(align)] },
                         2 => { attr => [qw(datafld dataformatas datasrc)] } },
    'li'            => { 1 => { attr => [qw(type value)] } },
    'link'          => { 2 => { attr => [qw(charset methods rev target urn)] } },
    'map'           => { 2 => { attr => [qw(name)] } },
    'marquee'       => { 2 => { attr => [qw(datafld dataformatas datasrc)] } },
    'menu'          => { 0 => { tag  => [qw(ul)] },
                         1 => { attr => [qw(compact)] } },
    'meta'          => { 2 => { attr => [qw(scheme)] } },
    'noframes'      => { 0 => { tag  => [qw(iframe)] } },
    'object'        => { 1 => { attr => [qw(align border hspace vspace)] },
                         2 => { attr => [qw(archive classid code codebase codetype datafld dataformatas datasrc declare standby)] } },
    'ol'            => { 1 => { attr => [qw(compact start type)] } },
    'option'        => { 2 => { attr => [qw(dataformatas datasrc name)] } },
    'param'         => { 2 => { attr => [qw(datafld type valuetype)] } },
    'p'             => { 1 => { attr => [qw(align)] } },
    'pre'           => { 1 => { attr => [qw(width)] } },
    's'             => { 0 => { css  => [qw(text-decoration)] } },
    'script'        => { 1 => { attr => [qw(language)] },
                         2 => { attr => [qw(event for)] } },
    'select'        => { 2 => { attr => [qw(datafld dataformatas datasrc)] } },
    'span'          => { 2 => { attr => [qw(datafld dataformatas datasrc)] } },
    'strike'        => { 0 => { css  => [qw(text-decoration)] } },
    'table'         => { 1 => { attr => [qw(align bgcolor)] },
                         2 => { attr => [qw(background cellpadding cellspacing dataformatas datapagesize datasrc frame rules summary width)] } },
    'tbody'         => { 2 => { attr => [qw(align background char charoff valign)] } },
    'td'            => { 1 => { attr => [qw(bgcolor height nowrap width)] },
                         2 => { attr => [qw(abbr align axis background char charoff valign)] } },
    'textarea'      => { 2 => { attr => [qw(datafld datasrc)] } },
    'tfoot'         => { 2 => { attr => [qw(align background char charoff valign)] } },
    'th'            => { 1 => { attr => [qw(bgcolor height nowrap width)] },
                         2 => { attr => [qw(abbr align axis background char charoff valign)] } },
    'thead'         => { 2 => { attr => [qw(align background char charoff valign)] } },
    'tr'            => { 1 => { attr => [qw(bgcolor)] },
                         2 => { attr => [qw(align background char charoff valign)] } },
    'tt'            => { 0 => { css  => [qw(text-decoration)] } },
    'u'             => { 0 => { css  => [qw(text-decoration)] } },
    'ul'            => { 1 => { attr => [qw(compact type)] } },
);

my @TAGS = (
    # list taken from http://www.w3schools.com/tags/default.asp
    'a', 'abbr', 'acronym', 'address', 'applet', 'area',
    'b', 'base', 'basefont', 'bdo', 'big', 'blockquote', 'body', 'br', 'button',
    'caption', 'center', 'cite', 'code', 'col', 'colgroup',
    'dd', 'del', 'dfn', 'dir', 'div', 'dl', 'dt',
    'em', 'embed',
    'fieldset', 'font', 'form', 'frame', 'frameset',
    'head', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hr', 'html',
    'i', 'iframe', 'img', 'input', 'ins', 'isindex',
    'kbd',
    'label', 'layer', 'legend', 'li', 'link',
    'map', 'menu', 'meta',
    'noframes', 'noscript',
    'object', 'ol', 'optgroup', 'option',
    'p', 'param', 'pre',
    'q',
    's', 'samp', 'script', 'select', 'small', 'span', 'strike', 'strong', 'style', 'summary', 'sub',
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
    my $self  = { dtdtype => 0 };
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
        $str .= " [row $error->{row}, column $error->{col}]"    if($FIXED && ($error->{row} || $error->{col}));
        $str .= "\n";
        $i++;
    }
    return $str;
}

# -------------------------------------
# Subroutines

# TODO
# * privacy policy
# * home page link

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

            if($tag->[0] eq uc $tag->[0]) {
                $self->_check_case($tag);
                $tag->[0] = lc $tag->[0];
            }

            $self->_check_deprecated($tag);

            if($tag->[0] eq 'map') {
                $self->_check_name($tag);
            } elsif($tag->[0] eq 'img') {
                $self->_check_name($tag);
                $self->_check_size($tag);
            } elsif($tag->[0] eq 'a') {
                $self->_check_policy1($tag,$p);
            } elsif($tag->[0] eq 'script') {
                $self->_check_language($tag);
            } elsif($tag->[0] eq 'title') {
                $self->_check_title($tag,$p);
            }
        }

        $self->_check_policy2();


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

sub _check_case {
    my ($self,$tag) = @_;

    if($self->{dtdtype} == 1) {
        push @{ $self->{ERRORS} }, {
            #ref     => 'Best Practices Recommedation only',
            error   => "C001",
            message => "W3C recommends use of lowercase in HTML 4 (<$tag->[0]>)",
            row     => $tag->[2],
            col     => $tag->[3]
        };
    } elsif($self->{dtdtype} == 2) {
        push @{ $self->{ERRORS} }, {
            #ref     => 'Best Practices Recommedation only',
            error   => "C002",
            message => "declaration requires lowercase tags (<$tag->[0]>)",
            row     => $tag->[2],
            col     => $tag->[3]
        };
    }
}

sub _check_deprecated {
    my ($self,$tag) = @_;

    return  unless($deprecated{ $tag->[0] });

    my ($elem,@css);
    for my $dtdtype (sort {$b <=> $a} keys %{$deprecated{$tag->[0]}}) {
        $elem ||= $deprecated{$tag->[0]}{$dtdtype}{tag};
        push @css, @{ $deprecated{$tag->[0]}{$dtdtype}{css} } if($deprecated{$tag->[0]}{$dtdtype}{css});

        next    unless($self->{dtdtype} > $dtdtype);
        next    unless($deprecated{$tag->[0]}{$dtdtype}{attr});

        for my $attr (@{ $deprecated{$tag->[0]}{$dtdtype}{attr} }) {
            if($tag->[1]{$attr}) {
                push @{ $self->{ERRORS} }, {
                    #ref     => 'Best Practices Recommedation only',
                    error   => "C010",
                    message => "'$attr' attribute deprecated in <$tag->[0]> tag",
                    row     => $tag->[4],
                    col     => $tag->[5]
                };
            }
        }
    }

    if($elem && $elem->[0] ne $tag->[0]) {
        push @{ $self->{ERRORS} }, {
            #ref     => 'Best Practices Recommedation only',
            error   => "C011",
            message => "<$tag->[0]> has been deprecated in favour of <$elem->[0]>",
            row     => $tag->[4],
            col     => $tag->[5]
        };
    } elsif(@css) {
        push @{ $self->{ERRORS} }, {
            #ref     => 'Best Practices Recommedation only',
            error   => "C012",
            message => "<$tag->[0]> has been deprecated in favour of CSS elements (".join(',',@css).")",
            row     => $tag->[4],
            col     => $tag->[5]
        };
    }
}

sub _check_name {
    my ($self,$tag) = @_;

    if($tag->[1]{name}) {
        push @{ $self->{ERRORS} }, {
            #ref     => 'Best Practices Recommedation only',
            error   => "C003",
            message => "name attribute deprecated in <$tag->[0]> tag",
            row     => $tag->[4],
            col     => $tag->[5]
        };
    }
}

sub _check_size {
    my ($self,$tag) = @_;

    if(!$tag->[1]{width} || !$tag->[1]{height}) {
        push @{ $self->{ERRORS} }, {
            #ref     => 'Best Practices Recommedation only',
            error   => "C004",
            message => "width and height attributes allow for pre-rendering <$tag->[0]> tags ($tag->[1]{src})",
            row     => $tag->[4],
            col     => $tag->[5]
        };
    }
}

sub _check_language {
    my ($self,$tag) = @_;

    if($tag->[1]{language}) {
        push @{ $self->{ERRORS} }, {
            #ref     => 'Best Practices Recommedation only',
            error   => "C005",
            message => "language attribute deprecated in <$tag->[0]> tag",
            row     => $tag->[4],
            col     => $tag->[5]
        };
    }
}

sub _check_policy1 {
    my ($self,$tag,$p) = @_;

    my $x = $p->get_text();

    if(     $x =~ /privacy policy/i 
        ||  ($tag->[1]{title} && $tag->[1]{title} =~ /privacy policy/i)
        ||  $x =~ /terms.*conditions/i 
        ||  ($tag->[1]{title} && $tag->[1]{title} =~ /terms.*conditions/i) ) {
        $self->{policy}{privacy} = 1;
    }

    if(     $x =~ /home/i 
        ||  ($tag->[1]{title} && $tag->[1]{title} =~ /home/i) ) {
        $self->{policy}{home} = 1;
    }
}

sub _check_policy2 {
    my ($self) = @_;

    if(!$self->{policy}{privacy}) {
        push @{ $self->{ERRORS} }, {
            #ref     => 'Best Practices Recommedation only',
            error   => "C006",
            message => "no link to a privacy policy"
        };
    }

    if(!$self->{policy}{home}) {
        push @{ $self->{ERRORS} }, {
            #ref     => 'Best Practices Recommedation only',
            error   => "C007",
            message => "no home page link"
        };
    }
}

sub _check_title {
    my ($self,$tag,$p) = @_;

    my $x = $p->get_text();

    if(length $x > 64) {
        push @{ $self->{ERRORS} }, {
            #ref     => 'Best Practices Recommedation only',
            error   => "C008",
            message => "W3C recommend <title> should not be longer than 64 characters [".(substr($x,0,64))."]",
            row     => $tag->[4],
            col     => $tag->[5]
        };
    }

    if($x =~ /['"(){}\[\]]/) {
        push @{ $self->{ERRORS} }, {
            #ref     => 'Best Practices Recommedation only',
            error   => "C009",
            message => qq!avoid using the characters '"(){}[] in <title> tag - <$x>!,
            row     => $tag->[4],
            col     => $tag->[5]
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

Creates and returns a Test::XHTML::Critic object.

=back

=head2 Public Methods

=over 4

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
