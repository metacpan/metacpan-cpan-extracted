# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use ExtUtils::MakeMaker::CPANfile;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git@github.com:cpanel/p5-cPanel-APIClient.git',
                web => 'https://github.com/cpanel/p5-cPanel-APIClient',
            },
            bugtracker => {
                web => 'https://github.com/cpanel/p5-cPanel-APIClient/issues',
            },
        },
    },

    NAME         => 'cPanel::APIClient',
    AUTHOR       => 'cPanel, L. L. C. (CPANEL)',
    VERSION_FROM => 'lib/cPanel/APIClient.pm',      # finds \$VERSION
    ABSTRACT_FROM => 'lib/cPanel/APIClient.pm',
    LICENSE      => 'perl',

    # Because of X::Tiny
    MIN_PERL_VERSION => 5.010000,
);

# For tracking down CPAN Testers failures:
force_verbose_output() if $ENV{'PERL_CPAN_REPORTER_CONFIG'};

# Useful for diagnosing CPAN Testers issues …
sub force_verbose_output {
    my $path = 'Makefile';

    open my $fh, '+<', 'Makefile' or do {
        print "No “Makefile” …$/";
        return;
    };

    my $txt = do { local $/; <$fh> };
    $txt =~ s<TEST_VERBOSE=0><TEST_VERBOSE=1>;
    seek $fh, 0, 0;
    print {$fh} $txt;
}
