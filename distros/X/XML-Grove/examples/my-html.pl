#
# Copyright (C) 1997, 1998 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: my-html.pl,v 1.5 1999/05/06 23:13:02 kmacleod Exp $
#

# `my-html.pl' uses `accept_name' methods to generate calls back using
# an element's name instead of the generic `visit_element'.  Because
# we don't want to handle every single possible element name, Perl's
# AUTOLOAD feature is used to pass through any elements we don't
# handle.

use XML::Parser::PerlSAX;
use XML::Grove;
use XML::Grove::Builder;
use XML::Grove::AsString;
use Data::Grove::Visitor;

($prog = $0) =~ s|.*/||g;

die "usage: $prog HTML-DOC\n"
    if ($#ARGV != 0);

my $builder = XML::Grove::Builder->new;
my $parser = XML::Parser::PerlSAX->new(Handler => $builder);
my $grove = $parser->parse (Source => { SystemId => @ARGV[0] });

$grove->accept_name (MyHTML->new);

exit (0);

######################################################################
#
# A Visitor package.
#

package MyHTML;

use strict;
use vars qw{$AUTOLOAD};

sub new {
    my $class = shift;

    return bless {}, $class;
}

sub visit_document {
    my $self = shift;
    my $grove = shift;

    $grove->children_accept_name ($self, @_);
}

sub visit_element {
    my $self = shift;
    my $element = shift;
    print "<$element->{Name}>";
    $element->children_accept_name ($self, @_);
    print "</$element->{Name}>";
}

sub visit_entity {
    my $self = shift;
    my $entity = shift;

    warn "is entity?\n";
    print "&" . $entity->{Name} . ";";
}

sub visit_characters {
    my $self = shift;
    my $characters = shift;
    my $data = $characters->{Data};

    # FIXME do we need to translate special chars here?
    $data =~ tr/\r/\n/;
    print $data;
}

######################################################################
#
# My special HTML tags
#

sub visit_name_DATE {
    my $time = localtime;

    # use only non-breaking spaces
    $time =~ s/ /\&nbsp;/g;

    print $time;
}

sub visit_name_PERL {
    my $self = shift;
    my $element = shift;

    # doesn't grok entities, be sure to use CDATA marked sections
    my $perl = $element->as_string;
    $perl =~ tr/\r//d;
    no strict;
    eval $perl;
    use strict;
    warn $@ if $@;
}

1;
