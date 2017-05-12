## ----------------------------------------------------------------------------
# Copyright (C) 2010 NZ Registry Services
## ----------------------------------------------------------------------------
package Test::XML::Assert;

use 5.006000;
use strict;
use warnings;
#use base 'Test::Builder::Module';
use Test::Builder::Module;
our @ISA = qw(Test::Builder::Module);
use XML::LibXML;
use XML::Assert;

our @EXPORT = qw(
    is_xpath_count
    does_xpath_value_match
    do_xpath_values_match
    does_attr_value_match
);

our $VERSION = '0.03';

my $CLASS = __PACKAGE__;
my $PARSER = XML::LibXML->new();

sub is_xpath_count($$$$;$) {
    my ($doc, $xmlns, $xpath, $count, $name) = @_;

    # create the $xml_assert object
    my $xml_assert = XML::Assert->new();
    $xml_assert->xmlns($xmlns);

    # do the test and remember the result
    my $is_ok = $xml_assert->is_xpath_count($doc, $xpath, $count);

    my $tb = $CLASS->builder();
    return $tb->ok($is_ok, $name);
}

sub does_xpath_value_match($$$$;$) {
    my ($doc, $xmlns, $xpath, $match, $name) = @_;

    my $xml_assert = XML::Assert->new();
    $xml_assert->xmlns($xmlns);

    # do the test and remember the result
    my $is_ok = $xml_assert->does_xpath_value_match($doc, $xpath, $match);

    my $tb = $CLASS->builder();
    return $tb->ok($is_ok, $name);
}

sub do_xpath_values_match($$$$;$) {
    my ($doc, $xmlns, $xpath, $match, $name) = @_;

    my $xml_assert = XML::Assert->new();
    $xml_assert->xmlns($xmlns);

    # do the test and remember the result
    my $is_ok = $xml_assert->do_xpath_values_match($doc, $xpath, $match);

    my $tb = $CLASS->builder();
    return $tb->ok($is_ok, $name);
}

sub does_attr_value_match($$$$$;$) {
    my ($doc, $xmlns, $xpath, $attr, $match, $name) = @_;

    my $xml_assert = XML::Assert->new();
    $xml_assert->xmlns($xmlns);

    # do the test and remember the result
    my $is_ok = $xml_assert->does_attr_value_match($doc, $xpath, $attr, $match);

    my $tb = $CLASS->builder();
    return $tb->ok($is_ok, $name);
}

sub do_attr_values_match($$$$;$) {
    my ($doc, $xmlns, $xpath, $attr, $match, $name) = @_;

    my $xml_assert = XML::Assert->new();
    $xml_assert->xmlns($xmlns);

    # do the test and remember the result
    my $is_ok = $xml_assert->do_attr_values_match($doc, $xpath, $attr, $match);

    my $tb = $CLASS->builder();
    return $tb->ok($is_ok, $name);
}

1;

__END__

=head1 NAME

Test::XML::Assert - Tests XPaths into an XML Document for correct values/matches

=head1 SYNOPSIS

 use Test::XML::Assert tests => 2;

 my $xml1 = "<foo xmlns="urn:message"><bar baz="buzz">text</bar></foo>";
 my $xml2 = "<f:foo xmlns:f="urn:message"><f:bar baz="buzz">text</f:bar></f:foo>";
 my $xml3 = "<foo><bar baz="buzz">text</bar></foo>";

 ToDo

=head1 DESCRIPTION

This module allows you to test if two XML documents are semantically the
same. This also holds true if different prefixes are being used for the xmlns,
or if there is a default xmlns in place.

It uses XML::Assert to do all of it's checking.

=head1 SUBROUTINES

In all of the following subroutines there are three common parameters.

C<$doc> is a XML::LibXML documentElement(), which may or may not use
namespaces.

C<$xmlns> is a hashref of key value pairs which provide the namespace prefix
and the namespace they map to. These namespace prefixes should be used in your
$xpath. An empty hashref or null may also be passed if the $doc doesn't use
namespaces.

C<$xpath> is a string which contains the path to the element(s) you'd like to
match against, whether this is for a count or a value match.

=over 4

=item is_xpath_count($doc, $xmlns, $xpath, $count, $name)

Test passes if there are $count nodes referenced by $xpath in the $doc.

C<$count> is the number of expected nodes which match the C<$xpath>.

=item does_xpath_value_match($doc, $xmlns, $xpath, $match, $name)

Test passes if and only if C<$xpath> matches one node in C<$doc> and that
node's value smart matches C<$match>.

C<$match> is the thing to match again. I say thing since it can be a string or
a regex. In fact, it can be anything the smart smart operator can match
against. See L<perlsyn> for more details.

=item do_xpath_values_match($doc, $xmlns, $xpath, $match, $name)

Test passes if C<$path> matches at least one node in C<$doc> and all nodes
matched smart matches against C<$match>.

Again, C<$match> can be a scalar, regex, arrayref or anything the smart match
operator can match on.

=item does_attr_value_match($doc, $xmlns, $xpath, $attr, $match, $name)

Test passes if and only if C<$xpath> matches one node in C<$doc>, that node has
an attr called C<$attr> and the value of that smart matches C<$match>.

=item do_attr_values_match($doc, $xmlns, $xpath, $match, $name)

Test passes if C<$xpath> matches at least one node in C<$doc>, those nodes all
have an attr called C<$attr> and those values smart matches C<$match>.

=back

=head1 EXPORTS

Everything in L<"SUBROUTINES"> by default, as expected.

=head1 SEE ALSO

L<XML::Assert>, L<XML::Compare>, L<Test::Builder>, L<XML::LibXML>

=head1 AUTHOR

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

Copyright (c) 2010, NZ Registry Services.  All Rights Reserved.  This software
may be used under the terms of the Artistic License 2.0.  Note that this
license is compatible with both the GNU GPL and Artistic licenses.  A copy of
this license is supplied with the distribution in the file COPYING.txt.

=cut
