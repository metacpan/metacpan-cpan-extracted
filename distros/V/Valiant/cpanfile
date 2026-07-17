requires 'Carp', '1.50';
requires 'Class::Method::Modifiers', '2.15';
# Valiant::I18N loads Data::Localize::MultiLevel, which hard-uses Config::Any;
# Data::Localize only 'recommends' it (optional localizer), so declare it here.
requires 'Config::Any', '0';
requires 'Data::Localize', '0.00028';
requires 'Data::Perl::Collection::Array', '0.002011';
requires 'DateTime', '1.65';
requires 'DateTime::Format::Strptime', '1.79';
requires 'Devel::StackTrace', '2.05';
requires 'FreezeThaw', '0.5001';
requires 'HTML::Escape', '1.11';
requires 'Cpanel::JSON::XS', '4.38';
requires 'Lingua::EN::Inflexion', '0.002008';
requires 'Module::Runtime', '0.016';
requires 'Moo', '2.005005';
requires 'namespace::autoclean', '0.29';
requires 'Scalar::Util', '1.63';
requires 'Sub::Util', '1.63';
requires 'String::CamelCase', '0.04';
requires 'Text::Autoformat', '1.75';
requires 'Type::Tiny', '2.004000';
requires 'URI', '5.28';

# these come bundled with Perl so just use whatever version we have
requires 'overload';
requires 'File::Spec';
requires 'Data::Dumper';

on test => sub {
  requires 'Test::Most', '0.38';
  requires 'Test::Lib', '0.003';
  requires 'Test::Needs', '0.002010';
};
