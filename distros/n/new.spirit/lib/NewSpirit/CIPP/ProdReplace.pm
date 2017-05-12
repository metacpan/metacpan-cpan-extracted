# $Id: ProdReplace.pm,v 1.5 2003/01/30 16:25:50 joern Exp $

package NewSpirit::CIPP::ProdReplace;

$VERSION = "0.01";

#---------------------------------------------------------------------
# This module is for CIPP object types, which need the functionality
# of multiple versions for different installation targets, i.e.
# Config and Database objects.
#---------------------------------------------------------------------

use strict;
use Carp;
use File::Find;

sub property_widget_target_config {
	my $self = shift;
	
	my %par = @_;
	
	my $name = $par{name};
	my $data = $par{data_href};
	
	my $q = $self->{q};

	my $files = $self->get_base_configs;
	my (@files, %labels);

	foreach my $file (sort keys %{$files}) {
		my $tmp = $file;
		$tmp =~ s!/!.!g;
		$tmp =~ s!\.cipp-base-config$!!;
		$tmp =~ s!\.cipp-driver-config$!!;
		next if $tmp eq 'configuration';
		push @files, $file;
		$labels{$file} = "$self->{project}.$tmp";
	}

	print $q->popup_menu (
		-name    => $name,
		-values  => [ @files ],
		-default => $data->{$name},
		-labels  => \%labels
	);
	
	print qq{<a href="$self->{object_url}&e=refresh_base_config_popup&next_e=properties"><b>Refresh Base Configuration Popup</b></a>},
}

#---------------------------------------------------------------------
# get_base_configs - Returns a hash of base config objects
#---------------------------------------------------------------------
# SYNOPSIS:
#	$config_href = $self->get_base_configs
#
# DESCRIPTION:
#	This method returns a hash of base config object names defined
#	in this project. This hash ist stored in a project specific
#	file. If this file does not exist, the information will
#	be gathered from the filesystem and stored to the file.
#
#	If base configuration objects are created or deleted this
#	file must be updated.
#---------------------------------------------------------------------

sub get_base_configs {
	my $self = shift;
	
	my $base_configs_file = $self->{project_base_configs_file};
	
	if ( not -f $base_configs_file ) {
		# uh oh, not there yet, we must scan the source
		# tree for cipp-base-config files
		
		my %files;
		my $src_dir = $self->{project_src_dir};
		find (
			sub {
				return 1 if /^\./;
				if ( /\.(cipp-base-config|cipp-driver-config)$/ ) {
					my $filename = "$File::Find::dir/$_";
					$filename =~ s!^$src_dir/!!;
					$files{$filename} = 1;
				}
				1;
			},
			$src_dir
		);
		
		my $df = new NewSpirit::DataFile ($base_configs_file);
		$df->write (\%files);
		$df = undef;
		
		return \%files;
	} else {
		my $df = new NewSpirit::DataFile ($base_configs_file);
		return $df->read;
	}
}

#---------------------------------------------------------------------
# refresh_base_config_popup - Creates a new base config hash file
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->refresh_base_config_popup
#
# DESCRIPTION:
#	The base_config hash file will be recreated. Then the to
#	$q->param('next_e') corresponding _ctrl method ist called.
#---------------------------------------------------------------------

sub refresh_base_config_popup {
	my $self = shift;
	
	my $file = $self->{project_base_configs_file};
	unlink $file;
	
	$self->get_base_configs;

	my $e = $self->{q}->param('next_e');
	my $method = "${e}_ctrl";

	$self->{event} = $e;
	$self->$method();
}

#---------------------------------------------------------------------
# get_install_object_name - returns target object name for actual base config
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->get_install_object_name
#
# DESCRIPTION:
#	Depending on $self->{project_base_conf} the target object
#	name will be determined.
#	
#---------------------------------------------------------------------

sub get_install_object_name {
	my $self = shift;
	
	my $project_base_conf = $self->{project_base_conf};
	return $self->{object_name}
		if $project_base_conf eq $CFG::default_base_conf;

	my $prop = $self->get_meta_data;
	
	if ( $prop->{target_config} eq $self->{project_base_conf} and
	     $prop->{replace_object} ) {
		return $self->canonify_object_name ($prop->{replace_object});
	}
	
	return $self->{object_name};
}

sub replace_target_prod_file {
	my $self = shift;
	
	my $object_name = $self->get_install_object_name;

	if ( $object_name ne $self->{object_name} ) {
		print "$self->{object_name} replaces $object_name ... ";
		print "<FONT COLOR=green><B>OK</B></FONT><br>\n";
		$self->install_file;
		
		return $object_name;
	} else {
		return;
	}
}

sub installation_allowed {
	my $self = shift;
	
	if ( $self->{project_base_conf} eq $CFG::default_base_conf ) {
#		print STDERR "$self->{object_name}: normal install\n";
		return 1;
	} else {
		# ok we have an alternate base config
		my $object_name = $self->get_install_object_name;
		if ( $object_name ne $self->{object_name} ) {
			# only install, if we are a replace object
#			print STDERR "$self->{object_name}: replace install -> $object_name\n";
			return 2;
		}
	}
	
#	print STDERR "$self->{object_name}: NO install\n";
	0;
}

sub check_properties {
	my $self = shift;
	
	my ($meta) = @_;
	
	return if not $meta->{replace_object};
	
	my $filename = $self->get_object_src_file ( $meta->{replace_object} );
	
	if ( not $filename ) {
		return "Replace object '$meta->{replace_object}' does not exist!";
	} else {
		return;
	}
	
	return;
}

1;


