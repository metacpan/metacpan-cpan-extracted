package NewSpirit::CIPP::DB;

$VERSION = "0.02";
@ISA = qw(
	NewSpirit::Object::Record
	NewSpirit::CIPP::ProdReplace
);

use strict;

my %FIELD_DEFINITION = (
	db_source => {
		description => 'DBI Data Source',
		type => 'text'
	},
	db_user => {
		description => 'Username',
		type => 'text'
	},
	db_pass => {
		description => 'Password',
		type => 'password'
	},
	db_autocommit => {
		description => 'AutoCommit',
		type => 'switch'
	},
	db_cache_enable => {
		description => 'Enable Connection Caching',
		type => 'switch'
	},
	db_env => {
		description => 'Environment Variables',
		type => 'textarea'
	},
	db_init => {
		description => 'Initial SQL Statement',
		type => 'textarea'
	},
	db_init_perl => {
		description => 'Initial Perl Statements<br>($dbh is given)',
		type => 'textarea'
	},
);

my @FIELD_ORDER = (
	'db_source', 'db_user', 'db_pass',
	'db_autocommit', 'db_cache_enable',
	'db_env', 'db_init', 'db_init_perl'
);

use Carp;
use NewSpirit::CIPP::ProdReplace;
use NewSpirit::Object::Record;
use NewSpirit::Param1x;
use NewSpirit::DataFile;
use FileHandle;

sub init {
	my $self = shift;
	
	$self->{record_field_definition} = \%FIELD_DEFINITION;
	$self->{record_field_order} = \@FIELD_ORDER;
	
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
		db_source 	=> $old_data->{DB_SOURCE},
		db_user 	=> $old_data->{DB_USER},
		db_pass 	=> $old_data->{DB_PASS},
		db_autocommit	=> $old_data->{DB_AUTOCOMMIT} =~ /an/i ? 1 : 0,
		db_cache_enable => 0,
		db_env 		=> $old_data->{DB_ENV},
		db_init		=> ''
	);

	my $df = new NewSpirit::DataFile ($object_file);
	$df->write (\%data);
	$df = undef;

	1;
}

sub save_file {
	my $self = shift;
	
	my $q = $self->{q};
	
	my $db_pass = $q->param('db_pass');
	
	if ( $db_pass ) {
		# aha, a new password. Let's obscure it!
		my $x;
		$db_pass =~ s/(.)/($x=chr(ord($1)^85),ord($x)>15)?
		                  (sprintf("%%%x",ord($x))):
				  ("%0".sprintf("%lx",ord($x)))/eg;

	} else {
		# no password given: get the old password entry
		my $df = new NewSpirit::DataFile ($self->{object_file});
		my $data = $df->read;
		$df = undef;
		
		$db_pass = $data->{db_pass};
	}
	
	# build the data hash, generic
	my $field_order = $self->{record_field_order};
	
	my %data;
	foreach my $key ( @{$field_order} ) {
		$data{$key} = $q->param($key);
		$data{$key} =~ s/\r//g;
	}

	# save special handled password
	$data{db_pass} = $db_pass;

	# store the hash
	my $df = new NewSpirit::DataFile ($self->{object_file});
	$df->write ( \%data );
	$df = undef;
	
	return 0;	# no project file browser update needed
}

sub get_install_filename {
	my $self = shift;
	
	my ($name) = @_;
	
	# this method comes from ProdReplace. It may return
	# another object name as the installation target
	my $file = $name;
	$file ||= $self->get_install_object_name;

	# remove project name
	$file =~ s/^[^\.]+\.//;
	
	if ( $file eq 'default' and $name ne 'default' ) {
		croak "Sorry, the DB object name 'default' is reserved!";
	}
	
	return if not $file;
	return "$self->{project_config_dir}/$file.db-conf";
}

sub install_file {
	my $self = shift;
	my ($noupdate_check) = @_;

	my $prod_replace;
	return 1 if not $prod_replace = $self->installation_allowed;	# prod replace
	if ( !$noupdate_check ) {
		return 2 if $prod_replace != 2 and $self->is_uptodate;
	}

	# first we install ourself with our real name
	my $install_file = $self->get_install_filename;
	return 1 if not $install_file;

	$self->real_install_file (
		$install_file,
		$self->get_install_object_name,
#		$self->{object_name},
	);

	# now check if we are default database, so
	# we will also write a configuration named 'default'

	my $default_db = $self->get_default_database;
	
	if ( $default_db eq $self->{object} ) {
		$install_file = $self->get_install_filename ('default');
		$self->real_install_file ($install_file, 'default');
	}

	1;
}

sub real_install_file {
	my $self = shift;
	
	my ($install_file, $name) = @_;
	
	my $data = $self->get_data;
	
	my $fh = new FileHandle;
	
	my $pkg = $name;
	$pkg =~ s/^[^\.]+\.//;
	$pkg =~ s!\.!_!g;
	$pkg = '$CIPP_Exec::cipp_db_'.$pkg;
	
	$data->{db_cache_enable} ||= '0';
	
	open ($fh, "> $install_file")
		or die "can't write '$install_file'";

	foreach my $env ( split (/\n/, $data->{db_env}) ) {
		my ($k,$v) = split (/\s+/, $env);
		print $fh qq{\$main::ENV{$k} = q{$v};\n}
	}

	my $db_source		= $data->{db_source};
	my $db_user		= $data->{db_user};
	my $db_autocommit	= $data->{db_autocommit};
	my $db_init		= $data->{db_init};
        my $db_init_perl        = $data->{db_init_perl};

	foreach my $x ( $db_source, $db_user, $db_autocommit, $db_init ) {
		$x =~ s/'/\\'/g;
	}

        my $init_perl_sub = $db_init_perl =~ /\S/ ?
            qq[sub { my (\$dbh) = shift; $db_init_perl }] :
            qq[''];

	print $fh <<__EOF;
my \$_cipp_password;
(\$_cipp_password = q{$data->{db_pass}} ) =~ s/%(..)/chr(ord(pack('C', hex(\$1)))^85)/eg;
{
	data_source => '$db_source',
	user => '$db_user',
	password => \$_cipp_password,
	autocommit => $db_autocommit,
	init => q{$db_init},
        init_perl => $init_perl_sub,
}
__EOF

	close $fh;
	chmod 0660, $install_file;

	1;
}

sub print_post_install_message {
	my $self = shift;
	
	my $to_file = $self->get_install_filename;
	
	print "$CFG::FONT<p>",
	      "Successfully installed to<br><b>$to_file</b>",
	      "</FONT>\n";

	my $default_db = $self->get_default_database;
	
	if ( $default_db eq $self->{object} ) {
		$to_file = $self->get_install_filename ('default');
		print "$CFG::FONT",
		      "<br><b>$to_file</b>",
		      "</FONT>\n";
	}

	1;
}

sub create {
	my $self = shift;
	
	# first create the object via the super class mechanism
	$self->SUPER::create;
	
	# no add a entry to the global databases file
	my $databases_file = $self->{project_databases_file};
	
	my $df = new NewSpirit::DataFile ($databases_file);
	my $data = $df->read;
	$data->{$self->{object}} = 'CIPP::DB_DBI';
	$df->write ($data);
	
	return;
}

sub delete {
	my $self = shift;
	
	# first delete the object via the super class mechanism
	$self->SUPER::delete;
	
	# no remove the entry from the global databases file
	my $file = $self->{project_databases_file};
	
	my $df = new NewSpirit::DataFile ($file);
	my $data = $df->read;
	delete $data->{$self->{object}};
	$df->write ($data);

	return;
}

sub get_show_depend_key {
	my $self = shift;
	
	my $default_db = $self->get_default_database;
	
	if ( $default_db eq $self->{object} ) {
		return "__default.cipp-db:cipp-db";
	} else {
		return "$self->{object}:$self->{object_type}";
	}
}


1;
