#
# make sure persist really writes where its supposed to.
#
use strict;
use warnings;
use Test::More;
use MyNote;
use Config;
use File::Spec ();
use File::Temp ();

use vars qw(@OPTS $TMPDIR $TARG $FULL);

BEGIN {
    my $eummh = File::Spec->catfile(qw(ulib EUMM.h));
    open my $fh, '<', $eummh or die "open: $eummh: $!";
    my $conf = join '', <$fh>;
    return 1 if $conf =~ /define HAVE_SYMLINK/;
    plan skip_all => 'no symlinks';
}

BEGIN {
    $TMPDIR = File::Temp::tempdir(
        'asserttestXXXXXXXX',
        DIR     => File::Spec->curdir(),
        CLEANUP => 1,
    );
    ok -d $TMPDIR, 'tmpdir exists';

    $TARG = 'foo.txt';
    $FULL = File::Spec->catdir($TMPDIR, $TARG);

    my $newfile = File::Spec->catfile(
        File::Spec->curdir(), $TMPDIR, 'state.txt'
    );

    symlink $TARG, $newfile;
    ok -l $newfile, 'symlink exists';

    @OPTS = ":persist=$newfile";
}

use UUID @OPTS;

ok 1, 'loaded';

my $uu = UUID::uuid1();
# is it a uuid?
is length($uu), 36, 'uuid length';
like $uu, qr/^[-0-9a-f]{36}$/, 'uuid looks ok';

# is the target in the tmpdir?
ok !-e $FULL, 'target exists';

done_testing;
