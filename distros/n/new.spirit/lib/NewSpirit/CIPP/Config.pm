# $Id: Config.pm,v 1.14 2004/09/10 12:51:22 joern Exp $

package NewSpirit::CIPP::Config;

$VERSION = "0.01";
@ISA = qw(
	NewSpirit::CIPP::Prep
	NewSpirit::CIPP::ProdReplace
);
#
use strict;
use Carp;
use NewSpirit::CIPP::Prep;
use NewSpirit::CIPP::ProdReplace;
use CIPP::Compile::PerlCheck;
use File::Basename;
use FileHandle;

sub get_install_filename {
	my $self = shift;
	
	# this method comes from ProdReplace. It may return
	# another object name as the installation target
	my $filename = $self->get_install_object_name;
	return if not $filename;

	$filename = "$filename.config";

	# remove projekt name
	$filename =~ s/^.*?\.//;

	return "$self->{project_config_dir}/$filename";
}

sub print_pre_install_message {
	my $self = shift;
	
	print "<p>$CFG::FONT Perl syntax checking in progress...</FONT><p>\n";

	1;
}

sub install_file {
	my $self = shift;

	my $prod_replace;
	return 1 if not $prod_replace = $self->installation_allowed;	# prod replace
	return 2 if $prod_replace != 2 and $self->is_uptodate;

	my $perl_code_sref = $self->get_data;

	# check Perl syntax
	$$perl_code_sref = "no strict;\n".$$perl_code_sref;

	my $pc = CIPP::Compile::PerlCheck->new (
		directory => $self->{project_config_dir},
		lib_path  => $self->get_runtime_lib_path,
	);
	
	my $error_sref = $pc->check (
		code_sref    => $perl_code_sref,
		parse_result => 0,
	);

	$self->{install_errors} = {};
	my $ok = 1;
	if ( $error_sref ) {
		# uh, oh, errors! :))
		$ok = 0;

		$self->{install_errors}->{perl_unformatted} = \$error_sref;

	} else {
		# OK, let's install the config file
		my $to_file = $self->get_install_filename;
		return 1 if not $to_file;

		my $fh = new FileHandle;
		my ($success, $message);
		if ( open ($fh, "> $to_file") ) {
			print $fh $$perl_code_sref;
			close $fh;
			chmod 0664, $to_file;
		} else {
			push @{$self->{install_errors}->{other}},
				"Can't write '$to_file'!";
		}
	}

	return $ok;
}

1;
