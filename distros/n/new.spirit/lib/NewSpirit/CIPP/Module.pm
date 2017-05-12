# $Id: Module.pm,v 1.22 2005/09/21 09:12:49 joern Exp $

package NewSpirit::CIPP::Module;

$VERSION = "0.01";
@ISA = qw(
	NewSpirit::CIPP::Prep
);

use strict;
use Carp;
use NewSpirit::CIPP::Prep;
use NewSpirit::PerlCheck;
use File::Basename;
use CIPP::Compile::NewSpirit;
use NewSpirit::LKDB;
use IO::String;

sub get_install_filename {
	my $self = shift;
	
	my $meta_href = $self->get_meta_data;
	return if not $meta_href->{_pkg_name};

	my $rel_path = $meta_href->{_pkg_name};
	$rel_path =~ s!::!/!g;

	my $path = "$self->{project_lib_dir}/$rel_path.pm";
	
	return $path;
}

sub install_file {
	my $self = shift;

	my $ok = 1;
	$self->{install_errors} = {};

	my $trunc_ws = $self->{project_base_config_data}
			    ->{base_trunc_ws};

	my $CIPP = CIPP::Compile::NewSpirit->new (
		program_name  	=> $self->{object_name},
		project 	=> $self->{project},
		trunc_ws        => $trunc_ws,
		start_context 	=> 'html',
		object_type   	=> 'cipp-module',
		project_root  	=> $self->{project_root_dir},
		lib_path        => $self->get_runtime_lib_path,
		url_par_delimiter => $self->{project_base_config_data}
				        ->{base_url_par_delimiter},
	);

	$CIPP->process();

	return 2 if $CIPP->get_cache_ok and not $CIPP->has_errors;

	# update dependencies
	$self->build_module_dependencies ($CIPP);
	$self->update_dependencies ( $CIPP->get_used_objects );

	# check if module exists elsewhere
	$self->check_double_module_definition ($CIPP);

	if ( $CIPP->has_errors ) {
		# uh oh, errors! ;)
		$ok = 0;
		# if we are in a dependency installation, we
		# only give a brief list of the errors, and no
		# error highlighted version of the source code
		if ( $self->{dependency_installation} ) {
			if ( $CIPP->has_direct_errors ) {
				$self->{install_errors}->{unformatted}
					= $CIPP->get_messages;
			} else {
				$ok = -1;
			}
		} else {
			$self->{install_errors}->{formatted}
				= $CIPP->format_debugging_source (
					brief => $self->{command_line_mode}
				);
		}

#		my $perl_code_sref = $CIPP->get_perl_code_sref;
#		open (OUT, "> /tmp/cippdebug");
#		print OUT $$perl_code_sref;
#		close OUT;

	} else {
		# ok, check if the module name changed
		my $module_name = $CIPP->get_module_name;
		my $meta = $self->get_meta_data;

		if ( $meta->{_pkg_name} ne $module_name ) {
			# module name changed
			# lets delete the old module installation file
			my $old_inst_file = $self->get_install_filename;
			unlink $old_inst_file;

			# store the new module name
			$meta->{_pkg_name} = $module_name;
			$self->save_meta_data ($meta);

			# and create the path for the new module name
			$self->make_install_path;
		}
	}

#	$self->{_perl_code} = $CIPP->get_perl_code_sref;

	return $ok;
}

sub check_double_module_definition {
	my $self = shift;
	
	my ($CIPP) = @_;
	
	my $module_name = $CIPP->get_module_name;
	
	my $module_file = new NewSpirit::LKDB ($self->{project_modules_file});
	my $href = $module_file->{hash};

	if ( $href->{$module_name} and $href->{$module_name} ne $self->{object} ) {
		my $object = $href->{$module_name};
		$object =~ s/\.([^.]+)$//;
		$object =~ s!/!.!g;
		$object = "$self->{project}.$object";
		$CIPP->add_message (
			line_nr => 0,
			tag     => 'module',
			message => "Module '$module_name' is already defined in $object"
		);
	} else {
		$href->{$module_name} = $self->{object} if not $href->{$module_name};
	}
}

1;
