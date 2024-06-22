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
requires 'DateTime' => 0;
requires 'Error::Pure' => 0.15;
requires 'Exporter' => 0;
requires 'Readonly' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Wikibase-Datatype-Print/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/Wikibase-Datatype-Print';
resources 'repository' => 'git://github.com/michal-josef-spacek/Wikibase-Datatype-Print';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular' => 0;
test_requires 'Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog' => 0.24;
test_requires 'Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun' => 0.17;
test_requires 'Test::Shared::Fixture::Wikibase::Datatype::Mediainfo::Commons::ImageOfHuman' => 0.15;
test_requires 'Test::Shared::Fixture::Wikibase::Datatype::MediainfoSnak::Commons::Depicts::Human' => 0.15;
test_requires 'Test::Shared::Fixture::Wikibase::Datatype::MediainfoStatement::Commons::Depicts::Human' => 0.25;
test_requires 'Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf' => 0.17;
test_requires 'Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog' => 0;
test_requires 'Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::Human' => 0;
test_requires 'Unicode::UTF8' => 0;
test_requires 'Wikibase::Cache' => 0;
test_requires 'Wikibase::Cache::Backend::Basic' => 0.03;
test_requires 'Wikibase::Datatype::Form' => 0;
test_requires 'Wikibase::Datatype::Item' => 0;
test_requires 'Wikibase::Datatype::Lexeme' => 0;
test_requires 'Wikibase::Datatype::MediainfoSnak' => 0;
test_requires 'Wikibase::Datatype::Reference' => 0;
test_requires 'Wikibase::Datatype::Sense' => 0;
test_requires 'Wikibase::Datatype::Sitelink' => 0;
test_requires 'Wikibase::Datatype::Snak' => 0;
test_requires 'Wikibase::Datatype::Statement' => 0;
test_requires 'Wikibase::Datatype::Value::Globecoordinate' => 0;
test_requires 'Wikibase::Datatype::Value::Item' => 0;
test_requires 'Wikibase::Datatype::Value::Lexeme' => 0;
test_requires 'Wikibase::Datatype::Value::Monolingual' => 0;
test_requires 'Wikibase::Datatype::Value::Property' => 0;
test_requires 'Wikibase::Datatype::Value::Quantity' => 0;
test_requires 'Wikibase::Datatype::Value::Sense' => 0.29;
test_requires 'Wikibase::Datatype::Value::String' => 0;
test_requires 'Wikibase::Datatype::Value::Time' => 0;
tests_recursive;
version '0.17';

# Run.
WriteAll();
