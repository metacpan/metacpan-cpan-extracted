# Load the Module::Install bundled in ./inc/
use inc::Module::Install;
    
# Define metadata
name            'Ubigraph';
all_from        'lib/Ubigraph.pm';
    
    # Specific dependencies
requires        'Frontier::Client';
#build_requires  'Test::More'        => '0.42';
    
auto_install;
WriteAll;
