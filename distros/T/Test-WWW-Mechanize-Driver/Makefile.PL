use inc::Module::Install;
name           'Test-WWW-Mechanize-Driver';
perl_version   5.005;
license        'Public Domain';
all_from       'lib/Test/WWW/Mechanize/Driver.pm';


# Core from perl 5.6 onward:
test_requires 'Test::More' => 0;
requires 'Test::Builder' => 0;

# Core from perl 5.8 onward:
requires 'Scalar::Util' => 0;
requires 'Storable' => 0;

# Non-core even in recent perls
requires 'URI' => 0;
requires 'URI::QueryParam' => 0;
requires 'Test::WWW::Mechanize' => 0;
test_requires 'DateTime' => 0;
test_requires 'Template' => 0;
test_requires 'YAML' => 0;

# standard usage uses these, but they may not be needed if you have an
# alternate loader/tester or do not use templates.
recommends 'DateTime' => 0;
recommends 'Template' => 0;
recommends 'YAML' => 0;

WriteAll;
