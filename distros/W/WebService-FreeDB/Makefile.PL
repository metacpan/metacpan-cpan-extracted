BEGIN { require 5.002 }

use ExtUtils::MakeMaker;
use ExtUtils::Manifest qw(maniread);

#--- MY package

sub MY::libscan
{
 my($self,$path) = @_;

 return '' 
	if($path =~ m:/(RCS|CVS|SCCS)/: ||
	   $path =~ m:[~%]$: ||
	   $path =~ m:\.(orig|rej|nfs)$:
	  );
 $path;
}

#--- Write the Makefile

WriteMakefile(
	VERSION_FROM => "FreeDB.pm",
	NAME      => 'WebService::FreeDB',
	AUTHOR    => 'Henning Mersch <hm@mystical.de>, Reini Urban <rurban@cpan.org>',
	ABSTRACT  => 'Module to search a keyword in a FreeDB-Database.',
	PREREQ_PM => {
		      'LWP::UserAgent' => 1.32,
		      'Test::More' => 0.45,
		    },
	SIGN  => 1,
);
