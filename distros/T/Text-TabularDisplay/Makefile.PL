package Text::TabularDisplay;

use strict;
use vars qw(%PREREQ_PM @EXE_FILES %clean);

use ExtUtils::MakeMaker;

%PREREQ_PM = ();
%clean     = ('FILES' => '$(DISTVNAME).tar$(SUFFIX)');

WriteMakefile(
    NAME            => __PACKAGE__,
    AUTHOR          => 'darren chamberlain <darren@cpan.org>',
    LICENSE         => 'gpl',
    ABSTRACT_FROM   => 'TabularDisplay.pm',
    VERSION_FROM    => "TabularDisplay.pm",
    PREREQ_PM       => \%PREREQ_PM,
    clean           => \%clean,
);

__END__
