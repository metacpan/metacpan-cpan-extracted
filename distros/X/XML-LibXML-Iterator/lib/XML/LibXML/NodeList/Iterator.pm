# $Id: Iterator.pm,v 1.1.1.1 2002/11/08 17:18:36 phish Exp $
#
package XML::LibXML::NodeList::Iterator;
$XML::LibXML::NodeList::Iterator::VERSION = '1.05';
use strict;
use XML::NodeFilter qw(:results);

use vars qw($VERSION);
$VERSION = "1.03";

use overload
    '++' => sub { $_[0]->nextNode();     $_[0]; },
    '--' => sub { $_[0]->previousNode(); $_[0] },
    '<>' => sub { return wantarray ? $_[0]->_get_all : $_[0]->nextNode(); },
    ;

sub new
{
    my $class = shift;
    my $list  = shift;
    my $self  = undef;
    if ( defined $list )
    {
        $self = bless [ $list, -1, [], ], $class;
    }

    return $self;
}

sub set_filter
{
    my $self = shift;
    $self->[2] = [@_];
}

sub add_filter
{
    my $self = shift;
    push @{ $self->[2] }, @_;
}

# helper function.
sub accept_node
{
    foreach ( @{ $_[0][2] } )
    {
        my $r = $_->accept_node( $_[1] );
        return $r if $r;
    }

    # no filters or all decline ...
    return FILTER_ACCEPT;
}

sub first
{
    $_[0][1] = 0;
    my $s = scalar( @{ $_[0][0] } );
    while ( $_[0][1] < $s )
    {
        last if $_[0]->accept_node( $_[0][0][ $_[0][1] ] ) == FILTER_ACCEPT;
        $_[0][1]++;
    }
    return undef if $_[0][1] == $s;
    return $_[0][0][ $_[0][1] ];
}

sub last
{
    my $i = scalar( @{ $_[0][0] } ) - 1;
    while ( $i >= 0 )
    {
        if ( $_[0]->accept_node( $_[0][0][$i] ) == FILTER_ACCEPT )
        {
            $_[0][1] = $i;
            last;
        }
        $i--;
    }

    if ( $i < 0 )
    {
        # this costs a lot, but is more safe
        return $_[0]->first;
    }
    return $_[0][0][$i];
}

sub current
{
    if ( $_[0][1] >= 0 || $_[0][1] < scalar @{ $_[0][0] } )
    {
        return $_[0][0][ $_[0][1] ];
    }
    return undef;
}

sub index
{
    if ( $_[0][1] >= 0 || $_[0][1] < scalar @{ $_[0][0] } )
    {
        return $_[0][1];
    }
    return undef;
}

sub next     { return $_[0]->nextNode(); }
sub previous { return $_[0]->previousNode(); }

sub nextNode
{
    my $nlen = scalar @{ $_[0][0] };
    if ( $nlen <= ( $_[0][1] + 1 ) )
    {
        return undef;
    }
    my $i = $_[0][1];
    $i = -1 if $i < 0;    # assure that we end up with the first
                          # element in the first iteration
    while (1)
    {
        $i++;
        return undef if $i >= $nlen;
        if ( $_[0]->accept_node( $_[0][0]->[$i] ) == FILTER_ACCEPT )
        {
            $_[0][1] = $i;
            last;
        }
    }
    return $_[0][0]->[ $_[0][1] ];
}

sub previousNode
{
    if ( $_[0][1] <= 0 )
    {
        return undef;
    }
    my $i = $_[0][1];
    while (1)
    {
        $i--;
        return undef if $i < 0;
        if ( $_[0]->accept_node( $_[0][0]->[$i] ) == FILTER_ACCEPT )
        {
            $_[0][1] = $i;
            last;
        }
    }
    return $_[0][0][ $_[0][1] ];
}

sub iterate
{
    my $self    = shift;
    my $funcref = shift;
    my $rv;

    return unless defined $funcref && ref($funcref) eq 'CODE';

    $self->[1] = -1;    # first element
    while ( my $node = $self->next )
    {
        $rv = $funcref->( $self, $node );
    }
    return $rv;
}

# helper function for the <> operator
# returns all nodes that have not yet been accessed
sub _get_all
{
    my $self   = shift;
    my @retval = ();
    my $node;
    while ( $node = $self->next() )
    {
        push @retval, $node;
    }
    return @retval;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::LibXML::NodeList::Iterator - Iteration Class for XML::LibXML XPath results

=head1 VERSION

version 1.05

=head1 SYNOPSIS

  use XML::LibXML;
  use XML::LibXML::NodeList::Iterator;

  my $doc = XML::LibXML->new->parse_string( $somedata );
  my $nodelist = $doc->findnodes( $somexpathquery );

  my $iter= XML::LibXML::NodeList::Iterator->new( $nodelist );

  # more control on the flow
  while ( $iter->nextNode ) {
      # do something
  }

  # operate on the entire tree
  $iter->iterate( \&operate );

=head1 DESCRIPTION

XML::LibXML::NodeList::Iterator is very similar to
XML::LibXML::Iterator, but it does not iterate on the tree structure
but on a XML::LibXML::NodeList object. Because XML::LibXML::NodeList
is basically an array the functionality of
XML::LibXML::NodeList::Iterator is more restircted to stepwise
foreward and backward than XML::LibXML::Iterator is.

=head1 METHODS

=over 4

=item * accept_node

=item * add_filter

=item * current

=item * first

=item * index

=item * iterate

=item * last

=item * new

=item * next

=item * nextNode

=item * previous

=item * previousNode

=item * set_filter

=back

=head1 SEE ALSO

L<XML::LibXML::NodeList>, L<XML::NodeFilter>, L<XML::LibXML::Iterator>

=head1 AUTHOR

Christian Glahn, E<lt>phish@cpan.orgE<gt>

=head1 COPYRIGHT

(c) 2002-2007, Christian Glahn. All rights reserved.

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

unknown

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by unknown.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/xml-libxml-iterator/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc XML::LibXML::NodeList::Iterator

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/XML-LibXML-Iterator>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/XML-LibXML-Iterator>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=XML-LibXML-Iterator>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/XML-LibXML-Iterator>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/XML-LibXML-Iterator>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/XML-LibXML-Iterator>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/X/XML-LibXML-Iterator>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=XML-LibXML-Iterator>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=XML::LibXML::Iterator>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-xml-libxml-iterator at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=XML-LibXML-Iterator>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/xml-libxml-iterator>

  git clone git://github.com/shlomif/xml-libxml-iterator.git

=cut
