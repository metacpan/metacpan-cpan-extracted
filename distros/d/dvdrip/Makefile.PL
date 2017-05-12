# $Id: Makefile.PL 2393 2009-12-19 13:42:17Z joern $

use strict;

use File::Find;
use ExtUtils::MakeMaker;
use FileHandle;

$| = 1;

my %REQUIRED_MODULES = (
        'Gtk2'                  => 1.121,
        'Locale::TextDomain'    => 1.16,
	'Event'                 => 1.06,
        'Gtk2::Ex::FormFactory' => 0.65,
        'Event::ExecFlow'       => 0.64,
        'Event::RPC'            => 0.89,
        'AnyEvent'              => 1.02,
);

my $required_module_files = $ENV{SKIP_UNPACK_REQUIRED_MODULES} ?
    "" : unpack_shipped_modules(\%REQUIRED_MODULES);

my @add_bin_files = grep m!bin/!, split (/\s+/, $required_module_files);

WriteMakefile(
    'NAME'         => 'Video::DVDRip',
    'VERSION_FROM' => 'lib/Video/DVDRip.pm',
    'EXE_FILES'    => [
        'bin/dvdrip',          'bin/dvdrip-master',
        'bin/dvdrip-exec',     'bin/dvdrip-multitee',
        'bin/dvdrip-replex',   'bin/dvdrip-subpng',
        'bin/dvdrip-splitpipe',
        'bin/dvdrip-progress', 'bin/dvdrip-splash',
        'bin/dvdrip-thumb',
        @add_bin_files
    ],
    'PREREQ_PM' => \%REQUIRED_MODULES,
    'clean' => {
              FILES => 'bin/dvdrip-splitpipe src/dvdrip-splitpipe '
            . 'bin/dvdrip-progress src/dvdrip-progress '
            . 'l10n/.mo.installed '
            . $required_module_files
    },
    'dist' => {
        COMPRESS => "gzip",
        SUFFIX   => "gz",
        PREOP => 'echo "DONT USE THIS - USE tools/mkdist.pl INSTEAD"; exit 1',
    },
);

sub MY::postamble {
    '
bin/dvdrip-splitpipe bin/dvdrip-progress: src/Makefile
	cd src && make
';
}

sub unpack_shipped_modules {
    my ($required_modules) = @_;
    
    my (@files, @modules);
    foreach my $module ( keys %{$required_modules} ) {
        #-- check if a tar.gz file for this module is shipped
        my $module_dist_file = get_module_dist_file($module);
        next unless $module_dist_file;
        
        #-- now check if this module is already installed
        my $out = qx[ perl -M$module -e1 2>&1 >/dev/null && echo PERL_MODULE_OK 2>&1 ];
        next if $out =~ /PERL_MODULE_OK/;
        
        #-- Ok, module is missing and will be installed during
        #-- dvd::rip install
        push @modules, $module;
        my $module_dist_dir = $module_dist_file;
        $module_dist_dir =~ s/\.tar.gz$//;
        
        my $cmd =
             "cd perl-modules && "
            ."tar xfz $module_dist_file && "
            ."cd $module_dist_dir && "
            ."cp -r lib/* ../../lib && echo MODULE_COPY_OK; "
            ."ls lib/*.pm 2>/dev/null; "
            ."test -d bin && cp -r bin/* ../../bin; "
            ."test -d bin && ls bin/*; "
            ."cd ..; "
            ."rm -rf $module_dist_dir";

        $out = qx[ ( $cmd ) 2>&1 ];
        
        if ( $out =~ /MODULE_COPY_OK/ ) {
            $out =~ s/\s*MODULE_COPY_OK\s*//;
            push @files, split(/\s+/, $out);
            $module_dist_dir =~ /^([^-]+)/;
            push @files, "lib/$1";
        }
        else {
            print STDERR "Error unpacking $module_dist_file!\n";
            print STDERR "Executed command was:\n\n$cmd\n\n";
            print STDERR "Output was:\n\n$out\n";
            exit 1;
        }
    }

    if ( @modules ) {
        @modules = sort @modules;
        print "\n";
        print "Note:\n";
        print "-----\n";
        print "The following modules are required for dvd::rip but not found on your\n";
        print "system. They're shipped with dvd::rip for your convenience and will be\n";
        print "installed automatically when you run 'make install':\n\n";
        print "  @modules\n";
        print "\n";
        print "You can ignore the 'prerequisite not found' warnings beyond for them.\n\n";
        print "If you don't like this and want to install these modules manually\n";
        print "just set SKIP_UNPACK_REQUIRED_MODULES before executing Makefile.PL,\n";
        print "e.g. this way:\n\n";
        print "  SKIP_UNPACK_REQUIRED_MODULES=1 perl Makefile.PL\n\n";
    }

    return join(" ", @files);
}

sub get_module_dist_file {
    my ($module) = @_;

    my @dist_files = glob("perl-modules/*");
    
    my $module_dist_re = $module;
    $module_dist_re =~ s/::/-/g;
    $module_dist_re = quotemeta($module_dist_re);
    $module_dist_re = qr[($module_dist_re-[\d._-]+\.tar\.gz)];
    my $module_dist_file;
    foreach my $dist_file ( @dist_files ) {
        if ( $dist_file =~ $module_dist_re && -f "perl-modules/$1" ) {
            $module_dist_file = $1;
            last;
        }
    }

    return $module_dist_file;
}
