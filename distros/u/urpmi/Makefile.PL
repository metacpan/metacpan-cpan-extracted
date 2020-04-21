#!perl
# Makefile.PL for urpmi
# $Id: Makefile.PL 271298 2010-11-21 15:39:18Z peroyvind $

use strict;
use ExtUtils::MakeMaker;

# Command-line parsing.
# --without-rpm : don't use rpm to find some paths, and generate make targets
#   to produce an rpm of this
# --install-po : compile .po files and install locale files
#		 also, install localized man pages
# --install-gui : install gurpmi
my $with_po  = 0; $with_po  = 1 if grep $_ eq '--install-po', @ARGV;
my $with_polkit = 0; $with_polkit = 1 if grep $_ eq '--install-polkit', @ARGV;
my $with_gui = 0; $with_gui = 1 if grep $_ eq '--install-gui', @ARGV;

# All scripts, some of them go in /usr/sbin (see DESTINSTALLSBIN below)
our @bin_scripts = qw(urpmq urpmf rpm-find-leaves);
our @sbin_scripts = qw(urpmi urpme urpmi.addmedia urpmi.removemedia rurpmi rurpme);
our @libexec_scripts = qw(urpmi.update);
if ($with_gui) {
    push @bin_scripts, qw(gurpmi);
    push @libexec_scripts, qw(gurpmi2);
}

# And now, add some functionality to MakeMaker.
package MY;

# Don't install gurpmi.pm if we don't install gui
sub libscan {
    my ($self, $path) = @_;
    return !$with_gui && $path =~ /gurpmi/ ? '' : $path;
}

# Make proper sbin/libexec/man5/man8 dirs in blib
sub top_targets {
    my $inherited = shift->SUPER::top_targets(@_);
    $inherited =~ s/^config ::/$& \$(INST_MAN5DIR)\$(DIRFILESEP).exists \$(INST_MAN8DIR)\$(DIRFILESEP).exists \$(INST_SBIN)\$(DIRFILESEP).exists \$(INST_LIBEXEC)\$(DIRFILESEP).exists/m;
    $inherited;
}

# Install sbin_scripts in sbin under blib
sub installbin {
    my $self = shift;
    my $inherited = $self->SUPER::installbin(@_);
    my $s = join '|', map quotemeta, @libexec_scripts;
    $inherited =~ s{\$\(INST_SCRIPT\)/($s)}{\$(INST_LIBEXEC)/$1}g;
    $s = join '|', map { quotemeta($_) . '\s' } @sbin_scripts;
    $inherited =~ s{\$\(INST_SCRIPT\)/($s)}{\$(INST_SBIN)/$1}g;
    # how to create needed directories under blib
    $inherited .= $self->dir_target("\$(INST_$_)") for qw(SBIN LIBEXEC MAN5DIR MAN8DIR);
    $inherited;
}

sub install {
    my $inherited = shift->SUPER::install(@_);
    # Take into account scripts in sbin under blib
    # and new manpage sections
    if ($inherited !~ s/"\$\(INST_BIN\)" "\$\(DESTINSTALL(\w*)BIN\)"/$& "\$(INST_SBIN)" "\$(DESTINSTALL$1SBIN)" "\$(INST_LIBEXEC)" "\$(DESTINSTALLLIBEXECDIR)" "\$(INST_MAN5DIR)" "\$(DESTINSTALLMAN5DIR)" "\$(INST_MAN8DIR)" "\$(DESTINSTALLMAN8DIR)"/g) {
        die "Could not replace INST_SBIN!" if $] >= 5.022000;
    }
    # install files under /etc and /var
    my $po = $with_po ? ' installpo' : '';
    my $polkit = $with_polkit ? ' installpolkit' : '';
    my $gui = $with_gui ? ' installgurpmi2' : '';
    if ($inherited !~ s/^install ::/$& installconfigfiles installstatedir$po$polkit$gui/gm) {
        die "Could not replace install.";
    }
    $inherited;
}

# Due to some hateful layout (that I can't change because the whole stuff is
# hosted in CVS (double hate)) I need to add pm_to_blib in the phonic targets.
sub special_targets {
    my $inherited = shift->SUPER::special_targets(@_);
    $inherited =~ s/PHONY:/$& pm_to_blib/;
    $inherited;
}

sub manifypods {
    my $inherited = shift->SUPER::manifypods(@_);
    #- TODO repartition of man pages in sections by pod2man is incorrect
    #- TODO as more languages are added adapt the following quick hack
    # Adjust captions to make them look less like perl packages
    $inherited =~ s/^(POD2MAN_EXE\s*=\s*)(.+)$/$1$2 -c "Mageia Package Management" -r "Mageia Linux"/m;
    $inherited;
}

# to generate the ChangeLog depending on the checkout layout
my $commonusername = "../common/";
-d $commonusername or do {
    $commonusername = "../../common/";
    -d $commonusername or do {
	$commonusername = "../../../common/";
	-d $commonusername or $commonusername = "";
    };
};

# Additional targets
sub postamble {
    <<"**MM**";
.PHONY: installconfigfiles installstatedir ChangeLog TAGS

installpo:
	\$(MAKE) -C po install

installpolkit:
	\$(MAKE) -C polkit install

installconfigfiles:
	install -d \$(SYSCONFDIR)/urpmi
	install -m 644 inst.list skip.list \$(SYSCONFDIR)/urpmi

installstatedir:
	install -d \$(LOCALSTATEDIR)/urpmi
	install -d \$(DESTDIR)/var/cache/urpmi/partial
	install -d \$(DESTDIR)/var/cache/urpmi/headers
	install -d \$(DESTDIR)/var/cache/urpmi/rpms

installgurpmi2: pure_install gurpmi.desktop

TAGS:
	etags *.pm */*.pm

testall:
	make test
	sudo make test TEST_FILES='t/superuser--*.t'

%.desktop:   %.desktop.in
	intltool-merge --utf8 po \$< \$@ -d -u -c intltool-merge-cache


**MM**
}

# Back to our schedule
package main;

WriteMakefile(
    NAME		=> 'urpmi',
    ABSTRACT		=> 'Tools to handle the rpm & urpmi databases (install, query, remove installed/available packages)',
    LICENSE		=> 'gpl_2',
    AUTHOR		=> 'Thierry Vignaud',
    'CONFIGURE_REQUIRES' => {
	'ExtUtils::MakeMaker' => '6.64'
    },
    PREREQ_PM		=> {
	'Filesys::Df'		=> '0',
	'Getopt::Long'		=> '0',
	'Locale::gettext'	=> '1.01',
	'MDV::Distribconf'	=> '4.100',
	'Net::LDAP'		=> '0',
	'Time::ZoneInfo'	=> '0',
	'URPM'			=> 'v5.25',
	'XML::LibXML'		=> '0',
	'XML::LibXML::Reader'	=> '0',
    },
    'TEST_REQUIRES' => {
	'Expect'		=> '0',
	'File::Slurp'		=> '0',
	'Net::Server'		=> '0',
	'rpmtools'		=> '7.12',
	'Test::More'		=> '1.302',
	'Test::Pod'		=> '0',
	'Test::Pod::Coverage'	=> '0',
    },
    VERSION_FROM	=> 'urpm.pm',
    macro		=> {
	DESTINSTALLSBIN		=> '$(DESTINSTALLBIN)/../sbin',
	DESTINSTALLSITESBIN	=> '$(DESTINSTALLSITEBIN)/../sbin',
	DESTINSTALLVENDORSBIN	=> '$(DESTINSTALLVENDORBIN)/../sbin',
	INSTALLLIBEXECDIR	=> '$(PERLPREFIX)/libexec',
	DESTINSTALLLIBEXECDIR	=> '$(DESTDIR)$(INSTALLLIBEXECDIR)',
	INSTALLMAN5DIR		=> '$(PERLPREFIX)/share/man/man5',
	DESTINSTALLMAN5DIR	=> '$(DESTDIR)$(INSTALLMAN5DIR)',
	INSTALLMAN8DIR		=> '$(PERLPREFIX)/share/man/man8',
	DESTINSTALLMAN8DIR	=> '$(DESTDIR)$(INSTALLMAN8DIR)',
	INST_SBIN		=> 'blib/sbin',
	INST_LIBEXEC		=> 'blib/libexec',
	INST_MAN5DIR		=> 'blib/man5',
	INST_MAN8DIR		=> 'blib/man8',
	# We could read those values from rpm macros.
	SYSCONFDIR		=> '$(DESTDIR)/etc',
	LOCALSTATEDIR		=> '$(DESTDIR)/var/lib',
    },
    ( $ExtUtils::MakeMaker::VERSION >= 6.46 ? (
        'META_MERGE' => {
	  "meta-spec" => { version => 2 },
            provides => {
		'urpm' => {
		    file => 'urpm.pm',
		    version => 0, # workaround RT#127881
		},
		'urpmi' => {
		    file => 'urpmi.pm',
		    version => 'v8.120',
		},
            },
            resources => {
                repository  => {
		    type => 'git',
		    url => 'git://git.mageia.org/software/rpm/urpmi/',
		    web =>  'http://gitweb.mageia.org/software/rpm/urpmi/',
		},
            },
	    release_status => 'stable',
        } ) : ()
    ),
    MIN_PERL_VERSION => '5.010000',
    EXE_FILES		=> [ @bin_scripts, @sbin_scripts, @libexec_scripts ],
    PMLIBDIRS		=> [ qw(gurpm urpm) ],
    $with_po ? (DIR	=> [ 'po' ]) : (),
    MAN1PODS		=> {
	map {
	    my $targ = $_;
	    $targ =~ s{^pod/}{};
	    $targ =~ s{^(\d)/(.*)\.pod$}{$2};
	    my $section = $1 || 1;
	    ( $_ => "\$(INST_MAN${section}DIR)/$targ.$section" );
	} <pod/*/*.pod>, $with_po ? <pod/*/*.pod> : ()
    },
    dist		=> { COMPRESS => "xz -f", SUFFIX => ".xz" },
);
