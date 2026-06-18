use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;
use File::Temp qw(tempfile);
use File::Spec;

my $define = "";
my $libs   = "";

if ($^O eq 'MSWin32') {
    $define = "-DHAS_WINHR";
} else {
    my $probe_c = <<'C';
#include <time.h>
int main(void) {
    struct timespec ts;
    return clock_gettime(CLOCK_MONOTONIC, &ts);
}
C

    my $has_cgt = 0;

    my ($fh, $c_file) = tempfile("probe_XXXXXX", SUFFIX => ".c", DIR => File::Spec->tmpdir);
    print $fh $probe_c;
    close $fh;

    my $exe = "$c_file.out";

    if (system("$Config{cc} $Config{ccflags} -o $exe $c_file $Config{ldflags} 2>/dev/null") == 0) {
        $has_cgt = 1;
        $libs = "";
    }
    elsif (system("$Config{cc} $Config{ccflags} -o $exe $c_file $Config{ldflags} -lrt 2>/dev/null") == 0) {
        $has_cgt = 1;
        $libs = "-lrt";
    }

    unlink $c_file, $exe, "$c_file.o";

    if ($has_cgt) {
        $define = "-DHAS_CLOCK_GETTIME";
    }
}

WriteMakefile(
    NAME         => 'Time::Nanos',
    VERSION_FROM => 'lib/Time/Nanos.pm',
    LIBS         => [$libs],
    DEFINE       => $define,
    ABSTRACT     => 'High resolution time via clock_gettime(CLOCK_MONOTONIC)',
    AUTHOR       => 'Author',
    LICENSE      => 'perl_5',
    PREREQ_PM    => {
        'Exporter' => 0,
        'XSLoader' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
);
