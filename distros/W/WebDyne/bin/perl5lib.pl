#
#  This file is part of WebDyne.
#
#  This software is Copyright (c) 2017 by Andrew Speer <andrew@webdyne.org>.
#
#  This is free software, licensed under:
#
#    The GNU General Public License, Version 2, June 1991
#
#  Full license text is available at:
#
#  <http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt>
#

#  Massage @INC library to support WebDyne (and other modules) installated
#  into custom directories via PREFIX=/foo directive.
#
#  Jumps through hoops to try and add all possible relevant directories to
#  @INC so module load will work.

package perl5lib;
use strict qw(vars);
use vars qw($VERSION);
use Config;
use Cwd qw(realpath);
use lib;
use File::Spec;

no warnings;
local $^W=0;


#  Version information
#
$VERSION='1.248';


#  Get location of library include file (perl5lib.pm) for this particular
#  type of OS.  Use %WINDIR% in Windows, /etc on other platforms
#
my $Perllib_dn={

    MSWin32	    => $ENV{'windir'},
    MSWin64	    => $ENV{'windir'},

}->{$^O} || File::Spec->catdir(File::Spec->rootdir(), 'etc');
my $Perllib_cn=File::Spec->catfile($Perllib_dn, 'perl5lib.pm');
my @Perllib_dn=@{do($Perllib_cn) if (-f $Perllib_cn && !$ENV{'PAR_TEMP'})};


#  Run main routine to adjust @INC
#
&main();


sub import {


    #  Only run main routine again if user specs different prefix on use, eg
    #  use perl5lib '/opt/foo'
    #
    &main($_[1]) if $_[1];

}


sub main {


    #  Prefix is supplied as ARG, quit if same as standard Perl prefix and
    #  no other libraries to load.
    #
    my @prefix_dn = shift() ||  &prefix();
    if (($prefix_dn[0] eq $Config{'prefix'}) && !@Perllib_dn)  { return 1 }
    my @inc;
    my %prefix_dn; 
    foreach my $prefix_dn (grep {-d $_} (@prefix_dn, @Perllib_dn)) {


        #  Skip duplicates
        #
        next if $prefix_dn{$prefix_dn}++;


	#  Add base prefix directory 
	#
	push @inc, $prefix_dn;


        #  Juggle to get correct INC dir
        #
        my @config=(
	    qw(sitelib privlib archlib vendorlib otherlibdirs sitearch vendorarch),
	   );

        my @version=($Config{'version'}, split(/\s+/, $Config{'inc_version_list'}));
        my %version=map { $_=> 1} @version;
	my @config_version=split(/\./, $Config{'version'});
	while (my $config_version=join('.', @config_version)) {
	    push @version, $config_version unless $version{$config_version};
	    pop @config_version;
        }


	my %lib_dn;
        LIB_DN: foreach my $lib_dn (@Config{@config}) {
            next unless $lib_dn;
            foreach my $perl_prefix_dn (@Config{qw(prefix siteprefix)}) {
                (my $dn=$lib_dn)=~s/\Q$perl_prefix_dn\E//;
                $dn=File::Spec->catdir($prefix_dn, $dn);
		next LIB_DN if $lib_dn{$lib_dn}++;
                push @inc, File::Spec->catdir($dn);
                foreach my $version (@version) {
		    my $dn_version=$dn;
		    my @config_version_temp=split(/\./, $Config{'version'});
		    while (my $config_version=join('.', @config_version_temp)) {
			$dn_version=~s/\Q$config_version\E$/$version/;
			push @inc, File::Spec->catdir($dn_version);
			pop @config_version_temp;
		    }
                }

		#  Legacy perl5 stuff
                if ($dn=~s/perl5//) {
		    push @inc, File::Spec->catdir($dn);
		    push @inc, File::Spec->catdir($dn, $Config{'archname'});
		    foreach my $version (@version) {
			my $dn_version=$dn;
			my @config_version_temp=split(/\./, $Config{'version'});
			while (my $config_version=join('.', @config_version_temp)) {
			    $dn_version=~s/\Q$config_version\E$/$version/;
			    push @inc, File::Spec->catdir($dn_version);
			    push @inc, File::Spec->catdir($dn_version, $Config{'archname'});
			    pop @config_version_temp;
			}
		    }
                }
            }
        }
        
        #  One-off fix
        foreach my $version (@version) {
	    push @inc, File::Spec->catdir($prefix_dn, 'lib', $version, $Config{'archname'});
        }
        
    }


    #  Get rid of non-existant directories, clean up path. Try to avoid stat'ing dirs if not
    #  needed by remembering which ones we have seen and avoid doing -d again - the above
    #  routing can generate duplicate entries in @inc;
    #
    my %inc; 
    @inc=grep { !$inc{$_}++ } @inc;
    @inc=grep { -d $_ } @inc;
    @inc=map  { realpath($_) } @inc;
    my %inc_realpath= map { $_=>1 } @inc;


    #  Kludge to fix up when running from PAR - PAR inserts first line of 'package main; shift @INC', which
    #  removes the first path from *our* added libraries
    #
    if ($ENV{'PAR_TEMP'}) {
	shift @INC if (ref($INC[0]) eq 'CODE');
	unshift @inc, $ENV{'PAR_TEMP'};
	unshift @inc, sub {};
    }
    
    
    #  Allow PERL5INC environment variable to add directories also
    #
    if (my @perl5inc=split(/:/,$ENV{'PERL5INC'})) {
        unshift @inc, @perl5inc;
    }
    

    #  Add to @INC
    #
    'lib'->import(@inc);


    #  Try to add any SITELIB paths from ExtUtils::MM if it loaded. Only load ExtUtils/MM after
    #  adjusting @INC as it loads a stack of modules - including Carp. If loaded before @INC
    #  adjusted they will all be loaded from existing @INC rather than new library location user
    #  might want
    #
    eval ("use ExtUtils::MM") || eval { undef }; # Clear $@ if fail
    if ($INC{'ExtUtils/MM.pm'}) {
        my @inc_mm;
        my %prefix_mm_dn;
        foreach my $prefix_mm_dn (grep {$prefix_dn{$_}} (@prefix_dn, @Perllib_dn)) {


            #  Skip if seen before otherwise add
            #
            next if $prefix_mm_dn{$prefix_mm_dn}++;
            my $mm_or=bless({ ARGS=>{ PREFIX=>$prefix_mm_dn }}, ExtUtils::MM) || next;
            if (eval { $mm_or->init_INSTALL() }) {
                foreach my $key (qw(INSTALLSITELIB INSTALLSITEARCH)) {
                    my $dn=$mm_or->{$key} || next;
                    if ($dn=~s/^\Q$(SITEPREFIX)\E/$prefix_mm_dn/) {
                        push @inc_mm, $dn;
                    }
                }
            }
            else {
                # Clear eval
                #
                eval { undef } if $@;
            }
        }

        @inc_mm=grep { !$inc{$_}++ } @inc_mm;
        @inc_mm=grep { -d $_ } @inc_mm;
        @inc_mm=map  { realpath($_) } @inc_mm;
        @inc_mm=map  { !inc_realpath($_) } @inc_mm;
        'lib'->import(@inc_mm);


    }

    #  Re-order relative lib (except relative ones starting with .);
    #
    foreach my $inc (grep {/^.\//} @INC) {
        lib->unimport($inc);
        lib->import($inc);
    }

}


sub prefix {

    my %prefix;
    my @prefix;
    my @prefix_dn=(File::Spec->splitpath(File::Spec->rel2abs(__FILE__)));
    pop @prefix_dn; ## Remove file portion
    my $prefix_dn=File::Spec->catpath(@prefix_dn);
    my @updir=File::Spec->updir();
    while (my $dn=realpath(File::Spec->catdir(grep {$_} $prefix_dn, @updir))) {
        last if $prefix{$dn}++;
        push @prefix, $dn;
        last if $dn eq $Config{'prefix'}; # Quit if same as perl prefix
        last; # Remove if need to traverse up directory tree because of wierd binary install location
        push @updir, File::Spec->updir();
    }
    return @prefix;

}


sub add {

    my $dn=shift() || return;
    my %perllib_dn=map { $_=>1 } @Perllib_dn;
    unless ($perllib_dn{$dn}) {
	push @Perllib_dn, $dn;
	&save(\@Perllib_dn);
    }

}


sub del {

    my $dn=shift() || return;
    my %perllib_dn=map { $_=>1 } @Perllib_dn;
    if ($perllib_dn{$dn}) {
	@Perllib_dn=grep {$_ ne $dn} @Perllib_dn;
	&save(\@Perllib_dn);
    }

}


sub save {

    my $perllib_dn_ar=shift();
    require IO::File;
    require Fcntl;
    my $fh=IO::File->new($Perllib_cn, &Fcntl::O_WRONLY|&Fcntl::O_CREAT|&Fcntl::O_TRUNC) ||
	die("unable to open file '$Perllib_cn', $!");
    require Data::Dumper;
    $Data::Dumper::Indent=1;
    print $fh &Data::Dumper::Dumper($perllib_dn_ar);
    $fh->close();

}


sub update {
    &add(&prefix);
}


1;
