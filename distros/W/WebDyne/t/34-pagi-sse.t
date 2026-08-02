#  Pragma
#
use strict;
use warnings;


#  Test Harness
#
use Test::More;


#  Skip test if missing modules
#
BEGIN {
    my @missing;
    for my $m (qw(PAGI::Test::Client PAGI::Request PAGI::Response PAGI::SSE PAGI::WebSocket Future::AsyncAwait)) {
        eval "require $m; 1" or push @missing, $m;
    }
    if (@missing) {
        plan skip_all => "Skipping PAGI SSE test: missing " . join(", ", @missing);
    }
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
    my $page_fn=File::Spec->catfile($root_dn, 'sse.psp');
    ok(my $page_fh=IO::File->new($page_fn, O_WRONLY|O_CREAT|O_TRUNC), 'create temporary SSE page');
    print {$page_fh} <<'EOF';
<start_html sse>
__PERL__
use Future::AsyncAwait;
use HTTP::Status qw(HTTP_OK);

async sub sse {
    my $self=shift();
    my $sse_or=$self->r()->sse();
    await $sse_or->start(
        status  => HTTP_OK,
        headers => [
            ['Content-Type' => 'text/event-stream'],
            ['Cache-Control' => 'no-cache'],
        ],
    );
    await $sse_or->send_event(event => 'tick', data => 'alpha');
    $sse_or->close();
}
EOF
    $page_fh->close();

    ok(my $app_cr=WebDyne::PAGI->new(root => $root_dn)->to_app(), 'build PAGI app');
    ok(my $test_or=PAGI::Test::Client->new(app => $app_cr), 'create PAGI test client');

    $test_or->sse('/sse.psp', sub {
        my $sse=shift();

        is($sse->{'status'}, 200, 'SSE transport returns HTTP 200');
        my $headers_ar=$sse->{'headers'} || [];
        ok(
            scalar(grep {
                lc($_->[0]) eq 'content-type' && $_->[1] =~ m{text/event-stream}i
            } @{$headers_ar}),
            'SSE transport advertises text/event-stream'
        );

        my $event=$sse->receive_event();
        is($event->{'event'}, 'tick', 'SSE event name is correct');
        is($event->{'data'}, 'alpha', 'SSE event payload is correct');
    });

    return \1;
}
