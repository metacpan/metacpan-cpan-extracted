#!perl -w
use strict;
use warnings;

use 5.006;
use ExtUtils::MakeMaker;
use Config;

unless ($^O eq "MSWin32" || $^O eq "cygwin") {
    die "OS unsupported\n";
}

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

WriteMakefile(
    NAME                => 'Win32::GUI::HyperLink',
    VERSION_FROM        => 'lib\Win32\GUI\HyperLink.pm',
    ABSTRACT_FROM       => 'lib\Win32\GUI\HyperLink.pm',
    AUTHOR              => 'Robert May <robertmay@cpan.org>',

    # MIN_PERL_VERSION
    ($mm_ver >= 6.48 ? (MIN_PERL_VERSION => '5.006') : ()),

    # LICENSE
    ($mm_ver >= 6.31 ? (LICENSE => 'perl') : ()),

    PREREQ_PM => {
        'Test::More' => 0,
        'Win32::GUI' => 0,
        'Win32::API' => 0,
    },

    # META_MERGE
    ($mm_ver <= 6.45 ? () : (META_MERGE => {
        resources => {
            license     =>      'http://dev.perl.org/licenses/',
            homepage    =>      'http://rob.themayfamily.me.uk/win32-gui/win32-gui-hyperlink',
            bugtracker  =>      'http://rt.cpan.org/Public/Bug/Report.html?Queue=Win32-GUI-HyperLink',
            repository  =>      'http://github.com/remay/perl-win32-gui-hyperlink',
                     },
    })),
);
