package only::install;
$VERSION = '0.26';
@EXPORT_OK = qw(install);
use strict;
use 5.006001;
use base 'Exporter';
use only;
use File::Spec;
use Config;
use Carp;

sub install {
    my %args = @_;
    check_env();
    my ($dist_name, $dist_ver) = get_meta();
    my $versionlib = $args{versionlib} || &only::config::versionlib;
    my $version = $args{version} || $dist_ver;
    if ($version !~ /^\d+(\.\d+)?$/) {
        croak <<END;
Install failed. '$version' is an invalid version string. Must be numeric.
END
    }
    
    my $lib  = File::Spec->catdir(qw(blib lib));
    mkdir($lib, 0777) unless -d $lib;
    my $arch = File::Spec->catdir(qw(blib arch));
    mkdir($arch, 0777) unless -d $arch;

    my $install_lib  = File::Spec->catdir(
        $versionlib, 
        $version,
    );
    my $install_arch = File::Spec->catdir(
        $versionlib, 
        $Config{archname},
        $version,
    );
    my $install_map = {
        $lib  => $install_lib,
        $arch => $install_arch,
        read  => '',
    };

    {   # 5.6.1 has a warning bug. :(
        local $^W = 0;
        require ExtUtils::Install;
    }
    ExtUtils::Install::install($install_map, 1, 0);

    my @lib_pm_files = map trim_dir($_), find_pm($lib);
    my @arch_pm_files = map trim_dir($_), find_pm($arch);
    my $meta = <<END;
# This meta file created by/for only.pm
meta_version: $only::VERSION
install_version: $version
distribution_name: $dist_name
distribution_version: $dist_ver
distribution_modules:
END
    for my $file (sort(@lib_pm_files, @arch_pm_files)) {
        my $pm_file = join '/', File::Spec->splitdir($file);
        $meta .= "  - $pm_file\n";
    }
    install_meta($meta, $install_lib, $_) for @lib_pm_files;
    install_meta($meta, $install_arch, $_) for @arch_pm_files;
}

sub install_meta {
    my ($meta, $base, $module) = @_;
    my $meta_file = File::Spec->catfile($base, $module);
    $meta_file =~ s/\.pm$/\.yaml/
      or croak;
    my $old_meta = '';
    if (-f $meta_file) {
        open META, $meta_file
          or croak "Can't open $meta_file for input\n";
        $old_meta = do {local $/; <META>};
        close META;
    }
    if ($meta eq $old_meta) {
        print "Skipping $meta_file (unchanged)\n";
    }
    else {
        print "Installing $meta_file\n";
        open META, '>', $meta_file
          or croak "Can't open $meta_file for output\n";
        print META $meta;
        close META;
    }
}

sub trim_dir {
    my ($path) = @_;
    my ($vol, $dir, $file) = File::Spec->splitpath($path);
    my @dirs = File::Spec->splitdir($dir);
    pop @dirs unless $dirs[-1];
    splice(@dirs, 0, 2);
    $dir = scalar(@dirs) ? File::Spec->catdir(@dirs) : '';
    $dir ? File::Spec->catfile($dir, $file) : $file
}

sub find_pm {
    my ($path, $base) = (@_, '');
    croak unless $path;
    my (@pm_files);
    $path = File::Spec->catdir($base, $path) if $base;
    local *DIR;
    opendir(DIR, $path) 
      or croak "Can't open directory '$path':\n$!";
    while (my $file = readdir(DIR)) {
        next if $file =~ /^\./;
        my $file_path = File::Spec->catfile($path, $file);
        my $dir_path = File::Spec->catdir($path, $file);
        if ($file =~ /^\w+\.pm$/) {
            push @pm_files, $file_path;
        }
        elsif (-d $dir_path) {
            push @pm_files, find_pm($file, $path);
        }
    }
    return @pm_files;
}

sub check_env {
    my $lib  = File::Spec->catdir(qw(blib lib));
    my $arch = File::Spec->catdir(qw(blib arch));
    return 1 if -d 'blib' and (-d $lib or -d $arch);
    if (-f 'Build.PL') {
        croak <<END;
First you need to run:
  
  perl Build.PL
  ./Build
  ./Build test    # (optional)

END
    }
    elsif (-f 'Makefile.PL') {
        croak <<END;
First you need to run:
  
  perl Makefile.PL
  make
  make test       # (optional)

END
    }
    else {
        croak <<END;
You don't appear to be inside a directory fit to install a Perl module.
See 'perldoc only' for more information.
END
    }
}

sub get_meta {
    my $dist_name = '';
    my $dist_ver = '';
    if (-f 'META.yml') {
        open META, "META.yml"
          or croak "Can't open META.yml for input:\n$!\n";
        local $/;
        my $meta = <META>;
        close META;
        if ($meta =~ /^name\s*:\s+(\S+)$/m) {
            $dist_name = $1;
        }
        if ($meta =~ /^version\s*:\s+(\S+)$/m) {
            $dist_ver = $1;
        }
    }
    else {
        if (-f 'Makefile') {
            open MAKEFILE, "Makefile"
              or croak "Can't open Makefile for input:\n$!\n";
            local $/;
            my $makefile = <MAKEFILE>;
            close MAKEFILE;
            if ($makefile =~ /^DISTNAME\s*=\s*(\S+)$/m) {
                $dist_name = $1;
            }
            if ($makefile =~ /^VERSION\s*=\s*(\S+)$/m) {
                $dist_ver = $1;
            }
        }
    }
    croak <<END unless length($dist_ver);
Can't determine the version for this install. Please specify manually:

    perl -Monly=install - version=1.23

END
    return ($dist_name, $dist_ver);
}

1;

__END__

=head1 NAME

only::install - Install multiple versions of modules

=head1 SYNOPSIS

    use only::install qw(install);
    
    chdir($module_installation_directory);
    
    install;
    
    install(version => 1.23,
            versionlib => '/my/version/lib',
           );

=head1 DESCRIPTION

This module provides the programmer's API for installing multiple
versions of a module. There is only one exportable function: C<install>.

In order to install, you must be chdir()ed into a valid module
distribution directory, and C<make> or C<./Build> must already have been
run. More specifically, there must be a C<blib> directory and either a
C<Makefile> or a C<META.yml> file.

=head1 ARGUMENTS

=over 4

=item * version

The version parameter tells C<install> which version to install the
distribution modules under. You normally don't need this, since
C<install> can extrapolate the vaule from the Makefile or from the
META.yml file.

=item * versionlib

The versionlib parameter tells where to install the distribution
contents. The default is stored in C<only::config>.

=back

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
