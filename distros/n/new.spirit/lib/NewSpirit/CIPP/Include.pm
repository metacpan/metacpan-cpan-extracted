# $Id: Include.pm,v 1.25 2005/09/21 09:12:49 joern Exp $

package NewSpirit::CIPP::Include;

@ISA = qw(
	NewSpirit::CIPP::Prep
);

use strict;
use Carp;
use NewSpirit::CIPP::Prep;
use NewSpirit::PerlCheck;
use File::Basename;
use CIPP::Compile::NewSpirit;
use IO::String;

sub convert_meta_from_spirit1 {
	my $self = shift;
	
	my ($old_href, $new_href) = @_;
	
	$new_href->{use_strict} = ($old_href->{USE_STRICT} eq 'off' ? 0 : 1);
	
	1;
}

sub get_install_filename {
	my $self = shift;
	
	my $rel_path = "$self->{object_rel_dir}/$self->{object_basename}";
	
	$rel_path =~ s/\.[^\.]+$//;
	my $path = "$self->{project_inc_dir}/$rel_path.code";
	
	$path =~ s!/+!/!g;
	
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
		object_type   	=> 'cipp-inc',
		project_root  	=> $self->{project_root_dir},
		lib_path        => $self->get_runtime_lib_path,
		url_par_delimiter => $self->{project_base_config_data}
				        ->{base_url_par_delimiter},
	);

	my $had_cached_error = -f $CIPP->get_err_filename;

	$CIPP->process();

	my $interface_changed = $CIPP->get_interface_changed;

	# THIS DOES NOT WORK! The $had_cached_error only reports
	# if our object had a *direct* error. But we need also
	# the information, if a preliminary dependency installation
	# reported errors for dependent objects!

	$self->{_cipp_include_dep_inst_needed} = 1;
		# $had_cached_error || $interface_changed;

#	print $CIPP->get_cache_ok ? " 1 " : " 0 ";

	return 2 if $CIPP->get_cache_ok and not $CIPP->has_errors;

	# update dependencies
	$self->build_module_dependencies ( $CIPP );
	$self->update_dependencies ( $CIPP->get_used_objects );

	if ( $CIPP->has_errors ) {
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
	}

#	$self->{_perl_code} = $CIPP->get_perl_code_sref;

	return $ok;
}

sub dependency_installation_needed {
	my $self = shift;
	return 1;
	return $self->{_cipp_include_dep_inst_needed};
}

1;
