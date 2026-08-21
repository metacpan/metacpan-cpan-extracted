#!/bin/perl
#
#  Wrapper-level traversal regression coverage for PSGI/PAGI
#
use strict qw(vars);
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use lib $RealBin;
use pagi_compat_helper qw(pagi_skip_reason);

use File::Temp qw(tempdir tempfile);
use File::Path qw(make_path);
use File::Spec;


my $tmp_dn=tempdir(CLEANUP => 1);
my $document_root=File::Spec->catdir($tmp_dn, 'sandbox', 'site', 'root');
make_path($document_root);
make_path(File::Spec->catdir($tmp_dn, 'sandbox', 'escape_dir'));

write_file(File::Spec->catfile($document_root, 'app.psp'), "<start_html>inside\n");
write_file(File::Spec->catfile($tmp_dn, 'sandbox', 'escape.psp'), "<start_html>outside\n");
write_file(File::Spec->catfile($tmp_dn, 'sandbox', 'escape_dir', 'index.psp'), "<start_html>outside_dir\n");


SKIP: {
    eval { require WebDyne::PSGI; 1 } or skip("Skipping PSGI wrapper traversal test: $@", 6);

    my ($input_fh)=tempfile();
    my $app_cr=WebDyne::PSGI->new(root => $document_root, index => 'index.psp')->to_app();

    my $inside_res=run_psgi_app($app_cr, '/app.psp', $input_fh);
    is($inside_res->[0], 200, 'PSGI wrapper serves in-root request');
    like(join('', @{$inside_res->[2]}), qr/inside/, 'PSGI wrapper returns in-root body');

    my $file_res=run_psgi_app($app_cr, '/../../escape.psp', $input_fh);
    is($file_res->[0], 404, 'PSGI wrapper rejects direct traversal request');
    unlike(join('', @{$file_res->[2]}), qr/outside/, 'PSGI wrapper does not leak direct traversal body');

    my $dir_res=run_psgi_app($app_cr, '/../../escape_dir/', $input_fh);
    is($dir_res->[0], 404, 'PSGI wrapper rejects directory traversal request');
    unlike(join('', @{$dir_res->[2]}), qr/outside_dir/, 'PSGI wrapper does not leak default-document traversal body');
}


SKIP: {
    my $pagi_skip=pagi_skip_reason(qw(PAGI::Request PAGI::Response PAGI::Test::Client PAGI::SSE PAGI::WebSocket Future::AsyncAwait));
    skip "Skipping PAGI wrapper traversal test: $pagi_skip", 5
        if $pagi_skip;
    eval { require WebDyne::PAGI; require PAGI::Test::Client; 1 } or skip("Skipping PAGI wrapper traversal test: $@", 5);

    my $app_cr=WebDyne::PAGI->new(root => $document_root, index => 'index.psp')->to_app();
    my $test_or=PAGI::Test::Client->new(app => $app_cr);

    my $inside_res=$test_or->get('/app.psp');
    is($inside_res->{'status'}, 200, 'PAGI wrapper serves in-root request');
    like($inside_res->{'body'}, qr/inside/, 'PAGI wrapper returns in-root body');

    my $file_res=$test_or->get('/../../escape.psp');
    like($file_res->{'body'}, qr/Not Found/, 'PAGI wrapper reports not found for direct traversal');
    unlike($file_res->{'body'}, qr/outside/, 'PAGI wrapper does not leak direct traversal body');

    my $dir_res=$test_or->get('/../../escape_dir/');
    unlike($dir_res->{'body'}, qr/outside_dir/, 'PAGI wrapper does not leak default-document traversal body');
}


done_testing();


sub run_psgi_app {

    my ($app_cr, $path, $input_fh)=@_;
    seek($input_fh, 0, 0);
    return $app_cr->({
        REQUEST_METHOD    => 'GET',
        PATH_INFO         => $path,
        SCRIPT_NAME       => '',
        SERVER_NAME       => 'localhost',
        SERVER_PORT       => 80,
        'psgi.version'    => [1, 1],
        'psgi.url_scheme' => 'http',
        'psgi.input'      => $input_fh,
        'psgi.errors'     => *STDERR,
        'psgi.multithread' => 0,
        'psgi.multiprocess' => 0,
        'psgi.run_once'     => 1,
        'psgi.streaming'    => 0,
        'psgi.nonblocking'  => 0,
    });

}


sub write_file {

    my ($fn, $data)=@_;
    open(my $fh, '>', $fn) || die "unable to open '$fn' for write, $!";
    print {$fh} $data;
    close($fh) || die "unable to close '$fn', $!";

}
