use strict; use warnings;
use lib '../lib';
use Test::Pod::Content tests => 3;
pod_section_is 'Test::Pod::Content' , 'NAME', "Test::Pod::Content - Test a Pod's content", 'NAME section';
pod_section_like 'Test/Pod/Content.pm', 'SYNOPSIS', qr{ use \s Test::Pod::Content }xm, 'SYNOPSIS section';
pod_section_like 'Test/Pod/Content.pm', 'DESCRIPTION', qr{ Test::Pod::Content \s provides \s the }xm, 'DESCRIPTION section';
