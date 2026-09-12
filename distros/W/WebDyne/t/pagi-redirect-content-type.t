use strict;
use warnings;
use Test::More;
BEGIN {
    unshift @INC, 't';
    require pagi_compat_helper;
    my $skip=pagi_compat_helper::pagi_skip_reason(qw(PAGI::Request PAGI::Response PAGI::SSE PAGI::WebSocket Future::AsyncAwait));
    plan skip_all => "Skipping PAGI redirect test: $skip" if $skip;
    $ENV{'WEBDYNE_CONF'}='.';
}
use File::Temp qw(tempdir);
use WebDyne::PAGI;
use Future;

my $temp_dn=tempdir(CLEANUP => 1);
my @case=(
    ['characters', 'text', pack('C*', 0xe2, 0x82, 0xac), undef],
    ['utf8_bytes', 'text', pack('C*', 0xe2, 0x82, 0xac), undef],
    ['binary', 'text', pack('C*', 0..255), 'application/octet-stream'],
    ['svg', 'text', '<svg xmlns="http://www.w3.org/2000/svg"/>', 'image/svg+xml'],
    ['text', 'text', 'hello', undef],
    ['html', 'html', '<b>hello</b>', undef],
    ['json', 'json', '{"ok":true}', undef],
);
foreach my $case_ar (@case) {
    my ($name, $type, $body, $mime)=@{$case_ar};
    open(my $page_fh, '>', "$temp_dn/$name.psp") || die $!;
    my $extra=$mime ? ", content_type => '$mime'" : '';
    my $body_expr=$name eq 'binary' ? "pack('C*', 0..255)" : "'$body'";
    $body_expr='chr(0x20ac)' if $name eq 'characters';
    $body_expr="pack('C*', 0xe2, 0x82, 0xac)" if $name eq 'utf8_bytes';
    print {$page_fh} "<html><body>BEFORE<perl handler/><p>AFTER</p></body></html>\n__PERL__\nsub handler { my \$self=shift(); return \$self->redirect($type => $body_expr$extra); }\n";
    close($page_fh);
}
my $app_cr=WebDyne::PAGI->new(root => $temp_dn, static => 0)->to_app();
foreach my $case_ar (@case) {
    my ($name, $type, $body, $mime)=@{$case_ar};
    my @event;
    $app_cr->(
        {type => 'http', method => 'GET', path => "/$name.psp", headers => [], query_string => ''},
        sub { Future->done({type => 'http.request', body => '', more => 0}) },
        sub { push @event, shift(); Future->done() },
    )->get();
    my %header=map { @{$_} } @{$event[0]->{'headers'}};
    my $actual=join('', map { $_->{'body'} || '' } grep { $_->{'type'} eq 'http.response.body' } @event);
    is($event[0]->{'status'}, 200, "$name status");
    is($actual, $body, "$name exact body without HTML wrapper");
    my %expected=(text => 'text/plain', html => 'text/html', json => 'application/json');
    like($header{'content-type'}, qr/^\Q@{[$mime || $expected{$type}]}\E(?:;|$)/, "$name content type");
    is($header{'content-length'}, length($body), "$name content length");
}
done_testing();
