package lib::prereqs::only;

our $DATE = '2017-01-11'; # DATE
our $VERSION = '0.004'; # VERSION

use strict;
use warnings;

require lib::filter;

sub import {
    my ($pkg, %opts) = @_;

    my $allow_runtime_requires   = delete $opts{RuntimeRequires}   // 1;
    my $allow_runtime_recommends = delete $opts{RuntimeRecommends} // 0;
    my $allow_runtime_suggests   = delete $opts{RuntimeSuggests}   // 0;
    my $allow_test_requires      = delete $opts{TestRequires}      // 1;
    my $allow_test_recommends    = delete $opts{TestRecommends}    // 0;
    my $allow_test_suggests      = delete $opts{TestSuggests}      // 0;
    my $allow_core               = delete $opts{allow_core}        // 1;
    my $debug                    = delete $opts{debug}             // 0;
    my $allow                    = delete $opts{allow};
    my $allow_re                 = delete $opts{allow_re};
    my $disallow                 = delete $opts{disallow};
    my $disallow_re              = delete $opts{disallow_re};
    for (keys %opts) {
        die "Unknown options '$_', see documentation for known options";
    }
    my $dbgh = "[lib::prereqs::only]";

    #print "D:ENV:\n", map {"  $_=$ENV{$_}\n"} sort keys %ENV;
    my $running_under_prove = do {
        ($ENV{_} // '') =~ m![/\\]prove\z! ? 1:0;
    };
    warn "$dbgh we are running under prove\n" if $running_under_prove && $debug;

    my %allow;
    my %disallow;

    if ($running_under_prove) {
        # modules required by prove
        $allow{$_} = 1 for qw(
                                 App::Prove
                         );
    }

    {
        open my($fh), "<", "dist.ini"
            or die "Can't open dist.ini in current directory: $!";
        my $cur_section = '';
        my ($key, $value);
        while (defined(my $line = <$fh>)) {
            chomp $line;
            #print "D:line=<$line>\n";
            if ($line =~ /\A\s*\[\s*([^\]]+?)\s*\]\s*\z/) {
                #print "D:section=<$1>\n";
                $cur_section = $1;
                next;
            } elsif ($line =~ /\A\s*([^;][^=]*?)\s*=\s*(.*?)\s*\z/) {
                ($key, $value) = ($1, $2);
                next if $key eq 'perl';
                if ($cur_section =~ m!\A(Prereqs|Prereqs\s*/\s*RuntimeRequires)\z!) {
                    if ($allow_runtime_requires) {
                        $allow{$key} = 1;
                    } else {
                        $disallow{$key} = 1;
                    }
                } elsif ($cur_section =~ m!\A(Prereqs\s*/\s*RuntimeRecommends)\z!) {
                    if ($allow_runtime_recommends) {
                        $allow{$key} = 1;
                    } else {
                        $disallow{$key} = 1;
                    }
                } elsif ($cur_section =~ m!\A(Prereqs\s*/\s*RuntimeSuggests)\z!) {
                    if ($allow_runtime_suggests) {
                        $allow{$key} = 1;
                    } else {
                        $disallow{$key} = 1;
                    }
                } elsif ($cur_section =~ m!\A(Prereqs\s*/\s*TestRequires)\z!) {
                    if ($allow_test_requires) {
                        $allow{$key} = 1;
                    } else {
                        $disallow{$key} = 1;
                    }
                } elsif ($cur_section =~ m!\A(Prereqs\s*/\s*TestRecommends)\z!) {
                    if ($allow_test_recommends) {
                        $allow{$key} = 1;
                    } else {
                        $disallow{$key} = 1;
                    }
                } elsif ($cur_section =~ m!\A(Prereqs\s*/\s*TestSuggests)\z!) {
                    if ($allow_test_suggests) {
                        $allow{$key} = 1;
                    } else {
                        $disallow{$key} = 1;
                    }
                }
            }
        }
        warn "$dbgh modules collected from prereqs in dist.ini to be allowed: ", join(";", sort keys %allow), "\n"
            if $debug;
        warn "$dbgh modules collected from prereqs in dist.ini to be disallowed: ", join(";", sort keys %disallow), "\n"
            if $debug;
    }

    # collect modules under lib/
    {
        my @distmods;
        my $code_find_pm;
        $code_find_pm = sub {
            my ($dir, $fulldir) = @_;
            chdir $dir or die "Can't chdir to '$fulldir': $!";
            opendir my($dh), "." or die "Can't opendir '$fulldir': $!";
            for my $e (readdir $dh) {
                next if $e eq '.' || $e eq '..';
                if (-d $e) {
                    $code_find_pm->($e, "$fulldir/$e");
                }
                next unless $e =~ /\.pm\z/;
                my $mod = "$fulldir/$e"; $mod =~ s/\.pm\z//; $mod =~ s!\Alib/!!; $mod =~ s!/!::!g;
                push @distmods, $mod;
                $allow{$mod} = 1;
            }
            chdir ".." or die "Can't chdir back to '$fulldir': $!";
        };
        $code_find_pm->("lib", "lib");
        warn "$dbgh modules under lib/: ", join(";", @distmods), "\n"
            if $debug;
    }

    # allow
    if (defined $allow) {
        $allow{$_} = 1 for split /;/, $allow;
    }

    # we should not use disallow because that overrides allow
    #
    #unless ($allow_core) {
    #    # these are modules required by lib::filter itself, so they are already
    #    # loaded. we need to disallow them explicitly.
    #    for ("strict", "warnings",
    #         # "warnings::register"
    #         "Config",
    #         # "vars",
    #         "lib::filter") {
    #        $disallow{$_} = 1 unless $allow{$_};
    #    }
    #}

    my @lf_args = (
        allow_core    => $allow_core,
        allow_noncore => 0,
        debug         => $debug,
        disallow      => join(';', (sort keys %disallow),
                              (defined $disallow ? split(/;/, $disallow) : ())),
        (disallow_re  => $disallow_re) x !!(defined $disallow_re),
        allow         => join(';', sort keys %allow),
        (allow_re     => $allow_re) x !!(defined $allow_re),
        allow_is_recursive => 1,
    );
    warn "$dbgh importing lib::filter with arguments: ", join(", ", @lf_args)
        if $debug;
    lib::filter->import(@lf_args);
}

sub unimport {
    lib::filter->unimport;
}

1;
# ABSTRACT: Only allow loading modules specified in prereqs in dist.ini

__END__

=pod

=encoding UTF-8

=head1 NAME

lib::prereqs::only - Only allow loading modules specified in prereqs in dist.ini

=head1 VERSION

This document describes version 0.004 of lib::prereqs::only (from Perl distribution lib-prereqs-only), released on 2017-01-11.

=head1 SYNOPSIS

To test your distribution:

 % cd Your-Dist
 % PERL5OPT=-Mlib::prereqs::only prove -l

To allow RuntimeRecommends prereqs too:

 % PERL5OPT=-Mlib::prereqs::only=RuntimeRecommends,1 prove -l

To test script:

 % PERL5OPT=-Mlib::prereqs::only some-script

To test script in your distribution (as well as turn debugging on, and allowing
core modules even though they are not specified in F<dist.ini>):

 % cd Your-Dist
 % perl -Mlib::prereqs::only=debug,1,allow_core,1 -Ilib bin/some-script

=head1 DESCRIPTION

This pragma reads the prerequisites found in F<dist.ini>, the modules found in
F<lib/>, and uses L<lib::filter> to only allow those modules to be
locateable/loadable. It is useful while testing L<Dist::Zilla>-based
distribution: it tests that the prerequisites you specify in F<dist.ini> is
already complete (at least to run the test suite).

Some caveats:

=over

=item * For using with C<prove>, this pragma currently only works via C<PERL5OPT>

Using:

 % prove -Mlib::prereqs::only ...

currently does not work, because the test script is run in a separate process.

=back

By default, only prereqs specified in RuntimeRequires and TestRequires sections
are allowed. But you can include other sections too if you want:

 % PERL5OPT=-Mlib::prereqs::only=RuntimeRecommends,1,TestSuggests,1 prove ...

Currently only (Runtime|Test)(Requires|Recommends|Suggests) are recognized.

Other options that can be passed to the pragma:

=over

=item * allow_core => bool (default: 1)

This will be passed to lib::filter. By default (allow_core=1), core modules will
also be allowed. If you specify core modules in your prereqs and want to test
that, perhaps you want to set this to 0 (but currently XS modules won't work
with C<allow_core> set to 0).

=item * debug => bool (default: 0)

If set to 1, will print debug messages.

=item * allow => str

Specify an extra set of modules to allow. Value is a semicolon-separated list of
module names. Will be passed to lib::filter.

=item * disallow => str

Specify an extra set of modules to disallow. Value is a semicolon-separated list
of module names. Will be passed to lib::filter.

=item * allow_re => str

Specify module pattern to allow. Will be passed to lib::filter.

=item * disallow_re => str

Specify module pattern to disallow. Will be passed to lib::filter.

=back

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/lib-prereqs-only>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-lib-prereqs-only>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=lib-prereqs-only>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<lib::filter>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
