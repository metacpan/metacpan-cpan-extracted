requires   "Exporter";
requires   "DynaLoader";
requires   "Scalar::Util";
requires   "Try::Tiny"           => "0";

on "configure" => sub {
    requires   "ExtUtils::Depends"   => "0.405";
    requires   "ExtUtils::MakeMaker";
    recommends "ExtUtils::MakeMaker" => "7.22";
    suggests   "ExtUtils::MakeMaker" => "7.70";
    }

om "test" => sub {
    requires   "Carp";
    requires   "FindBin";
    requires   "IO::Handle";
    requires   "POSIX";
    requires   "Test::More";
    }
