#  Makefile.PL
#
package WebDyne;


#  Compiler Pragma
#
use 5.006;
use strict  qw(vars);


#  External Modules
#
use ExtUtils::MakeMaker;
use File::Spec;
use IO::File;


#  Get MakeMaker version - from Test::Simple Makefile.PL
#
my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}


#  All done, init finished
#
#------------------------------------------------------------------------------


#  Create the Makefile params, save in hash
#
my ($prereq_hr, $version_from_fn);
my %makefile=(

    NAME				    =>  __PACKAGE__,
    VERSION_FROM			    =>  $version_from_fn=File::Spec->catfile(

	'lib',
	split(/::/, __PACKAGE__),

       ).'.pm',

    PREREQ_PM				    =>	do { $prereq_hr={

	'CGI'				    =>  0,
	'Digest::MD5'			    =>  0,
	'HTTP::Status'			    =>  0,
	'HTML::Tagset'			    =>  0,
	'HTML::TreeBuilder'                 =>  0,
	'Storable'			    =>  0,
	'Test::More'                        =>  0,
	'Tie::IxHash'			    =>  0,

        #  Needed for installer - can be ignored if not using installer
        'Text::Template'                    =>  0,
        'Env::Path'                         =>  0,

       }; ($ENV{'PREREQ_PM'} eq '0') ? {} : $prereq_hr },

    CONFIGURE                               =>  sub { {

	PREREQ_PM			    =>  $prereq_hr

    } },

    EXE_FILES				    =>  [

	'bin/wdcompile',
	'bin/wdrender',
	'bin/wddump',
	'bin/wdapacheinit',
	'bin/wddebug',
	'bin/perl5lib.pl',
	'bin/webdyne-mod_perl-1_99-compat.pl'

       ],


    'dist'				    =>  {

	COMPRESS			    =>  'gzip -9f',
	SUFFIX				    =>  '.gz'

       },

    'depend'				    =>  {

	Makefile			    =>  '$(VERSION_FROM)'

       },

    'macro'				    =>  {

        COPYRIGHT			    =>  'Copyright (C) 2006-2010 Andrew Speer, All rights reserved',
	#LICENSE				    =>  'GPL: GNU General Public License',

       },

    ($] <  5.005 ? () : (

        ABSTRACT_FROM			    =>  $version_from_fn,    
        AUTHOR				    =>  'Andrew Speer <andrew@webdyne.org>',
        
    )),

    ($mm_ver < 6.31 ? () : (

        LICENSE                             =>  'gpl_2',

    )),
    
    ($mm_ver <= 6.45 ? () : (
        
        META_MERGE => { 

            'meta-spec'         => {
                version         => 2
            },
            resources           => {
                homepage        => 'https://webdyne.org',
                repository      => {
                    type        => 'git',
                    url         => 'https://github.com/aspeer/WebDyne.git',
                    web         => 'https://github.com/aspeer/WebDyne'
                }
            }
        }
    )),

    ($mm_ver < 6.48 ? () : (

        MIN_PERL_VERSION	=>  '5.006',

    )),

   );


#  Debugging on or off ? If off every deug statement will be stripped from source
#  before install.
#
my $debug=$ENV{'WEBDYNE_DEBUG'} ? 1 : 0;


#  Get ExtUtils::MakeMaker version. see if it supports PM_FILTER. From SpamAssassin Makefile.PL
#
my $mm_has_pm_filter=$mm_ver >  5.45 || ($mm_ver == 5.45 && $] > 5.006);


#  Install if supported
#
if (!$debug && $mm_has_pm_filter) {


    #  Write filter script and assign. Will strip debug statements depening on WEBDYNE_DEBUG env
    #  var
    #
    my $fn='pm_filter.pf';
    my $fh=IO::File->new($fn, O_WRONLY|O_CREAT|O_TRUNC) ||
	die ("unable to write filter file '$fn', $!");
    print $fh 's/debug\\(/0 && debug\\(/m; print';
    $fh->close();
    my $pm_filter="\$(PERL) -nl $fn";
    $makefile{'PM_FILTER'}=$pm_filter;

}

WriteMakefile(%makefile);

package MY;

sub post_initialize {

    #  Add license file, other support files here
    #
    my $mm_or=shift();
    $mm_or->{'PM'}{'LICENSE'}='$(INST_LIBDIR)/$(BASEEXT)/LICENSE';
    $mm_or->SUPER::post_initialize;

};

sub selfdocument {


    #  Copy pre built man files
    #
    my $postamble=shift()->SUPER::postamble;
    $postamble.="subdirs ::\n\t\t".
        '$(CP) man/*.3pm $(INST_MAN3DIR)';

};

