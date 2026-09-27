use 5.020;
use strict;
use warnings;
use Test::More;
use JSON::PP ();
use WebDyne::Cloudflare::D1;
use WebDyne::Cloudflare::KV;
use WebDyne::Cloudflare::R2;

my $json_or=JSON::PP->new()->canonical()->allow_nonref();

foreach my $service (qw(D1 KV R2)) {
    my $class="WebDyne::Cloudflare::$service";
    my $blob_cr=$class->can('blob');
    my $scope_hr={extensions => {
        'webdyne.cloudflare.'.lc($service) => {
            version => 1, capability => 'test-capability', bindings => ['DB'],
        },
    }};
    my $service_or=$class->new(scope => $scope_hr, binding => 'DB');
    foreach my $bytes ('', '0', "\0\xff", $class) {
        is($blob_cr->($bytes)->wire_value()->{'base64'},
            $class->blob($bytes)->wire_value()->{'base64'}, "$service function/class blob agrees");
        is($service_or->blob($bytes)->wire_value()->{'base64'},
            $class->blob($bytes)->wire_value()->{'base64'}, "$service object/class blob agrees");
    }
    foreach my $bad_ref (undef, [], {}) {
        eval {$blob_cr->($bad_ref)};
        like($@, qr/defined byte string/, "$service rejects invalid blob input");
    }
    eval {$blob_cr->('one', 'two')};
    like($@, qr/exactly one/, "$service rejects excess blob arguments");
    eval {$class->blob("\x{100}")};
    like($@, qr/wide characters/, "$service rejects wide characters at construction");
    is($class->blob("\x{ff}")->wire_value()->{'base64'}, '/w==', "$service preserves Latin-1 bytes");

    foreach my $extensions_ref ([], 'bad') {
        eval {$class->new(scope => {extensions => $extensions_ref})};
        like($@, qr/has no .* capability/, "$service rejects malformed extensions");
    }
    my $extension_hr=$scope_hr->{'extensions'}{'webdyne.cloudflare.'.lc($service)};
    {
        local $extension_hr->{'bindings'}={};
        eval {$class->new(scope => $scope_hr)};
        like($@, qr/capability binding list/, "$service rejects malformed binding list");
    }
    {
        local $extension_hr->{'version'}='1junk';
        eval {$class->new(scope => $scope_hr)};
        like($@, qr/Unsupported .* protocol/, "$service rejects malformed version");
    }
    {
        no strict 'refs';
        local ${"$class\::HOST_CALL"}=sub {return '{}'};
        my $future_or=($service eq 'D1')
            ? $service_or->first('SELECT 1') : $service_or->get('key');
        my ($error_or)=$future_or->failure();
        isa_ok($error_or, "$class\::Error");
        is($error_or->name(), "${service}_PROTOCOL_ERROR", "$service detects missing response status");
    }
}

my $scope_hr={extensions => {'webdyne.cloudflare.d1' => {
    version => 1, capability => 'd1-test', bindings => ['DB'],
}}};
my $db_or=WebDyne::Cloudflare::D1->new(scope => $scope_hr);
my $row_hr={type => 'blob', base64 => 'AAH/', count => 0, empty => '', missing => undef};
{
    local $WebDyne::Cloudflare::D1::HOST_CALL=sub {
        my ($wire)=@_;
        my $request_hr=$json_or->decode($wire);
        my $result_ref=($request_hr->{'operation'} eq 'first')
            ? (exists($request_hr->{'column'}) ? {type => 'blob', base64 => 'AAH/'} : $row_hr)
            : ($request_hr->{'operation'} eq 'raw')
                ? [[{type => 'blob', base64 => 'AAH/'}, 0, '', undef]]
                : {results => [$row_hr], meta => {}, success => JSON::PP::true()};
        return $json_or->encode({ok => JSON::PP::true(), result => $result_ref});
    };
    is_deeply($db_or->first('SELECT type, base64')->get(), $row_hr,
        'first row with envelope-like column names remains a row');
    is_deeply($db_or->all('SELECT type, base64')->get()->{'results'}, [$row_hr],
        'all rows with envelope-like column names remain rows');
    is($db_or->prepare('SELECT payload')->first('payload')->get(), "\0\1\xff",
        'first column still decodes a blob');
    is_deeply($db_or->prepare('SELECT payload')->raw()->get(), [["\0\1\xff", 0, '', undef]],
        'raw preserves blob, zero, empty and NULL values');
}

foreach my $service (qw(D1 KV R2)) {
    my $class="WebDyne::Cloudflare::$service";
    my $scope_hr={extensions => {'webdyne.cloudflare.'.lc($service) => {
        version => 1, capability => 'unicode-test', bindings => ['DB'],
    }}};
    my $service_or=$class->new(scope => $scope_hr, binding => 'DB');
    my $request_hr;
    no strict 'refs';
    local ${"$class\::HOST_CALL"}=sub {
        $request_hr=$json_or->decode($_[0]);
        return '{"ok":true,"result":null}';
    };
    my $bytes="caf\xc3\xa9";
    my $text="caf\x{e9}";
    utf8::upgrade($text);
    if ($service eq 'D1') {
        $service_or->prepare("SELECT '$bytes'")->bind(0, $bytes)->first($bytes)->get();
        is($request_hr->{'sql'}, "SELECT '$text'", 'D1 SQL decodes UTF-8 bytes');
        is($request_hr->{'column'}, $text, 'D1 column decodes UTF-8 bytes');
        is_deeply($request_hr->{'params'}, [0, $text], 'D1 retains numeric and text parameters');
    }
    else {
        $service_or->put($bytes, 0)->get();
        is($request_hr->{'key'}, $text, "$service key decodes UTF-8 bytes");
        like($json_or->encode($request_hr), qr/"value":"0"/, "$service numeric body is text");
        $service_or->list(prefix => $bytes)->get() if ($service eq 'KV');
        is($request_hr->{'prefix'}, $text, 'KV prefix decodes UTF-8 bytes') if ($service eq 'KV');
        if ($service eq 'KV') {
            $service_or->put_json('key', {$bytes => [$bytes, 0, JSON::PP::false()]})->get();
            is_deeply($json_or->decode($request_hr->{'value'}),
                {$text => [$text, 0, JSON::PP::false()]}, 'KV JSON normalizes nested text and retains types');
        }
        my %opt=($service eq 'KV') ? (metadata => {$bytes => $bytes})
            : (custom_metadata => {$bytes => $bytes});
        $service_or->put('key', '', %opt)->get();
        my $name=($service eq 'KV') ? 'metadata' : 'custom_metadata';
        is_deeply($request_hr->{$name}, {$text => $text}, "$service metadata decodes UTF-8 bytes");
        is_deeply($opt{$name}, {$bytes => $bytes}, "$service leaves caller metadata unchanged");
    }
    my $future_or=($service eq 'D1') ? $service_or->first("SELECT '\xff'")
        : $service_or->get("\xff");
    ok($future_or->is_failed(), "$service rejects invalid UTF-8 before calling host");
}
my $cycle_ar=[];
push(@{$cycle_ar}, $cycle_ar);
eval {WebDyne::Cloudflare::json_value($cycle_ar)};
like($@, qr/circular reference/, 'cyclic metadata fails without recursing indefinitely');
@{$cycle_ar}=();
my $byte_key="caf\xc3\xa9";
my $text_key="caf\x{e9}";
utf8::upgrade($text_key);
eval {WebDyne::Cloudflare::json_value({$byte_key => 1, $text_key => 2})};
like($@, qr/duplicate UTF-8 keys/, 'normalization rejects colliding byte and character keys');
my $shared_hr={value => 0};
is_deeply(WebDyne::Cloudflare::json_value([$shared_hr, $shared_hr]),
    [{value => 0}, {value => 0}], 'shared acyclic metadata is accepted');
done_testing();
