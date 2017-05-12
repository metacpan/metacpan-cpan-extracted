package Test::RunValgrind;

use strict;
use warnings;

our $VERSION = '0.0.1';

use Test::More;
use Path::Tiny qw/path/;

use Carp;

sub new
{
    my $class = shift;

    my $self = bless {}, $class;

    $self->_init(@_);

    return $self;
}

sub _init
{
    my ($self, $args) = @_;

    return;
}

sub run
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($self, $args) = @_;

    my $blurb = $args->{blurb}
        or Carp::confess("blurb not specified.");

    my $log_fn = $args->{log_fn}
        or Carp::confess("log_fn not specified.");

    my $prog = $args->{prog}
        or Carp::confess("prog not specified.");

    my $argv = $args->{argv}
        or Carp::confess("argv not specified.");

    system(
        "valgrind",
        "--track-origins=yes",
        "--leak-check=yes",
        "--log-file=$log_fn",
        $prog,
        @$argv,
    );

    my $out_text = path( $log_fn )->slurp_utf8;
    my $ret = Test::More::ok (
        (index($out_text, q{ERROR SUMMARY: 0 errors from 0 contexts}) >= 0)
        &&
        (index($out_text, q{in use at exit: 0 bytes}) >= 0)
        , $blurb
    );
    if ($ret)
    {
        unlink($log_fn);
    }
    return $ret;
}

1;

__END__

=pod

=head1 NAME

Test::RunValgrind - tests that an external program is valgrind-clean.

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

    use Test::More tests => 1;

    # TEST
    Test::RunValgrind->new({})->run(
        {
            log_fn => './expr--valgrind-log.txt',
            prog => '/usr/bin/expr',
            argv => [qw/5 + 6/],
            blurb => 'valgrind likes /usr/bin/expr',
        }
    );

=head1 DESCRIPTION

valgrind is an open source and convenient memory debugger that runs on some
platforms. This module runs valgrind (L<http://en.wikipedia.org/wiki/Valgrind>)
on an executable and makes sure that valgrind did not find any faults in it.

It originated from some code used to test the Freecell Solver executables
using valgrind, and was extracted into its own CPAN module to allow for
reuse by other projects, including fortune-mod
(L<https://github.com/shlomif/fortune-mod>).

=head1 METHODS

=head2 my $obj = Test::RunValgrind->new({})

The constructor - currently accepts a single hash reference and does not use
any of its keys.

=head2 $obj->run({ ... })

Runs valgrind.

Accepts a hash ref with the following keys:

=over 4

=item * blurb

The L<Test::More> test assertion blurb.

=item * log_fn

The path to write the log file to (and read from it). Make sure it is secured.

=item * prog

The path to the executable to run.

=item * argv

An array reference contains strings with command line arguments to the executable.

=back

See the synopsis for an example.

=head1 SEE ALSO

L<Test::Valgrind> - seems to be only for running perl itself under valgrind.

L<Devel::Valgrind::Client>

L<http://en.wikipedia.org/wiki/Valgrind> - wikipedia page.

L<http://github.com/shlomif/fc-solve/blob/master/fc-solve/source/t/t/lib/FC_Solve/Test/Valgrind.pm>
- original code using Test::RunValgrind in Freecell Solver

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-RunValgrind or by email to
bug-test-runvalgrind@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Test::RunValgrind

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Test-RunValgrind>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Test-RunValgrind>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test-RunValgrind>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Test-RunValgrind>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Test-RunValgrind>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Test-RunValgrind>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Test-RunValgrind>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Test-RunValgrind>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Test-RunValgrind>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Test::RunValgrind>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-test-runvalgrind at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Test-RunValgrind>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-Test-RunValgrind>

  git clone https://github.com/shlomif/perl-Test-RunValgrind.git

=cut
