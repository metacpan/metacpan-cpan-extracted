use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Wikibase data types print.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Wikibase-Datatype-Print';
perl_version 5.006002;
readme_from 'Print.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'DateTime::Format::ISO8601' => 0;
requires 'Error::Pure' => 0.15;
requires 'List::MoreUtils' => 0;
requires 'Unicode::UTF8' => 0;
requires 'Wikibase::Cache' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Wikibase-Datatype-Print/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/Wikibase-Datatype-Print';
resources 'repository' => 'git://github.com/michal-josef-spacek/Wikibase-Datatype-Print';
test_requires 'Wikibase::Datatype' => 0.12;
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog' => 0.16;
test_requires 'Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun' => 0.17;
test_requires 'Test::Shared::Fixture::Wikibase::Datatype::Mediainfo::Commons::ImageOfHuman' => 0.15;
test_requires 'Test::Shared::Fixture::Wikibase::Datatype::MediainfoSnak::Commons::Depicts::Human' => 0.15;
test_requires 'Test::Shared::Fixture::Wikibase::Datatype::MediainfoStatement::Commons::Depicts::Human' => 0.15;
test_requires 'Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf' => 0.17;
test_requires 'Unicode::UTF8' => 0;
test_requires 'Wikibase::Cache::Backend::Basic' => 0;
test_requires 'Wikibase::Datatype::Form' => 0;
test_requires 'Wikibase::Datatype::Snak' => 0;
test_requires 'Wikibase::Datatype::Statement' => 0;
test_requires 'Wikibase::Datatype::Value::Item' => 0;
test_requires 'Wikibase::Datatype::Value::Monolingual' => 0;
test_requires 'Wikibase::Datatype::Value::String' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
