requires "Test::More";
requires "Test::Time" => "0.07";
requires "Time::HiRes";
requires "perl" => "5.008";
requires "strict";
requires "warnings";

on 'test' => sub {
    requires "ExtUtils::MakeMaker";
    requires "Test::More" => "0.96";
    requires "lib";
    requires "strict";
    requires "warnings";
};

on 'test' => sub {
    recommends "CPAN::Meta";
    recommends "CPAN::Meta::Requirements";
};

on 'configure' => sub {
    requires "ExtUtils::MakeMaker" => "6.17";
};

on 'develop' => sub {
    requires "Dist::Milla";
    requires "Dist::Zilla::Plugin::MetaProvides";
    requires "File::Spec";
    requires "File::Temp";
    requires "IO::Handle";
    requires "IPC::Open3";
    requires "Pod::Coverage::TrustPod";
    requires "Test::CPAN::Meta";
    requires "Test::Exception";
    requires "Test::More"          => "0.96";
    requires "Test::Pod"           => "1.41";
    requires "Test::Pod::Coverage" => "1.08";
};

