#!/usr/bin/perl -wT
# usage:  perl -wT get_JPO_patent_translation_to_english.pl "JPH09-123456A" > JPH09-123456A.zip &  

use strict; use diagnostics; use warnings;
use Archive::Zip;
use WWW::Patent::Page;

my $agent = WWW::Patent::Page->new();
my $request = shift;
my $response = $agent->get_page($request, 		'office' => 'JPO_IPDI',
		'format' => 'translation',
);

# print $response->content;

binmode STDOUT ;
$response->writeToFileHandle( *STDOUT, 0);    # 0 for not seekable

__END__

