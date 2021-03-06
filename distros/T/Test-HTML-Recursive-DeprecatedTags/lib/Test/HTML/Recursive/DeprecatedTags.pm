package Test::HTML::Recursive::DeprecatedTags;
$Test::HTML::Recursive::DeprecatedTags::VERSION = '0.0.2';
use strict;
use warnings;

use MooX qw/ late /;

extends('Test::HTML::Tidy::Recursive');

use HTML::TokeParser;

sub check_file
{
    my ( $self, $args ) = @_;

    my $fn = $args->{filename};
    my $p  = HTML::TokeParser->new($fn);
TOKENS:
    while ( my $token = $p->get_token )
    {
        if ( $token->[0] eq 'S' or $token->[0] eq 'E' )
        {
            if ( 'tt' eq lc $token->[1] )
            {
                $self->report_error( { message => "tt tag found in $fn ." } );
                last TOKENS;
            }
        }
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::HTML::Recursive::DeprecatedTags - check HTML files for deprecated tags.

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

In a test script for a web-site:

    use Test::HTML::Recursive::DeprecatedTags;

    Test::HTML::Recursive::DeprecatedTags->new(
        {
            targets         => ['./dest'],
        }
    )->run;

=head1 DESCRIPTION

This is a subclass of L<Test::HTML::Tidy::Recursive> so more information
can be found there.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Test-HTML-Recursive-DeprecatedTags>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test-HTML-Recursive-DeprecatedTags>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Test-HTML-Recursive-DeprecatedTags>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Test-HTML-Recursive-DeprecatedTags>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Test-HTML-Recursive-DeprecatedTags>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Test::HTML::Recursive::DeprecatedTags>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-test-html-recursive-deprecatedtags at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Test-HTML-Recursive-DeprecatedTags>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-Test-HTML-Recursive-DeprecatedTags>

  git clone https://github.com/shlomif/perl-Test-HTML-Recursive-DeprecatedTags

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/test-html-recursive-deprecatedtags/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
