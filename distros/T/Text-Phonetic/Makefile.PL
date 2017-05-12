# Load the Module::Install bundled in ./inc/
use strict;
use inc::Module::Install 1.05;

my $from = 'lib/Text/Phonetic.pm';

# Define metadata
name            'Text-Phonetic';
all_from        $from;
readme_from     $from;

perl_version    '5.008';

# Specific dependencies
requires        'Moo'                   => '1.001000';
requires        'Module::Find'          => '0.11';
requires        'Text::Unidecode'       => 0;
requires        'Text::Soundex'         => '3.03';
requires        'Class::Load'           => 0;

recommends      'Text::Metaphone'       => 0;
recommends      'Text::DoubleMetaphone' => 0;

feature 'Soundex support',
    -default   => 1,
    'Text::Soundex' => '3.03';

feature 'Metaphone support',
    -default   => 1,
    'Text::Metaphone' => 0;

feature 'DoubleMetaphone support',
    -default   => 1,
    'Text::DoubleMetaphone' => 0;

build_requires  'Test::Most'            => 0;
build_requires  'Test::NoWarnings'      => 0;

author_requires 'Test::Pod'             => '1.14';
author_requires 'Test::Pod::Coverage'   => '1.04';
author_requires 'Test::Perl::Critic'    => 0;
author_requires 'Module::Install::ReadmeFromPod'        => 0;

repository 'git://github.com/maros/Text-Phonetic.git';

WriteAll;
