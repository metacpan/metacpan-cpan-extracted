#!/bin/perl
#
#  Regression test for request-path containment in PSGI/PAGI adapters
#
use strict qw(vars);
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use lib $RealBin;
use pagi_compat_helper qw(pagi_skip_reason);

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

my $tmp_dn=tempdir(CLEANUP => 1);
my $document_root=File::Spec->catdir($tmp_dn, 'sandbox', 'site', 'root');
my $outside_psp_fn=File::Spec->catfile($tmp_dn, 'sandbox', 'escape.psp');
my $outside_dir_index_fn=File::Spec->catfile($tmp_dn, 'sandbox', 'escape_dir', 'index.psp');
my $inside_psp_fn=File::Spec->catfile($document_root, 'inside.psp');

make_path($document_root);
make_path(dirname($outside_psp_fn));
make_path(dirname($outside_dir_index_fn));

write_file($outside_psp_fn, "<start_html>outside</start_html>\n");
write_file($outside_dir_index_fn, "<start_html>outside dir</start_html>\n");
write_file($inside_psp_fn, "<start_html>inside</start_html>\n");

SKIP: {
    skip 'Skipping PSGI traversal adapter test: missing PSGI modules', 4
        unless eval { require WebDyne::Request::PSGI; 1 };

    require_ok('WebDyne::Request::PSGI');

    my $safe_psgi_r=WebDyne::Request::PSGI->new(
        document_root => $document_root,
        env           => { PATH_INFO => '/inside.psp' },
    );
    ok(path_is_under_root($safe_psgi_r->filename(), $document_root), 'PSGI in-root request stays under document_root');

    my $traversal_psgi_r=WebDyne::Request::PSGI->new(
        document_root => $document_root,
        env           => { PATH_INFO => '/../../escape.psp' },
    );
    ok(!defined($traversal_psgi_r->filename()) || path_is_under_root($traversal_psgi_r->filename(), $document_root),
        'PSGI direct .psp traversal is contained or rejected');

    my $dir_traversal_psgi_r=WebDyne::Request::PSGI->new(
        document_root    => $document_root,
        document_default => 'index.psp',
        env              => { PATH_INFO => '/../../escape_dir/' },
    );
    ok(!defined($dir_traversal_psgi_r->filename()) || path_is_under_root($dir_traversal_psgi_r->filename(), $document_root),
        'PSGI directory traversal with default document is contained or rejected');
}

SKIP: {
    my $pagi_skip=pagi_skip_reason(qw(PAGI::Request));
    skip "Skipping PAGI traversal adapter test: $pagi_skip", 4
        if $pagi_skip;
    skip "Skipping PAGI traversal adapter test: $@", 4
        unless eval { require WebDyne::Request::PAGI; 1 };

    require_ok('WebDyne::Request::PAGI');

    my $safe_pagi_r=WebDyne::Request::PAGI->new(
        document_root => $document_root,
        req           => bless({ path => '/inside.psp' }, 'WebDyne::Test::PAGIReq'),
    );
    ok(path_is_under_root($safe_pagi_r->filename(), $document_root), 'PAGI in-root request stays under document_root');

    my $traversal_pagi_r=WebDyne::Request::PAGI->new(
        document_root => $document_root,
        req           => bless({ path => '/../../escape.psp' }, 'WebDyne::Test::PAGIReq'),
    );
    ok(!defined($traversal_pagi_r->filename()) || path_is_under_root($traversal_pagi_r->filename(), $document_root),
        'PAGI direct .psp traversal is contained or rejected');

    my $dir_traversal_pagi_r=WebDyne::Request::PAGI->new(
        document_root    => $document_root,
        document_default => 'index.psp',
        req              => bless({ path => '/../../escape_dir/' }, 'WebDyne::Test::PAGIReq'),
    );
    ok(!defined($dir_traversal_pagi_r->filename()) || path_is_under_root($dir_traversal_pagi_r->filename(), $document_root),
        'PAGI directory traversal with default document is contained or rejected');
}

done_testing();


sub path_is_under_root {

    my ($fn, $document_root)=@_;
    my $resolved_fn=abs_path($fn) || return 0;
    my $resolved_root=abs_path($document_root) || return 0;
    return 1 if $resolved_fn eq $resolved_root;
    return index($resolved_fn, "${resolved_root}/") == 0 ? 1 : 0;

}


sub write_file {

    my ($fn, $data)=@_;
    open(my $fh, '>', $fn) || die "unable to open '$fn' for write, $!";
    print {$fh} $data;
    close($fh) || die "unable to close '$fn', $!";

}


package WebDyne::Test::PAGIReq;

sub path {
    return shift()->{'path'};
}
