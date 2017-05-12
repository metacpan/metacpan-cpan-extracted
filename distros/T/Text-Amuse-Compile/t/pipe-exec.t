use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp;
use IO::Pipe;
use Cwd;

if ($ENV{TEST_WITH_LATEX}) {
    plan tests => 4; # 3 success, 1 failure
}
else {
    plan skip_all => "No test needed";
    exit;
}

my $dir = File::Temp->newdir(CLEANUP => 1);

my $home = getcwd;
chdir $dir->dirname or die $!;

open (my $fh, '>:encoding(utf-8)', 'pippo.tex');
print $fh <<'EOF';
\documentclass{article}
\begin{document}
Hello world!
\end{document}
EOF
close $fh;

open ($fh, '>:encoding(utf-8)', 'broken.tex');
print $fh <<'EOF';
\documentclass{article}
\beginxxxx{document}
Hello world!
\end{document}
EOF
close $fh;

foreach my $source (qw/pippo.tex broken.tex/) {
    for my $i (1..3) {
        diag "Run $source $i\n";
        my $pipe = IO::Pipe->new;
        # parent swallows the output
        $pipe->reader(xelatex => '-interaction=nonstopmode', $source);
        $pipe->autoflush(1);
        my $shitout;
        while (<$pipe>) {
            my $line = $_;
            if ($line =~ m/^[!#]/) {
                $shitout++;
            }
            if ($shitout) {
                diag "PRINT OUT: " . $line;
            }
        }
        wait;
        my $exit_code = $? >> 8;
        if ($source eq 'pippo.tex') {
            is($exit_code, 0);
        }
        else {
            ok($exit_code, "$source run $i ok");
        }
        if ($exit_code != 0) {
            diag "XeLaTeX compilation failed with exit code $exit_code\n";
            last;
        }
    }
}
chdir $home;
