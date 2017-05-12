package XML::Traverse::ParseTree;
use strict;
use warnings;
use Carp;

#
#   $Id: ParseTree.pm,v 1.6 2006/10/31 17:10:04 martin Exp $
#
our $VERSION = "0.03";

sub new {
    my ( $pkg, @params ) = @_;
    $pkg = ref($pkg) if ref($pkg);
    my $self = {@params};
    return bless $self, $pkg;
}

#
# returns the text content of $e and all subnodes
#
sub get_element_text {
    my ( $pkg, $e ) = @_;

    my $interesting = sub {
        return !ref( $_[0] );
    };
    my $children = sub {
        $pkg->_text_iterator( $_[0] );
    };

    my $i =
      $pkg->_make_dfs_search( _value_to_iterator($e), $children, $interesting );

    my $rv = undef;
    while ( my $t = $i->() ) {
        $rv .= $t;
    }
    $rv;
}

sub get_element_name {
    my ( $pkg, $e ) = @_;

    # $e must be an arrayref, the first element must be
    # a string, it has to be different than 0 as "0" specifies a
    # text content
    return $e->[0] if ref($e) =~ /array/i && !ref( $e->[0] ) && $e->[0] ne "0";

    carp "Wrong context! Arrayref expected!";
    undef;
}

# returns the attributes (hashref) of the given element
sub get_element_attrs {
    my ( $pkg, $e ) = @_;

    carp "Wrong context! Arrayref expected!"
      unless ref($e) =~ /array/i
      && !ref( $e->[0] )
      && defined( $e->[0] )
      && $e->[0] ne "0";
    $e->[1]->[0];
}

#
# get($current,@path) - general purpose getter.
#
# result is either a single value or an iterator, depending on
# the contents of @path.
# (see pod at the end of this file)
#

sub get {
    my ( $pkg, $e, @path ) = @_;

    my @iterator_context =
      grep { /ITERATOR/ }
      map  { ( $pkg->_action($_) )[3] } @path;

    if (@iterator_context) {
        my @creators = map { $pkg->_icreator($_) } @path;
        my $i = _value_to_iterator($e);
        while (@creators) {
            $i = _flatten( $i, shift @creators );
        }
        return $i;
    }
    else {
        while ( defined($e) && @path ) {
            $e = $pkg->_scalar_get( $e, shift @path );
        }
        return $e;
    }
}

#
# returns a curried version of get, this may be used in function-style programming
# (i.e. without package/object reference)
#
# the only parameter to the created function is the current element
#
sub getter {
    my ( $pkg, @path ) = @_;
    sub {
        $pkg->get( $_[0], @path );
    };
}

# returns an iterator over all child elements (direct childs, i.e. one level only)
#
#   $e - current element
#   $filter
#       - undef - all child elements are returned
#       - string - all childs named "string" are returned
#       - coderef - all those child elements for
#           which the coderef evaluates to true are returned
#
sub child_iterator {
    my ( $pkg, $e, $filter ) = @_;

    my $result = $pkg->_child_iterator($e);

    if ( ( UNIVERSAL::isa( $filter, 'CODE' ) ) ) {
        $result = _igrep( $filter, $result );
    }
    elsif ( defined $filter ) {

        # filter contains a name
        $result = _igrep( $pkg->_name_filter($filter), $result );
    }
    $result;
}

#
# $current - current element or an element iterator
# $name - name (string) of an element or a coderef
#
#   - given a name, only elements of that name are returned.
#   - given a coderef, only those elements are returned where
#     $name-sub evaluates to true (element is the only param
#     to $name-sub)
#   - no name given (=undef) all elements are given
#
sub dfs_iterator {
    my ( $pkg, $current, $name ) = @_;

    my $children = sub {
        my $ce = shift;
        $pkg->child_iterator($ce);
    };
    my $filter;
    if ( ( UNIVERSAL::isa( $name, 'CODE' ) ) ) {
        $filter = $name;
    }
    elsif ( defined $name ) {
        $filter = sub {
            my ($ce) = @_;
            my $ceName = $pkg->get_element_name($ce);
            return $ceName eq $name;
        };
    }
    else {
        $filter = undef;
    }

    my $root =
      ( UNIVERSAL::isa( $current, 'CODE' ) )
      ? $current
      : _value_to_iterator($current);

    $pkg->_make_dfs_search( $root, $children, $filter );
}

#
# creates a hashref with the contents of an element incl. all sub elements
#
sub element_to_object {
    my ( $pkg, $o ) = @_;
    my $r = {};

    $r->{_name} = $pkg->get_element_name($o);
    $r->{_attr} = $pkg->get_element_attrs($o);
    $r->{_text} = $pkg->get_element_text($o);

    my $i = $pkg->child_iterator($o);
    while ( my $ce = $i->() ) {
        my $cr = $pkg->element_to_object($ce);
        my $cn = $pkg->get_element_name($ce);
        if ( exists( $r->{$cn} ) ) {
            if ( ref( $r->{$cn} ) =~ /array/i ) {
                push( @{ $r->{$cn} }, $cr );
            }
            else {

                # convert to an array
                my $temp = $r->{$cn};
                $r->{$cn} = [ $temp, $cr ];
            }
        }
        else {
            $r->{$cn} = $cr;
        }
    }
    $r;
}

#-----------------------------------------------------------------------------
#
#       private functions & methods
#
# performs an access to $e according to $path
# (in scalar context)
#
sub _scalar_get {
    my ( $pkg, $e, $path ) = @_;

    my ( $action, $name, $position ) = $pkg->_action($path);

    my $dispatch = {
        '#RETURN' => sub { return $e },
        '#TEXT'   => sub { $pkg->get_element_text($e) },
        '#ATTR'   => sub {
            my $attrs = $pkg->get_element_attrs($e);
            return ( $name eq '*' ) ? $attrs : $attrs->{$name};
        },
        '#CHILD' => sub {
            return _iterator_at( $pkg->child_iterator( $e, $name ), $position );
        },
    };
    my $accessor = $dispatch->{$action};
    croak "Invalid state!" unless UNIVERSAL::isa( $accessor, 'CODE' );
    return $accessor->();
}

#
# checks what kind of action is to perfom for the given access-path element.
#
# result is an array with following elements:
#   action name - what to do
#   name        - element or attribute name
#   position    - element position - when a named child at a specified position is requested
#   context     - does it imply a scalar or iterator context?
#
sub _action {
    my ($pkg,$ctx) = @_;
    if ( !defined $ctx ) {
        return ( '#RETURN', undef, undef, 'SCALAR' );
    }
    elsif ( $ctx eq '#TEXT' ) {
        return ( '#TEXT', undef, undef, 'SCALAR' );
    }
    elsif ( $ctx =~ /^@(.*)$/ ) {
        return ( '#ATTR', $1, undef, 'SCALAR' );
    }
    elsif ( $ctx =~ m|^//(.*)$| ) {
        return ( '#DFS', $1, undef, 'ITERATOR' );
    }
    elsif ( $ctx =~ /^(.*?)\[(\*|\d+)\]$/ ) {    # explicit position or iterator
        my $name     = $1;
        my $position = $2;
        $position = undef if $position eq "*";
        my $context = ( defined $position ) ? 'SCALAR' : 'ITERATOR';
        croak "position must be >= 1" if defined($position) && $position < 1;
        return ( '#CHILD', $name, $position, $context );
    }
    elsif ( $ctx eq '*' ) {                      # all childs
        return ( '#CHILD', undef, undef, 'ITERATOR' );
    }
    else {
        return ( '#CHILD', $ctx, 1, 'SCALAR' );    # first named child
    }
}

#
# iterator-creator for one hierarchy level
# _icreator (path)
#   - iterator for the parent level
#   - path - access path for the child level
#
# returns an iterator
#
sub _icreator {
    my ( $pkg, $path ) = @_;

    my ( $action, $name, $position ) = $pkg->_action($path);

    my $dispatch = {
        '#RETURN' => sub { croak "undefined!" },
        '#TEXT'   =>
          sub { _value_to_iterator( $pkg->get_element_text( $_[0] ) ) },
        '#ATTR' => sub {
            my $attrs = $pkg->get_element_attrs( $_[0] );
            my $v = ( $name eq '*' ) ? $attrs : $attrs->{$name};
            _value_to_iterator($v);
        },
        '#DFS'   => sub { $pkg->dfs_iterator( $_[0], $name ) },
        '#CHILD' => sub {
            my $i = $pkg->child_iterator( $_[0], $name );
            if ( defined $position ) {
                $i = _value_to_iterator( _iterator_at( $i, $position ) );
            }
            return $i;
        },
    };
    my $subiterator_creator = $dispatch->{$action};
    croak "Invalid state!"
      unless UNIVERSAL::isa( $subiterator_creator, 'CODE' );
    return $subiterator_creator;
}

sub _name_filter {
    my ( $pkg, $name ) = @_;
    sub {
        my ($ce) = @_;
        my $ceName = $pkg->get_element_name($ce);
        return $ceName eq $name;
    };
}

sub _make_dfs_search {
    my ( $pkg, $root, $children, $is_interesting ) = @_;
    my @agenda = ($root);

    my $next = sub {
        while (@agenda) {
            my $ce = $agenda[0]->();
            return $ce if $ce;
            shift @agenda;
        }
        return;
    };

    return sub {
        while ( my $ce = $next->() ) {
            unshift @agenda, $children->($ce);
            return $ce if !$is_interesting || $is_interesting->($ce);
        }
        return;
    };
}

# returns an iterator over all child elements
sub _child_iterator {
    my ( $pkg, $e ) = @_;

    carp "Wrong context! Arrayref expected!" unless ref($e) =~ /array/i;

    my $i =
      _array_iterator( $e->[1] )
      ;    # e->[0] is element name, e->[1] is element content
    $i->();    # skip attributes
    my $ce = $i->();

    sub {
        while ( defined($ce) ) {
            if ( $ce eq "0" ) {    # skip textnode
                $i->();
                $ce = $i->();
                next;
            }
            my $ceInhalt = $i->();
            croak "Error in the structure... $ce"
              unless ref($ceInhalt) =~ /array/i;
            my $r = [ $ce, $ceInhalt ];
            $ce = $i->();
            return $r;
        }
        undef;
      }
}

# iterator over all text nodes
sub _text_iterator {
    my ( $pkg, $e ) = @_;

    return sub { undef }
      unless UNIVERSAL::isa( $e, 'ARRAY' );

    # e->[0] is element name, e->[1] is element content
    my $i = _array_iterator( $e->[1] );
    $i->();    # skip attributes
    my $ce = $i->();

    sub {
        while ( defined($ce) ) {
            if ( $ce eq "0" ) {    # textnode
                my $text = $i->();
                $ce = $i->();
                return $text;
            }
            my $ceInhalt = $i->();
            croak "Error in the structure... $ce"
              unless ref($ceInhalt) =~ /array/i;
            my $r = [ $ce, $ceInhalt ];
            $ce = $i->();
            return $r;
        }
        undef;
      }
}

sub _array_iterator {
    my $array = shift;
    my $idx   = -1;

    return sub {
        $idx++;
        return $array->[$idx] if $idx < scalar(@$array);
        $array = undef;
        undef;
      }
}

# returns the n-th element of an iterator
sub _iterator_at {
    my ( $iterator, $position ) = @_;
    while ( my $ce = $iterator->() ) {
        return $ce if --$position == 0;
    }
    return undef;
}

sub _igrep {
    my ( $filter, $iterator ) = @_;
    sub {
        local $_;
        while ( defined( $_ = $iterator->() ) ) {
            return $_ if $filter->($_);
        }
        return;
      }
}

sub _imap {
    my ( $transform, $iterator ) = @_;
    sub {
        local $_ = $iterator->();
        return unless defined $_;
        $transform->($_);
    };
}

#
#   Converts a single value to an iterator which
#   returns that value once
#
sub _value_to_iterator {
    my $v = shift;
    sub {
        my $rv = $v;
        $v = undef;
        return $rv;
      }
}

#
# _flatten (iterator, subiterator_creator)
#
#  returns an iterator over all elements of an
#  sub-iterator, the sub iterator is created using
#  a subiterator_creator for each element of iterator
#
sub _flatten {
    my ( $iterator, $subiterator_creator ) = @_;
    my $np = $iterator->();
    my $si = ( defined $np ) ? $subiterator_creator->($np) : undef;

    sub {
        while ( defined $si ) {
            my $next = $si->();
            return $next if $next;
            $np = $iterator->();
            return unless $np;
            $si = $subiterator_creator->($np);
        }
        undef;
    };
}

1;

__END__

=head1 NAME

XML::Traverse::ParseTree - iterators and getters for xml-access

=head1 SYNOPSIS

    my $xml = XML::Parser->new(Style => "Tree")->parse($xmlcont);
    my $h   = XML::Traverse::ParseTree->new();

    my $a1  = $h->get($xml,'document','section','entries');
    my $i   = $h->child_iterator($a1);
    while (my $e = $i->()) {
        ...
        $attr = $h->get($e,'another-child-element','@attribute-name');
        $text = $h->get($e,'#TEXT');
    }
    ...
    my $filter = sub { ... }
    my $i   = $h->child_iterator($xml,$filter);
    while (my $e = $i->()) {
        ...
    }
    ...
    my $i = $h->get($xml,'section[*]','sections[*]','#TEXT');
    my $i = $h->get($xml,'//sections');
    my $i = $h->get($xml,'section[2],'sections[3]','*');

=head1 DESCRIPTION

XML::Traverse::ParseTree supplies iterators and getters for accessing
the contents of a xml content. The xml content must be already parsed
using XML::Parser (tree-style)

=cut

=head1 METHODS

=over

=item new()

Creates an instance of XML::Traverse::ParseTree. Currently, this instance does not have
an intrinsic state. Although it could be used in a static way, this is not recommended.
(Possible extention: support for different character encodings)

=item get_element_name($current)

Returns the element name of the  current element.

=item get_element_attrs($current)

Return all attributes of the current element.

=item get_element_text($current)

Returns the text of the current element.

=item get($parse_tree,access_path [,access_path ...])

General purpose access method. Depending on the access path elements, it returns
an iterator ("iterator-context") or an scalar value.
Returned value may be an element (position in the parse tree), an attribute value,
all attributes of an element or the contents of text node.


Access path may consist of one or more entries. Each entry specifies a hierarchy level.
The last one specifies if a attribute
value is requested (prefix @) or the text (special value of #TEXT) or an element (position
in the parse tree). Examples:

    $h->get($current,'@id') - returns the value of the attribute "id" of the current element
    $h->get($current,'a-child') - returns the first child element named "a-child"
    $h->get($current,'#TEXT') - returns the text node of the current element
    $h->get($current,'section[2]') - returns the second section child element
    $h->get($current,'section[*]') - returns an iterator over all child elements named section
    $h->get($current,'//section')  - returns an iterator over all child elements named section on all hierarchy levels AT and BELOW $current


More than one entry in the access path means more hierarchy levels, e.g.:

    $h->get($current,'document','sections','section','@id')

Returns the value of the attribute "id" of the element "section" which is a child
element of an element "sections", which in turn is a child element of an element
named "document", the "document" element is a child of the current element.
(xpath-style: document/sections/section/@id)

    $h->get($current,'document','#TEXT')

Returns the text of the element document (and all of its children), 
which is a child element of current.

    <current><document>abc<sub>child</sub>def</document></current>

Then only "abcchilddef" will be returned.


More (advanced) examples:

    $h->get($current,'sub1[*]','sub2[*]')

Returns an iterator over all sub2 elements which are child elements of all sub1 
elements, which in turn are child elements of $current.

    $h->get($current,'sub1[*]','sub2[2]')

Returns an iterator over sub2 Elements. Only those sub2 elements will be returned
which are on second position relative to their respective parents.
Example:

    <xml>
        <sub1>
            <sub2 id="1"/>
            <sub2 id="2"/>
            <sub2 id="3"/>
        </sub1>
        <sub1>
            <sub2 id="4"/>
            <sub2 id="5"/>
        </sub1>
        <sub1>
            <sub2 id="6"/>
        </sub1>
    </xml>

With the above mentioned get:

    $h->get($current,'sub1[*]','sub2[2]')

an iterator is returned, it delivers elements with the following ids: 2 and 5.

    $h->get($current,'sub1[*]','#TEXT')

returns an iterator which delivers text content of all sub1 elements.
B<Caution:> Does a sub1 element has no text at all, undef is returned. This
 undef cannot be distinguished from undef used to terminate the iteration.

    $h->get($current,'@*')

returns a hashref containing all attributes of the current element (no iterator!)

    $h->get($current,'sub1[3]','//sub2')

returns an iterator over all sub2 elements on all hierarchy levels below the third
sub1 element.

=item child_iterator($current,[$name|$coderef])

returns an iterator over child elements (one hierarchy level below $current).
When neither $name or $coderef is given, all child elements will be iterated.

If a name (scalar) is given, only child elements with that name will be
iterated.

If a codereff is given, only those child elements will be iterated, for which 
the given function evaluates to true. The respective element is passed as
parameter. Example:

    my $filter = sub {
        $pkg->get($_[0],'@class') eq "heading" ||
        defined $pkg->get($_[0],'@style')
    };
    $i = $pkg->child_iterator($current,$filter);

=item dfs_iterator($current,[$name|$filter])

returns an iterator over the current element and child elements 
on all hierarchy levels. The order is depth-first (exactly:
current, then childs).
Regarding the meaning of $name and $filter see child_iterator above.

=item element_to_object($current)

Creates a hashref with the contens of the current element
(experimental)

=item getter(access_path [,access_path ...])

Returns a curried version of get(), this is usefull in cases where the same
access path is used in different places. Example:

    *get_id = $pkg->getter('@id');

    $i = $pkg->child_iterator($xml);
    while(my $e = $i->()) {
        if (get_id($e) eq '45')) {
            ...
        }
    ...

=back

=head1 BUGS

None known.

=head1 SEE ALSO

  Concerning the concepts of iterators using closures/anonymous subs: 
  L<http://hop.perl.plover.com/>

=head1 AUTHOR

  Martin Busik <martin.busik@busik.de>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2006 by Martin Busik.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

