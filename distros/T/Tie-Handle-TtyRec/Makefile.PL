# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name           'Tie-Handle-TtyRec';
all_from       'lib/Tie/Handle/TtyRec.pm';
githubmeta;

requires       'Time::HiRes';
requires       'Tie::Handle';

build_requires 'Term::TtyRec::Plus';

auto_install;
WriteAll;

