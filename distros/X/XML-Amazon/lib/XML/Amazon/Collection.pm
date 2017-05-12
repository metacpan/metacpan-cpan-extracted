package XML::Amazon::Collection;

use strict;
use warnings;

use XML::Amazon;
use LWP::Simple;
use XML::Simple;
use utf8;

sub new{
	my $pkg = shift;
	my $data = {
	total_results => undef,
	total_pages => undef,
	current_page => undef,
	collection => []
	};
	bless $data, $pkg;
    return $data;
}

sub add_Amazon {
	my $self = shift;
	my $add_data = shift;

	if(ref $add_data ne "XML::Amazon::Item") {
		warn "add_Amazon called with type ", ref $add_data;
		return undef;
	}
	push @{$self->{collection}}, $add_data;
}

sub total_results {
	my $self = shift;
	return $self->{total_results};
}

sub total_pages {
	my $self = shift;
	return $self->{total_pages};
}

sub current_page {
	my $self = shift;
	return $self->{current_page};
}

sub collection {
	my $self = shift;
	my @list;
	for (my $i = 0; $self->{collection}->[$i]; $i++){
		push @list, $self->{collection}->[$i];
	}
	return @list;
}

1;

__END__

=pod

=encoding UTF-8

=head1 VERSION

version 0.13

=head1 METHODS

=head2 new

Constructor

=head2 $self->add_Amazon($item)

Add item to the collection.

=head2 $self->current_page()

Returns the current page.

=head2 $self->total_pages()

Returns the count of total pages.

=head2 $self->total_results()

Returns the total results.

=head2 $self->collection()

Returns a flattened array of the collection.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Shlomi Fish.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Amazon or by email to
bug-test-runvalgrind@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc XML::Amazon

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/XML-Amazon>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/XML-Amazon>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=XML-Amazon>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/XML-Amazon>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/XML-Amazon>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/XML-Amazon>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/XML-Amazon>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/X/XML-Amazon>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=XML-Amazon>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=XML::Amazon>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-xml-amazon at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=XML-Amazon>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-XML-Amazon>

  git clone https://github.com/shlomif/perl-XML-Amazon.git

=cut
