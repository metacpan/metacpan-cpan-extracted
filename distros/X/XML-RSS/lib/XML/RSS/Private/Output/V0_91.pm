package XML::RSS::Private::Output::V0_91;
$XML::RSS::Private::Output::V0_91::VERSION = '1.60';
use strict;
use warnings;

use vars (qw(@ISA));

use XML::RSS::Private::Output::Base;
use XML::RSS::Private::Output::Roles::ImageDims;

@ISA = (qw(
    XML::RSS::Private::Output::Roles::ImageDims
    XML::RSS::Private::Output::Base
    )
);

sub _get_rdf_decl
{
    return
    qq{<!DOCTYPE rss PUBLIC "-//Netscape Communications//DTD RSS 0.91//EN"\n} .
    qq{            "http://www.rssboard.org/rss-0.91.dtd">\n\n} .
    qq{<rss version="0.91">\n\n};
}

sub _calc_lastBuildDate {
    my $self = shift;
    if (defined(my $d = $self->channel('lastBuildDate'))) {
        return $d;
    }
    elsif (defined(my $d2 = $self->_channel_dc('date'))) {
        return $self->_date_to_rss2($self->_date_from_dc_date($d2));
    }
    else {
        return undef;
    }
}

sub _output_rss_middle {
    my $self = shift;

    # PICS rating
    $self->_out_def_chan_tag("rating");

    $self->_out_copyright();

    $self->_out_dates();

    # external CDF URL
    $self->_out_def_chan_tag("docs");

    $self->_out_editors;

    $self->_out_last_elements;
}

1;

__END__

=pod

=head1 VERSION

version 1.60

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2001 by Various.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-XML-RSS/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc XML::RSS::Private::Output::V0_91

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/XML-RSS>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/XML-RSS>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=XML-RSS>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/XML-RSS>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/XML-RSS>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/XML-RSS>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/X/XML-RSS>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=XML-RSS>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=XML::RSS>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-xml-rss at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=XML-RSS>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-XML-RSS>

  git clone git://github.com/shlomif/perl-XML-RSS.git

=cut
