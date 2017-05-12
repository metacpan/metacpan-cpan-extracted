use strict;
use warnings;
use File::Spec;
use Test::More tests => 5;

SKIP: {
    my @expect = (
        qr{^1\.\.4$},
        qr{^not\s+ok\s+1\s*$},
        qr{^ok\s+2\s+(?:-\s+)?this\s+has\s+a\s+message\s*$},
        qr{^ok\s+3\s+(?:-\s+)?this\s+also\s+has\s+a\s+message\s*$},
        qr{^not\s+ok\s+4\s*$}
    );

    # Hide diagnostics from nested failures. Of course this will also
    # hide any diagnostics /we/ emit...
    open STDERR, '>', '/dev/null'
      or skip "No /dev/null ($!)" => scalar @expect;

    open my $pipe, '-|', $^X, File::Spec->catfile( 't', 'fail.tt' )
      or die "Can't run fail.tt ($!)";
    my $line = 0;
    while ( <$pipe> ) {
        chomp;
        like $_, shift @expect, "got line " . ( ++$line ) . " OK";
    }
    close $pipe;
}
