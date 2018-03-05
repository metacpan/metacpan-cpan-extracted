package XML::RSS::Private::Output::V2_0;
$XML::RSS::Private::Output::V2_0::VERSION = '1.60';
use strict;
use warnings;

use vars (qw(@ISA));

use XML::RSS::Private::Output::Base;
use XML::RSS::Private::Output::Roles::ModulesElems;
use XML::RSS::Private::Output::Roles::ImageDims;

@ISA = (qw(
    XML::RSS::Private::Output::Roles::ImageDims
    XML::RSS::Private::Output::Roles::ModulesElems
    XML::RSS::Private::Output::Base
    )
);

sub _get_filtered_items {
    my $self = shift;

    return [
        grep {exists($_->{title}) || exists($_->{description})}
        @{$self->_get_items()},
    ];
}

sub _out_item_2_0_tags {
    my ($self, $item) = @_;

    $self->_output_def_item_tag($item, "author");
    $self->_output_array_item_tag($item, "category");
    $self->_output_def_item_tag($item, "comments");

    $self->_out_guid($item);

    $self->_output_def_item_tag($item, "pubDate");

    $self->_out_item_source($item);

    $self->_out_item_enclosure($item);
}

sub _get_textinput_tag {
    return "textInput";
}

sub _get_item_defined {
    return 1;
}

sub _output_rss_middle {
    my $self = shift;

    # PICS rating
    # Not supported by RSS 2.0
    # $output .= '<rating>'.$self->{channel}->{rating}.'</rating>'."\n"
    #    if $self->{channel}->{rating};

    # copyright
    $self->_out_copyright();

    $self->_out_dates();

    # external CDF URL
    $self->_out_def_chan_tag("docs");

    $self->_out_editors;

    $self->_out_channel_array_self_dc_field("category");
    $self->_out_channel_self_dc_field("generator");

    # Insert cloud support here

    # ttl
    $self->_out_channel_self_dc_field("ttl");

    $self->_out_modules_elements($self->channel());

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

  perldoc XML::RSS::Private::Output::V2_0

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
