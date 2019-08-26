package XML::Grammar::Fortune::Synd::Heap::Elem;
$XML::Grammar::Fortune::Synd::Heap::Elem::VERSION = '0.0214';
use strict;
use warnings;


use parent 'Class::Accessor';

__PACKAGE__->mk_accessors(qw(
    date
    id
    idx
    file
    ));

# "All problems in computer science can be solved by
# adding another level of indirection;"
# -- http://en.wikipedia.org/wiki/Abstraction_layer
sub cmp
{
    my ($self, $other) = @_;
    return
    (
        ($self->date()->compare($other->date()))
            ||
        ($self->idx() <=> $other->idx())
    )
    ;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Grammar::Fortune::Synd::Heap::Elem - heap element class for
XML::Grammar::Fortune::Synd. For internal use.

=head1 VERSION

version 0.0214

=head1 SYNOPSIS

For internal use.

=head1 FUNCTIONS

=head2 cmp()

Internal use.

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-grammar-fortune-synd at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Grammar-Fortune-Synd>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Grammar::Fortune::Synd

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Grammar-Fortune-Synd>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-Grammar-Fortune-Synd>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-Grammar-Fortune-Synd>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-Grammar-Fortune-Synd>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT/X11 License

L<http://www.opensource.org/licenses/mit-license.php>

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/fortune-xml/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc XML::Grammar::Fortune::Synd::Heap::Elem

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/XML-Grammar-Fortune-Synd>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/XML-Grammar-Fortune-Synd>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=XML-Grammar-Fortune-Synd>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/XML-Grammar-Fortune-Synd>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/XML-Grammar-Fortune-Synd>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/XML-Grammar-Fortune-Synd>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/X/XML-Grammar-Fortune-Synd>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=XML-Grammar-Fortune-Synd>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=XML::Grammar::Fortune::Synd>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-xml-grammar-fortune-synd at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=XML-Grammar-Fortune-Synd>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/fortune-xml>

  git clone git://github.com/shlomif/fortune-xml.git

=cut
