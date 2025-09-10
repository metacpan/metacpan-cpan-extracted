#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;

# Forcing this for more consistency, especially with random folks that may install it
use URI::AnyService ':InternalServicesData';

use List::Util qw< pairs >;

###################################################################################################

subtest 'Constructor' => sub {
    subtest 'Valid Schemes' => sub {
        subtest 'Basic' => sub {
            my $u = URI::AnyService->new('smtp://mail.example.com/path');
            isa_ok $u, ['URI::AnyService'], 'Constructor returns URI::AnyService object';
            is $u->scheme, 'smtp',             'Scheme extracted correctly';
            is $u->host,   'mail.example.com', 'Host extracted correctly';
            is $u->path,   '/path',            'Path extracted correctly';
        };

        subtest 'With Port' => sub {
            my $u2 = URI::AnyService->new('ftp://ftp.example.com:2121/files');
            is $u2->scheme, 'ftp',             'FTP scheme correct';
            is $u2->host,   'ftp.example.com', 'FTP host correct';
            is $u2->port,   2121,              'Explicit port overrides default';
            is $u2->path,   '/files',          'FTP path correct';
        };

        subtest 'Dashed Scheme' => sub {
            my $u3 = URI::AnyService->new('netbios-ns://localhost');
            is $u3->scheme, 'netbios-ns', 'NetBIOS-NS scheme correct';
            is $u3->host,   'localhost',  'NetBIOS-NS host correct';
            is $u3->port,   137,          'NetBIOS-NS default port correct';
        };

        subtest 'Two-Parameter Constructor' => sub {
            my $u4 = URI::AnyService->new('//example.com/test', 'ssh');
            is $u4->scheme, 'ssh',           'Two-parameter constructor scheme';
            is $u4->host,   'example.com',   'Two-parameter constructor host';
            is $u4->path,   '/test',         'Two-parameter constructor path';
        };
    };

    subtest 'Error Conditions' => sub {
        like dies { URI::AnyService->new('//example.com/test') },
            qr/No scheme defined in URI/,
            'Dies when no scheme provided'
        ;

        like dies { URI::AnyService->new('invalid-scheme://example.com/') },
            qr/Scheme 'invalid-scheme' not found in/,
            'Dies when scheme not in services file'
        ;

        like dies { URI::AnyService->new('') },
            qr/No scheme defined in URI/,
            'Dies on empty string'
        ;
    };
};

subtest 'URI Normalization' => sub {
    # Test URL wrapping removal
    my $u1 = URI::AnyService->new('<URL:smtp://example.com/path>');
    is $u1->host, 'example.com', 'URL: wrapper removed';

    my $u2 = URI::AnyService->new('<smtp://example.com/path>');
    is $u2->host, 'example.com', 'Angle bracket wrapper removed';

    my $u3 = URI::AnyService->new('"smtp://example.com/path"');
    is $u3->host, 'example.com', 'Quote wrapper removed';

    # Test whitespace trimming
    my $u4 = URI::AnyService->new('  smtp://example.com/path  ');
    is $u4->host, 'example.com', 'Whitespace trimmed';
};

subtest 'Default Port Lookup' => sub {
    my $smtp = URI::AnyService->new('smtp://mail.example.com/');
    is $smtp->default_port, 25,  'SMTP default port is 25';
    is $smtp->port,         25,  'Port defaults to service port';

    my $ssh = URI::AnyService->new('ssh://server.example.com/');
    is $ssh->default_port, 22, 'SSH default port is 22';
    is $ssh->port,         22, 'SSH port defaults correctly';

    my $ftp = URI::AnyService->new('ftp://ftp.example.com/');
    is $ftp->default_port, 21, 'FTP default port is 21';
    is $ftp->port,         21, 'FTP port defaults correctly';

    my $https = URI::AnyService->new('https://secure.example.com/');
    is $https->default_port, 443, 'HTTPS default port is 443';
    is $https->port,         443, 'HTTPS port defaults correctly';
};

subtest 'Port Manipulation' => sub {
    my $u = URI::AnyService->new('smtp://mail.example.com/path');
    is $u->port, 25, 'Initial port is default';

    # Set explicit port
    my $old_port = $u->port(587);
    is $old_port, 25,  'Returns old port value';
    is $u->port,  587, 'New port set correctly';
    is "$u", 'smtp://mail.example.com:587/path', 'URI string includes explicit port';

    # Reset to default
    $u->port(25);
    is "$u", 'smtp://mail.example.com:25/path', 'Explicit default port shown';

    # Clear port (should still default)
    $u->port('');
    is $u->port, 25, 'Empty port string defaults to service port';

    # Undefined port
    $u->port(undef);
    is "$u",     'smtp://mail.example.com/path', 'Undefined port removes explicit port';
    is $u->port, 25,                             'But port() still returns default';
};

subtest 'Scheme Manipulation' => sub {
    my $u = URI::AnyService->new('smtp://example.com/test');
    is $u->scheme, 'smtp', 'Initial scheme';

    # Invalid scheme should die
    like dies { $u->scheme('invalid-scheme') },
        qr/Scheme 'invalid-scheme' not found in/,
        'Dies when setting invalid scheme'
    ;

    # Test getting current scheme
    is $u->scheme, 'smtp', 'Scheme getter works';

    # Try to clear scheme with empty string (doesn't actually clear)
    my $old_scheme = $u->scheme('');
    is $old_scheme, 'smtp', 'Returns old scheme when attempting to clear with empty string';
    is $u->scheme,  'smtp', 'Empty string does not clear scheme (falls back to getter)';

    # Set to a valid scheme
    $u->scheme('https');
    is $u->scheme, 'https', "Scheme changed to 'https'";
};

subtest 'Host and Path Manipulation' => sub {
    my $u = URI::AnyService->new('ssh://server.example.com/home/user');
    is $u->host, 'server.example.com', 'Initial host';
    is $u->path, '/home/user',         'Initial path';

    $u->host('new.example.com');
    is $u->host, 'new.example.com', 'Host changed';

    $u->path('/new/path');
    is $u->path, '/new/path', 'Path changed';

    is "$u", 'ssh://new.example.com/new/path', 'Full URI updated';
};

subtest 'Case-Insensitive Scheme Handling' => sub {
    # Test uppercase scheme acceptance (URI module normalizes scheme to lowercase only)
    my $u = URI::AnyService->new('FTP://FTP.EXAMPLE.COM/PATH');
    isa_ok $u, ['URI::AnyService'], 'Uppercase scheme creates valid object';
    is $u->scheme,       'ftp',             'URI module normalizes scheme to lowercase';
    is $u->host,         'FTP.EXAMPLE.COM', 'Host case preserved (not normalized by URI)';
    is $u->default_port, 21,                'Default port lookup works with uppercase scheme';

    # Test mixed case
    my $u2 = URI::AnyService->new('SmTp://mail.example.com/test');
    is $u2->scheme,       'smtp', 'Mixed case scheme normalized to lowercase by URI module';
    is $u2->default_port, 25,     'Mixed case scheme port lookup works';

    # Verify string representation preserves original case from input
    like "$u", qr/^FTP:/,              'String representation preserves original scheme case from input';
    like "$u", qr/FTP\.EXAMPLE\.COM/, 'And preserves original host case';
};

subtest 'Stringification and Canonical Form' => sub {
    # Test basic string representation
    my $u = URI::AnyService->new('smtp://mail.example.com/path');
    is "$u", 'smtp://mail.example.com/path', 'Basic string representation';

    # Test with encoded characters
    my $u2 = URI::AnyService->new('smtp://mail.example.com/path with spaces');
    like "$u2", qr/path%20with%20spaces/, 'Spaces encoded in path';

    # Test with query parameters
    my $u3 = URI::AnyService->new('ftp://ftp.example.com/file?type=binary');
    like "$u3", qr/\?type=binary/, 'Query parameters preserved';
};

# NOTE: This is mostly to test compatibility/changes from the parent base modules.
subtest 'Other misc URI::_* method tests' => sub {
    my $full_url = 'https://user@www.example.com/path?query=value#fragment';
    my $uri = URI::AnyService->new($full_url);

    my @tests = (
        # Base URI methods
        scheme    => 'https',
        has_recognized_scheme => !!1,
        opaque    => '//user@www.example.com/path?query=value',
        fragment  => 'fragment',
        as_string => $full_url,
        TO_JSON   => $full_url,

        # _query methods
        query           => 'query=value',
        query_form      => [qw< query value >],
        query_keywords  => undef,
        query_param     => [qw< query >],
        query_form_hash => { query => 'value' },

        # _generic methods
        authority     => 'user@www.example.com',
        path          => '/path',
        path_query    => '/path?query=value',
        path_segments => ['', 'path'],
        # XXX: I have no idea why they called these methods reserved function names...
        #abs          => 'https://user@www.example.com/path',
        #rel          => 'path',

        # _server methods
        host      => 'www.example.com',
        ihost     => 'www.example.com',
        port      => 443,
        host_port => 'www.example.com:443',
        # NOTE: Not using URI::_login as a base class, so user/password isn't available
        userinfo  => 'user',
        as_iri    => $full_url,
        canonical => $full_url,
    );

    foreach my $pair (pairs @tests) {
        my ($method, $value) = @$pair;
        is(
            ( ref $value eq 'ARRAY' ? [ $uri->$method ] : $uri->$method ),
            $value,
            "\$uri->$method returns correct value",
        );
    }
};

subtest 'SERVICE_PORTS Hash Population' => sub {
    ok exists $URI::AnyService::SERVICE_PORTS{smtp}, 'SMTP service loaded';
    ok exists $URI::AnyService::SERVICE_PORTS{http}, 'HTTP service loaded';
    ok exists $URI::AnyService::SERVICE_PORTS{ftp},  'FTP service loaded';

    is $URI::AnyService::SERVICE_PORTS{smtp},  25,  'SMTP port correct';
    is $URI::AnyService::SERVICE_PORTS{http},  80,  'HTTP port correct';
    is $URI::AnyService::SERVICE_PORTS{ftp},   21,  'FTP port correct';
    is $URI::AnyService::SERVICE_PORTS{ssh},   22,  'SSH port correct';
    is $URI::AnyService::SERVICE_PORTS{https}, 443, 'HTTPS port correct';
};

done_testing;
