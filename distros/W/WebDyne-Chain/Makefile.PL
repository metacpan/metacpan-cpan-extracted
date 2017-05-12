#  Makefile.PL for WebDyne::Chain
#
package WebDyne::Chain;


#  Compiler Pragma
#
use 5.006;
use strict qw(vars);


#  Get MakeMaker version - from Test::Simple Makefile.PL
#
my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}


#  External Modules
#
use ExtUtils::MakeMaker;
use IO::File;


#  All done, init finished
#
#------------------------------------------------------------------------------


#  Create the Makefile params in hash
#
my ($prereq_hr, $version_from_fn);
my %makefile=(

    NAME				     =>  __PACKAGE__,
    VERSION_FROM			     =>  $version_from_fn=File::Spec->catfile(

	'lib',
	split(/::/, __PACKAGE__),

       ).'.pm',

    PREREQ_PM				     =>  do { $prereq_hr={

	'WebDyne'			     =>  0

       }; ($ENV{'PREREQ_PM'} eq '0') ? {} : $prereq_hr },

    CONFIGURE				    =>  sub { { PREREQ_PM=>$prereq_hr } },

    'dist'				     =>  {

	COMPRESS			     =>  'gzip -9f',
	SUFFIX				     =>  '.gz'

       },

    'depend'				     =>  {

	Makefile			     =>  '$(VERSION_FROM)'

       },

    'macro'				     =>  {

        COPYRIGHT			     =>  'Copyright (C) 2006-2010 Andrew Speer <andrew@webdyne.org>',
	LICENSE				     =>  'GPL: GNU General Public License'

       },

    ($] <  5.005 ? () : (

        ABSTRACT_FROM			    =>  $version_from_fn,    
        AUTHOR				    =>  'Andrew Speer <andrew@webdyne.org>',
        
    )),

    ($mm_ver < 6.31 ? () : (

        LICENSE                             =>  'gpl',

    )),
    
    ($mm_ver <= 6.45 ? () : (
        
        META_MERGE => { resources => {
            
            homepage                        =>  'http://webdyne.org',
            license                         =>  'http://www.gnu.org/licenses/gpl.html'
            
        }}
    )),

);


#  Debugging on or off ?
#
my $debug=$ENV{'WEBDYNE_DEBUG'} ? 1 : 0;


#  Get ExtUtils::MakeMaker version. see if it supports PM_FILTER. From SpamAssassin Makefile.PL
#
my $mm_has_pm_filter=$mm_ver >  5.45 || ($mm_ver == 5.45 && $] > 5.006);


#  Install if supported
#
if (!$debug && $mm_has_pm_filter) {


    #  Write filter script and assign
    #
    my $fn='pm_filter.pl';
    my $fh=IO::File->new($fn, O_WRONLY|O_CREAT|O_TRUNC) ||
	die ("unable to write filter file '$fn', $!");
    print $fh 's/debug\\(/0 && debug\\(/m; print';
    $fh->close();
    my $pm_filter="\$(PERL) -nl $fn";
    $makefile{'PM_FILTER'}=$pm_filter;

}

WriteMakefile(%makefile);

package MY;

sub constants {


    #  Add license file, other support files here
    #
    my $mm_or=shift();
    $mm_or->{'PM'}{'LICENSE'}='$(INST_LIBDIR)/$(BASEEXT)/LICENSE';
    $mm_or->SUPER::constants;

};
