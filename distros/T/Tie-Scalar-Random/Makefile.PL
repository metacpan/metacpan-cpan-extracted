# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name           'Tie-Scalar-Random';
all_from       'lib/Tie/Scalar/Random.pm';
githubmeta;

auto_install;
WriteAll;

