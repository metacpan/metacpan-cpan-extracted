use ExtUtils::MakeMaker;

if ($^O ne "linux") {
   print "\nFolks, Video4linux, as the name implies, requires linux.\n";
   print "Configuring anyway, but you have been warned!\n\n";
}

WriteMakefile(
    'NAME'	=> 'Video::Capture::V4l',
    'VERSION_FROM' => 'V4l.pm',
    LIBS	=> '-lpthread',
);
