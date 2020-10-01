package Text::WrapAsUtf8;
$Text::WrapAsUtf8::VERSION = '0.0.2';
use strict;
use warnings;

use parent 'Exporter';

our @EXPORT_OK = (
    qw(
        print_utf8
        wrap_as_utf8
        )
);

sub wrap_as_utf8
{
    my ($cb) = @_;

    binmode STDOUT, ":encoding(UTF-8)";

    $cb->();

    binmode STDOUT, ":raw";

    return;
}

sub print_utf8
{
    my (@data) = @_;

    wrap_as_utf8(
        sub {
            print @data;

            return;
        }
    );

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::WrapAsUtf8 - temporarily wraps output to stdout as the UTF-8 binmode.

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

    use Text::WrapAsUtf8 qw/ print_utf8 wrap_as_utf8 /;

    print_utf8("Hello\n", "World\n");

    wrap_as_utf8(sub {
        print("string containing unicode\n");
    });

=head1 DESCRIPTION

This module implements two functions that proved of utility in my Website
Meta Language
(L<http://www.shlomifish.org/open-source/projects/website-meta-language/>)
sites and which I decided to extract into a common CPAN distribution. They
temporarily wrap output to STDOUT in the UTF-8 encoding layer.

=head1 VERSION

=head1 EXPORTS

=head2 wrap_as_utf8(sub { print ... });

Sets the STDOUT binmode to UTF-8, calls the subroutine that is passed as an
argument, and sets binmode to raw.

=head2 print_utf8(@strings)

Prints @strings while inside wrap_as_utf8().

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Text-WrapAsUtf8>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-WrapAsUtf8>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Text-WrapAsUtf8>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Text-WrapAsUtf8>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Text-WrapAsUtf8>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Text::WrapAsUtf8>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-text-wrapasutf8 at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Text-WrapAsUtf8>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/Text-WrapAsUtf8>

  git clone https://github.com/shlomif/Text-WrapAsUtf8.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/text-wrapasutf8/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
