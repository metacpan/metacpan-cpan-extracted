# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'pod2book';
all_from        'lib/Pod/LaTeX/Book.pm';
abstract        'Compile POD pages into a LaTeX book';

# Specific dependencies
requires        'Carp'              => 0;
requires        'Pod::LaTeX'        => '0.58';
requires        'Config::Any'       => 0;
requires        'Params::Validate'  => 0;
requires        'Perl6::Slurp'      => 0;
requires        'Pod::ParseUtils'   => '1.33';
requires        'Pod::Find'         => '1.34';
requires        'Getopt::Long'      => 0;
requires        'Pod::Usage'        => 0;
build_requires  'Test::More'        => 0;

no_index        'directory'         => 'examples';

install_script  'bin/pod2book';

auto_install;
WriteAll;

