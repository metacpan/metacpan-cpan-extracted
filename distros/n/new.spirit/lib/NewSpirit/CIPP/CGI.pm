package NewSpirit::CIPP::CGI;

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
use IO::String;
use Config;

sub convert_meta_from_spirit1 {
	my $self = shift;
	
	my ($old_href, $new_href) = @_;
	
	$new_href->{mime_type} = $old_href->{MIME_TYPE};
	$new_href->{use_strict} = ($old_href->{USE_STRICT} eq 'off' ? 0 : 1);
	
	1;
}

sub get_install_filename {
	my $self = shift;
	
	my $rel_path = "$self->{object_rel_dir}/$self->{object_basename}";
	
	$rel_path =~ s/\.[^\.]+$//;
	my $path = "$self->{project_cgi_dir}/$rel_path.cgi";
	
	$path =~ s!/+!/!g;
	
	return $path;
}

sub install_file {
	my $self = shift;

	my $meta = $self->get_meta_data;

	# determine MIME Type and 'use strict' mode
	my $mime_type = $meta->{mime_type};

	$self->{install_errors} = {};

	my $ok = 1;

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
		object_type   	=> 'cipp',
		project_root  	=> $self->{project_root_dir},
		mime_type	=> $mime_type,
		lib_path        => $self->get_runtime_lib_path,
		url_par_delimiter => $self->{project_base_config_data}
				        ->{base_url_par_delimiter},
	);

	$CIPP->process();

#	print $CIPP->get_cache_ok ? "&nbsp;1&nbsp;" : "&nbsp;0&nbsp;";

	return 2 if $CIPP->get_cache_ok and not $CIPP->has_errors;

	# update dependencies
	$self->build_module_dependencies ( $CIPP );
	$self->update_dependencies ( $CIPP->get_used_objects );

	# did we have errors?
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
	}

#	$self->{_perl_code} = $CIPP->get_perl_code_sref;

	return $ok;
}

1;
