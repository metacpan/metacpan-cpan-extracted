

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Xymon::DB::Schema',
    VERSION_FROM => 'lib/Xymon/DB/Schema.pm', # finds \$VERSION
    AUTHOR       => 'David Peters (davidp@electronf.com)',
    ABSTRACT     => 'Group of Schemas for Xymon',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'DBIx::Class' => 0.01
                    },
   
);
