
# A generic Makefile.PL file for any pure Perl/Tk mega-widget.
# Update %widinfo.
# Leave $widtrib undefined unless you have an addition for widget's User
# Contributed Demonstrations section.
#
# This program creates the MANIFEST and test.pl files, then invokes
# MakeMaker to create the Makefile.  sol0@Lehigh.EDU, 2001/01/01

use strict;
use warnings;
use v5.5;
use Tk::MMutil;
use vars qw/$widinfo $widtrib %widtrib/;

# $widtrib = 'metest.pl';	# widtrib demo file name
if( $widtrib ) {
    %widtrib = ($widtrib => "\$(INST_ARCHLIB)/Tk/demos/widtrib/$widtrib");
}

Tk::MMutil::TkExtMakefile(
    'NAME'          => "Tk::MatchEntry",
    'DISTNAME'      => "Tk-MatchEntry",
    'VERSION_FROM'  => "MatchEntry.pm",
    'ABSTRACT'      => 'Entry widget with auto-completion capability',
    'AUTHOR'        => 'Wolfgang Hommel (wolf@code-wizards.com)',
    'PM'            => {"MatchEntry.pm" => "\$(INST_LIBDIR)/MatchEntry.pm", %widtrib},
    'dist'          => {'COMPRESS' => 'gzip', 'SUFFIX' => 'gz'},
    'PREREQ_PM'  => {
        'Tk' => 800.022,
    },
    'CONFIGURE_REQUIRES' => {
		"ExtUtils::MakeMaker" => 6.52,
		"Tk::MMutil" => 0,
	},
    'META_MERGE' => {
		"meta-spec" => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'https://github.com/asb-capfan/Tk-MatchEntry.git',
				web => 'https://github.com/asb-capfan/Tk-MatchEntry',
			},
		},
	},
);