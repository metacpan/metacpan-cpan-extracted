requires   "Carp";
requires   "DBI"                      => "1.613";
requires   "Storable";

recommends "DBD::CSV"                 => "0.62";
recommends "DBD::Pg"                  => "3.18.0";
recommends "DBD::SQLite"              => "1.76";
recommends "DBI"                      => "1.647";
recommends "Sereal"                   => "5.004";
recommends "Storable"                 => "3.32";

on "configure" => sub {
    requires   "ExtUtils::MakeMaker";

    recommends "ExtUtils::MakeMaker"      => "7.22";

    suggests   "ExtUtils::MakeMaker"      => "7.72";
    };

on "test" => sub {
    requires   "Test::Harness";
    requires   "Test::More"               => "0.90";
    requires   "Time::HiRes";

    recommends "Test::More"               => "1.302209";
    };
