use inc::Module::Install;

# Define metadata
name        'Test-System';
all_from    'lib/Test/System.pm';

# Specific dependencies
requires    'Moose'             => '0.87';
requires    'YAML::Syck'        => '1.07';
requires    'TAP::Harness'      => '3.17';
requires    'File::Basename'    => '2.74';
requires    'Class::Factory'    => '1.05';
requires    'Test::More'        => '0.94';

# Formatters
requires    'TAP::Formatter::HTML'    => '0.08';
requires    'TAP::Formatter::Console' => '3.17';

# Recos
recommends  'Getopt::Awesome'   => '0.1.3';

no_index directory => 'example';

repository 'http://github.com/pfischer/Test-System';

WriteAll;
