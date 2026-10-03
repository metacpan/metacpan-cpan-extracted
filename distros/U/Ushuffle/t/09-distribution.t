use strict;
use warnings;

use Test::More;

use ExtUtils::Manifest;
use FindBin;

use Ushuffle;

# Consistency of the files that make up the distribution.

my $root = "$FindBin::Bin/..";

sub slurp {
    my ($file) = @_;
    open my $fh, '<', "$root/$file" or die "cannot read $file: $!";
    local $/;
    return scalar <$fh>;
}

my %pod = (
    'Ushuffle'           => slurp('lib/Ushuffle.pm'),
    'Ushuffle::Shuffler' => slurp('lib/Ushuffle/Shuffler.pod'),
);

# every public function and method has its own entry in the documentation
like $pod{'Ushuffle'}, qr/^=head2 \Q$_\E$/m, "Ushuffle: $_ is documented" for qw(shuffle set_seed);
like $pod{'Ushuffle::Shuffler'}, qr/^=head2 \Q$_\E$/m, "Ushuffle::Shuffler: $_ is documented"
    for grep { !/^(?:DESTROY|CLONE_SKIP)$/ } sort grep { defined &{"Ushuffle::Shuffler::$_"} }
    keys %Ushuffle::Shuffler::;

# the sections expected of a module on CPAN
for my $package (sort keys %pod) {
    for my $section ('NAME', 'VERSION', 'SYNOPSIS', 'DESCRIPTION', 'SEE ALSO', 'AUTHOR',
        'COPYRIGHT AND LICENSE')
    {
        like $pod{$package}, qr/^=head1 \Q$section\E$/m, "$package: has a $section section";
    }
    like $pod{$package}, qr/^=head1 NAME\n\n\Q$package\E - \S/m,
        "$package: NAME gives the package and an abstract";
    like $pod{$package}, qr/^=head1 VERSION\n\n.*\bversion \Q$Ushuffle::VERSION\E\.$/m,
        "$package: VERSION section is current";
}
like $pod{'Ushuffle'}, qr/^=head1 \Q$_\E$/m, "Ushuffle: has a $_ section"
    for 'FUNCTIONS', 'RANDOM NUMBERS', 'THREADS', 'LIMITATIONS', 'SUPPORT';
like $pod{'Ushuffle'}, qr/Copyright \(c\) 2007\s+Minghui Jiang/,
    'documentation reproduces the copyright notice of the library';

# the library's licence terms are given in full, word for word
{
    my ($terms) = slurp('ushufflelib/ushuffle.c') =~ m{(Redistribution and use.*?SUCH DAMAGE\.)}s
        or die 'no licence terms in the library source';
    $terms =~ s/^ \* ?//mg;
    my $squeeze = sub { my ($text) = @_; $text =~ s/\s+/ /g; $text };
    for my $file ('LICENSE', 'lib/Ushuffle.pm') {
        ok index($squeeze->(slurp($file)), $squeeze->($terms)) >= 0,
            "$file contains the licence terms of the library";
    }
}

# the version is the same everywhere
like slurp('README'),  qr/^Ushuffle version \Q$Ushuffle::VERSION\E$/m, 'README names the version';
like slurp('Changes'), qr/^\Q$Ushuffle::VERSION\E\b/m, 'Changes has an entry for the version';

# the MANIFEST is complete and nothing in it is missing
{
    my %listed = map { $_ => 1 } keys %{ ExtUtils::Manifest::maniread("$root/MANIFEST") };

    my @missing = grep { !-f "$root/$_" } sort keys %listed;
    is "@missing", '', 'every file in the MANIFEST exists';

    my @tests = map { s{^\Q$root\E/}{}; $_ } glob("$root/t/*.t"), glob("$root/t/lib/*.pm");
    cmp_ok scalar @tests, '>', 5, 'found the test files';
    my @unlisted = grep { !$listed{$_} } @tests;
    is "@unlisted", '', 'every test file is in the MANIFEST';

    ok $listed{$_}, "$_ is in the MANIFEST"
        for qw(Makefile.PL Ushuffle.xs typemap ushuffle_lib.c lib/Ushuffle.pm
        lib/Ushuffle/Shuffler.pod README LICENSE Changes
        ushufflelib/ushuffle.c ushufflelib/ushuffle.h);
}

# the bundled library is the patched one
like slurp('ushufflelib/ushuffle.c'), qr/\(long long\) \(htablesize \* f\) % htablesize/,
    'bundled library has the hash overflow fix';

SKIP: {
    skip 'Test::Pod 1.00 is needed to check the POD syntax', 2
        unless eval { require Test::Pod; Test::Pod->VERSION(1.00); 1 };
    Test::Pod::pod_file_ok("$root/lib/Ushuffle.pm",          'POD syntax of Ushuffle');
    Test::Pod::pod_file_ok("$root/lib/Ushuffle/Shuffler.pod", 'POD syntax of Ushuffle::Shuffler');
}

done_testing;
