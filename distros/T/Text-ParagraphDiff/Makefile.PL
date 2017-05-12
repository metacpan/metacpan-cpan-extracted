use ExtUtils::MakeMaker;
# See lib/ExtUtils/Makeaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'    => 'Text::ParagraphDiff',
    'VERSION_FROM' => 'lib/Text/ParagraphDiff.pm',
    'PREREQ_PM' => {
        'Algorithm::Diff' => 1.10,
        'HTML::Entities'  => 1.00,
    },
    ($] >= 5.005 ?    # Add these new keywords supported since 5.005
# retrieve abstract from module
      (ABSTRACT_FROM => 'lib/Text/ParagraphDiff.pm',
       AUTHOR     => 'Joseph F. Ryan <ryan.311@osu.edu>') : ()),
);

