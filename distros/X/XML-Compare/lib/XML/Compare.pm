## ----------------------------------------------------------------------------
# Copyright (C) 2009 NZ Registry Services
## ----------------------------------------------------------------------------
package XML::Compare;
$XML::Compare::VERSION = '0.05';
use 5.006;
use Moo 2;
use MooX::Types::MooseLike::Base qw(Bool Str ArrayRef HashRef Undef);

use XML::LibXML 1.58;

our $VERBOSE = $ENV{XML_COMPARE_VERBOSE} || 0;

my $PARSER = XML::LibXML->new();

my $has = {
    localname => {
        # not Comment, CDATASection
        'XML::LibXML::Attr' => 1,
        'XML::LibXML::Element' => 1,
    },
    namespaceURI => {
        # not Comment, Text, CDATASection
        'XML::LibXML::Attr' => 1,
        'XML::LibXML::Element' => 1,
    },
    attributes => {
        # not Attr, Comment, CDATASection
        'XML::LibXML::Element' => 1,
    },
    value => {
        # not Element, Comment, CDATASection
        'XML::LibXML::Attr' => 1,
        'XML::LibXML::Comment' => 1,
    },
    data => {
        # not Element, Attr
        'XML::LibXML::CDATASection' => 1,
        'XML::LibXML::Comment' => 1,
        'XML::LibXML::Text' => 1,
    },
};

has 'namespace_strict' =>
    is => "rw",
    isa => Bool,
    default => 0,
    ;

has 'error' =>
    is => "rw",
    isa => Str,
    clearer => "_clear_error",
    ;

sub _self {
    my $args = shift;
    if ( @$args == 3 ) {
	shift @$args;
    }
    else {
	__PACKAGE__->new();
    }
}

# acts almost like an assertion (either returns true or throws an exception)
sub same {
    my $self = _self(\@_);
    my ($xml1, $xml2) = @_;
    # either throws an exception, or returns true
    return $self->_compare($xml1, $xml2);;
}

sub is_same {
    my $self = _self(\@_);
    my ($xml1, $xml2) = @_;
    # catch the exception and return true or false
    $self->_clear_error;
    eval { $self->same($xml1, $xml2); };
    if ( $@ ) {
	$self->error($@);
        return 0;
    }
    return 1;
}

sub is_different {
    my $self = _self(\@_);
    my ($xml1, $xml2) = @_;
    return !$self->is_same($xml1, $xml2);
}

# private functions
sub _xpath {
    my $l = shift;
    return "/".join("/",@$l);
}

sub _die {
    my ($l, $fmt, @args) = @_;
    my $msg;
    if ( @args ) {
	    $msg = sprintf $fmt, @args;
    }
    else {
	    $msg = $fmt;
    }
    die("[at "._xpath($l)."]: ".$msg);
}

sub _compare {
    my $self = shift;
    my ($xml1, $xml2) = (@_);
    if ( $VERBOSE ) {
        print '-' x 79, "\n";
        print $xml1 . ($xml1 =~ /\n\Z/ ? "" : "\n");
        print '-' x 79, "\n";
        print $xml2 . ($xml2 =~ /\n\Z/ ? "" : "\n");
        print '-' x 79, "\n";
    }

    my $parser = XML::LibXML->new();
    my $doc1 = $parser->parse_string( $xml1 );
    my $doc2 = $parser->parse_string( $xml2 );
    return $self->_are_docs_same($doc1, $doc2);
}

sub _are_docs_same {
    my $self = shift;
    my ($doc1, $doc2) = @_;
    my $ignore = $self->ignore;
    if ( $ignore and @$ignore ) {
	my $in = {};
	for my $doc ( map { $_->documentElement } $doc1, $doc2 ) {
	    my $xpc;
	    if ( my $ix = $self->ignore_xmlns ) {
		$xpc = XML::LibXML::XPathContext->new($doc);
		$xpc->registerNs($_ => $ix->{$_})
		    for keys %$ix;
	    }
	    else {
		$xpc = $doc;
	    }
	    for my $ignore_xpath ( @$ignore ) {
		$in->{$_->nodePath}=undef
		    for $xpc->findnodes( $ignore_xpath );
	    }
	}
	$self->_ignore_nodes($in);
    }
    else {
	$self->_ignore_nothing;
    }
    return $self->_are_nodes_same(
	[ $doc1->documentElement->nodeName ],
	$doc1->documentElement,
	$doc2->documentElement,
	);
}

has 'ignore' =>
    is => "rw",
    isa => ArrayRef[Str],
    ;

has 'ignore_xmlns' =>
    is => "rw",
    isa => HashRef[Str],
    ;

has '_ignore_nodes' =>
    is => "rw",
    isa => HashRef[Undef],
    clearer => "_ignore_nothing",
    ;

sub _are_nodes_same {
    my $self = shift;
    my ($l, $node1, $node2) = @_;
    _msg($l, "\\ got (" . ref($node1) . ", " . ref($node2) . ")");

    # firstly, check that the node types are the same
    my $nt1 = $node1->nodeType();
    my $nt2 = $node2->nodeType();
    if ( $nt1 eq $nt2 ) {
        _same($l, "nodeType=$nt1");
    }
    else {
        _outit($l, 'node types are different', $nt1, $nt2);
        _die $l, 'node types are different (%s, %s)', $nt1, $nt2;
    }

    # if these nodes are Text, compare the contents
    if ( $has->{data}{ref $node1} ) {
        my $data1 = $node1->data();
        my $data2 = $node2->data();
        # _msg($l, ": data ($data1, $data2)");
        if ( $data1 eq $data2 ) {
            _same($l, "data");
        }
        else {
            _outit($l, 'data differs', $data1, $data2);
            _die $l, 'data differs: (%s, %s)', $data1, $data2;
        }
    }

    # if these nodes are Attr, compare the contents
    if ( $has->{value}{ref $node1} ) {
        my $val1 = $node1->getValue();
        my $val2 = $node2->getValue();
        # _msg($l, ": val ($val1, $val2)");
        if ( $val1 eq $val2 ) {
            _same($l, "value");
        }
        else {
            _outit($l, 'attr node values differs', $val1, $val2);
            _die $l, "attr node values differs (%s, %s)", $val1, $val2
        }
    }

    # check that the nodes are the same name (localname())
    if ( $has->{localname}{ref $node1} ) {
        my $ln1 = $node1->localname();
        my $ln2 = $node2->localname();
        if ( $ln1 eq $ln2 ) {
            _same($l, 'localname');
        }
        else {
            _outit($l, 'node names are different', $ln1, $ln2);
            _die $l, 'node names are different: ', $ln1, $ln2;
        }
    }

    # check that the nodes are the same namespace
    if ( $has->{namespaceURI}{ref $node1} ) {
        my $ns1 = $node1->namespaceURI();
        my $ns2 = $node2->namespaceURI();
        # _msg($l, ": namespaceURI ($ns1, $ns2)");
        if ( defined $ns1 and defined $ns2 ) {
            if ( $ns1 eq $ns2 ) {
                _same($l, 'namespaceURI');
            }
            else {
                _outit($l, 'namespaceURIs are different', $node1->namespaceURI(), $node2->namespaceURI());
                _die $l, 'namespaceURIs are different: (%s, %s)', $ns1, $ns2;
            }
        }
        elsif ( (!defined $ns1) and (!defined $ns2) ) {
            _same($l, 'namespaceURI (not defined for either node)');
        }
        else {
	    if ( $self->namespace_strict or defined $ns1 ) {
		_outit($l, 'namespaceURIs are defined/not defined', $ns1, $ns2);
		_die $l, 'namespaceURIs are defined/not defined: (%s, %s)', ($ns1 || '[undef]'), ($ns2 || '[undef]');
	    }
        }
    }

    # check the attribute list is the same length
    if ( $has->{attributes}{ref $node1} ) {

	my $in = $self->_ignore_nodes;
        # get just the Attrs and sort them by namespaceURI:localname
        my @attr1 = sort { _fullname($a) cmp _fullname($b) }
	    grep { (!$in) or (!exists $in->{$_->nodePath}) }
		grep { defined and $_->isa('XML::LibXML::Attr') }
		    $node1->attributes();

        my @attr2 = sort { _fullname($a) cmp _fullname($b) }
	    grep { (!$in) or (!exists $in->{$_->nodePath}) }
		grep { defined and $_->isa('XML::LibXML::Attr') }
		    $node2->attributes();

        if ( scalar @attr1 == scalar @attr2 ) {
            _same($l, 'attribute length (' . (scalar @attr1) . ')');
        }
        else {
            _die $l, 'attribute list lengths differ: (%d, %d)', scalar @attr1, scalar @attr2;
        }

        # for each attribute, check they are all the same
        my $total_attrs = scalar @attr1;
        for (my $i = 0; $i < scalar @attr1; $i++ ) {
            # recurse down (either an exception will be thrown, or all are correct
            $self->_are_nodes_same( [@$l,'@'.$attr1[$i]->name], $attr1[$i], $attr2[$i] );
        }
    }

    my $in = $self->_ignore_nodes;

    # don't need to compare or care about Comments
    my @nodes1 = grep { (!$in) or (!exists $in->{$_->nodePath}) }
	grep { (not $_->isa('XML::LibXML::Comment')) and
		   not ( $_->isa("XML::LibXML::Text") && ($_->data =~ /\A\s*\Z/) )
	       }
	    $node1->childNodes();

    my @nodes2 = grep { (!$in) or (!exists $in->{$_->nodePath}) }
	grep { (not $_->isa('XML::LibXML::Comment')) and
		   not ( $_->isa("XML::LibXML::Text") && ($_->data =~ /\A\s*\Z/) )
	       } $node2->childNodes();

    # firstly, convert all CData nodes to Text Nodes
    @nodes1 = _convert_cdata_to_text( @nodes1 );
    @nodes2 = _convert_cdata_to_text( @nodes2 );

    # append all the consecutive Text nodes
    @nodes1 = _squash_text_nodes( @nodes1 );
    @nodes2 = _squash_text_nodes( @nodes2 );

    # check that the nodes contain the same number of children
    if ( @nodes1 != @nodes2 ) {
        _die $l, 'different number of child nodes: (%d, %d)', scalar @nodes1, scalar @nodes2;
    }

    # foreach of it's children, compare them
    my $total_nodes = scalar @nodes1;
    for (my $i = 0; $i < $total_nodes; $i++ ) {
        # recurse down (either an exception will be thrown, or all are correct
	my $nn = $nodes1[$i]->nodeName;
	if ( grep { $_->nodeName eq $nn }
		 @nodes1[0..$i-1, $i+1..$#nodes1] ) {
	    $nn .= "[position()=".($i+1)."]";
	}
	$nn =~ s{#text}{text()};
        $self->_are_nodes_same( [@$l,$nn], $nodes1[$i], $nodes2[$i] );
    }

    _msg($l, '/');
    return 1;
}

# takes an array of nodes and converts all the CDATASection nodes into Text nodes
sub _convert_cdata_to_text {
    my @nodes = @_;
    my @new;
    foreach my $n ( @nodes ) {
	if ( ref $n eq 'XML::LibXML::CDATASection' ) {
	    $n = XML::LibXML::Text->new( $n->data() );
	}
	push @new, $n;
    }
    return @new;
}

# takes an array of nodes and concatenates all the Text nodes together
sub _squash_text_nodes {
    my @nodes = @_;
    my @new;
    my $last_type = '';
    foreach my $n ( @nodes ) {
	if ( $last_type eq 'XML::LibXML::Text' and ref $n eq 'XML::LibXML::Text' ) {
	    $n = XML::LibXML::Text->new( $new[-1]->data() . $n->data() );
	    $new[-1] = $n;
	}
	else {
	    push @new, $n;
	}
	$last_type = ref $n;
    }
    return @new;
}

sub _fullname {
    my ($node) = @_;
    my $name = '';
    $name .= $node->namespaceURI() . ':' if $node->namespaceURI();
    $name .= $node->localname();
    # print "name=$name\n";
    return $name;
}

sub _same {
    my ($l, $msg) = @_;
    return unless $VERBOSE;
    print '' . ('  ' x (@$l+1)) . "= $msg\n";
}

sub _msg {
    my ($l, $msg) = @_;
    return unless $VERBOSE;
    print ' ' . ('  ' x (@$l)) ._xpath($l). " $msg\n";
}

sub _outit {
    my ($l, $msg, $v1, $v2) = @_;
    return unless $VERBOSE;
    print '' . ('  ' x @$l) . "! " ._xpath($l)." $msg:\n";
    print '' . ('  ' x @$l) . '. ' . ($v1 || '[undef]') . "\n";
    print '' . ('  ' x @$l) . '. ' . ($v2 || '[undef]') . "\n";
}

1;
__END__

=head1 NAME

XML::Compare - Test if two XML documents semantically the same

=head1 SYNOPSIS

    use XML::Compare tests => 2;

    my $xml1 = '<foo xmlns="urn:message"><bar baz="buzz">text</bar></foo>';
    my $xml2 = '<f:foo xmlns:f="urn:message"><f:bar baz="buzz">text</f:bar></f:foo>';

    my $same = eval { XML::Compare::same($xml1, $xml2); };
    if ( $same ) {
        print "same\n";
    }
    else {
        print "different: $@\n";
    }

    # OO interface, if you want to customise operation
    my $xml_compare = XML::Compare->new( namespace_strict => 1 );
    if ($xml_compare->is_same($xml1, $xml2)) {
         # same!
    }
    else {
        print "different: " . $xml_compare->error . "\n";
    }

=head1 DESCRIPTION

This module allows you to test if two XML documents are semantically the
same. This also holds true if different prefixes are being used for the xmlns,
or if there is a default xmlns in place.

This modules ignores XML Comments.

=head1 SUBROUTINES

=over 4

=item same($xml1, $xml2)

Returns true if the two xml strings are semantically the same.

If they are not the same, it throws an exception with a description in $@ as to
why they aren't.

=item is_same($xml1, $xml2)

Returns true if the two xml strings are semantically the same.

Returns false otherwise. No diagnostic information is available.

=item is_different($xml1, $xml2)

Returns true if the two xml strings are semantically different. No diagnostic
information is available.

Returns false otherwise.

=back

=head1 PROPERTIES

=over

=item namespace_strict

(Bool) If this property is set, then all the namespaces of both
documents must match exactly.  The default, unset, raises an error
only if the first document, C<$xml1>, has a namespace defined and this
is different from C<$xml2>'s (or C<$xml2> has no namespace).

=item error

After the 'is_same' method is used, this will contain either the error
string from the last comparison error, or C<undef>.

=item ignore

An array ref of XPath expressions to 'strip' from the documents before
comparing.  This is implemented by evaluating each XPath expression at
the beginning, then removing those nodes from any lists later found.

=item ignore_xmlns

A hashref of prefix => XMLNS, if you used namespaces on any of the
'ignore' XPath entries.

=back

=head1 EXPORTS

Nothing.

=head1 SEE ALSO

L<XML::LibXML>

=head1 REPOSITORY

L<https://github.com/neilb/XML-Compare>

=head1 AUTHOR

Andrew Chilton, E<lt>andychilton@gmail.comE<gt>,
E<lt>andy@catalyst dot net dot nz<gt>

http://www.chilts.org/blog/

=head1 COPYRIGHT & LICENSE

This software development is sponsored and directed by New Zealand Registry
Services, http://www.nzrs.net.nz/

The work is being carried out by Catalyst IT, http://www.catalyst.net.nz/

Copyright (c) 2009, NZ Registry Services.  All Rights Reserved.  This software
may be used under the terms of the Artistic License 2.0.  Note that this
license is compatible with both the GNU GPL and Artistic licenses.  A copy of
this license is supplied with the distribution in the file COPYING.txt.

=cut

# Local Variables:
# mode:cperl
# indent-tabs-mode: f
# tab-width: 8
# cperl-continued-statement-offset: 4
# cperl-brace-offset: 0
# cperl-close-paren-offset: 0
# cperl-continued-brace-offset: 0
# cperl-continued-statement-offset: 4
# cperl-extra-newline-before-brace: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# cperl-indent-wrt-brace: nil
# cperl-label-offset: -4
# cperl-merge-trailing-else: t
# End:
# vim: filetype=perl:noexpandtab:ts=3:sw=3
