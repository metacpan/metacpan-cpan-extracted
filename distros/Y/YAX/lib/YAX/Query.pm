package YAX::Query;

use strict;

use YAX::Constants qw/:all/;

our $rx_iden = "[a-zA-Z0-9-\\:_]+|\\*";
our $rx_item = "\\[(?:(?:-?\\d+)|(?:\\d+\\s*\\.\\.\\s*-?\\d+))\\]";
our $rx_func = "\\b(?:parent|document|id)\\b\\(\\)";
our $rx_type = "#(?:text|processing-instruction|comment|cdata|node)";
our $rx_filt = "\\(.+?\\)(?:$rx_item)?(?=(?:\\.|\$))";
our $rx_attr = "@(?:$rx_iden)(?:$rx_item)?";
our $rx_elmt = "(?:$rx_iden)(?:$rx_item)?";
our $rx_term = "(?:$rx_type)(?:$rx_item)?|(?:$rx_func)(?:$rx_item)?";
our $rx_frag = "(?:$rx_attr)|(?:$rx_term)|(?:$rx_elmt)|(?:$rx_filt)";
our $rx_chld = "\\.(?:$rx_frag)";
our $rx_desc = "\\.\\.(?:$rx_frag)";
our $rx_expr = "$rx_desc|$rx_chld";

our $RX_TEST = "^(?:$rx_expr)+\$";
our $RX_EXEC = $rx_expr;
our $RX_ITEM = '\[(-?\d+)\]$';
our $RX_SLCE = '\[(-?\d+)\s*\.\.\s*(-?\d+)\]$';

our %CACHE;

sub new {
    my ( $class, $node ) = @_;
    my $self = bless [ $node ], $class;
    $self;
}

sub tokenize {
    my ( $self, $expr ) = @_;
    $expr =~ /$RX_EXEC/g;
}

sub compile {
    my ( $self, $expr ) = @_;
    $expr = ".$expr" unless substr( $expr, 0, 1 ) eq '.';
    die "failed to parse `$expr'" unless $expr =~ /$RX_TEST/g;

    return @{ $CACHE{ $expr } } if exists $CACHE{ $expr };

    my @exec;
    my @tokens = $self->tokenize( $expr );

    my ( $index, $start, $end, $seen_flat );
    foreach my $token ( @tokens ) {
        $token = substr( $token, 1 );

        undef( $index );
        undef( $start );
        undef( $end   );

        if ( $token =~ /$RX_ITEM/ ) {
            $token =~ s/$RX_ITEM//;
            $index = $1;
        } elsif ( $token =~ /$RX_SLCE/ ) {
            $token =~ s/$RX_SLCE//;
            $start = $1;
            $end   = $2;
        }

        if ( substr( $token, 0, 1 ) eq '.' ) {
            $seen_flat && die "cannot select `$token' following `$seen_flat'";
            push @exec, [ 'descendants', substr( $token, 1 ) ];
        }
        elsif ( $token eq '#node' ) {
            $seen_flat && die "cannot select `$token' following `$seen_flat'";
            push @exec, [ 'children' ];
        }
        elsif ( $token eq '*' ) {
            $seen_flat && die "cannot select `$token' following `$seen_flat'";
            push @exec, [ 'children', ELEMENT_NODE ];
        }
        elsif ( $token eq '#text' ) {
            $seen_flat && die "cannot select `$token' following `$seen_flat'";
            push @exec, [ 'children', TEXT_NODE ];
            $seen_flat = $token;
        }
        elsif ( $token eq '#cdata' ) {
            $seen_flat = $token;
            push @exec, [ 'children', CDATA_SECTION_NODE ];
        }
        elsif ( $token eq '#processing-instruction' ) {
            $seen_flat && die "cannot select `$token' following `$seen_flat'";
            push @exec, [ 'children', PROCESSING_INSTRUCTION_NODE ];
        }
        elsif ( $token eq '#comment' ) {
            $seen_flat && die "cannot select `$token' following `$seen_flat'";
            push @exec, [ 'children', COMMENT_NODE ];
        }
        elsif ( $token eq '@*' ) {
            $seen_flat && die "cannot select `$token' following `$seen_flat'";
            push @exec, [ 'attributes' ];
            $seen_flat = $token;
        }
        elsif ( substr( $token, 0, 1 ) eq '@' ) {
            $seen_flat && die "cannot select `$token' following `$seen_flat'";
            push @exec, [ 'attribute', substr( $token, 1 ) ];
            $seen_flat = $token;
        }
        elsif ( substr( $token, 0, 1 ) eq '(' ) {
            push @exec, [ 'filter', substr( $token, 1, -1 ) ];
        }
        elsif ( $token eq 'parent()' ) {
            $seen_flat && die "cannot select `$token' following `$seen_flat'";
            push @exec, [ 'parent' ];
        }
        else {
            $seen_flat && die "cannot select `$token' following `$seen_flat'";
            push @exec, [ 'child', $token ]
        }

        if ( defined $index ) {
            push @exec, [ 'item', 0+$index ];
        }
        elsif ( defined $start and defined $end ) {
            push @exec, [ 'slice', 0+$start, 0+$end ];
        }
    }

    $CACHE{ $expr } = [ @exec ];
    return @exec;
}

sub select {
    my ( $self, $expr ) = @_;
    my @exec = $self->compile( $expr );
    my ( $meth, @list );
    foreach my $exec ( @exec ) {
        $meth = shift @$exec;
        if ( $meth eq 'item' ) {
            @$self = ( $self->[ $exec->[0] ] );
        }
        elsif ( $meth eq 'slice' ) {
            @$self = @$self[ $exec->[0] .. $exec->[1] ];
        }
        elsif ( $meth eq 'filter' ) {
            $self->filter( $exec->[0] );
        }
        else {
            @list = @$self;
            @$self = ( );
            foreach my $node ( @list ) {
                $self->$meth( $node, @$exec );
            }
        }
    }
    $self;
}

sub parent {
    my ( $self, $node ) = @_;
    push @$self, $node->parent; 
    $self;
}

sub children {
    my ( $self, $node, $type ) = @_;
    if ( UNIVERSAL::can( $node, 'children' ) ) {
        foreach my $child ( @{ $node->children } ) {
            next if defined $type and ( $child->type != $type );
            push @$self, $child;
        }
    }
    $self;
}

sub child {
    my ( $self, $node, $name ) = @_;
    if ( UNIVERSAL::can( $node, 'children' ) ) {
        foreach my $child ( @{ $node->children } ) {
            next unless $child->name eq $name;
            push @$self, $child;
        }
    }
    $self;
}

sub attributes {
    my ( $self, $node ) = @_;
    push @$self, $node->attributes;
    $self;
}

sub attribute {
    my ( $self, $node, $name ) = @_;
    push @$self, $node->attributes->{ $name };
    $self;
}

sub descendants {
    my ( $self, $node, $name ) = @_;
    $name = '*' unless $name;
    if ( UNIVERSAL::can( $node, 'children' ) ) {
        my @stack;
        my $count = 0;
        foreach my $child ( reverse @{ $node->children } ) {
            $stack[ $count++ ] = $child;
        }
        while ( --$count >= 0 ) {
            my $n = $stack[ $count ];
            if ( $name eq '*' and $n->type == ELEMENT_NODE ) {
                push @$self, $n;
            }
            elsif ( $name eq '#processing-instruction' and
                ( $n->type == PROCESSING_INSTRUCTION_NODE ) ) {
                push @$self, $n;
            }
            elsif ( $n->name eq $name ) {
                push @$self, $n;
            }
            if ( UNIVERSAL::can( $n, 'children' ) ) {
                foreach my $child ( reverse @{ $n->children } ) {
                    $stack[ $count++ ] = $child;
                }
            }
        }
        undef( @stack );
    }
    $self;
}

sub filter {
    my ( $self, $test ) = @_;
    unless ( ref $test eq 'CODE' ) {
        my $orig = $test;
        $test =~ s/@([a-zA-Z\-:._]+)\b/\$_->{$1}/g;
        $orig = $test;
        $test = mk_code( $test );
        die "$@ while compiling filter: `$orig'" if $@;
    }
    @$self = grep { &$test } @$self;
    $self;
}

sub mk_code { eval 'sub { '.$_[-1].' }' }

1;
__END__

=head1 NAME

YAX::Query - Query the YAX DOM

=head1 SYNOPSIS

 use YAX::Query;

 $q = YAX::Query->new( $node );
 $q->select( $expr );

 # method interface
 $q->parent();
 $q->descendants();
 $q->children( $type );
 $q->child( $tag_name );
 $q->attributes;
 $q->attribute( $name );
 $q->filter( \&code );

=head1 DESCRIPTION

This module implements a tool for querying a YAX DOM tree. It supports
an expression parser for simple querying of the DOM using an E4X-ish
syntax, as well as a method interface.

It is useful to note that a YAX::Query object is a blessed array reference
and that the resulting nodes matching the query are stored in this array
reference. Therefore all query methods return the query object itself,
and to access the results you simply inspect this object. For example,
the following searches for all text nodes which are children of `em'
elements, which in turn are children of all `div' descendants:

 my $q = YAX::Query->new( $node );
 $q->select(q{..div.em.#text});
 
 for my $found ( @$q ) {
     # $found is a YAX::Text node
 }

The select method returns the query object itself, so the following,
which selects all `li' descendants which have an `foo' attribute equal
to "bar", also works:

 for my $item ( @{ $q->select(q{..li.(@foo eq "bar")}) } ) {
     ...
 }

=head1 QUERY EXPRESSIONS

A query expression is constructed of a sequence of tokens separated by
a literal `.' (dot). Each successive token represents an operation on
the resulting set of the application of the previous token's operation.

In the initial state, the set of nodes contains only the context node
passed to the constructor: C<YAX::Query->new( $node )>.

Filters are enclosed in `(' and `)', and generally contain Perl
expressions with the exception that tokens of the form /\@(\w+)/ are
replaced with $_->{$1} where `$_' is the current node in the loop which
is applying the filter.

The following is a list of valid tokens:

=over 4

=item '..'

descendants of

=item '.*'

all element children of

=item '.I<element_name>'

all elements named C<element_name>

=item '.@*

all attributes of

NOTE: This adds the B<hash reference> of the element itself, and B<not>
a list of attribute values. Moreover, adding a node selector after this
in sequence is meaningless since attributes cannot have children. An
exception will be raised if this occurs.

=item '.@I<attribute_name>'

all attributes named C<attribute_name>

NOTE: This adds a list of attribute values to the set. As above, node
selectors following this are meaningless, and will raise and exception.

=item '.parent()'

parent nodes of the set

=item '.#text'

all text children

=item '.#processing-instruction'

all processing instruction children

=item '.#cdata'

all CDATA children

=item '.#node'

all child nodes of

=item '.#comment'

all comment children of

=item '.( $expr )'

Apply the filter C<$expr> by turning it into a Perl code reference.
Expressions are Perl with the exception that tokens of the form /\@(\w+)/
are replaced with $_->{$1} where `$_' is the current node in the loop
which is applying the filter.

=item '[I<n>]'

the n-th element of the set

=back

=head1 METHODS

=over 4

=item new( $node )

Constructor.

=item select( $expr )

Evaluates C<$expr> and returns the query object itself. The results are
simply the elements in the query object which is a blessed array reference.
This allows for chaining and piecemeal querying. The follow shows some
different ways of achieving the same thing:

 my $q = YAX::Query->new( $node );
  
 $q->select('..div.*');         # get all children of all `div' descendants
 $q->filter( \&filter );        # filter the set obtained on the live above
 
 $q->select('..div.*')->filter( \&filter ); # same as the two lines above
 
 # or the equivalent
 @ids = grep { filter( $_ ) } @{ $q->select('..div.*') };

=item parent()

See `.parent()' above

=item children( $type )

Selects child nodes of type $type (see L<YAX::Constants> for valid types).
The `#text', `#cdata', `#processing-instruction' and `#comment' selectors
are implemented with C<children(...)>.

=item child( $name )

Selects elements named $name.

=item attribute( $name )

Selects attribute values named $name.

=item attributes()

Selects the attributes hash for each element in the set.

=item descendants()

Selects descendants for each element in the set.

=item filter(\&code)

Applies the passed code reference to each element in the set, adding
the element to the resulting set iff the code reference returns a
true value.

=back

=head1 BUGS AND LIMITATIONS

Syntax errors in the expressions are currently not handled very well. If
the expression doesn't parse, an exception is raised, but because of the
simplicity of the lexer, the information required to inform the user of
exactly what went wrong is unavailable.

Changing this requires a more complex parser which will significantly
impact performance, and so I'm reluctant to implement this since query
expressions tend to be short enough for debugging by inspection.

Result sets from a query are not "live". That is, if a node is removed
from or added to the DOM tree after the query is performed, these changes
will not be reflected in the query result set.

=head1 SEE ALSO

t/03-query.t in the test suite for an extensive list of examples

=head1 AUTHOR

 Richard Hundt

=head1 LICENSE

This program is free software and may be used and distributed under the
same terms as Perl itself.
