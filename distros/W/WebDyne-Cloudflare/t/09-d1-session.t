use 5.020;
use strict;
use warnings;
use Test::More;
use JSON::PP ();
use WebDyne::Cloudflare::D1;

my $json_or=JSON::PP->new()->allow_nonref();
my $extension_hr={version => 1, capability => 'session-capability', bindings => ['DB'], session_bindings => ['DB']};
my $db_or=WebDyne::Cloudflare::D1->new(scope => {extensions => {'webdyne.cloudflare.d1' => $extension_hr}});
my @request;
my $count=0;
local $WebDyne::Cloudflare::D1::HOST_CALL=sub {
    my ($wire)=@_;
    my $request_hr=$json_or->decode($wire);
    push(@request, $request_hr);
    my $operation=$request_hr->{'operation'};
    my $result_ref=$operation eq 'with_session' ? 'session-'.++$count
        : $operation eq 'get_bookmark' ? undef
        : $operation eq 'first' ? {value => 7}
        : $operation eq 'raw' ? [[7]]
        : {success => JSON::PP::true(), meta => {served_by_primary => JSON::PP::false()}, results => []};
    $result_ref=[$result_ref] if ($operation eq 'batch');
    return $json_or->encode({ok => JSON::PP::true(), result => $result_ref});
};
foreach my $constraint ('first-primary', 'first-unconstrained', 'bookmark-old') {
    my $session_or=$db_or->with_session($constraint)->get();
    isa_ok($session_or, 'WebDyne::Cloudflare::D1::Session');
    is($request[-1]{'constraint'}, $constraint, 'constraint preserved');
    is($session_or->binding(), 'DB', 'binding inherited');
    is($session_or->get_bookmark()->get(), undef, 'null bookmark becomes undef');
    my $id=$request[-1]{'session'};
    $session_or->run('SELECT ?1', 7)->get();
    is($request[-1]{'session'}, $id, 'query retains session identity');
    is_deeply($request[-1]{'params'}, [7], 'bound values retained');
    is_deeply($session_or->first('SELECT 7')->get(), {value => 7}, 'first works');
    is_deeply($session_or->prepare('SELECT 7')->raw()->get(), [[7]], 'raw works');
    $session_or->all('SELECT 7')->get();
    is($request[-1]{'operation'}, 'run', 'all uses run result');
    $session_or->batch([$session_or->prepare('SELECT 7')])->get();
    is($request[-1]{'session'}, $id, 'batch retains session identity');
    my $before=scalar(@request);
    ok($session_or->batch([$db_or->prepare('SELECT 7')])->is_failed(), 'parent statement rejected');
    ok($db_or->batch([$session_or->prepare('SELECT 7')])->is_failed(), 'session statement rejected by parent');
    ok($session_or->with_session()->is_failed(), 'nested session rejected');
    is(scalar(@request), $before, 'invalid operations do not cross host');
}
my $first_or=$db_or->with_session()->get();
is($request[-1]{'constraint'}, 'first-unconstrained', 'default mode matches Cloudflare');
my $second_or=$db_or->with_session()->get();
ok($first_or->batch([$second_or->prepare('SELECT 1')])->is_failed(), 'different session statement rejected');
foreach my $bad_ref (undef, '', {}, []) {
    ok($db_or->with_session($bad_ref)->is_failed(), 'invalid constraint rejected');
}
$db_or->run('SELECT 1')->get();
ok(!exists($request[-1]{'session'}), 'ordinary database queries unchanged');
my $old_or=WebDyne::Cloudflare::D1->new(scope => {extensions => {'webdyne.cloudflare.d1' => {%{$extension_hr}, session_bindings => []}}});
ok($old_or->with_session()->is_failed(), 'old host rejected clearly');
foreach my $bad_ref (undef, '', {}, []) {
    local $WebDyne::Cloudflare::D1::HOST_CALL=sub { return $json_or->encode({ok => 1, result => $bad_ref}) };
    my ($error_or)=$db_or->with_session()->failure();
    isa_ok($error_or, 'WebDyne::Cloudflare::D1::Error');
}
{
    local $WebDyne::Cloudflare::D1::HOST_CALL=sub { return $json_or->encode({ok => 1, result => 'bookmark-next'}) };
    is($first_or->get_bookmark()->get(), 'bookmark-next', 'bookmark string preserved');
}
done_testing();
