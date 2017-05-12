require 5.6.0;

use strict;
use ExtUtils::MakeMaker;

my %preq = ('Tk' => "800.022");
$preq{"Win32::API"} = "0.20" if $^O =~ /Win32/;

WriteMakefile(
    'NAME'          => 'Tk::HideCursor',
    'VERSION_FROM'  => 'lib/Tk/HideCursor.pm',
    'PREREQ_PM'     => \%preq,
    'ABSTRACT'      => 'Hide the cusror in your Tk widget',
    'AUTHOR'        => 'Gavin Brock <gbrock@cpan.org>',
    'dist'          => { COMPRESS=>'gzip', SUFFIX=>'gz' },
);
