use Test::More tests => 17;

use Web::Detect;

ok( !defined &detect_web,      'detect_web() not exported by default' );
ok( !defined &detect_web_fast, 'detect_web_fast() not exported by default' );

Web::Detect->import("detect_web");
ok( defined &detect_web, 'detect_web() is exportable' );

Web::Detect->import("detect_web_fast");
ok( defined &detect_web_fast, 'detect_web_fast() is exportable' );

{
    local %ENV = ();
    ok( !detect_web(),      'detect_web() false based on ENV' );
    ok( !detect_web_fast(), 'detect_web_fast() false based on ENV' );

    $ENV{GATEWAY_INTERFACE} = 'CGI';
    ok( detect_web(),      'detect_web() true based on ENV' );
    ok( detect_web_fast(), 'detect_web_fast() true based on ENV' );
    is_deeply( detect_web(),      { cgi => 1 }, 'detect_web() hashref is as expected' );
    is_deeply( detect_web_fast(), { cgi => 1 }, 'detect_web_fast() hashref is as expected' );

    $ENV{PANGEA} = '0.42';
    ok( detect_web(),      'detect_web() true based on ENV' );
    ok( detect_web_fast(), 'detect_web_fast() true based on ENV' );
    is_deeply( detect_web(), { pangea => 1, psgi => 1, cgi => 1 }, 'detect_web() hashref has all results' );
    is_deeply( detect_web_fast(), { pangea => 1, psgi => 1 }, 'detect_web_fast() hashref has first result only' );

    {
        local $ENV{SCRIPT_NAME} = "chuck.pl";
        is( detect_web()->{general}, 1, "first general check is 1" );
    }

    $ENV{HTTP_FOO} = 'bar';
    is( detect_web()->{general}, 2, "second general check is 2" );

    $ENV{SCRIPT_NAME} = "norris.pl";
    is( detect_web()->{general}, 3, "both general checks is 3" );
}
