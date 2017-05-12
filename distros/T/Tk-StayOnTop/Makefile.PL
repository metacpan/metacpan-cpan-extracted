require 5.6.0;

use strict;
use ExtUtils::MakeMaker;


WriteMakefile(
    'NAME'          => 'Tk::StayOnTop',
    'VERSION_FROM'  => 'lib/Tk/StayOnTop.pm',
    'PREREQ_PM'     => {'Tk' => "800.022", "Switch" => 2.07 },
    'ABSTRACT'      => 'Keep your Tk window in the foreground',
    'AUTHOR'        => 'Gavin Brock <gbrock@cpan.org>',
    'dist'          => { COMPRESS=>'gzip', SUFFIX=>'gz' },
);
