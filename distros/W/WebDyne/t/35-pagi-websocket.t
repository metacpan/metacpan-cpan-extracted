#  Pragma
#
use strict;
use warnings;


#  Test Harness
#
use Test::More;
use FindBin qw($RealBin);
use lib $RealBin;
use pagi_compat_helper qw(pagi_skip_reason);


#  Skip test if missing modules
#
BEGIN {
    unshift @INC, 't';
    require pagi_compat_helper;
    my $skip=pagi_compat_helper::pagi_skip_reason(qw(PAGI::Test::Client PAGI::Request PAGI::Response PAGI::SSE PAGI::WebSocket Future::AsyncAwait));
    plan skip_all => "Skipping PAGI WebSocket test: $skip" if $skip;
}


#  Skip any local config
#
BEGIN {
    $ENV{'WEBDYNE_CONF'}='.';
    $ENV{'WEBDYNE_ERROR_TEXT'}=1;
}


#  Modules we need
#
use File::Spec;
use File::Temp qw(tempdir);
use IO::File;


#  Load WebDyne modules we need
#
use WebDyne::PAGI;


#  Run tests
#
ok(${&main() || die 'main failed'} || 0);
done_testing();


#======================================================================================================================


sub main {

    my $root_dn=tempdir(CLEANUP => 1);
    my $page_fn=File::Spec->catfile($root_dn, 'ws.psp');
    ok(my $page_fh=IO::File->new($page_fn, O_WRONLY|O_CREAT|O_TRUNC), 'create temporary WebSocket page');
    print {$page_fh} <<'EOF';
<start_html ws>
__PERL__
use Future::AsyncAwait;

async sub ws {
    my $self=shift();
    my $r=$self->r();
    my ($receive, $send)=map { $r->{$_} } qw(receive send);

    await $send->({
        type => 'websocket.accept',
    });

    while (1) {
        my $event=await $receive->();
        last if $event->{type} eq 'websocket.disconnect';

        if (defined $event->{text}) {
            await $send->({
                type => 'websocket.send',
                text => 'echo:' . $event->{text},
            });
        }
    }
}
EOF
    $page_fh->close();

    ok(my $app_cr=WebDyne::PAGI->new(root => $root_dn)->to_app(), 'build PAGI app');
    ok(my $test_or=PAGI::Test::Client->new(app => $app_cr), 'create PAGI test client');

    $test_or->websocket('/ws.psp', sub {
        my $ws=shift();

        ok(!$ws->is_closed(), 'WebSocket connection is accepted and open');
        $ws->send_text('hello');
        is($ws->receive_text(), 'echo:hello', 'WebSocket echoes text payload');

        $ws->close(1000, 'done');
        ok($ws->is_closed(), 'WebSocket connection closes cleanly');
        is($ws->close_code(), 1000, 'WebSocket close code is preserved');
    });

    return \1;
}
