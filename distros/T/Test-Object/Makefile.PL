use inc::Module::Install;

name     'Test-Object';
all_from 'lib/Test/Object.pm';
requires 'overload'              => 0;
requires 'Carp'                  => 0;
requires 'Exporter'              => 0;
requires 'Scalar::Util'          => '1.16';
requires 'Test::More'            => '0.42';
requires 'Test::Builder'         => '0.33';
requires 'Test::Builder::Tester' => '1.02';
requires 'File::Spec'            => '0.80';

WriteAll;
