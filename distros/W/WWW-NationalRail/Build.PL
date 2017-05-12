#!/usr/bin/perl

use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new (
    module_name         => "WWW::NationalRail",
    license             => "perl",
    dist_author         => "Edward Betts <edward\@debian.org>",
    create_makefile_pl  => "small",
    create_readme       => 1,
    requires            => {
        "Class::Accessor"    => "0.16",
        "HTML::TableExtract" => "1.03",
        "Test::More"         => 0,
        "WWW::Mechanize"     => "1.0",
        "perl"               => "5.6.1",
    }
);

$build->create_build_script;
