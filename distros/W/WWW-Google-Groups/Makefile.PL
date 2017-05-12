# $Id: Makefile.PL,v 1.5 2003/09/16 15:14:51 cvspub Exp $
use ExtUtils::MakeMaker;
if($proxy = prompt("Please set your PROXY server for faster testing:")){
    open F, '>', '.proxy';
    print F $proxy.$/;
    close F;
}
WriteMakefile(
	      'NAME'		=> 'WWW::Google::Groups',
	      'VERSION_FROM'	=> 'Groups.pm', 
	      'PREREQ_PM'		=> {
		  qw(
		   WWW::Mechanize 0.5
		   Email::Simple  1.6
		   Date::Parse    2.24
		     )
		  }, 
	      ($] >= 5.005 ?    
	       (ABSTRACT_FROM => 'Groups.pm', 
		AUTHOR     => 'xern <xern@cpan.org>') : ()),
);
