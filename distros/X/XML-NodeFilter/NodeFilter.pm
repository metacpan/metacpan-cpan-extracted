#------------------------------------------------------------------------#
package XML::NodeFilter;
#------------------------------------------------------------------------#
# $Id: NodeFilter.pm,v 1.1.1.1 2002/11/08 09:26:59 phish108 Exp $
#------------------------------------------------------------------------#
# (c) 2002 Christian Glahn <christian.glahn@uibk.ac.at>                  #
# All rights reserved.                                                   #
#                                                                        #
# This code is free software; you can redistribute it and/or             #
# modify it under the same terms as Perl itself.                         #
#                                                                        #
#------------------------------------------------------------------------#

#------------------------------------------------------------------------#
# general settings                                                       #
#------------------------------------------------------------------------#
use 5.005;
use strict;

require Exporter;
use vars qw( $VERSION @ISA %EXPORT_TAGS @EXPORT @EXPORT_OK
             @FLAGNAMES %FLAGMAPPING);


$VERSION = '0.01';

@ISA = qw(Exporter);

#------------------------------------------------------------------------#
# export information                                                     #
#------------------------------------------------------------------------#

%EXPORT_TAGS = (
'results' => [ qw(
                  FILTER_DECLINED
                  FILTER_ACCEPT
                  FILTER_SKIP
                  FILTER_REJECT
) ],
'flags'   => [ qw(
                  SHOW_ALL
                  SHOW_ELEMENT
                  SHOW_ATTRIBUTE
                  SHOW_TEXT
                  SHOW_CDATA_SECTION
                  SHOW_ENTITY_REFERENCE
                  SHOW_ENTITY
                  SHOW_PROCESSING_INSTRUCTION
                  SHOW_COMMENT
                  SHOW_DOCUMENT
                  SHOW_DOCUMENT_TYPE
                  SHOW_DOCUMENT_FRAGMENT
                  SHOW_NOTATION
                  SHOW_NONE
) ],
'all'     => [ qw(
                  FILTER_DECLINED
                  FILTER_ACCEPT
                  FILTER_SKIP
                  FILTER_REJECT
                  SHOW_ALL
                  SHOW_ELEMENT
                  SHOW_ATTRIBUTE
                  SHOW_TEXT
                  SHOW_CDATA_SECTION
                  SHOW_ENTITY_REFERENCE
                  SHOW_ENTITY
                  SHOW_PROCESSING_INSTRUCTION
                  SHOW_COMMENT
                  SHOW_DOCUMENT
                  SHOW_DOCUMENT_TYPE
                  SHOW_DOCUMENT_FRAGMENT
                  SHOW_NOTATION
                  SHOW_NONE	
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw();

#------------------------------------------------------------------------#
# constants declaration                                                  #
#------------------------------------------------------------------------#

@FLAGNAMES = qw(
                SHOW_ELEMENT
                SHOW_ATTRIBUTE
                SHOW_TEXT
                SHOW_CDATA_SECTION
                SHOW_ENTITY_REFERENCE
                SHOW_ENTITY
                SHOW_PROCESSING_INSTRUCTION
                SHOW_COMMENT
                SHOW_DOCUMENT
                SHOW_DOCUMENT_TYPE
                SHOW_DOCUMENT_FRAGMENT
                SHOW_NOTATION
               );

use constant FILTER_DECLINED    => 0; # check what other filters say ...
use constant FILTER_ACCEPT      => 1;
use constant FILTER_SKIP        => 2;
use constant FILTER_REJECT      => 3;

use constant SHOW_ALL                    => 0xFFFFFFFF;
use constant SHOW_ELEMENT                => 0x00000001;
use constant SHOW_ATTRIBUTE              => 0x00000002;
use constant SHOW_TEXT                   => 0x00000004;
use constant SHOW_CDATA_SECTION          => 0x00000008;
use constant SHOW_ENTITY_REFERENCE       => 0x00000010;
use constant SHOW_ENTITY                 => 0x00000020;
use constant SHOW_PROCESSING_INSTRUCTION => 0x00000040;
use constant SHOW_COMMENT                => 0x00000080;
use constant SHOW_DOCUMENT               => 0x00000100;
use constant SHOW_DOCUMENT_TYPE          => 0x00000200;
use constant SHOW_DOCUMENT_FRAGMENT      => 0x00000400;
use constant SHOW_NOTATION               => 0x00000800;

# why are specs always incomplete regarding the NULL set???
use constant SHOW_NONE                   => 0x00000000;

@FLAGMAPPING{@FLAGNAMES} = (SHOW_ELEMENT,
                            SHOW_ATTRIBUTE,
                            SHOW_TEXT,
                            SHOW_CDATA_SECTION,
                            SHOW_ENTITY_REFERENCE,
                            SHOW_ENTITY,
                            SHOW_PROCESSING_INSTRUCTION,
                            SHOW_COMMENT,
                            SHOW_DOCUMENT,
                            SHOW_DOCUMENT_TYPE,
                            SHOW_DOCUMENT_FRAGMENT,
                            SHOW_NOTATION);

#------------------------------------------------------------------------#
# class constructor                                                      #
#------------------------------------------------------------------------#
sub new {
    my $class = shift;
    my %args  = @_;
    my $flags = SHOW_ALL;
    if ( defined $args{WHAT_TO_SHOW} ) {
        $flags = $args{WHAT_TO_SHOW};
        delete $args{WHAT_TO_SHOW};
    }
    elsif ( defined $args{-show} ) {
        $flags = $args{-show};
        delete $args{-show};
    }

    my $self = bless \%args, $class;

    $self->what_to_show( ref( $flags ) ? %{$flags} : $flags );

    return $self;
}

#------------------------------------------------------------------------#
# what_to_show                                                           #
#------------------------------------------------------------------------#
sub what_to_show {
    my $self = shift;
    my $mask = $self->{WHAT_TO_SHOW};

    if ( my $n = scalar @_ ) {
        if ( $n == 1) {
            $mask = shift;
            unless ( defined $mask ) {
                $self->{WHAT_TO_SHOW} = SHOW_ALL;
                $mask = SHOW_ALL;
            }
        }
        elsif ( $n > 1 ) {
            my %args = @_;
            $mask= SHOW_NONE;

            foreach ( keys %args ) {
                if ( defined $FLAGMAPPING{$_}
                     and defined $args{$_}
                     and $args{$_} ){
                    $mask |= $FLAGMAPPING{$_};
                }
            }

            if ( defined $args{SHOW_ALL} ) {
                $mask = SHOW_ALL;
            }

        }

        $self->{WHAT_TO_SHOW} = $mask;
    }

    if ( wantarray ) {
        my %retval = ();

        @retval{@FLAGNAMES} = map { $mask & $_ ? "1" : "0" } (
                                                SHOW_ELEMENT,
                                                SHOW_ATTRIBUTE,
                                                SHOW_TEXT,
                                                SHOW_CDATA_SECTION,
                                                SHOW_ENTITY_REFERENCE,
                                                SHOW_ENTITY,
                                                SHOW_PROCESSING_INSTRUCTION,
                                                SHOW_COMMENT,
                                                SHOW_DOCUMENT,
                                                SHOW_DOCUMENT_TYPE,
                                                SHOW_DOCUMENT_FRAGMENT,
                                                SHOW_NOTATION
                                                            );
        return %retval;
    }

    return $mask;
}

#------------------------------------------------------------------------#
# accept_node and acceptNode                                             #
#------------------------------------------------------------------------#
# accept_node() will call acceptNode() on default. This allows a         #
# transparent implementation towards spec conformance.                   #
#                                                                        #
# the default return value is FILTER_ACCEPT rather than FILTER_DECLINED, #
# because FILTER_DECLINED was not specified                              #
#------------------------------------------------------------------------#
sub accept_node { my $s = shift; return $s->acceptNode( @_ );  }
sub acceptNode  { return FILTER_ACCEPT; }

1;
#------------------------------------------------------------------------#
# Code End                                                               #
#------------------------------------------------------------------------#
__END__

=head1 NAME

XML::NodeFilter - Generic XML::NodeFilter Class

=head1 SYNOPSIS

  use XML::NodeFilter;

  my $filter = XML::NodeFilter->new();

  $your_iterator->set_filter( $filter );

=head1 DESCRIPTION

"Filters are objects that know how to "filter out" nodes. If a
NodeIterator or a TreeWalker is given a NodeFilter, it applies the
filter before it returns the next node. If the filter says to accept
the node, the traversal logic returns it; otherwise, traversal looks
for the next node and pretends that the node was rejected was not
there."

This definition is given by the DOM Traversal and Range
Specification. It explains pretty well, what this class is for: A
XML::NodeFilter will recieve a node from a traversal object, such as
XML::LibXML::Iterator is one and tells if the given node should be
returned to the caller or not.

Although I refere only to XML::LibXML here, XML::NodeFilter is
implemented more open, so it can be used with other DOM
implementations as well.

=head2 The Spec And The Implementation

The DOM Traversal and Range Specification just defines the contstants
and accept_node() for a node filter. The XML::NodeFilter
implementation also adds the what_to_show() function to the class
definition, since I think that it is a filters job to decide which
node-types should be shown and which not.

Also XML::NodeFilter adds two constants which are not part of the
specification. The first one is B<FILTER_DECLINED>. It tells the
traversal logic, that it should apply another filter in order to
decide if the node should be visible or not. While the spec only
defines the traversal logic to have either one or no filter applied,
it showed that it leads to cleaner code if more filter could be used
in conjunktion. If a traversal logic finds a single filter that
returns B<FILTER_DECLINED>, it should be handled as a synonym of
B<FILTER_ACCEPT>. While B<FILTER_ACCEPT> is finite and would cause all
other not to be executed, B<FILTER_DECLINED> gives one more
flexibility.

The second extension of the specification is the B<SHOW_NONE>
symbol. It was added for operational completeness, so one can
explicitly switch the node type filter off (means all node types are
rejected). This will cause the two calls of what_to_show have a
different result:

  $filter->what_to_show( undef );     # will set SHOW_ALL
  $filter->what_to_show( SHOW_NONE ); # will not set SHOW_ALL

Infact B<SHOW_NONE> is a NULL flag, that means it can be added to any
list of flags without altering it.

  $filter->what_to_show( SHOW_ELEMENT | SHOW_TEXT | SHOW_NONE );

is therefore identical to

  $filter->what_to_show( SHOW_ELEMENT | SHOW_TEXT );

B<SHOW_NONE> is espacially usefull to avoid numerically or even more ugly
unintialized values while building such flag lists dynamically.

=head2 How To write a Node Filter with XML::NodeFilter?

Actually writing a node filter becomes very simple with
XML::NodeFilter: Simply inherit your specialized node filter from
XML::NodeFilter and implement your implement the function
accept_node(). This name is more perlish than the name given by the
specification. If your implementation needs to stay very close to the
specification, you can alternativly implement
acceptNode(). Implementing both functions makes no sense, since
accept_node() should be prefered by the traversal logic. Because of
this acceptNode() will only be called if no accept_node()
implementation was given.

Example:

   package My::NodeFilter;

   use XML::NodeFilter qw(:results);
   use vars qw(@ISA);
   @ISA = qw(XML::NodeFilter);

   use XML::LibXML::Common;

   sub accept_node {
       my $filter = shift;
       my $node   = shift;

       unless ( $node->getNodeType == ELEMENT_NODE
                and defined $node->getNamespaceURI ) {
          # ignore node without a defined namespace
          return FILTER_REJECT;
       }
       return FILTER_DECLINED;
   }

   1;

This example shows a simple nodefilter that will reject any element
without a namespace defined. Note that FILTER_DECLINED is returned if
the node was not rejected. This allows a traversal logic to apply
another filter on the nodes with a namespace defined. If your
application needs to use different filters on the namespaced elements
depending on the state where you want to traverse your DOM but you
need allways to ignore elements without a namespace such a filter will
enshure that you need not to add redundant code to your filter or even
to choose a base class.

=head2 How To make use of a XML::NodeFilter Filter?

If you need to write some traversal code yourself, you should call the
node filters accept_node() function to test if the logic should return
the current node. A node is not returned if any filter retunrs
FILTER_SKIP or FILTER_REJECT. In this case you need to reinvoke your
traversal code.

The following code snippet shows how you can make use of
XML::NodeFilter in your traversal logic:

  use XML::NodeFilter qw(:results);

  #...
  sub traversal_logic {
      my $refnode = shift;
      my @filters = @_;
      my $node = undef;

      TRAVERSE: while (1) {
            my $state = FILTER_DECLINED;
            # your traversal logic
            # ...
            last TRAVERSE unless defined $node;
            FILTER: foreach my $filter ( @filters ) {
                $state = $filter->accept_node($node);
                last TRAVERSE if     $state == FILTER_ACCEPT;
                last FILTER   unless $state == FILTER_DECLINED;
                        last TRAVERSE if $state == FILTER_DECLINED;
      }

      return $node;
  }

As you see the traversal code will call only accept_node() on each
filter. Still this will work fine with filters, that have acceptNode()
implemented: XML::NodeFilter calls acceptNode() if the original
accept_node() function is called. This ashures that filters that use
function names conform to the specification will work as well.

Note that XML::NodeFilter uses as default return value of
accept_node() FILTER_ACCEPT rather than FILTER_DECLINED. This is done
so you can write 100% specification conform traversal and filter
logic.

=head2 Functions

=over 4

=item new()

As the constructor of this class it accepts some parameters in form of
a hash. This parameter hash will be blessed into a hash reference. The
only parameter used by the class itself is B<-show>. This parameter
may hold a bitmask of node filter flags as described below or a hash
reference containing the same information.

If B<-show> is ommited SHOW_ALL is assumed as default.

=item what_to_show()

This function is added to the filter class, rather than assuming it is
available directly from within a traversal logic. what_to_show() takes
either a bitmask or a hash that holds the information what nodes
should be filtered.

If what_to_show() is called without any parameter, it simply returns
the bitmaks in scalar context; if called in array context it returns a
hash containing the corresponding information: If a bit is set in the
bitmask the corresponding key has the value 1; otherwise it has the
value 0.

=item accept_node()

This function is used to tell a calling traversal function if a given
node should be returned to the caller or should be skipped. It has
four possible return values:

FILTER_DECLINED to indicate that the filter itself would accept if no
other (less significant) filters rejects or skips it. B<NOTE>
FILTER_DECLINED is not defined by the spec.

FILTER_ACCEPT to indicate that a node is accepted regardless what
other filters may indicate.

FILTER_SKIP to indicate a node is skipped, but its descendants should
be still available.

FILTER_REJECT to indicate a node and all its descendants should be
skipped by the traversal logic.

By default accept_node() returns FILTER_ACCEPT.

=item acceptNode()

Alternative function for accept_node(). This is only available for
spec conformance. Any traversal logic should request
accept_node(). Node filter implementations may choose either to
implement accept_node() or acceptNode(). Implmenting both makes no
sense at all!

=back

=head2 Constants

=over 4

=item * FILTER_DECLINED (0)

Additional symbol to allow stacked node filters.

=item * FILTER_ACCEPT   (1)

Defined by the specification

=item * FILTER_SKIP     (2)

Defined by the specification

=item * FILTER_REJECT   (3)

Defined by the specification

=item * SHOW_ALL

Defined by the specification

=item * SHOW_ELEMENT

Defined by the specification

=item * SHOW_ATTRIBUTE

Defined by the specification

=item * SHOW_TEXT

Defined by the specification

=item * SHOW_CDATA_SECTION

Defined by the specification

=item * SHOW_ENTITY_REFERENCE

Defined by the specification

=item * SHOW_ENTITY

Defined by the specification

=item * SHOW_PROCESSING_INSTRUCTION

Defined by the specification

=item * SHOW_COMMENT

Defined by the specification

=item * SHOW_DOCUMENT

Defined by the specification

=item * SHOW_DOCUMENT_TYPE

Defined by the specification

=item * SHOW_DOCUMENT_FRAGMENT

Defined by the specification

=item * SHOW_NOTATION

Defined by the specification

=item * SHOW_NONE

Additional symbol to indicate a NULL filter. This is for operational
completeness.

=item * @FLAGNAMES

Contains the names of the FLAGS used by what_to_show(). The combining
symbols SHOW_ALL and SHOW_NONE are not included by this list.

=item * %FLAGMAPPING

This hash mapps flagnames (as listed by @FLAGNAMES) to their
predefined values. The combining symbols SHOW_ALL and SHOW_NONE are
not included by this list.

B<NOTE:> @FLAGNAMES and %FALGMAPPING are not exported. To make use of
them you have to use the fully quallified namespace as follows

  # gives the value of the SHOW_ELEMENT.
  my $flag = $XML::NodeFilter::FLAGMAPPING{SHOW_ELEMENT};

=back

=head1 EXPORTS

XML::NodeFilter will not export any symbols at all. Instead it gives
two tags: ':results' and ':flags'.

=over 4

=item :results

This tag exports the FILTER_* constants. This is usefull to avoid
hardcoded numerical values within the filter code or the traversal
logic. These symbols are used by accept_node() and are required to
indicate the state

=item :flags

Exports SHOW_* flags. Import these symbols if what_to_show() should be
used conform to the specification rather than using named parameters.

=back

Alternativly you might import ':all' to get all symbols exported by
both of the tags just described.

=head1 AUTHOR

Christian Glahn, E<lt>christian.glahn@uibk.ac.atE<gt>

=head1 SEE ALSO

L<perl>, L<XML::LibXML::Iterator>, L<XML::LibXML::NodeFilter>

W3C DOM Level 2 Traversal and Range Specification

=head1 COPYRIGHT AND LICENSE

(c) 2002, Christian Glahn. All rights reserved.

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
