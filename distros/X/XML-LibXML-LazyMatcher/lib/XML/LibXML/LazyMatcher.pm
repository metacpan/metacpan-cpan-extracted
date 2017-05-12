package XML::LibXML::LazyMatcher;

use warnings;
use strict;

use XML::LibXML;

=head1 NAME

XML::LibXML::LazyMatcher - A simple XML matcher with lazy evaluation.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    my $dom = XML::LibXML->load_xml (string => "<root><c1><c2>hello</c2><c3>world</c3></c1></root>");
    my $matcher;
    my ($c2content, $c3content);
    {
	package XML::LibXML::LazyMatcher;
	$matcher = M (root =>
		      C (M (c1 =>
			    C (M (c2 =>
				  sub {
				      $c2content = $_[0]->textContent;
				      return 1;
				  }),
			       M (c3 =>
				  sub {
				      $c3content = $_[0]->textContent;
				      return 1;
				  })))));
    }
    $matcher->($dom->documentElement);

=head1 EXPORT

None.

=head1 SUBROUTINES/METHODS

=head2 M (tagname => [sub_matcher, ...])

Returns a matcher function.  This returned function takes an
XML::LibXML::Node object as an argument.  First, The matcher checks if
the tag name of the passed node is correct, then, applies the node to
all C<sub_matcher>s.  If all C<sub_matcher>s return true value then
the C<M()> returns 1.  Otherwise returns 0.

You can define some action as a sub_matcher.  A typical C<sub_matcher>
may be like this:

    sub {
        my $node = shift;	# $node should be a XML::LibXML::Node.
    
        return 0 unless is_valid($node);
    
        do_some_action($node);
        return 1;
    }

=cut

sub M {
    my $tagname = shift;
    my @matchers = @_;

    sub {
	my $elem = shift;

	# warn "matching $tagname", $elem->nodeName;

	return 0 unless ($elem->nodeName eq $tagname);

	# warn "eating $tagname";

	for my $m (@matchers) {
	    if (ref ($m) eq "CODE") {
		return 0 unless ($m->($elem)); # failure
	    } else {
		die "invalid matcher";
	    }
	}

	return 1;
    };
}

=head2 C (sub_matcher, ...)

Creates a matcher function which tests all child nodes.  If a
sub_matcher returns true value, then the C<C()> returns 1.  Otherwise
returns 0.

=cut

sub C {
    my $alternate = sub {
	my @children = @_;

	sub {
	    my $elem = shift;

	    for my $m (@children) {
		return 1 if ($m->($elem));
	    }
	    return 0;
	}
    };

    my @children = @_;

    sub {
	my $parent = shift;

	my $m = $alternate->(@children);
	for (my $c = $parent->firstChild; $c; $c = $c->nextSibling) {
	    return 0 unless $m->($c);
	}

	return 1;
    }
}

=head2 S (sub_matcher, ...)

Creates a matcher function which test all child nodes sequentially.
Every child nodes is tested by the appropriate C<sub_matcher>
accordingly.  The returned matcher fails if one of C<sub_matcher>s
fails.

Also, this matcher ignores empty text node for convenience.

=cut

sub S {
    my @children = @_;

    sub {
	my $parent = shift;

	for (my $c = $parent->firstChild; $c; $c = $c->nextSibling) {
	    next if ($c->nodeType == 3 && $c->textContent =~ /\s*/);
	    return 0 unless $#children >= 0 && shift (@children)->($c);
	}

	return 0 if $#children >= 0;

	return 1;
    }
}

=head1 AUTHOR

Toru Hisai, C<< <toru at torus.jp> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-libxml-lazymatcher at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-LibXML-LazyMatcher>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::LibXML::LazyMatcher


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-LibXML-LazyMatcher>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-LibXML-LazyMatcher>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-LibXML-LazyMatcher>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-LibXML-LazyMatcher/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Toru Hisai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of XML::LibXML::LazyMatcher
