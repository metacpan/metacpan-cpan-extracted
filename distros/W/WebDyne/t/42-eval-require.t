#!/bin/perl
#
#  Direct eval_require regression tests.
#
use strict qw(vars);
use warnings;

BEGIN {
    $ENV{'WEBDYNE_CONF'}='.';
    $ENV{'WEBDYNE_HEAD_INSERT'}=0;
}

use Test::More tests => 4;
use File::Temp qw(tempdir);
use File::Spec;
use Fcntl qw(:DEFAULT);
use IO::File;
use IO::String;
use WebDyne;
use WebDyne::Request::Fake;

my $wd=bless {_inode => 'EvalRequireTest'}, 'WebDyne';
ok(
    $wd->eval_require('Digest::SHA', {import => 'sha256_hex'}),
    'valid module require still succeeds'
);

my $temp_dn=tempdir(CLEANUP => 1);
my $require_fn=File::Spec->catfile($temp_dn, q[quote'file.pm]);
write_file(
    $require_fn,
    <<'END_PERL'
sub quoted_file {
    return 'quoted local require loaded';
}
1;
END_PERL
);

my $page_fn=File::Spec->catfile($temp_dn, 'quoted_require.psp');
write_file(
    $page_fn,
    <<'END_PSP'
<start_html>
<perl require="quote'file.pm" handler="quoted_file"/>
END_PSP
);

like(
    ${render($page_fn)},
    qr/quoted local require loaded/,
    'local require filename containing a quote is escaped and loaded'
);

my $marker='WebDyne::EvalRequireInjection::hit';
{
    no strict 'refs';
    ${$marker}=0;
}

ok(
    !$wd->eval_require(q[strict; $WebDyne::EvalRequireInjection::hit=1; #], {}),
    'invalid module require string is rejected'
);

{
    no strict 'refs';
    is(${$marker}, 0, 'invalid module require string was not evaluated');
}


sub write_file {

    my ($fn, $data)=@_;
    my $fh=IO::File->new($fn, O_WRONLY | O_CREAT | O_TRUNC) ||
        die "unable to open $fn for writing, $!";
    print {$fh} $data;
    $fh->close() ||
        die "unable to close $fn, $!";

}


sub render {

    my $srce_fn=shift();
    my $html;
    my $html_fh=IO::String->new($html);
    my $r=WebDyne::Request::Fake->new(
        filename => $srce_fn,
        select   => $html_fh,
        noheader => 1
    );
    defined(WebDyne->handler($r)) ||
        die 'render error';
    $r->DESTROY();
    $html_fh->close();
    return \$html;

}
