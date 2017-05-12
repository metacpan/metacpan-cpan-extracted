use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Text::Highlight',
    VERSION_FROM      => 'lib/Text/Highlight.pm', # finds $VERSION
    PREREQ_PM         => {
                           #for Text::Highlight::HTML
                           #HTML::SyntaxHighlighter => 0.03
			 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Text/Highlight.pm', # retrieve abstract from module
       AUTHOR         => 'Andrew Flerchinger <icrf@wdinc.org>') : ()),
);
