$NAME     = 'VCS';
$DISTNAME = "VCS_PVCS";
$VERSION  = "0.01";

use ExtUtils::MakeMaker;
use ExtUtils::Manifest qw(maniread);

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


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my @clean = qw(*% *.html *.b[ac]k *.old);

push @clean, map { "*/$_" } @clean;


WriteMakefile(
     VERSION   => $VERSION,
     DISTNAME  => $DISTNAME,
     NAME      => $NAME,
     'dist'    => {COMPRESS => 'gzip -9f',
         SUFFIX   => '.gz',
         DIST_DEFAULT => 'all tardist',
         },

     'clean'   => {FILES => join(" ", @clean)},

);
