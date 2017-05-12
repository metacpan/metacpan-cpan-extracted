use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
		#perl => 5.005,
WriteMakefile(
    'NAME'	=> 'ldapsh',
    'PREREQ_PM'	=> {
		'Parse::Lex' => 0,
		'Net::LDAP' => 0,
		'Date::Manip' => 0,
	},
    'VERSION_FROM' => 'lib/Net/LDAP/Shell.pm', # finds $VERSION
	'EXE_FILES' => [ 'ldapsh' ],
);

#sub MY::postamble {
#<<'EOT';
#YAPPPARSE = lib/Parse/Yapp/Parse.pm
#
#$(YAPPPARSE) :: YappParse.yp
#	$(PERL) -I./lib yapp -m 'Parse::Yapp::Parse' -o 'lib/Parse/Yapp/Parse.pm' YappParse.yp
#EOT
#}
