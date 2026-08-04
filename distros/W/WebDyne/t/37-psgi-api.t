#  Pragma
#
use strict;
use warnings;


#  Test Harness
#
use Test::More;


#  Skip test if PSGI dependencies are unavailable
#
BEGIN {
    my @missing;
    for my $m (qw(Plack::Test Plack::Request Plack::Response)) {
        eval "require $m; 1" or push @missing, $m;
    }
    plan skip_all => "Skipping PSGI API test: missing " . join(", ", @missing)
        if @missing;
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
use Plack::Test;
use HTTP::Request::Common qw(GET);
use lib "$RealBin/../lib";


#  Load WebDyne modules we need
#
use WebDyne::PSGI;


#  Run tests
#
ok(${&main() || die 'main failed'} || 0);
done_testing();


#======================================================================================================================


sub main {

    my $root_dn=tempdir(CLEANUP => 1);

    my %page=(
        'api.psp' => <<'EOF',
<api handler=uppercase pattern="/api/uppercase/{user}/:id">
__PERL__
sub uppercase {
    my ($self, $match)=@_;
    return { user => uc($match->{user}), id => $match->{id} };
}
EOF
        'example/route.psp' => <<'EOF',
<api handler=route pattern="/example/route/{user}">
__PERL__
sub route {
    my ($self, $match)=@_;
    return { user => uc($match->{user}) };
}
EOF
        'normal.psp' => '<start_html>normal PSGI page</start_html>',
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

    ok(my $psgi_or=WebDyne::PSGI->new(root => $root_dn), 'build PSGI application');
    ok(my $app_cr=$psgi_or->to_app(), 'build PSGI app');
    ok(my $test_or=Plack::Test->create($app_cr), 'create PSGI test client');

    my $res=$test_or->request(GET('/api/uppercase/bob/42'));
    is($res->code(), 200, 'root API PSP returns HTTP 200');
    like($res->decoded_content() || '', qr/"user"\s*:\s*"BOB"/, 'root API route receives user');
    like($res->decoded_content() || '', qr/"id"\s*:\s*"42"/, 'root API route receives id');
    ok($psgi_or->{'API_fn'}{File::Spec->catfile($root_dn, 'api.psp')},
        'root API PSP is cached after discovery');

    $res=$test_or->request(GET('/example/route/bob'));
    is($res->code(), 200, 'nested API PSP returns HTTP 200');
    like($res->decoded_content() || '', qr/"user"\s*:\s*"BOB"/, 'nested API route receives user');

    $res=$test_or->request(GET('/normal.psp'));
    is($res->code(), 200, 'normal PSP request remains available');
    like($res->decoded_content() || '', qr/normal PSGI page/, 'normal PSP response is rendered');

    $res=$test_or->request(GET('/missing/path'));
    is($res->code(), 404, 'unmatched request remains not found');

    return \1;
}
