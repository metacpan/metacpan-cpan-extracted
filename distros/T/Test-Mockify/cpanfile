requires 'perl', '5.10.1';

requires 'Module::Load';
requires 'Test::MockObject::Extends';
requires 'Sub::Override';
requires 'Data::Compare';
requires 'Data::Dumper';
requires 'Exporter';
requires 'Scalar::Util';
requires 'experimental';
requires 'strict';
requires 'parent';
requires 'Sub::Override';


on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Exception';
    requires 'FindBin';
};

on 'build' => sub { 
    requires 'Module::Build::Tiny', '0.039';
};

on 'develop' => sub {
    requires 'Version::Next';
    requires 'Fatal';
    requires 'Perl::Critic', '1.123';
    requires 'Devel::Cover', '1.23';
    requires 'Devel::Cover::Report::Clover', '1.01';
    requires 'TAP::Harness::Archive', '0.18';
    requires 'Module::Install', '1.19';
    requires 'Minilla', '3.0.0';
    requires 'CPAN::Uploader';
};