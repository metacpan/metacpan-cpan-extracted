# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name           'autobox-Closure-Attributes';
all_from       'lib/autobox/Closure/Attributes.pm';
githubmeta;

requires       'autobox' => '2.40';
requires       'PadWalker';

build_requires 'Test::Exception';

WriteAll;

