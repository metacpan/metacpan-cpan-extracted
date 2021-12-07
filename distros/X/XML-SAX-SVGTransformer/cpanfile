requires 'Math::Matrix' => '0.92';
requires 'Math::Trig';
requires 'XML::SAX::Base';

on 'configure' => sub {
    requires 'ExtUtils::MakeMaker::CPANfile' => '0.06';
};

on 'test' => sub {
    requires 'Test::More' => '0.96'; # for subtest
    requires 'Test::UseAllModules' => '0.10';
    requires 'XML::SAX';
    requires 'XML::SAX::Writer';
};
