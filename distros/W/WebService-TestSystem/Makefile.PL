use ExtUtils::MakeMaker;
require 5.006000;
use strict;

use File::Basename;
use File::Spec::Functions qw|:ALL|;
use Config;

# Grab out any custom cmdline args
my %args = (
            pkg_name  => 'webservice_testsystem',
            name      => 'WebService::TestSystem',
            DESTDIR   => undef
            );

my @pass_args;
while (my $arg = shift @ARGV) {
    my ($key, $value) = split /=/, $arg;
    if (exists $args{$key}) {
        $args{$key} = $value;
    } else {
        push @pass_args, $arg;
    }
}
@ARGV = @pass_args;

warn "Makefile.PL Args:  @ARGV\n";

my %opts = (
            'NAME'	   => $args{'name'},
            'VERSION_FROM' => 'lib/WebService/TestSystem.pm',
	    'EXE_FILES'    => [
                               'scripts/testsystem_d'
                               ],
            'PREREQ_PM' => {
                'Carp'           => 0,
		'Config::Simple' => 0,
		'Pod::Usage'     => 0,
                'Getopt::Long'   => 0,
                'XML::Parser'    => 0,
		'SOAP::Lite'	 => 0, # use 0.65 to get SSL functions working
		'WebService::TicketAuth' => 1.04,
                },
            'AUTHOR'       => 'Bryce Harrington <bryce@osdl.org>',
            'ABSTRACT_FROM'=> 'lib/WebService/TestSystem.pm',
);

# This puts us in the site_perl directory, not dependant on any version
# of perl.
if (defined($Config{'sitelib_stem'}) && $Config{'sitelib_stem'} ne "") {
    print "stem is: $Config{'sitelib_stem'}\n";
    $opts{'INSTALLSITELIB'} = "";
    $opts{'INSTALLSITELIB'} = $args{'DESTDIR'}
                if ($] >= 5.008 ||
                    $ExtUtils::MakeMaker::VERSION =~ /5\.9[1-6]|6\.0[0-5]/);
    $opts{'INSTALLSITELIB'} .= $Config{'sitelib_stem'};
}

WriteMakefile( %opts );

sub install_clause {
    my ($source, $target_dir, $overwrite) = @_;
    $overwrite = 1 unless (defined($overwrite));

    my $text = '';

    $text .= "install :: $source\n";
    $text .= "\t\$(MKPATH) $target_dir\n";
    $text .= "\t\$(CHMOD) a+rx $target_dir\n";
    if ($source) {
        if (-d $source) {
            # If we're copying a directory, update all permissions of subdirs & files
            $text .= "\tfind $source -type d | xargs \$(CHMOD) a+rx\n";
            $text .= "\tfind $source -type f | xargs \$(CHMOD) a+r\n";
        }
        if ($overwrite) {
            # Copy everything recursively excluding CVS dirs and preserving permissions
            $text .= "\t\$(RSYNC) -Cpr $source $target_dir\n";
        } elsif (-f $source) {
            # Don't over-write
            # (This assumes we're installing a _file_, not a directory tree)
            my $dest_file = catfile( $target_dir, basename( $source ) );
            $text .= "\tif [ -f $dest_file ]; ";
            $text .= "then \$(CP) $source $dest_file.dist; ";
            $text .= "else \$(CP) $source $dest_file; fi\n";
            $text .= "\t\$(CHMOD) -R a+r $dest_file\n";
        } else {
            die "Can't install directory '$source' unless overwrite=1\n";
        }
    }
    $text .= "\n";
    return $text;
}

sub MY::postamble {
    my $self = shift;
    my $text = '';
    my $etcdir = '';

    $text .= "RSYNC = rsync\n";
    $text .= "CHOWN = chown\n\n";

    # Determine location of etc conf files
    my $destdir = $args{DESTDIR} || rootdir();

    my $etcdir   = catdir( $destdir,  'etc', $args{pkg_name} );
    my $etcfiles = catfile( 'etc', "testsystem.conf" );
  
    $text .= install_clause($etcfiles, $etcdir, 0);

    $text .= "install :: init.d/testsystem\n";
    my $initdir  = catdir( $destdir,  'etc', 'init.d' );
    $text .= "\t\$(MKPATH) $initdir\n";
    my $initfiles;
    if (-f '/etc/gentoo-release') {
        # This is a gentoo system so use the gentoo init script instead
        $text .= "\t\$(CP) init.d/testsystem.gentoo $initdir/testsystem\n";
        $text .= "\t\$(CHMOD) -R a+rx $initdir/testsystem\n";
    } else {
        $text .= "\t\$(CP) init.d/testsystem $initdir/testsystem\n";
        $text .= "\t\$(CHMOD) -R a+rx $initdir/testsystem\n";
    }
    $text .= "\n\n";

    my $scripts_dist_dir = "stp_user_scripts-\$(VERSION)";
    $text .= "scripts-dist: \n";
    $text .= "\t\$(MKPATH) $scripts_dist_dir\n";
    $text .= "\t\$(CP) scripts/stp-* $scripts_dist_dir\n";
    $text .= "\t\$(CHMOD) a+rx $scripts_dist_dir/*\n";
    $text .= "\t\$(CP) doc/SCRIPTS_README $scripts_dist_dir/README\n";
    $text .= "\ttar czf $scripts_dist_dir.tgz $scripts_dist_dir\n\n";

    return $text;
}
# vi:set ai ts=4 sw=4 expandtab:
