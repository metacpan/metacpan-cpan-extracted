head	1.2;
access;
symbols
	rel-0-1:1.1.1.1 ziya:1.1.1;
locks; strict;
comment	@# @;


1.2
date	2001.10.03.15.07.27;	author ziya;	state Exp;
branches;
next	1.1;

1.1
date	2001.09.11.12.26.01;	author ziya;	state Exp;
branches
	1.1.1.1;
next	;

1.1.1.1
date	2001.09.11.12.26.01;	author ziya;	state Exp;
branches;
next	;


desc
@@


1.2
log
@namespace changed from Rcs:: to VCS::Rcs::
@
text
@use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'VCS::Rcs::Parser',
    'VERSION_FROM'	=> 'lib/Rcs/Parser.pm',
#    'PREREQ_PM'		=> {Parse::Yapp => 1.04},
    'MAN3PODS' => { 'lib/Rcs/Parser.pm' => '$(INST_MAN3DIR)/VCS::Rcs::Parser.3' },
    'PM'		=> {
	'lib/Rcs/Parser.pm' 		=> '$(INST_LIBDIR)/Parser.pm',
	'lib/Rcs/YappRcsParser.pm' 	=> '$(INST_LIBDIR)/YappRcsParser.pm',
	'lib/Rcs/Deltatext.pm'		=> '$(INST_LIBDIR)/Deltatext.pm',
			}, 
);
@


1.1
log
@Initial revision
@
text
@d5 1
a5 1
    'NAME'		=> 'Rcs::Parser',
d8 1
a8 1
    'MAN3PODS' => { 'lib/Rcs/Parser.pm' => '$(INST_MAN3DIR)/Rcs::Parser.3' },
@


1.1.1.1
log
@Initial release.
@
text
@@
