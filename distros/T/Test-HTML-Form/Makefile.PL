use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Test::HTML::Form',
    VERSION_FROM      => 'lib/Test/HTML/Form.pm', # finds $VERSION
    PREREQ_PM         => {
			 HTML::TreeBuilder => 0,
			 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
       (AUTHOR         => 'Aaron J Trevena <teejay@cpan.org>') : ()),
);
