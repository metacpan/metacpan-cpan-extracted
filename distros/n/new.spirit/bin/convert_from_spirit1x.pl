#!/usr/dim/perl/5.8/bin/perl

use strict;
use SDBM_File;
use Cwd;
use Fcntl;
use Data::Dumper;

$| = 1;

my $TEST = 0;

main: {
	$TEST && print "Test modus! No modifications!\n\n";

	my $spirit1_path = 'XXX';
	while ( not -f "$spirit1_path/etc/passwd.pag" ) {
		$spirit1_path = ask (
			text => "Absolute path of your spirit 1.x installation",
			default => "/usr/projects/newspirit"
		);
	}
	
	my $spirit2_path = 'XXX';
	my $default = cwd();
	$default =~ s!/[^/]+$!!;
	
	while ( not -d "$spirit2_path/var/sessions" ) {
		$spirit2_path = ask (
			text => "Absolute path of your spirit 2.x installation",
			default => $default
		);
	}
	
	require "$spirit2_path/etc/newspirit.conf";
	push @INC, "$spirit2_path/lib";
	require NewSpirit::LKDB;
	require NewSpirit::Project;
	
	convert_projects (
		from => "$spirit1_path/etc/projects",
	);
	
	convert_passwd (
		from => "$spirit1_path/etc/passwd",
		to   => "$spirit2_path/var/users/passwd"
	);
	
}

sub convert_projects {
	my %par = @_;
	
	my $from = $par{from};
	
	my %from_hash;
	
	tie (%from_hash, 'SDBM_File', $from, O_CREAT|O_RDWR, 0660)
		or die "can't tie $from as SDBM_File";

	my ($k, $v);
	my %projects;
	my %par_map = (
		DIRECTORY   => 'root_dir',
		DESCRIPTION => 'description',
		COPYRIGHT   => 'copyright'
	);

	while ( ($k, $v) = each %from_hash ) {
		my ($project, $par_name) = split ('_', $k, 2);
		if ( $par_map{$par_name} ) {
			$projects{$project}->{$par_map{$par_name}} = $v;
		}
	}
	
	my $p = new NewSpirit::Project;
	
	foreach my $project ( keys %projects ) {
		print "project '$project': $projects{$project}->{root_dir}\n";
		
		$projects{$project}->{project_name} = $project;
		$projects{$project}->{cvs} = 0;
		$projects{$project}->{cvs_module} = '';
		
		$TEST || $p->write_project_config ( $project, $projects{$project} );
	}
	
}

sub convert_passwd {
	my %par = @_;
	
	my $from = $par{from};
	my $to   = $par{to};
	
	my %from_hash;
	
	tie (%from_hash, 'SDBM_File', $from, O_CREAT|O_RDWR, 0660)
		or die "can't tie $from as SDBM_File";
	
	my $lkdb = new NewSpirit::LKDB ( $to );
	
	my ($user, $record);
	while ( ($user, $record) = each %from_hash ) {
		print "copy record of user '$user'\n";
		if ( not $TEST ) {
			$lkdb->{hash}->{$user} = $record;
		}
	}
	
	untie %from_hash;
}


sub ask {
	my %par = @_;
	
	my $text = $par{text};
	my $default = $par{default};
	
	print "$text [ '$default' ] : ";
	
	my $value = <STDIN>;
	
	chomp $value;
	
	return $value || $default;
}
