#!/usr/bin/perl
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG

use ExtUtils::MakeMaker;


BEGIN {
    require 5.008_000;
    #require 5.006_001;
}

WriteMakefile(
    NAME         => 'WWW::Webrobot',
    VERSION_FROM => 'lib/WWW/Webrobot.pm', # finds $VERSION
    AUTHOR       => 'StefanTrcek',
    ABSTRACT     => 'Automated HTTP requests - kind of batch browser',
    PREREQ_PM    => {
                     'Test::More' => 0,
                     'Bundle::LWP' => 0,
                     'HTML::TreeBuilder' => 0,
                     #'HTML::Tagset' => 0,
                     'XML::Parser' => 0,
                     'XML::XPath' => 0,
                         ### XML::XPath load the following modules
                         # Unicode::String
                         # Unicode::Map
                         # enum
                     'Time::HiRes' => 0,
                     'Unicode::Lite' => 0,

                     # Encode requires Perl 5.7.3, necessary for Unicode Support
                     # 'Encode' => 0,

                     # OPTIONAL 'MIME::Lite' => 0,
                     # OPTIONAL 'Crypt::SSLeay' => 0,
                    },
    DISTNAME => "webrobot",
    EXE_FILES      => [qw(
        bin/webrobot
        bin/webrobot-load
        bin/xpath-shell
        bin/webrobot-gen-plan
     )],

);
