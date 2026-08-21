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


#  Skip test if PAGI dependencies are unavailable
#
BEGIN {
    unshift @INC, 't';
    require pagi_compat_helper;
    my $skip=pagi_compat_helper::pagi_skip_reason(qw(PAGI::Test::Client PAGI::Request PAGI::Response Future::AsyncAwait));
    plan skip_all => "Skipping PAGI API test: $skip" if $skip;
}


#  Skip any local config
#
BEGIN {
    $ENV{'WEBDYNE_CONF'}='.';
    $ENV{'WEBDYNE_ERROR_TEXT'}=1;
}


#  Modules we need
#
use FindBin qw($RealBin);
use File::Spec;
use File::Temp qw(tempdir);
use IO::File;
use lib "$RealBin/../lib";


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

    my %page=(
        'api.psp' => <<'EOF',
<api handler=uppercase pattern="/uppercase/{user}/:id">
__PERL__
sub uppercase {
    my ($self, $match)=@_;
    return { user => uc($match->{user}), id => $match->{id} };
}
EOF
        'example/route.psp' => <<'EOF',
<api handler=route pattern="/{user}">
__PERL__
sub route {
    my ($self, $match)=@_;
    return { user => uc($match->{user}) };
}
EOF
        'example/api.psp' => <<'EOF',
<api handler=uppercase pattern="/uppercase/{user}/:id">
<api handler=lowercase pattern="/lowercase/{user}/:id">
__PERL__
sub uppercase {
    my ($self, $match)=@_;
    return { user => uc($match->{user}), id => $match->{id} };
}
sub lowercase {
    my ($self, $match)=@_;
    return { user => lc($match->{user}), id => $match->{id} };
}
EOF
        'normal.psp' => '<start_html>normal PAGI page</start_html>',
    );

    for my $relative (keys %page) {
        my $filename=File::Spec->catfile($root_dn, split m{/}, $relative);
        my ($volume, $directory)=File::Spec->splitpath($filename);
        mkdir $directory if length($directory) && !-d $directory;
        ok(my $page_fh=IO::File->new($filename, O_WRONLY|O_CREAT|O_TRUNC),
            "create temporary page $relative");
        print {$page_fh} $page{$relative};
        $page_fh->close();
    }

    ok(my $pagi_or=WebDyne::PAGI->new(root => $root_dn), 'build PAGI application');
    ok(my $app_cr=$pagi_or->to_app(), 'build PAGI app');
    ok(my $test_or=PAGI::Test::Client->new(app => $app_cr), 'create PAGI test client');

    my $res=$test_or->get('/api/uppercase/bob/42');
    is($res->{'status'}, 200, 'root API PSP returns HTTP 200');
    like($res->{'body'} || '', qr/"user"\s*:\s*"BOB"/, 'root API route receives user');
    like($res->{'body'} || '', qr/"id"\s*:\s*"42"/, 'root API route receives id');
    ok($pagi_or->{'API_fn'}{File::Spec->catfile($root_dn, 'api.psp')},
        'root API PSP is cached after discovery');

    $res=$test_or->get('/api/uppercase/bob');
    is($res->{'status'}, 200, 'unmatched API route returns HTTP 200');
    is($res->{'body'} || '', '', 'unmatched API route sends an empty response');

    $res=$test_or->get('/example/route/bob');
    is($res->{'status'}, 200, 'nested API PSP returns HTTP 200');
    like($res->{'body'} || '', qr/"user"\s*:\s*"BOB"/, 'nested API route receives user');

    $res=$test_or->get('/example/api/uppercase/bob/42');
    is($res->{'status'}, 200, 'subdirectory API PSP with local route returns HTTP 200');
    like($res->{'body'} || '', qr/"user"\s*:\s*"BOB"/,
        'subdirectory API PSP local route receives user');
    like($res->{'body'} || '', qr/"id"\s*:\s*"42"/,
        'subdirectory API PSP local route receives id');

    $res=$test_or->get('/example/api/lowercase/BOB/42');
    is($res->{'status'}, 200, 'subdirectory API PSP second local route returns HTTP 200');
    like($res->{'body'} || '', qr/"user"\s*:\s*"bob"/,
        'subdirectory API PSP second local route receives user');

    $res=$test_or->get('/normal.psp');
    is($res->{'status'}, 200, 'normal PSP request remains available');
    like($res->{'body'} || '', qr/normal PAGI page/, 'normal PSP response is rendered');

    $res=$test_or->get('/missing/path');
    is($res->{'status'}, 404, 'unmatched request remains not found');

    return \1;
}
