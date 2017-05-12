use 5.008003;
use inc::Module::Install;

name 'perl-Apache2-LogUtil';

abstract 'Prefix log messages with run-time context';
author 'Livesite Networks, LLC';
version '00.01001';
license 'lgpl';

perl_version 5.008003;
build_requires 'Test::More' => '0.42';

requires 'Apache2::Const' => 0;
requires 'Apache2::Log' => 0;
requires 'Apache2::ServerUtil' => 0;
requires 'APR::Const' => 0;
requires 'Apache2::MPM' => 0;
requires 'APR::OS' => 0;


auto_install;
WriteAll;
