# $Id: Makefile.PL,v 1.2 2004/01/05 16:49:04 cvspub Exp $
use ExtUtils::MakeMaker;


my $scriptname = 'bin/find-concept.pl';

WriteMakefile(
	      'NAME'		=> 'WWW::FindConcept',
	      'VERSION_FROM'	=> 'FindConcept.pm', 
	      'PREREQ_PM'		=> {
		  'WWW::Mechanize' => '0.70',
	      }, 
	      'EXE_FILES'       => [ $scriptname ],
	      ($] >= 5.005 ?    
	       (ABSTRACT_FROM => 'FindConcept.pm', 
		AUTHOR     => 'xern <xern@cpan.org>') : ()),
	      );


use Config;
local $/;
open S, $scriptname;
$_ = <S>;
close S;

open S, '>', $scriptname;
print S "#!$Config{perlpath}\n" unless s/#!.+?\n/#!$Config{perlpath}\n/;
print S $_;
close S;
