use inc::Module::Install;

# Define metadata
name        'YUI-MenuBar-Markup';
all_from    'lib/YUI/MenuBar/Markup.pm';

# Specific dependencies
requires    'Mouse'             => '0.27';
requires    'YAML::Syck'        => '1.07';

no_index directory => 'examples';

repository 'http://github.com/pfischer/YUI-MenuBar-Markup';

WriteAll;



