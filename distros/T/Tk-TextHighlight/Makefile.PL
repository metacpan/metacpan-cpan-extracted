use strict;
use ExtUtils::MakeMaker;

my $pm = 'TextHighlight';
my $ld = '$(INST_LIBDIR)';

WriteMakefile(
	NAME => "Tk::$pm",
	AUTHOR           => q{Jim Turner <turnerjw784@yahoo.com>},
	ABSTRACT_FROM    => "lib/Tk/$pm.pm",
	VERSION_FROM     => "lib/Tk/$pm.pm",
	PREREQ_PM => {
		'Tk' => '800.024',
		'Tk::TextUndo' => 0,
		'Tk::ROText' => 0,
		'Tk::HList' => 0,
		'Syntax::Highlight::Perl::Improved' => 0,
	},
#	PMLIBDIRS => ['Tk'],
	PM => {
		"lib/Tk/$pm.pm" => "$ld/$pm.pm",
		"lib/Tk/ROTextHighlight.pm" => "$ld/ROTextHighlight.pm",
		"lib/Tk/$pm/Bash.pm" => "$ld/$pm/Bash.pm",
		"lib/Tk/$pm/HTML.pm" => "$ld/$pm/HTML.pm",
		"lib/Tk/$pm/Kate.pm" => "$ld/$pm/Kate.pm",
		"lib/Tk/$pm/None.pm" => "$ld/$pm/None.pm",
		"lib/Tk/$pm/Perl.pm" => "$ld/$pm/Perl.pm",
		"lib/Tk/$pm/PerlCool.pm" => "$ld/$pm/PerlCool.pm",
#		"$pm/Pod.pm" => "$ld/$pm/Pod.pm",
		"lib/Tk/$pm/Template.pm" => "$ld/$pm/Template.pm",
		"lib/Tk/$pm/Xresources.pm" => "$ld/$pm/Xresources.pm",
#		"lib/Tk/$pm.pod" => "$ld/$pm.pod",
		"lib/Tk/$pm/RulesEditor.pm" => "$ld/$pm/RulesEditor.pm",
	},
	'dist'	=> {COMPRESS => 'gzip', SUFFIX => 'gz'},
);

1

