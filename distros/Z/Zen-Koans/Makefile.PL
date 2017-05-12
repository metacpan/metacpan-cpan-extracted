# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

name            'Zen-Koans';
all_from        'lib/Zen/Koans.pm';
build_requires  'Test::More'        => '0.42';
license 'perl';

# Generate the Makefile
WriteAll;
