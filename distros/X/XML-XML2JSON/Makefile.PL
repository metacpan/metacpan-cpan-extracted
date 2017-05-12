# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name 'XML-XML2JSON';
all_from 'lib/XML/XML2JSON.pm';

# Required dependencies
requires 'XML::LibXML' => '1.59';

#
# Require at least one of the below JSON modules
#
feature 'JSON::Syck',
  -default => 1,
  'JSON::Syck' => '0';

feature 'JSON::XS',
  -default => 0,
  'JSON::XS' => '0';

feature 'JSON',
  -default => 0,
  'JSON' => '0';

feature 'JSON::DWIW',
  -default => 0,
  'JSON::DWIW' => '0';

# Build dependencies
build_requires 'Test::More' => '0';

auto_install;
WriteAll;
