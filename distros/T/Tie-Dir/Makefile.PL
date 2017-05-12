#

use ExtUtils::MakeMaker;

sub MY::libscan {
    my($self,$path) = @_;

    return '' 
	if($path =~ m:/(RCS|CVS|SCCS)/: ||
	   $path =~ m:[~%]$: ||
	   $path =~ m:\.(orig|rej)$: ||
	   $path =~ m:FileHandle.pm:
	  );
 
    $path;
}

WriteMakefile(	NAME	 => 'Tie::Dir',
		VERSION_FROM => 'Dir.pm',
		'clean'	 => {FILES => q[*% *.bak *.old]},
		'dist'   => {COMPRESS => 'gzip -9f',
			     SUFFIX   => 'gz', 
			     POSTOP   => 'mv $(DISTNAME)-$(VERSION).tar.gz ../',
			     DIST_DEFAULT => 'all tardist',
			    },
	     );
