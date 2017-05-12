use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

if ($] < 5.005_62)
{
    print "Running under perl v.$] - less than 5.005_62\n";
    print "\t renaming '5.005/$_' to '$_'...\n\t\t",
          rename("5.005/$_", $_) ? "file renamed OK.\n" : "can't rename!\n"
          for qw/Lite.pm map/;
}

WriteMakefile(
    'NAME'         => 'Unicode::Lite',
    'VERSION_FROM' => 'Lite.pm',
    'EXE_FILES'    => ['map'],
    'PREREQ_PM'    => {
        'Unicode::String' => 2.06,
        'Unicode::Map'    => 0.110,
        'enum'            => 1.016,
    },
);
