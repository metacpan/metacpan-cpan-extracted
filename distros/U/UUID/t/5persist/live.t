#
# make sure persist really writes where its supposed to.
#
use strict;
use warnings;
use Test::More;
use MyNote;
use File::Spec ();
use File::Temp ();
use Config;

use vars qw(@OPTS $TMPDIR $STATEFILE);

BEGIN {
    my $tdo = File::Temp->newdir(CLEANUP => 0);
    $TMPDIR = $tdo->dirname;

    my $tfo = File::Temp->new(
        TEMPLATE => 'UUID.state.XXXXXXXX',
        DIR      => $TMPDIR,
        UNLINK   => 0,
    );
    $STATEFILE = $tfo->filename;

    @OPTS = ":persist=$STATEFILE";
}

use UUID @OPTS;

ok 1, 'loaded';

ok -d $TMPDIR,    'tempdir exists';
ok -f $STATEFILE, 'state file exists';

my $uu = UUID::uuid1();
ok 1,                          'got something';
is length($uu), 36,            'looks like uuid';
like $uu, qr/^[-0-9a-f]{36}$/, 'smells like uuid';

# does the content look reasonable?
{
    open my $fh, '<', $STATEFILE or die "open: $STATEFILE: $!";
    my $state = <$fh>;
    note $state;
    is length($state), 56, 'content length';
    like $state, qr/clock:\s+[0-9a-f]{4}\s/,             'clock field';
    like $state, qr/tv:\s+[0-9a-f]{16}\s+[0-9a-f]{8}\s/, 'tv field';
    like $state, qr/adj:\s+[0-9a-f]{8}/,                 'adj field';
}

# do this so UUID closes state file,
# thus allowing Win32 to unlink it.
UUID::_persist(undef);
unlink $STATEFILE;
rmdir  $TMPDIR;

done_testing;
