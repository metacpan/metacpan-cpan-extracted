on 'runtime' => sub {
    requires    "Moo";
    requires    "PerlX::Maybe";
    requires    "Ref::Util";
    requires    "Test::Builder";
    requires    "Types::Standard", '>=1.010';
    requires    "syntax";
};

on 'develop' => sub {
    requires    "ExtUtils::MakeMaker::CPANfile";
};

on 'test' => sub {
    requires    "Test::More";
    requires    "Test::Builder::Tester", '>=1.28'; # because of CR/LF
};

#   WARNING TOOLCHAIN BREAKAGE
#   
#   requires    "syntax";
#   
#   pulls in    "Data::OptList"
#   pulls in    "Sub::Install"
#   
#   which in turn will
#   
#   requires    "perl", '>=5.12'
#   
#   to run on old Perls edit your CI pipelines
#   or add:
#   
#   require     "Data::OptList", '< 0.114';
