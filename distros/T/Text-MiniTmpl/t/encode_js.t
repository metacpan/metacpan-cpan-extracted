use warnings;
use strict;
use utf8;
use open qw( :std :utf8 );
use Test::More;

use Text::MiniTmpl qw( render encode_js encode_js_data );
use JSON::XS qw( decode_json );
use Path::Tiny qw( tempfile );

my $JS_DUMP = '[a];'; # append this to rendered template to dump result
my $JSVER = `node -v 2>&1`;
plan skip_all => 'Node.js not detected' if !$JSVER || $JSVER !~ /\bv(\d+\.\d+)/ms;
diag "Node.js version: $JSVER";
my $JS = 'node -p 2>&1';


sub eval_js {
    my $js  = render(@_);
    my $tmp = tempfile();
    $tmp->spew_utf8("$js $JS_DUMP");
    my $out = `$JS < $tmp`;
    my $JS_STR_S = qr/'[^'\\]*(?:\\.[^'\\]*)*'/ms;
    my $JS_STR_D = qr/"[^"\\]*(?:\\.[^"\\]*)*"/ms;
    # check is output well-formed
    die $out if $out !~ /\A[^'"]*(?:(?:$JS_STR_S|$JS_STR_D)[^'"]*)*\z/ms;
    # convert hash keys to JSON strings
    1 while $out =~ s/\G([^'"]*?(?:(?:$JS_STR_S|$JS_STR_D)[^'"]*?)*?[{,]\s*)(\w+):/$1"$2":/msg;
    # convert single-quoted strings to JSON strings
    1 while $out =~ s/\G([^'"]*(?:(?:$JS_STR_D)[^'"]*)*)'([^'\\]*(?:\\.[^'\\]*)*)'/
        my ($pfx, $s) = ($1, $2);
        $s =~ s{\G([^"\\]*(?:\\.[^"\\]*)*)"}{$1\\"}msg;
        $s =~ s{\G([^\\]*(?:\\[^'][^\\]*)*)\\'}{$1'}msg;
        "$pfx\"$s\"";
        /msge;
    return eval { decode_json($out) } || $out;
}


is_deeply eval_js('t/tmpl/encode_js_number.txt', number=>0),
    [0], 'number: 0';
is_deeply eval_js('t/tmpl/encode_js_number.txt', number=>1),
    [1], 'number: 1';
is_deeply eval_js('t/tmpl/encode_js_number.txt', number=>+1),
    [1], 'number: +1';
is_deeply eval_js('t/tmpl/encode_js_number.txt', number=>"+1"),
    [1], 'number: "+1"';
is_deeply eval_js('t/tmpl/encode_js_number.txt', number=>-1),
    [-1], 'number: -1';
is_deeply eval_js('t/tmpl/encode_js_number.txt', number=>0.010),
    [0.010], 'number: 0.010';
is_deeply eval_js('t/tmpl/encode_js_number.txt', number=>-0.010),
    [-0.010], 'number: -0.010';
is_deeply eval_js('t/tmpl/encode_js_number.txt', number=>1e30),
    [1e30], 'number: 1e30';
is_deeply eval_js('t/tmpl/encode_js_number.txt', number=>1e-30),
    [1e-30], 'number: 1e-30';
like render('t/tmpl/encode_js_number.txt', number=>0777),
    qr/511/ms, 'octal->decimal number';
like render('t/tmpl/encode_js_number.txt', number=>0xFF),
    qr/255/ms, 'hex->decimal number';
like render('t/tmpl/encode_js_number.txt', number=>'0777'),
    qr/0777/ms, 'str->octal number';
like render('t/tmpl/encode_js_number.txt', number=>'0xFF'),
    qr/0xFF/ms, 'str->hex number';
is_deeply eval_js('t/tmpl/encode_js_number.txt', number=>'0777'),
    [511], 'number: 0777 (octal)';
is_deeply eval_js('t/tmpl/encode_js_number.txt', number=>'0xFF'),
    [255], 'number: 0xFF (hex)';
like eval_js('t/tmpl/encode_js_number.txt', number=>'NaN'),
    qr/\A\s*\[\s*NaN\s*\]\s*\z/ms, 'number: NaN';
like eval_js('t/tmpl/encode_js_number.txt', number=>'Infinity'),
    qr/\A\s*\[\s*Infinity\s*\]\s*\z/ms, 'number: Infinity';
like eval_js('t/tmpl/encode_js_number.txt', number=>'bad'),
    qr/error/msi, 'number: bad';

is_deeply eval_js('t/tmpl/encode_js_string.txt', string=>q{}),
    [q{}], 'string: ""';
is_deeply eval_js('t/tmpl/encode_js_string.txt', string=>q{ }),
    [q{ }], 'string: " "';
is_deeply eval_js('t/tmpl/encode_js_string.txt', string=>q{  }),
    [q{  }], 'string: "  "';
is_deeply eval_js('t/tmpl/encode_js_string.txt', string=>" \n "),
    [" \n "], 'string: " \n "';
is_deeply eval_js('t/tmpl/encode_js_string.txt', string=>'"'),
    ['"'], 'string: "\""';
is_deeply eval_js('t/tmpl/encode_js_string.txt', string=>'\''),
    ['\''], 'string: "\'"';
is_deeply eval_js('t/tmpl/encode_js_string.txt', string=>'\\"'),
    ['\\"'], 'string: "\\\""';
is_deeply eval_js('t/tmpl/encode_js_string.txt', string=>'\\\''),
    ['\\\''], 'string: "\\\'"';
is_deeply eval_js('t/tmpl/encode_js_string.txt', string=>'\\\\"'),
    ['\\\\"'], 'string: "\\\\\""';
is_deeply eval_js('t/tmpl/encode_js_string.txt', string=>'\\\\\''),
    ['\\\\\''], 'string: "\\\\\'"';
is_deeply eval_js('t/tmpl/encode_js_string.txt', string=>"para1\n\npara2\n"),
    ["para1\n\npara2\n"], 'string: "para1\n\npara2\n"';
is_deeply eval_js('t/tmpl/encode_js_string.txt', string=>"Юникод"),
    ["Юникод"], 'string: Unicode';

is_deeply eval_js('t/tmpl/encode_js_data.txt', data_ref=>[]),
    [[]], 'data: []';
is_deeply eval_js('t/tmpl/encode_js_data.txt', data_ref=>[undef]),
    [[undef]], 'data: [undef]';
is_deeply eval_js('t/tmpl/encode_js_data.txt', data_ref=>[0,'Test',[],-3.14]),
    [[0,'Test',[],-3.14]], 'data: [0,"Test",[],-3.14]';
is_deeply eval_js('t/tmpl/encode_js_data.txt', data_ref=>{}),
    [{}], 'data: {}';
is_deeply eval_js('t/tmpl/encode_js_data.txt', data_ref=>{a=>undef,b=>0,c=>[],d=>{}}),
    [{a=>undef,b=>0,c=>[],d=>{}}], 'data: {a=>undef,b=>0,c=>[],d=>{}}';
is_deeply eval_js('t/tmpl/encode_js_data.txt', data_ref=>{'the key'=>"line1\nline2"}),
    [{'the key'=>"line1\nline2"}], 'data: {"the key"=>"line1\nline2"}';

unlike render('t/tmpl/encode_js_string.txt', string=>'XSS</script>'),
    qr{</script}ms, 'string: not contain plain </script';
is_deeply eval_js('t/tmpl/encode_js_string.txt', string=>'XSS</script>'),
    ['XSS</script>'], 'string: "XSS</script>"';
unlike render('t/tmpl/encode_js_data.txt', data_ref=>['XSS</script>']),
    qr{</script}ms, 'data: not contain plain </script';
unlike render('t/tmpl/encode_js_data.txt', data_ref=>{'XSS</script>'=>'XSS</script>'}),
    qr{</script}ms, 'data: not contain plain </script';
is_deeply eval_js('t/tmpl/encode_js_data.txt', data_ref=>['XSS</script>']),
    [['XSS</script>']], 'data: ["XSS</script>"]';
is_deeply eval_js('t/tmpl/encode_js_data.txt', data_ref=>{'XSS</script>'=>'XSS</script>'}),
    [{'XSS</script>'=>'XSS</script>'}], 'data: {"XSS</script>"=>"XSS</script>"}';

done_testing();
