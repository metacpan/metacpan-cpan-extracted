eval '(exit $?0)' &&
   eval 'exec /u/cgdata/Perl/${ARCH}/bin/perl -S -w $0 ${1+"$@"}'
& eval 'exec /u/cgdata/Perl/${ARCH}/bin/perl -S -w $0 $argv:q'
   if 0;

# The above works on every platform (r6k, sgi4d, sun4, hppa, and alpha)
# for the shells sh, ksh, csh, and bash;
# EXCEPT Korn shell on DEC Alpha.

#
# $Id: FS_example.pl,v 1.1 1995/11/18 00:31:09 scheinin Exp $
#

require 5.001;
use Tk;
use Tk::SelFile;
use Getopt::Long;

GetOptions("startdir=s","filter=s");
if(defined($opt_startdir)){
   $startdir = $opt_startdir;
} else { $startdir = '.'; }
if(defined($opt_filter)){
   $filter = $opt_filter;
} else { $filter = '*'; }

$mw = MainWindow->new;

$mw->geometry('150x40+0+0');
$mw->sizefrom('user'); 
$mw->positionfrom('user');

$mw->title('FS');
$mw->iconname('SelFile');

$f = $mw->Frame;
$f->pack;

$label = $f->Label(-text => ' File Select started. ');
$label->pack;

$sfw = $mw->SelFile(
		    -directory => $startdir,
		    -width     =>  30,
		    -height    =>  20,
		    -filelistlabel  => 'Files',
		    -filter         => $filter,
		    -filelabel      => 'File',
		    -dirlistlabel   => 'Directories',
		    -dirlabel       => 'Filter',
		    );

@sel_file = $sfw->Show;
print STDOUT "$sel_file[0] $sel_file[1]\n";
exit 0;

#MainLoop;
#exit 0;


