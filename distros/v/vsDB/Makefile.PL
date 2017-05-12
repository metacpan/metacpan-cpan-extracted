use ExtUtils::MakeMaker;
  # See lib/ExtUtils/MakeMaker.pm for details of how to influence
  # the contents of the Makefile that is written.
  WriteMakefile(
      'NAME' => 'vsDB',
      'VERSION_FROM' => 'vsDB.pm', # finds $VERSION
      ($] ge '5.005') ? (
          'AUTHOR' => 'Jason Hinkle (jake67890@hotmail.com)',
          'ABSTRACT' => 'Simple interface to text-delimited data files',
      ) : (),
  );
