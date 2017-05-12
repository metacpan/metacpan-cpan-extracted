package NewSpirit::CIPP::Base;

$VERSION = "0.01";
@ISA = qw( NewSpirit::Object::Record );

use strict;
use CIPP;

my %FIELD_DEFINITION = (
	base_doc_url => {
		description => 'Document Mapping URL',
		type => 'text',
		check => "this.form.base_doc_url.value.substring(0,1)=='/'",
		alert => "Mappings must be a absolute URL",
	},
	base_cgi_url => {
		description => 'CGI Mapping URL',
		type => 'text',
		check => "this.form.base_cgi_url.value.substring(0,1)=='/'",
		alert => "Mappings must be a absolute URL",
	},
	base_server_name => {
		description => 'Server Domain Name[:Port]<br>(for local testing only)',
		type => 'text',
	},
	base_error_show => {
		description => 'Show Perl / CIPP Error Messages',
		type => 'switch'
	},
	base_error_text => {
		description => 'User Friendly Error Message',
		type => 'textarea'
	},
	base_http_header => {
		description => 'Default HTTP Header<br>(Key Whitespace Value)',
		type => 'textarea'
	},
	base_default_db => {
		description => 'Default Database',
		type => 'method'
	},
	base_perl_lib_dir => {
		description => 'Additional Perl Library Directories<br>'.
			       '(Colon delimited)',
		type => 'text'
	},
	base_add_prod_dir => {
		description => 'Additional CIPP Project prod Directories<br>'.
			       '(for Include and Module access - Colon delimited)',
		type => 'text'
	},
	base_install_dir => {
		description => 'Local Installation Directory</b><br>'.
			       '(relative to local project root directory, '.
			       '<b>mandatory)',
		type => 'text'
	},
	base_prod_root_dir => {
		description => 'Project root directory of production system</b><br>'.
			       '(leave empty if this does not differ from'.
			       'your local development system)<b>',
		type => 'text'
	},
	base_history_size => {
		description => "Object history limit (Default $CFG::default_history_size)",
		type => 'text 4',
	},
	base_prod_shebang => {
		description => 'Default Shebang line of production system</b><br>'.
			       '(leave empty if this does not differ from'.
			       'your local development system)<b>',
		type => 'text',
	},
	base_prod_shebang_map => {
		description => 'Map for advanced Shebang Line settings</b><br>'.
			       '(whitespace delimited, 2 fields, left: folder or object name '.
			       'in dotted notation, right: corresponding shebang line)',
		type => 'textarea',
	},
	base_url_par_delimiter => {
		description => 'Delimiter for CGI parameters',
		type => [ '&', ';' ],
	},
	base_utf8 => {
		description => 'Use UTF8 character set',
		type => "switch",
	},
	base_xhtml => {
		description => 'Generate XHTML conform code',
		type => "switch",
	},
	base_trunc_ws => {
		description => 'Truncate whitespace around CIPP tags',
		type => "switch",
	},
	base_cipp2_runtime => {
		description => 'Load CIPP2 Runtime for compatability',
		type => "switch",
	},
	_base_project => {
		type => 'text',
	},
	_base_server => {
		type => 'text',
	},
);

my @FIELD_ORDER_DEFAULT_CONFIG = (
	'base_doc_url', 'base_cgi_url', 'base_server_name', 'base_error_show',
	'base_error_text', 'base_http_header', 'base_perl_lib_dir',
	'base_add_prod_dir',
	'base_default_db', 'base_url_par_delimiter',
	'base_utf8', 'base_xhtml', 'base_trunc_ws',
	'base_cipp2_runtime','base_prod_shebang',
	'base_history_size', '_base_project', '_base_server',
);

my @FIELD_ORDER_NON_DEFAULT_CONFIG = (
	'base_doc_url', 'base_cgi_url', 'base_error_show',
	'base_error_text', 'base_http_header',  'base_perl_lib_dir',
	'base_add_prod_dir',
	'base_default_db', 'base_url_par_delimiter',
	'base_utf8', 'base_xhtml', 'base_trunc_ws',
	'base_cipp2_runtime',
	'base_install_dir', 'base_prod_root_dir',
	'base_prod_shebang', 'base_prod_shebang_map',
);
use Carp;
use NewSpirit::Object::Record;
use NewSpirit::Param1x;
use FileHandle;

sub init {
	my $self = shift;
	
	$self->{record_field_definition} = \%FIELD_DEFINITION;

	if ( $self->{object} eq $CFG::default_base_conf ) {
		# the default base configuration object has no
		# field for the production directory, this defaults
		# always to "$project_root_dir/prod"
		$self->{record_field_order} = \@FIELD_ORDER_DEFAULT_CONFIG;
	} else {
		$self->{record_field_order} = \@FIELD_ORDER_NON_DEFAULT_CONFIG;
	}
	
	1;
}

sub convert_data_from_spirit1 {
	my $self = shift;
	
	my ($object_file) = @_;
	
	my $fh = new FileHandle;
	
	open ($fh, $object_file)
		or croak "can't read $object_file";
	my $data = join ('', <$fh>);
	close $fh;
	
	my $old_data = NewSpirit::Param1x::Scalar2Hash ( \$data );
	
	my %data = (
		base_doc_url 	=> $old_data->{cipp_doc_url},
		base_cgi_url 	=> $old_data->{cipp_cgi_url},
		base_error_show	=> $old_data->{cipp_error_show},
		base_error_text	=> $old_data->{cipp_error_text}
	);

	my $df = new NewSpirit::DataFile ($object_file);
	$df->write (\%data);
	$df = undef;

	1;
}

sub property_widget_base_default_db {
	my $self = shift;
	
	my %par = @_;
	
	my $name = $par{name};
	my $data = $par{data_href};

	my $q = $self->{q};

	my $db_files = $self->get_databases;

	my @db_files = ('');
	my %labels = ( '' => 'none' );

	foreach my $db (sort keys %{$db_files}) {
		my $tmp = $db;
		$tmp =~ s!/!.!g;
		$tmp =~ s!\.cipp-db$!!;
		push @db_files, $db;
		$labels{$db} = "$self->{project}.$tmp";
	}

	print $q->popup_menu (
		-name => $name,
		-values => [ @db_files ],
		-default => $data->{$name},
		-labels => \%labels
	);

	print qq{<a href="$self->{object_url}&e=refresh_db_popup&next_e=edit"><b>Refresh Database Popup</b></a>},
}

sub get_install_filename {
	my $self = shift;

#	print "$self->{object} ne $self->{project_base_conf}<p>\n";

	return if $self->{object} ne $self->{project_base_conf};
	return $self->{project_config_dir}.'/cipp.conf';
}

sub install_file {
	my $self = shift;
	
# Das raus hier! Bei Project Install wird die Datei als
# uptodate gemeldet und überschreibt dann nicht die
# Ziel-Base-Config. RIESENSCHEISSE!
#	return 2 if $self->is_uptodate;

	my $data = $self->get_data;
	
	# setup http header hash
	my $http_header = "{ ";
	foreach my $line (split (/\n/, $data->{base_http_header})) {
		my ($key, $value) = split (/\s+/, $line, 2);
		$key =~ s/:$//;
		$key =~ s/'/\\'/g;
		$value =~ s/'/'\\'/g;
		$http_header .= "'$key' => '$value', ";
	}
	$http_header .= "}";

	my $fh = new FileHandle;
	my $install_file = $self->get_install_filename;
	
	return 1 if not $install_file;

	open ($fh, "> $install_file")
		or croak "can't write '$install_file'";

	my $base_doc_url = $data->{base_doc_url};
	my $base_cgi_url = $data->{base_cgi_url};
	$base_doc_url = "" if $base_doc_url eq '/';
	$base_cgi_url = "" if $base_cgi_url eq '/';

	my $base_url_par_delimiter = $data->{base_url_par_delimiter} || '&';
	my $base_utf8  = $data->{base_utf8} || 0;
	my $base_xhtml = $data->{base_xhtml} || 0;
	my $base_trunc_ws = $data->{base_trunc_ws} || 0;
	my $base_cipp2_runtime = $data->{base_cipp2_runtime} || 0;
	
	my $error_show = $data->{base_error_show};
	my $error_text = $data->{base_error_text};
	$error_text =~ s/\{/\\{/g;
	$error_text =~ s/\}/\\}/g;

        if ( $self->{object} ne 'configuration.cipp-base-config' ) {
		# ok, we are an alternate base configuration
		my $prod_dir;

		my $base_conf = NewSpirit::Object->new (
			q => $self->{q},
			object => $CFG::default_base_conf
		);

		my $base_perl_lib_dir = $base_conf->get_data->{base_perl_lib_dir};
		$base_perl_lib_dir =~ s/:/ /g;
		my $base_add_prod_dir = $base_conf->get_data->{base_add_prod_dir};
		$base_add_prod_dir =~ s/:/ /g;

		if ( $data->{base_prod_root_dir} ) {
			$prod_dir = "$data->{base_prod_root_dir}/prod";
		} else {
			$prod_dir = $base_conf->{project_prod_dir};
		} 

		my $cipp_project = $self->{project};

		print $fh <<__EOF;
{
	prod_dir	=> '$prod_dir',
	config_dir	=> '$prod_dir/config',
	inc_dir		=> '$prod_dir/inc',
	lib_dir		=> '$prod_dir/lib',
	log_dir		=> '$prod_dir/logs',
	log_file	=> '$prod_dir/logs/cipp.log',
	cgi_url		=> '$base_cgi_url',
	doc_url		=> '$base_doc_url',
	add_lib_dirs    => [ qw($base_perl_lib_dir) ],
	add_prod_dirs   => [ qw($base_add_prod_dir) ],
	http_header     => $http_header,
	error_show	=> $error_show,
	error_text	=> qq{$error_text},
	cipp_compiler_version => '$CIPP::VERSION',
 	url_par_delimiter => '$base_url_par_delimiter',
	utf8		=> $base_utf8,
	xhtml		=> $base_xhtml,
	trunc_ws	=> $base_trunc_ws,
	cipp2_runtime   => $base_cipp2_runtime,
}
__EOF
	} else {
		# standard development environment

		my $base_perl_lib_dir = $data->{base_perl_lib_dir};
		$base_perl_lib_dir =~ s/:/ /g;
		my $base_add_prod_dir = $data->{base_add_prod_dir};
		$base_add_prod_dir =~ s/:/ /g;

		print $fh <<__EOF;
{
	prod_dir	=> '$self->{project_prod_dir}',
	config_dir	=> '$self->{project_config_dir}',
	inc_dir		=> '$self->{project_inc_dir}',
	lib_dir		=> '$self->{project_lib_dir}',
	log_dir		=> '$self->{project_log_dir}',
	log_file	=> '$self->{project_log_file}',
	cgi_url		=> '$base_cgi_url',
	doc_url		=> '$base_doc_url',
	add_lib_dirs    => [ qw($base_perl_lib_dir) ],
	add_prod_dirs   => [ qw($base_add_prod_dir) ],
	http_header     => $http_header,
	error_show	=> $error_show,
	error_text	=> qq{$error_text},
	cipp_compiler_version => '$CIPP::VERSION',
 	url_par_delimiter => '$base_url_par_delimiter',
	utf8		=> $base_utf8,
	xhtml		=> $base_xhtml,
	trunc_ws	=> $base_trunc_ws,
	cipp2_runtime   => $base_cipp2_runtime,
}
__EOF
	}
	close $fh;

	if ( $data->{base_default_db} ) {
		# if there is a default DB configuration,
		# we install it
		my $o = new NewSpirit::Object (
			q => $self->{q},
			object => $data->{base_default_db},
			base_config_object => $self->{project_base_conf}
		);
		$o->install_file(1);	# force installation, no fs uptodate check
	} else {
		# otherwise we delete the configuration
		# prod file, if it exists
		my $default_conf_file =
			"$self->{project_config_dir}/default.db-conf";
		unlink $default_conf_file
			if -f $default_conf_file;
	}

	1;
}

sub create {
	my $self = shift;
	
	# first create the object via the super class mechanism
	$self->SUPER::create;
	
	# now add a entry to the global databases file
	my $file = $self->{project_base_configs_file};
	
	my $df = new NewSpirit::DataFile ($file);
	my $data;
	eval {
		# existence of the file is not mandatory
		$data = $df->read;
	};
	$data->{$self->{object}} = 1;
	$df->write ($data);

	return;
}

sub delete {
	my $self = shift;
	
	# first delete the object via the super class mechanism
	$self->SUPER::delete;
	
	# no remove the entry from the global base configs file
	my $file = $self->{project_base_configs_file};
	
	my $df = new NewSpirit::DataFile ($file);
	my $data = $df->read;
	delete $data->{$self->{object}};
	$df->write ($data);

	return;
}

sub save_file {
	my $self = shift;

	my $q = $self->{q};
	
	my $base_doc_url      = $q->param ('base_doc_url');
	my $base_cgi_url      = $q->param ('base_cgi_url');
	my $base_prod_shebang = $q->param ('base_prod_shebang');

	# add a slash if the first character is no slash
	# (only absoulte URLs are allowed here)
	$base_doc_url =~ s!^([^/])!/$1!;
	$base_cgi_url =~ s!^([^/])!/$1!;

	# correct shebang line, if #! is missing
	$base_prod_shebang = "#!".$base_prod_shebang
		if $base_prod_shebang ne '' and
		   $base_prod_shebang !~ m/^#\!/;

	# store the modified parameters back in the CGI object
	$q->param ('base_doc_url',      $base_doc_url);
	$q->param ('base_cgi_url',      $base_cgi_url);
	$q->param ('base_prod_shebang', $base_prod_shebang);

	# store project and server URL for the newspirit 
	# command line tool
	$q->param ('_base_project', $self->{project} );
	$q->param ('_base_server',  "http://$ENV{SERVER_NAME}$CFG::cgi_url");

	$self->SUPER::save_file;
}

sub print_install_errors {
	NewSpirit::CIPP::Prep::print_install_errors(@_);
}

1;
