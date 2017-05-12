#!/usr/dim/perl/5.8/bin/perl

# $Id: mktardist.pl,v 1.11 2004/09/14 09:08:03 joern Exp $

use strict;
use File::Find;
use File::Path;
use File::Copy;
use Data::Dumper;
require "etc/newspirit.conf";

$| = 1;

main: {
	my $real_files = scan_filesystem();
	my $plan_files = scan_manifest();

	my ($missing, $too_much) = check_files ($real_files, $plan_files);
	
	files_ok ($missing, $too_much);

	create_filemodes ("etc/filemodes.conf", $plan_files);
	create_modules ("etc/perl-modules.conf", $plan_files);
	create_conf_template ("etc/newspirit.conf", "etc/tmpl-newspirit.conf");
	create_windows_documents (
		"README", "RELEASE", "CHANGES"
	);

	mk_dist("dist", $plan_files);
}


exit;


main: {
	my $real_files = scan_filesystem();
	my $plan_files = scan_manifest();

	my ($missing, $too_much) = check_files ($real_files, $plan_files);
	
	files_ok ($missing, $too_much);

	create_filemodes ("etc/filemodes.conf", $plan_files);
	create_conf_template ("etc/newspirit.conf", "etc/tmpl-newspirit.conf");
	
	mktar ( $plan_files );
}

sub scan_filesystem {
	my %files;
	
	find (
		sub {
			if ( /CVS|cvsignore|dist|projects|develop|\.bck|passwd|\.lck|user-config|\.#/ or
			     $File::Find::dir =~ /var/ ) {
				$File::Find::prune = 1 if -d $_;
				return;
			}
			return if $_ eq '.';
			$files{"$File::Find::dir/$_"} = 1;
		},
		"."
	);
	
	return \%files;
}

sub scan_manifest {
	my %files;
	
	open (MF, "MANIFEST") or die "can't read MANIFEST";
	while (<MF>) {
		chomp;
		$files{"./$_"} = 1;
	}
	close MF;
	
	return \%files;
}

sub check_files {
	my ($real, $plan) = @_;
	
	my @too_much;
	my @missing;
	
	foreach my $entry (keys %{$real}) {
		push @too_much, $entry if not $plan->{$entry};
	}
	
	foreach my $entry (keys %{$plan}) {
		if ( not -r $entry ) {
			push @missing, $entry;
		} else {
			$plan->{$entry} = (stat($entry))[2];
		}
	}
	
	return (\@missing, \@too_much);
}

sub files_ok {
	my ($missing, $too_much) = @_;
	
	print "Missing files:\n";
	foreach my $entry (sort @{$missing}) {
		print "\t$entry\n";
	}
	
	print "\nUnknown files:\n";
	foreach my $entry (sort @{$too_much}) {
		print "\t$entry\n";
	}
	
	print "\n";
	
	print "Press Ctrl+C to cancel here.\n";
	<STDIN>;
	
	1;
}

sub create_filemodes {
	my ($filename, $href) = @_;
	
	open (OUT, "> $filename") or die "can't write $filename";
	print OUT Dumper ($href);
	close OUT;
}

sub create_conf_template {
	my ($from, $to) = @_;
	
	open (FROM, "$from") or die "can't read $from";
	open (TO, "> $to") or die "can't write $to";
	
	my %default = (
		root_dir => '',
		cgi_url => '/cgi-bin2',
		htdocs_url => '/newspirit2',
		db_module => '',
		ldap_enable => 0,
		ldap_server => 'ldap',
		ldap_base => 'o=dimedis.de',
		ldap_uid => 'uid',
	);
	
	while (<FROM>) {
		next if /#--delete--#/;
		if ( /;\s+#--(.*)--#/ ) {
			print TO "\t" if $1 eq 'root_dir';
			print TO "\$$1 = '$default{$1}'; #--$1--#\n";
		} else {
			print TO $_;
		}
	}
	
	close FROM;
	close TO;
}

sub mktar {
	my ($files) = @_;
	
	my $file_list;
	foreach my $file (sort keys %{$files}) {
		$file_list .= $file." " if not -d $file;
	}
	
	$file_list .= "tmpl tools usertmpl usertools var/lock var/sessions";
	
	my $filename = "new.spirit-$CFG::VERSION.tar";
	
	system ("tar cfz $filename.gz $file_list");
#	system ("tar cfI $filename.bz2 $file_list");
	
	1;
}

sub mk_dist {
	my ($dir, $files) = @_;
	
	my $base_dir = $dir;

	mkdir $dir, 0775;

	$dir = "$dir/new.spirit";
	rmtree ([$dir]);
	mkdir $dir, 0775;
	
	foreach my $entry (sort keys %{$files}) {
		if ( -d $entry ) {
			print "mkdir $dir/$entry\n";
			mkdir "$dir/$entry", 0775;
		} else {
			print "copy $dir/$entry $files->{$entry}\n";
			copy ($entry, "$dir/$entry");
		}
		chmod $files->{$entry}, "$dir/$entry";
	}
	
	my $filename = "new.spirit-$CFG::VERSION";
	
	system ("cd $base_dir;
	         tar cf - new.spirit | gzip -c --best > $filename.tar.gz;
		 rm -f $filename.zip;
		 zip -r -9 $filename.zip new.spirit");
	
	1;
}

sub create_modules {
	my ($filename, $files) = @_;
	
	my %modules;
	
	foreach my $file ( sort keys %{$files} ) {
		next if $file !~ /\.(pl|pm)$/;
		open (FILE, $file) or die "can't read $file";
		while (<FILE>) {
			if ( /use ([\w:]+)(\s+[\d\._]+)?;/ ) {
				my $module = $1;
				next if $module =~ /^[a-z]+$/;
				next if $module =~ /^.*?_File/;
				next if $module =~ /^NewSpirit/;
				$modules{"$1$2"} = 1;
			}
		}
	}
	
	open (OUT, "> $filename") or die "can't write $filename";
	print OUT Dumper (\%modules);
	close OUT;
}

sub create_windows_documents {
	my @files = @_;
	
	foreach my $file ( @files ) {
		my $win_file = "$file.txt";
		open (IN, $file) or die "can't read $file";
		open (OUT, ">$win_file") or die "can't write $win_file";
		
		print OUT "This is the Windows formatted version of the file '$file'.\r\n\r\n";
		
		while (<IN>) {
			chomp $_;
			print OUT "$_\r\n";
		}
		close IN;
		close OUT;
	}
		
		
}
