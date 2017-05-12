use inc::Module::Install;

name     'WWW-StaticBlog';
all_from 'lib/WWW/StaticBlog.pm';

author     'Jacob Helwig <jhelwig@cpan.org>';
license    'perl';
repository 'git://github.com/jhelwig/WWW-StaticBlog.git';
homepage   'http://github.com/jhelwig/WWW-StaticBlog',

readme_markdown_from 'lib/WWW/StaticBlog.pm';

requires 'aliased';
requires 'Class::MOP';
requires 'Config::JFDI';
requires 'Cwd';
requires 'Data::Dumper';
requires 'Date::Parse';
requires 'DateTime';
requires 'DateTime::TimeZone';
requires 'Email::Simple';
requires 'File::Copy::Recursive';
requires 'File::Find';
requires 'File::Path';
requires 'File::Slurp';
requires 'File::Spec';
requires 'Hash::Merge';
requires 'List::MoreUtils';
requires 'List::PowerSet';
requires 'Moose';
requires 'Moose::Exporter';
requires 'MooseX::Declare';
requires 'MooseX::Getopt';
requires 'MooseX::Method::Signatures';
requires 'MooseX::SimpleConfig';
requires 'MooseX::Types';
requires 'parent';
requires 'perl';
requires 'Set::Object';
requires 'Text::CSV';
requires 'Text::Multi';
requires 'Time::SoFar';
requires 'XML::Atom::SimpleFeed';

test_requires 'Data::Faker';
test_requires 'Data::Faker::DateTime';
test_requires 'Directory::Scratch';
test_requires 'File::Temp';
test_requires 'Test::CheckChanges' => '0.14';
test_requires 'Test::Mini';
test_requires 'Test::Mini::Unit';
test_requires 'Test::TempDir';
test_requires 'Text::Lorem';
test_requires 'Text::Outdent';

author_requires 'Test::More';
author_requires 'Test::Spelling';

auto_provides_class;

WriteAll;
