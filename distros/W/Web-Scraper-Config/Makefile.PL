use strict;
use inc::Module::Install;

name("Web-Scraper-Config");
all_from("lib/Web/Scraper/Config.pm");

requires("Config::Any");
requires("Data::Visitor::Callback");
requires("URI");
requires("Web::Scraper");

auto_install;
WriteAll;
