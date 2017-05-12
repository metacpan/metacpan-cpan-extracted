package Test::HTML::Tidy::Recursive;

use strict;
use warnings;
use 5.008;

our $VERSION = 'v0.0.3';

use Test::More;

use HTML::Tidy;
use File::Find::Object::Rule;
use IO::All qw/ io /;

use MooX qw/ late /;

has filename_re => (is => 'ro', default => sub {
        return qr/\.x?html\z/;
    });

has targets => (is => 'ro', isa => 'ArrayRef', required => 1);

has filename_filter => (is => 'ro', default => sub { return sub { return 1; } });

sub calc_tidy
{
    my $self = shift;

    my $tidy = HTML::Tidy->new({ output_xhtml => 1, });
    $tidy->ignore( type => TIDY_WARNING, type => TIDY_INFO );

    return $tidy;
}

sub run
{
    my $self = shift;
    plan tests => 1;
    local $SIG{__WARN__} = sub {
        my $w = shift;
        if ($w !~ /\AUse of uninitialized/)
        {
            die $w;
        }
        return;
    };

    my $tidy = $self->calc_tidy;

    my $error_count = 0;

    my $filename_re = $self->filename_re;
    my $filter = $self->filename_filter;

    foreach my $target (@{$self->targets})
    {
        for my $fn (File::Find::Object::Rule->file()->name($filename_re)->in($target))
        {
            if ($filter->($fn))
            {
                $tidy->parse( $fn, (scalar io->file($fn)->slurp()));

                for my $message ( $tidy->messages ) {
                    $error_count++;
                    diag( $message->as_string);
                }

                $tidy->clear_messages();
            }
        }
    }

    # TEST
    is ($error_count, 0, "No errors");
}

1;

__END__

=pod

=head1 NAME

Test::HTML::Tidy::Recursive - recursively check files in a directory using
HTML::Tidy .

=head1 VERSION

version v0.0.3

=head1 SYNOPSIS

    use Test::HTML::Tidy::Recursive;

    Test::HTML::Tidy::Recursive->new({
        targets => ['./dest-html', './dest-html-production'],
        })->run;

Or with over-riding the defaults:

    use Test::HTML::Tidy::Recursive;

    Test::HTML::Tidy::Recursive->new({
        filename_re => qr/\.x?html?\z/i,
        filename_filter => sub { return shift !~ m#MathJax#; },
        targets => ['./dest-html', './dest-html-production'],
        })->run;

=head1 DESCRIPTION

This module acts as test module which runs L<HTML::Tidy> on some directory
trees containing HTML/XHTML files and checks that they are all valid.

It was extracted from a bunch of nearly duplicate test scripts in some of
my (= Shlomi Fish) web sites, as an attempt to avoid duplicate code and
functionality.

=head1 METHODS

=head2 calc_tidy

Calculates the L<HTML::Tidy> object - can be overriden.

=head2 filename_filter

A parameter with a callback to filter the files. Defaults to accept all files.

=head2 filename_re

A regex for which filenames are checked. Defaults to files ending in ".html"
or ".xhtml".

=head2 run

The method that runs the program.

=head2 targets

A parameter that accepts an array reference of targets as strings.

=head1 SEE ALSO

L<HTML::Tidy> .

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-HTML-Tidy-Recursive or by
email to bug-test-html-tidy-recursive@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Test::HTML::Tidy::Recursive

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Test-HTML-Tidy-Recursive>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Test-HTML-Tidy-Recursive>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test-HTML-Tidy-Recursive>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Test-HTML-Tidy-Recursive>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Test-HTML-Tidy-Recursive>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Test-HTML-Tidy-Recursive>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Test-HTML-Tidy-Recursive>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Test-HTML-Tidy-Recursive>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Test-HTML-Tidy-Recursive>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Test::HTML::Tidy::Recursive>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-test-html-tidy-recursive at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Test-HTML-Tidy-Recursive>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-Test-HTML-Tidy-Recursive>

  git clone https://github.com/shlomif/perl-Test-HTML-Tidy-Recursive

=cut
