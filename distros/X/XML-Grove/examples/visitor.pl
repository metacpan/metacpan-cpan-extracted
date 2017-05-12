#
# Copyright (C) 1998 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: visitor.pl,v 1.5 1999/05/06 23:13:02 kmacleod Exp $
#

use XML::Parser::PerlSAX;
use XML::Grove;
use XML::Grove::Builder;
use Data::Grove::Visitor;

my $builder = XML::Grove::Builder->new;
my $parser = XML::Parser::PerlSAX->new(Handler => $builder);

my $visitor = new MyVisitor;

my $doc;
foreach $doc (@ARGV) {
    my $grove = $parser->parse (Source => { SystemId => $doc} );

    my @context;
    $grove->accept ($visitor, \@context);
}

package MyVisitor;

sub new {
    my $class = shift;

    return bless {}, $class;
}

sub visit_document {
    my $self = shift; my $grove = shift;

    $grove->children_accept ($self, @_);
}

sub visit_element {
    my $self = shift; my $element = shift; my $context = shift;

    push @$context, $element->{Name};
    my @attributes = %{$element->{Attributes}};
    print STDERR "@$context \\\\ (@attributes)\n";
    $element->children_accept ($self, $context, @_);
    print STDERR "@$context //\n";
    pop @$context;
}

sub visit_pi {
    my $self = shift; my $pi = shift; my $context = shift;

    my $target = $pi->{Target};
    my $data = $pi->{Data};
    print STDERR "@$context ?? $target($data)\n";
}

sub visit_characters {
    my $self = shift; my $characters = shift; my $context = shift;

    my $data = $characters->{Data};
    $data =~ s/([\x80-\xff])/sprintf "#x%X;", ord $1/eg;
    $data =~ s/([\t\n])/sprintf "#%d;", ord $1/eg;
    print STDERR "@$context || $data\n";
}
