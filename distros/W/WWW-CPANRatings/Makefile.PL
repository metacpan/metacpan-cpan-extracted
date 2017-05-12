use inc::Module::Install;
name 'WWW-CPANRatings';
all_from 'lib/WWW/CPANRatings.pm';

requires($_ => 0) for qw(
List::Util
LWP::Simple
DateTime::Format::DateParse
HTML::TokeParser::Simple
URI
Web::Scraper
JSON::XS
Text::CSV_PP
);

tests 't/*.t';
readme_markdown_from 'lib/WWW/CPANRatings.pm';


author_tests 'xt';
# test_requires 'Test::More';
# auto_set_repository;
auto_include;
WriteAll;
