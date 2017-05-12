requires "base";
requires "Carp";
requires "Class::Accessor::Fast";
requires "Hook::LexWrap";
requires "Scalar::Util";
requires "strict";
requires "version";
requires "warnings";

# for Test::MethodFixtures::Storage::File:
recommends "Data::Dump";
recommends "Digest::MD5";
recommends "Path::Tiny";

on test => sub {
    requires "Digest::MD5";
    requires "File::Temp";
    requires "Path::Tiny";
    requires "Storable";
    requires "Test::Deep";
    requires "Test::Exception";
    requires "Test::More";
};

on develop => sub {
    recommends "Dist::Milla";
    recommends "Dist::Zilla::Plugin::MetaProvides";
    recommends "Test::Pod";
};
