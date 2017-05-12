#!/usr/bin/env perl
##!/usr/perl5.8.0/bin/perl5.8.0
# -*- perl -*-
#
# DO NOT EDIT, created automatically by
# /home/e/eserte/bin/sh/mkprereqinst
# on Fri Aug  1 15:01:59 2003
#
# The latest version of mkprereqinst may be found at
# http://www.perl.com/CPAN-local/authors/id/S/SR/SREZIC/

use Getopt::Long;
my $require_errors;
my $use = 'cpan';

if (!GetOptions("ppm"  => sub { $use = 'ppm'  },
		"cpan" => sub { $use = 'cpan' },
	       )) {
    die "usage: $0 [-ppm | -cpan]\n";
}

$ENV{FTP_PASSIVE} = 1;

if ($use eq 'ppm') {
    require PPM;
    do { print STDERR 'Install XML-Parser'.qq(\n); PPM::InstallPackage(package => 'XML-Parser') or warn ' (not successful)'.qq(\n); } if !eval 'require XML::Parser';
    do { print STDERR 'Install Tk'.qq(\n); PPM::InstallPackage(package => 'Tk') or warn ' (not successful)'.qq(\n); } if !eval 'require Tk';
} else {
    use CPAN;
    install 'XML::Parser' if !eval 'require XML::Parser';
    install 'Tk' if !eval 'require Tk';
}
if (!eval 'require XML::Parser;') { warn $@; $require_errors++ }
if (!eval 'require Tk;') { warn $@; $require_errors++ }

if (!$require_errors) { warn "Autoinstallation of prerequisites completed\n" } else { warn "$require_errors error(s) encountered while installing prerequisites\n" } 
