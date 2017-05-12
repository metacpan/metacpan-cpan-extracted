#!/usr/bin/perl -w
use strict;
use warnings;
use Carp;
$SIG{__DIE__} = \&confess;

use Test::More tests => 17;


sub load_or_skip_module {
    my ($module) = @_;
    eval "require $module";
    SKIP: {
        skip("'$module' is not installed", 1) if $@;
        return use_ok($module);
    }
}

BEGIN {
    # included in Perl 5.8.0 but not in 5.6.1
    #use_ok('Clone');
    #use_ok('Net::FTP');
    use_ok('Test::More');
    use_ok('Time::HiRes');

    # LWP
    use_ok('MIME::Base64');
    use_ok('Digest::MD5');
    use_ok('URI');
    use_ok('HTML::Tagset');
    use_ok('HTML::Parser');
    use_ok('LWP');
    use_ok('Bundle::LWP');
    load_or_skip_module('Crypt::SSLeay') ||
        diag "NOTE: Crypt::SSLeay is only necessary if you want to use the protocol https\n";

    # anything else
    use_ok('HTML::Tree');
    use_ok('XML::Parser');
    use_ok('XML::XPath');

    # use_ok('enum');
    use_ok('Unicode::String');
    use_ok('Unicode::Map');
    use_ok('Unicode::Lite');

    load_or_skip_module("MIME::Lite") ||
        diag "NOTE: MIME::Lite is only necessary if you want to send e-mail\n";

    # not used
    #load_or_skip_module("Compress::Zlib");
    #load_or_skip_module("Archive::Zip");
    #load_or_skip_module("Archive::Tar");
}
