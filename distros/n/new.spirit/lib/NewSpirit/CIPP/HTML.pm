# $Id: HTML.pm,v 1.24 2005/09/21 09:12:49 joern Exp $

package NewSpirit::CIPP::HTML;

$VERSION = "0.01";
@ISA = qw( 
	NewSpirit::CIPP::Prep
);

use strict;
use Carp;
use File::Copy;
use File::Basename;
use CIPP;
use NewSpirit::CIPP::Prep;
use CIPP::Compile::NewSpirit;
use Config;

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
	
	# strip 'cipp-' from the extension
	my $ext = $self->{object_ext};
	$ext =~ s/^cipp-//;
			
	my $path = "$self->{project_htdocs_dir}/$rel_path.$ext";
	$path =~ s!/+!/!g;
	
	return $path;
}

sub install_file {
	my $self = shift;

	my $ok = 1;
	$self->{install_errors} = {};

	my $shebang = $self->{project_base_config_data}
			   ->{base_prod_shebang} ||
			   '#!'.$Config{'perlpath'};

	my $trunc_ws = $self->{project_base_config_data}
			    ->{base_trunc_ws};

	my $CIPP = CIPP::Compile::NewSpirit->new (
		program_name  	=> $self->{object_name},
		project 	=> $self->{project},
		start_context 	=> 'html',
		shebang       	=> $shebang,
		trunc_ws        => $trunc_ws,
		object_type   	=> 'cipp-html',
		project_root  	=> $self->{project_root_dir},
		project_prod	=> $self->{project_prod_dir},
		config_dir	=> $self->{project_config_dir},
		no_http_header  => 1,
		lib_path        => $self->get_runtime_lib_path,
		url_par_delimiter => $self->{project_base_config_data}
				        ->{base_url_par_delimiter},
	);

	$CIPP->process();

	return 2 if $CIPP->get_cache_ok and not $CIPP->has_errors;

	# update dependencies
	$self->build_module_dependencies ($CIPP);
	$self->update_dependencies ( $CIPP->get_used_objects );

	if ( $CIPP->has_errors ) {
		# uh oh, errors! ;)
		$ok = 0;
		# if we are in a dependency installation, we
		# only give a brief list of the errors, and no
		# error highlighted version of the source code
		if ( $self->{dependency_installation} ) {
			$self->{install_errors}->{unformatted}
				= $CIPP->get_messages;
		} else {
			$self->{install_errors}->{formatted}
				= $CIPP->format_debugging_source (
					brief => $self->{command_line_mode}
				);
		}
	}

	return $ok;
}

1;
