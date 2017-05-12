#!/usr/bin/perl 

use strict;
use warnings;

use Pod::Manual;

my $manual = Pod::Manual->new;

$manual->add_chapters(qw/ 
    WWW::Ohloh::API 
    WWW::Ohloh::API::Languages
    WWW::Ohloh::API::Language
    WWW::Ohloh::API::Project
    WWW::Ohloh::API::Projects
    WWW::Ohloh::API::Analysis
    WWW::Ohloh::API::Account
    WWW::Ohloh::API::KudoScore
/);

my $doc = 'www-ohloh-api.pdf';
print "generating pdf file $doc\n";
$manual->save_as_pdf( $doc );
print "done\n";

