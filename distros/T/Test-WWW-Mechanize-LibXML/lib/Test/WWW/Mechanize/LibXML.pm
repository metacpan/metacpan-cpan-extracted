package Test::WWW::Mechanize::LibXML;

use warnings;
use strict;

use 5.008;

=head1 NAME

Test::WWW::Mechanize::LibXML - use HTML::TreeBuilder::LibXML for testing
web-sites.

=head1 VERSION

Version 0.0.4

=head1 SYNOPSIS

    use Test::WWW::Mechanize::LibXML;

    my $mech = Test::WWW::Mechanize::LibXML->new();

    # TEST
    $mech->get_ok('http://www.shlomifish.org/');

    # TEST
    $mech->tree_matches_xpath('//p', "There are paragraphs in the page.");

=head1 DESCRIPTION

This module inherits from L<Test::WWW::Mechanize>, and allows one to utilize
L<HTML::TreeBuilder::LibXML> to perform XPath and L<HTML::TreeBuilder>
queries on the tree.

=cut

our $VERSION = '0.0.4';

use base 'Test::WWW::Mechanize';

use HTML::TreeBuilder::LibXML;

use MRO::Compat;

use Test::More;

=head1 METHODS

=head2 $mech->libxml_tree()

Returns the L<HTML::TreeBuilder::LibXML> tree of the current page.

=cut

sub libxml_tree
{
    my $self = shift;

    if (@_)
    {
        $self->{libxml_tree} = shift;
    }

    return $self->{libxml_tree};
}

sub _update_page
{
    my $self = shift;

    my $ret = $self->maybe::next::method(@_);

    my $tree = HTML::TreeBuilder::LibXML->new;
    $tree->parse($self->content());
    $tree->eof();

    $self->libxml_tree($tree);

    return $ret;
}

=head2 my $tag = $mech->contains_tag($tag_spec, $blurb)

See if the tree contains a tag using C< look_down(@$tag_spec) > and
returns it.

=cut

sub contains_tag
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $mech = shift;
    my $tag_spec = shift;
    my $blurb = shift;

    my $ret = $mech->libxml_tree->look_down(@$tag_spec);

    ok($ret, $blurb);

    return $ret;
}

=head2 $mech->tree_matches_xpath($xpath, $blurb)

Determines whether the tree matches the XPath expression $xpath and returns
it.

=cut

sub tree_matches_xpath
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $mech = shift;
    my $xpath = shift;
    my $blurb = shift;

    my @nodes = $mech->libxml_tree->findnodes($xpath);

    return ok(scalar(@nodes), $blurb);
}

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at insurgentsoftware.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-www-mechanize-libxml at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-WWW-Mechanize-LibXML>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::WWW::Mechanize::LibXML

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-WWW-Mechanize-LibXML>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-WWW-Mechanize-LibXML>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-WWW-Mechanize-LibXML>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-WWW-Mechanize-LibXML/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Insurgent Software for sponsoring this work.

=head1 TODO

At the moment, there's a very minimal number of methods here. More should
be added as needed.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Shlomi Fish. (C<shlomif@insurgentsoftware.com>,
L<http://www.shlomifish.org/> )

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

1; # End of Test::WWW::Mechanize::LibXML
