requires 'perl', '5.8.8';

requires 'Data::Float';
requires 'Data::Integer';
requires 'Error::TypeTiny';
requires 'Scalar::Util', '1.20';
requires 'Type::Library';
requires 'Type::Tiny::Intersection';
requires 'Type::Tiny::Union';
requires 'Types::Standard';

requires 'Math::BigFloat';
requires 'Math::BigInt', '>1.999719'; # 718&719 cause test failures
requires 'POSIX';
requires 'constant';
requires 'strict';
requires 'warnings';

on test => sub {
    requires 'Test::Exception';
    requires 'Test::More';
    requires 'Test::TypeTiny';

    requires 'Exporter';
    requires 'base';
    requires 'lib';
};

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
};
