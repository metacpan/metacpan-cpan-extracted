requires   "Carp";
requires   "File::Spec";
requires   "POSIX";

on "configure" => sub {
    requires   "ExtUtils::MakeMaker";
    };

on "test" => sub {
    requires   "Test::More";
    requires   "Test::NoWarnings";

    recommends "Test::More"               => "1.302175";
    };
