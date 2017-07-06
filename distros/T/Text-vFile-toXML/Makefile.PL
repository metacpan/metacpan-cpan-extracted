# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Text-vFile-toXML';
all_from        'lib/Text/vFile/toXML.pm';

# Specific dependencies
requires        'Text::vFile::asData'       => 0;
requires        'XML::Quick'                => 0;
build_requires  'Text::vFile::asData'       => 0;
build_requires  'Test::More'                => '0.42';
build_requires  'XML::SemanticDiff'         => 0;

auto_install;
WriteAll;

