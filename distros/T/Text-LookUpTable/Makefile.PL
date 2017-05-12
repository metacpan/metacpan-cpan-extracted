
use strict;
use warnings;

use inc::Module::Install;

name            'Text-LookUpTable';
all_from        'lib/Text/LookUpTable.pm';
requires        'Text::Aligner' => 0;
requires        'File::Slurp' => 0;
test_requires   'Test::More' => 0;

resources (
    'repository' => 'http://github.com/jmahler/libtext-lookuptable-perl',
    'homepage' => 'http://search.cpan.org/dist/Text-LookUpTable/',
);

WriteAll;

