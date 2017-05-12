package NewSpirit::CIPP::Prep;

$VERSION = "0.01";
@ISA = qw ( NewSpirit::Object::Text );

#---------------------------------------------------------------------
# This module provides methods for preprocessing CIPP source to
# Perl code (e.g. NewSpirit::CIPP::CGI and NewSpirit::CIPP::Include
# use it).
#---------------------------------------------------------------------

use strict;
use Carp;
use NewSpirit::Object::Text;

sub get_meta_data {
	my $self = shift;

	# this overloading of Object::get_meta_data is a
	# workaround. Sometimes the use_strict field is
	# not inialized correct, so we do this here.
	
	my $meta = $self->SUPER::get_meta_data;
	
	if ( exists $meta->{use_strict} and
	     not defined $meta->{use_strict} ) {
		# uh oh, not defined, that is bad :(
		# Default is USE STRICT !!! ;)
		$meta->{use_strict} = 1;
		$self->save_meta_data ($meta);
	}
	
	return $meta;
}


sub get_old_style_databases {
	# this method returns the databases hash with the
	# old style object dot separated notation for the
	# object names. CIPP expects it in this format.

	my $self = shift;
	
	my $databases_href = $self->get_databases;
	
	my %hash;
	foreach my $k (keys %{$databases_href}) {
		my $new_k = $k;
		$new_k =~ s!\.[^\.]+$!!;
		$new_k =~ s!/!.!g;
#		$new_k = "x.$new_k";
		$hash{$new_k} = $databases_href->{$k};
	}
	
	my $default_db = $self->get_default_database;
	
	if ( $default_db ) {
		$hash{default} = "CIPP::DB_DBI";
	}
	
	return \%hash;
}

sub get_old_style_default_database {
	# this method returns the default database in the
	# old style object dot separated notation.
	# CIPP expects it in this format.

	my $self = shift;
	
	my $default_db = $self->get_default_database;
	return "" if not $default_db;

	$default_db =~ s!\.[^\.]+$!!;
	$default_db =~ s!\.!_!g;
	$default_db = $self->{project}.".$default_db";

	return $default_db;	
}

sub print_pre_install_message {
	my $self = shift;
	
	print "<p>$CFG::FONT CIPP Preprocessing in progress...</FONT><p>\n";

	1;
}

sub print_install_errors {
	my $self = shift;

	my ($errors) = @_;

	my $head = qq{$CFG::FONT<FONT COLOR="red">}.
		   qq{<b>There are \%s errors:</b>}.
		   qq{</FONT>%s</FONT><p>\n};

	if ( $errors ) {
		# if $errors is given, we assume to be used for printing
		# the error summary for a dependency installation, so
		# the "There are bla errors" header is omitted.
		$head = '';
	}

	$errors ||= $self->{install_errors};

	if ( ref $errors eq 'ARRAY' ) {
		$self->SUPER::print_install_errors(@_);
		return 1;
	}


	if ( $errors->{formatted} ) {
		# formatted preprocessor errors
		print <<__HTML;
<FONT SIZE="$CFG::FONT_SIZE">
$CFG::FONT<b><a href="$self->{object_url}&e=download_prod_err_file&no_http_header=1">[DOWNLOAD PERL CODE]</a></b></font><br>
${$errors->{formatted}}
</FONT>
__HTML
	}
	
	if ( $errors->{perl} ) {
		# Perl syntax errors!
		printf (
			$head,
			'Perl syntax',
			qq{ <b><a href="$self->{object_url}&e=function&f=show_perl">}.
			qq{[Show Perl Source]}.
			qq{</a></b>}.
			qq{ <b><a href="$self->{object_url}&e=function&f=download_perl&no_http_header=1">}.
			qq{[Download]}.
			qq{</a></b>}
		);

		my $errors = ${$errors->{perl}};
		$errors =~ s/\n/<p>/g;

		print <<__HTML;
<FONT SIZE="$CFG::FONT_SIZE">
<tt>
$errors
</tt>
</FONT>
__HTML
	}
	
	if ( $errors->{perl_unformatted} ) {
		printf ($head, 'Perl syntax');
		print <<__HTML;
<table border=1 width="100%">
<tr bgcolor="#555555">
  <td>$CFG::FONT<font color="white"><b>Unformatted Perl Error Messages</b></FONT></FONT></td>
</tr>
<tr>
  <td>$CFG::FONT${$errors->{perl_unformatted}}</font></td>
</tr>
</table>
__HTML
	}

	if ( $errors->{unformatted} ) {
		# Unformatted CIPP errors
		printf ($head, 'CIPP preprocessor');
		print <<__HTML;
<table border=1 width="100%">
<tr bgcolor="#555555">
  <td width="10%">$CFG::FONT<font color="white"><b>Line</b></FONT></FONT></td>
  <td width="90%">$CFG::FONT<font color="white"><b>Message</b></FONT></FONT></td>
</tr>
__HTML

		my @bgcolor = (
			'bgcolor="#eeeeee"',
			'bgcolor="#dddddd"',
		);
		my $idx = 0;

		foreach my $err ( @{$errors->{unformatted}} ) {
			my $name = $err->get_name;
			my $line = $err->get_line_nr;
			my $tag  = $err->get_tag;
			my $msg  = $err->get_message;

			$msg =~ s/</&lt;/g;

			++$idx;
			$idx = 0 if $idx == 2;

			print qq{<tr $bgcolor[$idx]>},
			      qq{<td valign=top>$CFG::FONT$line</font></td>},
			      qq{<td valign=top>$CFG::FONT$msg</font></td></tr>\n};

		}			
		print "</table>\n";
	}

	if ( $errors->{other} ) {
		# Other errors
		printf ($head, 'installation');
		print <<__HTML;
<FONT SIZE="$CFG::FONT_SIZE"><pre>
__HTML
		print join ("\n", @{$errors->{other}});
		print "</pre></FONT>\n";
	}

	1;
}

sub function_ctrl {
	my $self = shift;
	
	my $q = $self->{q};
	my $f = $q->param('f');
	
	if ( $f eq 'show_perl' ) {
		$self->object_header ("Show Perl Code");
		$self->install_file;
		
		${$self->{_perl_code}} =~ s/</&lt;/g;
		
		print "<font size=$CFG::FONT_SIZE><tt><pre>";
		print ${$self->{_perl_code}};
		print "</tt></pre></font>\n";

		NewSpirit::end_page();
	} elsif ( $f eq 'download_perl' ) {
		$self->install_file;
		my $mime_type = $self->{object_type_config}->{mime_type};
		print $q->header(
			-nph => 1,
			-type => $mime_type,
			-Pragma => 'no-cache',
			-Expires => 'now'
		);
		print ${$self->{_perl_code}};
	}
}

sub create {
	my $self = shift;
	
	$self->SUPER::create;
	
	my $meta_href = $self->get_meta_data;
	$meta_href->{use_strict} = 1;
	$self->save_meta_data ($meta_href);
	
	return;
}

sub build_module_dependencies {
	my $self = shift;
	
	my ($CIPP) = @_;
	
	my $used_modules = $CIPP->get_used_modules;
	return if not $used_modules;
	
	my $module_file = new NewSpirit::LKDB ($self->{project_modules_file});
	my $href = $module_file->{hash};

	foreach my $module ( keys %{$used_modules} ) {
		my $object_file = $href->{$module};
		my $object_type = $self->get_object_type($object_file);
		$CIPP->add_used_object ($object_file, $object_type);
	}

	1;
}

sub check_for_perl_errors {
	my $self = shift;
	my %par = @_;
	my  ($parser, $perl_code_sref, $output_file) =
	@par{'parser','perl_code_sref','output_file'};

	my $lib_path = $self->{project_base_config_data}->{base_perl_lib_dir};

	$parser->check_for_perl_errors (
		lib_path       => $lib_path,
		perl_code_sref => $perl_code_sref,
		output_file    => $output_file,
	);

	1;
}

sub get_runtime_lib_path {
	my $self = shift;
	
	my $add_lib_dir =
		$self->{project_base_config_data}
		     ->{base_perl_lib_dir};

	my $add_prod_dir =
		$self->{project_base_config_data}
		     ->{base_add_prod_dir};

	my $project_root = $self->{project_lib_dir};
	
	my $lib_path = "$add_lib_dir:$add_prod_dir:$project_root";
	
	$lib_path =~ s/:+/:/g;
	$lib_path =~ s/^://g;
	
	return $lib_path;
}

1;


