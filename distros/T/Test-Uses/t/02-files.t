use Test::More tests => 14;

use strict;
use warnings;

BEGIN {
    use_ok('Test::Uses');   
}

uses_ok('t/data/test1.pmd', 'LWP::UserAgent', 
    "This test file uses LWP::UserAgent");
avoids_ok('t/data/test1.pmd', 'Lingua::Romana::Perligata', 
    "This test file doesn't use Lingua::Romana::Perligata");
avoids_ok('t/data/test1.pmd', 'autodie', 
    "This test file doesn't use autodie");

uses_ok('t/data/test1.pmd', 'strict', 
    "This test file uses strict");
uses_ok('t/data/test1.pmd', ['strict', 'warnings'], 
    "This test file uses strict and warnings");
uses_ok('t/data/test1.pmd', {-uses => ['strict', 'warnings']}, 
    "This test file uses strict and warnings (long version)");
uses_ok('t/data/test1.pmd', {-uses => 'strict', -avoids => 'autodie'}, 
    "This test file uses strict and avoids autodie");
uses_ok('t/data/test1.pmd', {-uses => ['strict'], -avoids => ['autodie']}, 
    "This test file uses strict and avoids autodie (long version)");

uses_ok('t/data/test1.pmd', qr/^strict$/, 
    "This test file uses strict");
uses_ok('t/data/test1.pmd', qr/^File::/, 
    "This test file uses File::* modules");
uses_ok('t/data/test1.pmd', qr/^File::Copy::/, 
    "This test file uses File::Copy::* modules");
avoids_ok('t/data/test1.pmd', qr/^Win32::/, 
    "This test file avoids Win32::* modules");

avoids_ok('t/data/test1.pmd', qr/5/, 
    "Check we don't find versions");

1;
