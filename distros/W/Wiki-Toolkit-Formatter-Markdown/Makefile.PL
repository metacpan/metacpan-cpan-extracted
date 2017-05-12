# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name 'Wiki-Toolkit-Formatter-Markdown';
all_from 'lib/Wiki/Toolkit/Formatter/Markdown.pm';

# Specific dependencies
requires 'Mouse'          => '0.10';
requires 'Text::Markdown' => '1.0.22';

build_requires 'Test::More' => '0.42';

no_index 'directory' => 'ex';

WriteAll;
