use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'              => 'Tk::ChooseDate',
    'VERSION_FROM'      => 'lib/Tk/ChooseDate.pm', # finds $VERSION
    'ABSTRACT_FROM'     => 'lib/Tk/ChooseDate.pm', # retrieve abstract from module
    'AUTHOR'            => 'Jack Dunnigan <dunniganj<at>cpan<dot>org>',
    'dist'              => {'COMPRESS'=>'gzip',
    'SUFFIX'            => '.gz',
    'POSTOP'            =>'-$(CHMOD) 644 $(DISTVNAME).tar$(SUFFIX)'},
    'PREREQ_PM'         => {
                   'Tk' => 800.015,
                   'Date::Calc' => 5.4,
                           },
	'PM'		=> {
		'lib/Tk/ChooseDate.pm'	=> '$(INST_LIB)/Tk/ChooseDate.pm',
		'demos/choosedate.pl'	=> ($] >= 5.005
					? '$(INST_ARCHLIB)'
					: '$(INST_LIB)') . '/Tk/demos/widtrib/choosedate.pl',
			},
    'MAN3PODS'          => {
                   'lib/Tk/ChooseDate.pm'   => '$(INST_MAN3DIR)/Tk::ChooseDate.$(MAN3EXT)',
                           },
);

sub MY::postamble {
	'
demo :: pure_all
	$(FULLPERL) -w -I$(SITELIBEXP)/Tk/demos/widget_lib -I$(SITEARCHEXP)/Tk/demos/widget_lib -Mblib demos/choosedate.pl
';
}
