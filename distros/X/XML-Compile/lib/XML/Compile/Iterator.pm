# Copyrights 2006-2019 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution XML-Compile.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::Iterator;
use vars '$VERSION';
$VERSION = '1.63';


use warnings;
use strict;

use XML::Compile::Util  qw/pack_type type_of_node SCHEMA2001i/;
use Log::Report 'xml-compile', syntax => 'SHORT';


sub new($@)
{   my ($class, $node, $path, $filter) = splice @_, 0, 4;
    (bless {}, $class)
      ->init( { node => $node, filter => $filter, path => $path, @_} );
}

sub init($)
{   my ($self, $args) = @_;
    $self->{node}   = delete $args->{node}
        or panic "no node specified";

    $self->{filter} = delete $args->{filter}
        or panic "no filter specified";

    $self->{path}   = delete $args->{path}
        or panic "no path specified";

    $self->{current} = 0;
    $self;
}


sub descend(;$$$)
{   my ($self, $node, $p, $filter) = @_;
    $node  ||= $self->currentChild;
    defined $node or return undef;

    my $path = $self->path;
    $path   .= '/'.$p if defined $p;

    (ref $self)->new
      ($node, $path, ($filter || $self->{filter}));
}

#----------------

sub node()   {shift->{node}}
sub filter() {shift->{filter}}
sub path()   {shift->{path}}

#----------------

sub childs()
{   my $self = shift;
    my $ln   = $self->{childs};
    unless(defined $ln)
    {   my $filter = $self->filter;
        $ln = $self->{childs}
            = [ grep {$filter->($_)} $self->node->childNodes ];
    }
    wantarray ? @$ln : $ln;
}


sub currentChild() { $_[0]->childs->[$_[0]->{current}] }


sub firstChild() {shift->childs->[0]}


sub lastChild()
{   my $list = shift->childs;
    @$list ? $list->[-1] : undef;   # avoid error on empty list
}


sub nextChild()
{   my $self = shift;
    my $list = $self->childs;
    $self->{current} < @$list ? $list->[ ++$self->{current} ] : undef;
}


sub previousChild()
{   my $self = shift;
    my $list = $self->childs;
    $self->{current} > 0 ? $list->[ --$self->{current} ] : undef;
}


sub nrChildren()
{   my $list = shift->childs;
    scalar @$list;
}

#---------

sub nodeType() { type_of_node(shift->node) || '' }


sub nodeLocal()
{   my $node = shift->node or return '';
    $node->localName;
}


sub nodeNil()
{   my $node = shift->node or return 0;
    my $nil  = $node->getAttributeNS(SCHEMA2001i, 'nil') || '';
    $nil eq 'true' || $nil eq '1';
}


sub textContent()
{   my $node = shift->node or return undef;
    $node->textContent;
}


sub currentType()
{   my $current = shift->currentChild or return '';
    type_of_node $current;
}


sub currentLocal()
{   my $current = shift->currentChild or return '';
    $current->localName;
}


sub currentContent()
{   my $current = shift->currentChild or return undef;
    $current->textContent;
}

1;
