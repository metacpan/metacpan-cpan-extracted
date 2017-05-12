use inc::Module::Install;
name 'Web-Dispatcher-Simple';
all_from 'lib/Web/Dispatcher/Simple.pm';

requires(
    'Router::Simple'   => 0.07,
    'Plack'            => 0.9951,
    'Try::Tiny'        => 0.06,
    'Carp'             => 0,
    'Scalar::Util'     => 0,
    'Encode'           => 0,
    'Hash::MultiValue' => 0,
);
test_requires(
    'Test::More'  => 0.88,
    'Plack::Test' => 0,
);
use_test_base;
auto_include;
WriteAll;
