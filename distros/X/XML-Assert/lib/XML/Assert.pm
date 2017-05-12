## ----------------------------------------------------------------------------
# Copyright (C) 2010 NZ Registry Services
## ----------------------------------------------------------------------------
package XML::Assert;

use XML::LibXML;
use Any::Moose;

our $VERSION = '0.03';
our $VERBOSE = $ENV{XML_ASSERT_VERBOSE} || 0;

my $PARSER = XML::LibXML->new();

has 'error' =>
    is => "rw",
    isa => "Str",
    clearer => "_clear_error",
    ;

sub _self {
    my $args = shift;
    if ( ref $args->[0] eq __PACKAGE__ ) {
        return shift @$args;
    }
    elsif ( $args->[0] eq __PACKAGE__ ) {
        return do { shift @$args }->new();
    }
    return __PACKAGE__->new();
}

# a hashref of all the namespaces being used (or asked for in the XPath)
has 'xmlns' =>
    is => "rw",
    isa => "HashRef[Str]",
    ;

has 'error' =>
    is => "rw",
    isa => "Str",
    clearer => "_clear_error",
    ;

sub register_ns {
    my ($self, $doc) = @_;

    if ( my $xmlns = $self->xmlns ) {
        my $xpc = XML::LibXML::XPathContext->new($doc);
		$xpc->registerNs($_ => $xmlns->{$_})
		    for keys %$xmlns;
        # do the test against the XPath Context rather than the Document
        $doc = $xpc;
    }
    return $doc;
}

# assert_xpath_count
sub assert_xpath_count {
    my $self = _self(\@_);
    my ($doc, $xpath, $count) = @_;

    $doc = $self->register_ns($doc);

    my ($nodes) = $doc->find($xpath);
    print 'assert_xpath_count: Found ' . (scalar @$nodes) . "\n" if $VERBOSE;
    unless ( @$nodes == $count ) {
        die "XPath '$xpath' has " . (scalar @$nodes) . " " . $self->_plural(scalar @$nodes, 'node') . ", not $count as expected";
    }

    return 1;
}

sub is_xpath_count {
    my $self = _self(\@_);
    my ($doc, $xpath, $count) = @_;

    $self->_clear_error();
    eval { $self->assert_xpath_count($doc, $xpath, $count) };
    if ( $@ ) {
        $self->error($@);
        return;
    }
    return 1;
}

# assert_xpath_value_match
sub assert_xpath_value_match {
    my $self = _self(\@_);
    my ($doc, $xpath, $match) = @_;

    $doc = $self->register_ns($doc);

    # firstly, check that the node actually exists
    my ($nodes) = $doc->find($xpath);
    print 'assert_xpath_value_match: Found ' . (scalar @$nodes) . "\n" if $VERBOSE;
    unless ( @$nodes == 1 ) {
        die "XPath '$xpath' matched " . (scalar @$nodes) . " nodes when we expected to match one";
    }

    # check the value is what we expect
    my $node = $nodes->[0];
    print "assert_xpath_value_match: This node's value : " . $node->string_value() . "\n" if $VERBOSE;
    unless ( $node->string_value() ~~ $match ) {
        die "XPath '$xpath' doesn't match '$match' as expected, instead it is '" . $node->string_value() . "'";
    }

    return 1;
}

sub does_xpath_value_match {
    my $self = _self(\@_);
    my ($doc, $xpath, $match) = @_;

    $self->_clear_error();
    eval { $self->assert_xpath_value_match($doc, $xpath, $match) };
    if ( $@ ) {
        $self->error($@);
        return;
    }
    return 1;
}

# assert_xpath_values_match
sub assert_xpath_values_match {
    my $self = _self(\@_);
    my ($doc, $xpath, $match) = @_;

    $doc = $self->register_ns($doc);

    # firstly, check that the node actually exists
    my ($nodes) = $doc->find($xpath);
    print 'assert_xpath_values_match: Found ' . (scalar @$nodes) . "\n" if $VERBOSE;
    unless ( @$nodes ) {
        die "XPath '$xpath' matched no nodes when we expected to match at least one";
    }

    # check the values are what we expect
    my $i = 0;
    foreach my $node ( @$nodes ) {
	print "assert_xpath_value_match: This node's value : " . $node->string_value() . "\n" if $VERBOSE;
        unless ( $node->string_value() ~~ $match ) {
            die "Elment $i of XPath '$xpath' doesn't match '$match' as expected, instead it is '" . $node->string_value() . "'";
        }
        $i++;
    }

    return 1;
}

sub do_xpath_values_match {
    my $self = _self(\@_);
    my ($doc, $xpath, $match) = @_;

    $self->_clear_error();
    eval { $self->assert_xpath_values_match($doc, $xpath, $match) };
    if ( $@ ) {
        $self->error($@);
        return;
    }
    return 1;
}

# assert_attr_value_match
sub assert_attr_value_match {
    my $self = _self(\@_);
    my ($doc, $xpath, $attr, $match) = @_;

    $doc = $self->register_ns($doc);

    # firstly, check that the node actually exists
    my ($nodes) = $doc->find($xpath);
    print 'assert_attr_value_match: Found ' . (scalar @$nodes) . "\n" if $VERBOSE;
    unless ( @$nodes == 1 ) {
        die "XPath '$xpath' matched " . (scalar @$nodes) . " nodes when we expected to match one";
    }

    # check that this node has this attribute
    my $node = $nodes->[0];
    my $value = $node->getAttribute( $attr );
    print "assert_xpath_value_match: This attr's value : " . $value . "\n" if $VERBOSE;
    unless ( $value ~~ $match ) {
        die "XPath '$xpath', attribute '$attr' doesn't match '$match' as expected, instead it is '" . $value . "'";
    }

    return 1;
}

sub does_attr_value_match {
    my $self = _self(\@_);
    my ($doc, $xpath, $attr, $match) = @_;

    $self->_clear_error();
    eval { $self->assert_attr_value_match($doc, $xpath, $attr, $match) };
    if ( $@ ) {
        $self->error($@);
        return;
    }
    return 1;

}

# assert_attr_values_match
sub assert_attr_values_match {
    my $self = _self(\@_);
    my ($doc, $xpath, $attr, $match) = @_;

    $doc = $self->register_ns($doc);

    # firstly, check that the node actually exists
    my ($nodes) = $doc->find($xpath);
    print 'assert_attr_values_match: Found ' . (scalar @$nodes) . "\n" if $VERBOSE;
    unless ( @$nodes ) {
        die "XPath '$xpath' matched no nodes when we expected to match at least one";
    }

    # check the values are what we expect
    my $i = 0;
    foreach my $node ( @$nodes ) {
        my $value = $node->getAttribute( $attr );
	print "assert_xpath_values_match: This attr's value : " . $value . "\n" if $VERBOSE;
        unless ( $value ~~ $match ) {
            die "Attribute '$attr' of element $i of XPath '$xpath' doesn't match '$match' as expected, instead it is '" . $value . "'";
        }
        $i++;
    }

    return 1;
}

sub do_attr_values_match {
    my $self = _self(\@_);
    my ($doc, $xpath, $attr, $match) = @_;

    $self->_clear_error();
    eval { $self->assert_attr_values_match($doc, $xpath, $attr, $match) };
    if ( $@ ) {
        $self->error($@);
        return;
    }
    return 1;

}

# private functions
sub _plural {
    my ($class, $number, $single, $plural) = @_;

    return $number == 1 ? $single : defined $plural ? $plural : "${single}s";
}

1;
__END__

=head1 NAME

XML::Assert - Asserts XPaths into an XML Document for correct values/matches

=head1 SYNOPSIS

    use XML::LibXML;
    use XML::Assert;

    my $xml = "<foo xmlns="urn:message"><bar baz="buzz">text</bar></foo>";
    my $xml_ns = "<foo xmlns="urn:message"><bar baz="buzz">text</bar></foo>";

    # get the DOM Document for each string
    my $doc = $parser->parse_string( $xml )->documentElement();
    my $doc_ns1 = $parser->parse_string( $xml_ns1 )->documentElement();

    # create an XML::Assert object
    my $xml_assert = XML::Assert->new();

    # assert that there is:
    # - only one <bar> element in the document
    # - the value of bar is 'text'
    # - the value of bar matches /^tex/
    # - the value of the baz attribute is buzz
    $xml_assert->assert_xpath_count($doc, '//bar', 1);
    $xml_assert->assert_xpath_value_match($doc, '//bar', 'text');
    $xml_assert->assert_xpath_value_match($doc, '//bar', qr{^tex});
    $xml_assert->assert_xpath_value_match($doc, '//bar[1]/@baz', 'buzz');

    # do the same with namespaces ...
    $xml_assert->xmlns({ 'ns' => 'urn:message' });
    $xml_assert->assert_xpath_count($doc, '//ns:bar', 1);
    # ...etc...

=head1 DESCRIPTION

This module allows you to test XPaths into an XML Document to check that their
number or values are what you expect.

To test the number of nodes you expect to find, use the C<assert_xpath_count()>
method. To test the value of a node, use the
C<assert_xpath_value_match()>. This method can test against strings or regexes.

You can also text a value against a number of nodes by using the
C<assert_xpath_values_match()> method. This can check your value against any
number of nodes.

Each of these assert methods throws an exception if they are false. Therefore,
there are equivalent methods which do not die, but instead return a truth
value. They are does_xpath_count(), does_xpath_value_match() and
do_xpath_values_match().

Note: all of the *_match() methods use the smart match operator C<~~> against
node->text_value() to test for truth.

=head1 SUBROUTINES

Please note that all subroutines listed here that start with C<assert_*> throw
an error if the assertion is not true. You'd expect this.

Also note that there are a corresponding number of other methods for each
C<assert_*> method which either return true or false and do not throw an
error. Please be sure to use the correct version for what you need.

=over 4

=item assert_xpath_count($doc, $xpath, $count)

Checks that there are C<$count> nodes in the C<$doc> that are returned by the
C<$xpath>. Throws an error if this is untrue.

=item is_xpath_count($doc, $xpath, $count)

Calls the above method but catches any error and instead returns a truth value.

=item assert_xpath_value_match($doc, $xpath, $match)

Checks that C<$xpath> returns only one node and that node's value matches
C<$match>.

=item does_xpath_value_match($doc, $xpath, $match)

Calls the above method but catches any error and instead returns a truth value.

=item assert_xpath_values_match($doc, $xpath, $match)

Checks that C<$xpath> returns at least one node and that all nodes returned
smart match against C<$match>.

=item do_xpath_values_match($doc, $xpath, $match)

Calls the above method but catches any error and instead returns a truth value.

=item assert_attr_value_match($doc, $xpath, $attr, $match)

Checks that C<$xpath> returns only one node, that node has an attr called
C<$attr> and that attr's value matches C<$match>.

=item does_attr_value_match($doc, $xpath, $attr, $match)

Calls the above method but catches any error and instead returns a truth value.

=item assert_attr_values_match($doc, $xpath, $attr, $match)

Checks that C<$xpath> returns at least one node, that every node has an attr
called C<$attr> and that those attr values smart match against C<$match>.

=item do_attr_values_match($doc, $xpath, $attr, $match)

Calls the above method but catches any error and instead returns a truth value.

=item register_ns

Takes a hash containing ns => value pairs which are namesapces to register when
Asserting into an XML document. If the correct namesapces are not registered,
then it's likely that you XPath expressions won't match any of the desired
nodes.

=back

=head1 PROPERTIES

=over

=item xmlns

A hashref of prefix => XMLNS, if you have namespaces in the XML document or in
the XPaths.

=back

=head1 EXPORTS

Nothing.

=head1 SEE ALSO

L<Test::XML::Assert>, L<XML::Compare>, L<XML::LibXML>

=head1 AUTHOR

Andrew Chilton

=over 4

=item Work

E<lt>andy at catalyst dot net dot nzE<gt>, http://www.catalyst.net.nz/

=item Personal

E<lt>andychilton at gmail dot comE<gt>, http://www.chilts.org/blog/

=back

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
