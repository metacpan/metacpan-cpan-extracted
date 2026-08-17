use strict;
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib $RealBin;
use lib "$RealBin/../lib";

use File::Spec;
use File::Temp qw(tempfile);
use HTTP::Headers::Fast;

use WebDyne;
use WebDyne::Request::Fake;
use WebDyne::Util ();


my ($fixture_fh, $fixture_fn)=tempfile('error_dump_uri_XXXX', DIR => $RealBin, SUFFIX => '.psp', UNLINK => 1);
print {$fixture_fh} "<start_html>\n!{! die('Bang !') !}\n__PERL__\n1;\n";
close($fixture_fh) || die "unable to close '$fixture_fn', $!";

WebDyne->init();

my $r=WebDyne::Request::Fake->new(
    filename   => $fixture_fn,
    noheader   => 1,
    headers_in => HTTP::Headers::Fast->new(),
);

my $uri=$r->uri();
ok($uri, 'fake uri() returns a value');
isa_ok($uri, 'URI');

my $uri_text=$uri->as_string();
ok(length($uri_text), 'fake uri stringifies');

WebDyne::Util::errclr();
WebDyne::Util::errnofatal(1);
WebDyne::Util::err('Bang !');
WebDyne::Util::errnofatal(0);
pass('seeded WebDyne error stack');

my $dump_uri=WebDyne::Util::errdump({
    URI  => $uri,
    Line => 1,
});
like($dump_uri, qr/Bang !|Bang/i, 'errdump with URI object returns error text');
like($dump_uri, qr/\Q$uri_text\E/, 'errdump stringifies URI object in diagnostic fields');

my $outer_accumulator='outer format accumulator';
{
    local $^A=$outer_accumulator;

    WebDyne::Util::errclr();
    WebDyne::Util::errnofatal(1);
    WebDyne::Util::err('Bang !');
    WebDyne::Util::errnofatal(0);

    my $dump_string=WebDyne::Util::errdump({
        URI  => $uri_text,
        Line => 1,
    });
    like($dump_string, qr/Bang !|Bang/i, 'errdump with URI string returns error text');
    is($^A, $outer_accumulator, 'errdump preserves outer format accumulator');
}

done_testing();
