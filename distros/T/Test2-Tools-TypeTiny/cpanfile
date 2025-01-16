requires 'perl', 'v5.18.0';

requires 'Data::Dumper';
requires 'List::Util', 'v1.29';
requires 'Scalar::Util';
requires 'Type::Tiny';
requires 'Test2::API';
requires 'Test2::Tools::Basic';
requires 'Test2::Tools::Compare';
requires 'namespace::clean';

on test => sub {
    requires 'Test2::V0';
    requires 'Types::Standard';
};

on develop => sub {
    requires 'Dist::Zilla::PluginBundle::Author::GSG';
};
