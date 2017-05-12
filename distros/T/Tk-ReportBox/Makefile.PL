use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tk::ReportBox',
    'VERSION_FROM'	=> 'ReportBox.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Tk' => 0},
    (ABSTRACT_FROM  => 'ReportBox.pm',
     AUTHOR  => 'Kenneth Gonsalves <lawgon@thenilgiris.com>'), 
);
