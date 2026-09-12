use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
BEGIN {
    my @missing;
    foreach my $module (qw(Plack::Builder Plack::Request Plack::Response Plack::Test)) {
        eval "require $module; 1" || push @missing, $module;
    }
    plan skip_all => 'Skipping PSGI tests: missing '.join(', ', @missing) if @missing;
    $ENV{'WEBDYNE_CONF'}='.';
}
use WebDyne::PSGI;
use Plack::Test;
use HTTP::Request;

my $root_dn=tempdir(CLEANUP => 1);
my @case=(
    ['wide', 'chr(0x20ac)', pack('C*', 0xe2, 0x82, 0xac)],
    ['encoded', "pack('C*', 0xe2, 0x82, 0xac)", pack('C*', 0xe2, 0x82, 0xac)],
    ['binary', "pack('C*', 0..255)", pack('C*', 0..255)],
    ['ascii', "'hello'", 'hello'],
    ['zero', "'0'", '0'],
    ['empty', "''", ''],
);
foreach my $case_ar (@case) {
    my ($name, $expression, $expected)=@{$case_ar};
    open(my $page_fh, '>', "$root_dn/$name.psp") || die $!;
    print {$page_fh} "<perl handler/>\n__PERL__\nsub handler { my \$self=shift(); return \$self->redirect(text => $expression); }\n";
    close($page_fh) || die $!;
}
my $app_cr=WebDyne::PSGI->new(root => $root_dn)->to_app();
my $test_or=Plack::Test->create($app_cr);
foreach my $case_ar (@case) {
    my ($name, undef, $expected)=@{$case_ar};
    my $response_or=$test_or->request(HTTP::Request->new(GET => "http://localhost/$name.psp"));
    is($response_or->code(), 200, "$name status");
    is($response_or->content(), $expected, "$name exact bytes");
    is($response_or->header('Content-Length'), length($expected), "$name byte length");
    ok(!utf8::is_utf8($response_or->content()), "$name unflagged byte body");
}
done_testing();
