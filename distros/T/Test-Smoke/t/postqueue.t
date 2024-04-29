#! perl -w
use strict;
use Test::More;

use File::Spec::Functions;
use File::Temp qw< tempdir >;
use JSON;

use Test::Smoke::PostQueue;

{
    my $base_dir = tempdir(CLEANUP => 1);
    my $adir = catdir($base_dir, "testprefix");
    mkdir($adir) or die "Cannot mkdir($adir): $!";

    my $poster = Test::Smoke::Poster::Dummy->new(
        smokedb_url => 'http://localhost/api/report',
        ddir        => $adir,
        jsnfile     => 'mktest.jsn',
        v           => 0,
    );

    my $qfile = catfile($base_dir, "testprefix.qfile");
    my $qrunner = Test::Smoke::PostQueue->new(
        qfile  => $qfile,
        adir   => $adir,
        poster => $poster,
        v      => 0,
    );
    isa_ok($qrunner, "Test::Smoke::PostQueue");

    prepare_archive($adir);
    prepare_queue($qfile);
    local $Test::Smoke::LogMixin::USE_TIMESTAMP = 0;
    open(my $out, '>', \my $outbuffer);
    my $old_out = select($out);

    $qrunner->handle();

    select($old_out);

    is($outbuffer, <<EOOUT, "Logfile ok");
Posted 7a29e8d2c80588346422b4b6b936e6f8b56a3af4 from queue: report_id = af4
Posted 69bc7167fa24b1e8d3f810ce465d84bdddf413f6 from queue: report_id = 3f6
Posted cd55125d69f5f698ef7cbdd650cda7d2e59fc388 from queue: report_id = 388
Posted 0c33882a943825845dde164b60900bf224b131cc from queue: report_id = 1cc
EOOUT

    open(my $qf, '<', $qfile) or die "Cannot open($qfile): $!";
    chomp(my @queue = <$qf>);
    close($qf);
    is_deeply(
        \@queue,
        [ 'is_not_real_8e29df142cfcefaa86725199d15b' ],
        "Queue has 1 item"
    );

    $qrunner->purge();

    undef($qf);
    open($qf, '<', $qfile) or die "Cannot open($qfile): $!";
    chomp(@queue = <$qf>);
    close($qf);
    is_deeply(
        \@queue,
        [ ],
        "Queue has no items"
    );

    my $qr2 = Test::Smoke::PostQueue->new();
    is($qr2, $qrunner, "Same object (singleton)");

}

done_testing();

sub prepare_queue {
    my ($qfile) = @_;
    open(my $fh, '>', $qfile) or die "Cannot create($qfile): $!";
    print {$fh} <<EOP;
7a29e8d2c80588346422b4b6b936e6f8b56a3af4
69bc7167fa24b1e8d3f810ce465d84bdddf413f6
cd55125d69f5f698ef7cbdd650cda7d2e59fc388
0c33882a943825845dde164b60900bf224b131cc
is_not_real_8e29df142cfcefaa86725199d15b
EOP
    close($fh);
}

sub prepare_archive {
    my ($adir) = @_;
    my @patch_levels = split(/\n/, <<EOP);
7a29e8d2c80588346422b4b6b936e6f8b56a3af4
69bc7167fa24b1e8d3f810ce465d84bdddf413f6
cd55125d69f5f698ef7cbdd650cda7d2e59fc388
0c33882a943825845dde164b60900bf224b131cc
b885e42dc2078e29df142cfcefaa86725199d15b
e772cf349a3609ba583f441d10e1e92c5e338377
f603e191e0bea582034a16f05909a56bcc05a564
51634b463845a03d4f22b9d23f6c5e2fb98af9c8
305697f3995f7ddfba2e200c5deb2e274e1136c0
18fa8a6f818cbe2838cfe9b1bfa0c5d9c311930c
EOP

    for my $pl (@patch_levels) {
        my $aname = catfile($adir, "jsn${pl}.jsn");
        if (open(my $fh, '>', $aname)) {
            print {$fh} qq/{"patch_level": "$pl"}/;
            close($fh);
        }
    }
}

package Test::Smoke::Poster::Dummy;
use warnings;
use strict;
use Test::Smoke::Util::LoadAJSON;

use base 'Test::Smoke::Poster::Base';

sub _post_data_api {
    my $self = shift;

    my $json = $self->get_json();
    my $data = JSON->new->utf8->allow_nonref->decode($json);

    return sprintf(qq/{"id": "%s" }/, substr($data->{patch_level}, -3, 3));
};

1;
