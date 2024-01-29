package YAML::yq::Helper;

use 5.006;
use strict;
use warnings;
use YAML;
use File::Slurp qw (read_file write_file);
use File::Temp  qw/ tempfile tempdir /;
use File::Copy;
use Cwd;

=head1 NAME

YAML::yq::Helper - Wrapper for yq for various common tasks so YAML files can be manipulated in a manner to preserve comments and version header.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use YAML::yq::Helper;

    my $yq = YAML::yq::Helper->new(file='/etc/suricata/suricata-ids.yaml');

    $yq->set_array(var=>'rule-files', vals=>['suricata.rules','custom.rules'])

=head1 METHODS

=head2 new

Inits the object and check if a version header is present for use with the
ensure method.

Will make sure the file specified exists, is a file, is readable, and is
writable. Otherwise it will die.

Will also die if yq is not in the path.

    - file :: The YAML file to operate on.

=cut

sub new {
	my ( $blank, %opts ) = @_;

	my $exists = `/bin/sh -c "which yq"`;
	if ( $? != 0 ) {
		die("yq not found in the path");
	}

	if ( !defined( $opts{file} ) ) {
		die('No file specified');
	}

	if ( !-e $opts{file} ) {
		die( '"' . $opts{file} . '" does not exist' );
	}

	if ( !-f $opts{file} ) {
		die( '"' . $opts{file} . '" is not a file' );
	}

	if ( !-r $opts{file} ) {
		die( '"' . $opts{file} . '" is not readable' );
	}

	my $self = {
		file   => $opts{file},
		qfile  => quotemeta( $opts{file} ),
		ensure => 0,
		ver    => '1.1',
	};
	bless $self;

	my $raw = read_file( $self->{file} );
	if ( $raw =~ /^\%YAML\ 1\.1/ ) {
		$self->{ensure} = 1;
		$self->{ver}    = '1.1';
	} elsif ( $raw =~ /^\%YAML\ 1\.2/ ) {
		$self->{ensure} = 1;
		$self->{ver}    = '1.2';
	} elsif ( $raw =~ /^\%YAML\ 1\.2\.0/ ) {
		$self->{ensure} = 1;
		$self->{ver}    = '1.2.0';
	} elsif ( $raw =~ /^\%YAML\ 1\.2\.1/ ) {
		$self->{ensure} = 1;
		$self->{ver}    = '1.2.1';
	} elsif ( $raw =~ /^\%YAML\ 1\.2\.2/ ) {
		$self->{ensure} = 1;
		$self->{ver}    = '1.2.2';
	} elsif ( $raw =~ /^\%YAML\ 1\.0/ ) {
		$self->{ensure} = 1;
		$self->{ver}    = '1.0';
	}

	return $self;
} ## end sub new

=head2 clear_array

Clears the entries in a array, but does not delete the array.

Will die if called on a item that is not a array.

    - var :: Variable to check. If not matching /^\./,
             a period will be prepended.

    $yq->clear_array(var=>'rule-files');

=cut

sub clear_array {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for var to check');
	} elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	if ( $self->is_array_clear( var => $opts{var} ) ) {
		return;
	}

	if ( $opts{var} !~ /\[\]$/ ) {
		$opts{var} = $opts{var} . '[]';
	}

	my $string = `yq -i "del $opts{var}" $self->{qfile}`;

	$self->ensure;
} ## end sub clear_array

=head2 clear_hash

Clears the entries in a hash, but does not delete the hash.

Will die if called on a item that is not a hash.

    - var :: Variable to check. If not matching /^\./,
             a period will be prepended.

    $yq->clear_hash(var=>'rule-files');

=cut

sub clear_hash {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for var to check');
	} elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	if ( $self->is_hash_clear( var => $opts{var} ) ) {
		return;
	}

	if ( $opts{var} !~ /\[\]$/ ) {
		$opts{var} = $opts{var} . '[]';
	}

	my $string = `yq -i "del $opts{var}" $self->{qfile}`;

	$self->ensure;
} ## end sub clear_hash

=head2 create_array

Creates a empty array. Unlike set_array, vals is optional.

Will die if it already exists.

    - var :: Variable to operate on. If not matching /^\./,
             a period will be prepended.

    - vals :: Array of values to set the array to.

    $yq->create_array(var=>'rule-files');

=cut

sub create_array {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for var to check');
	} elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	my $string;
	if ( !$self->is_defined( var => $opts{var} ) ) {
		$string = `yq -i '$opts{var}=[]' $self->{qfile}`;
	} else {
		die( '"' . $opts{var} . '" already exists' );
	}

	if ( $opts{var} !~ /\[\]$/ ) {
		$opts{var} =~ s/\[\]$//;
	}

	my $int = 0;
	while ( defined( $opts{vals}[$int] ) ) {
		my $insert = $opts{var} . '[' . $int . ']="' . $opts{vals}[$int] . '"';
		$string = `yq -i '$insert' $self->{qfile}`;
		$int++;
	}

	$self->ensure;
} ## end sub create_array

=head2 create_hash

Creates a empty hash.

Will die if it already exists.

    - var :: Variable to operate on. If not matching /^\./,
             a period will be prepended.

    $yq->clear_hash(var=>'rule-files');

=cut

sub create_hash {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for var to check');
	} elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	my $string;
	if ( !$self->is_defined( var => $opts{var} ) ) {
		$string = `yq -i '$opts{var}={}' $self->{qfile}`;
	} else {
		die( '"' . $opts{var} . '" already exists' );
	}

	$self->ensure;
} ## end sub create_hash

=head2 dedup_array

Dedup the specified array.

Will die if called on a item that is not a array or the array
does not exist.

    - var :: Variable to check. If not matching /^\./,
             a period will be prepended.

    $yq->dedup_array(var=>'rule-files');

=cut

sub dedup_array {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{dedup} ) ) {
		$opts{dedup} = 1;
	}

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for vals');
	} elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	if ( $opts{var} =~ /\[\]$/ ) {
		$opts{var} =~ s/\[\]$//;
	}

	my $string;
	if ( !$self->is_array( var => $opts{var} ) ) {
		die( '"' . $opts{var} . '" is not a array or is undef' );
	}

	$string = `yq "$opts{var}" $self->{qfile} 2> /dev/null`;
	my $yaml;
	if ( $string =~ /\[\]/ ) {
		print "blank\n";
		$yaml = [];
	} else {
		eval { $yaml = Load($string); }
			|| eval { $string = 'foo: ' . $string; $yaml = Load($string); $yaml = $yaml->{foo} };
	}

	my $int      = 0;
	my $existing = {};
	my @new_array;
	while ( defined( $yaml->[$int] ) ) {
		if ( !defined( $existing->{ $yaml->[$int] } ) ) {
			$existing->{ $yaml->[$int] } = 1;
			push( @new_array, $yaml->[$int] );
		}

		$int++;
	}

	$self->set_array( var => $opts{var}, vals => \@new_array );
} ## end sub dedup_array

=head2 delete

Deletes an variable. If it is already undef, it will just return.

    - var :: Variable to check. If not matching /^\./,
             a period will be prepended.

    $yq->delete_array(var=>'rule-files');

=cut

sub delete {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for var to check');
	} elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	if ( !$self->is_defined( var => $opts{var} ) ) {
		return;
	}

	my $string = `yq -i "del $opts{var}" $self->{qfile}`;

	$self->ensure;
} ## end sub delete

=head2 delete_array

Deletes an array. If it is already undef, it will just return.

Will die if called on a item that is not a array.

    - var :: Variable to check. If not matching /^\./,
             a period will be prepended.

    $yq->delete_array(var=>'rule-files');

=cut

sub delete_array {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for var to check');
	} elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	if ( !$self->is_defined( var => $opts{var} ) ) {
		return;
	}

	if ( !$self->is_array( var => $opts{var} ) ) {
		die( '"' . $opts{var} . '" is not a array' );
	}

	if ( $opts{var} =~ /\[\]$/ ) {
		$opts{var} =~ s/\[\]$//;
	}

	my $string = `yq -i "del $opts{var}" $self->{qfile}`;

	$self->ensure;
} ## end sub delete_array

=head2 delete_hash

Deletes an hash. If it is already undef, it will just return.

Will die if called on a item that is not a hash.

    - var :: Variable to check. If not matching /^\./,
             a period will be prepended.

    $yq->delete_hash(var=>'vars');

=cut

sub delete_hash {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for var to check');
	} elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	if ( !$self->is_defined( var => $opts{var} ) ) {
		return;
	}

	if ( !$self->is_hash( var => $opts{var} ) ) {
		die( '"' . $opts{var} . '" is not a hash or is undef' );
	}

	if ( $opts{var} =~ /\[\]$/ ) {
		$opts{var} =~ s/\[\]$//;
	}

	my $string = `yq -i "del $opts{var}" $self->{qfile}`;

	$self->ensure;
} ## end sub delete_hash

=head2 ensure

Makes sure that the YAML file has the
version at the top.

If the file none originally, no action will be taken
unless force=>1 is also set for this. At which point
it will it to 1.1.

    $yq->ensure;
    $yq->ensure(force=>1);

=cut

sub ensure {
	my ( $self, %opts ) = @_;

	if ( $opts{force} ) {
		$self->{ensure} = 1;
	}

	if ( !$self->{ensure} ) {
		return;
	}

	my $raw = read_file( $self->{file} );

	# starts
	if ( $raw =~ /^\%YAML/ ) {
		return;
	}

	# add dashes to the start of the raw if it is missing
	if ( $raw !~ /^\-\-\-\n/ ) {
		$raw = "---\n\n" . $raw;
	}

	# adds the yaml version
	$raw = '%YAML ' . $self->{ver} . "\n" . $raw;

	write_file( $self->{file}, $raw ) or die($@);

	return;
} ## end sub ensure

=head2 is_array

Checks if the specified variable in a array.

    - var :: Variable to check. If not matching /^\./,
             a period will be prepended.

    if ( $yq->is_array(var=>'rule-files') ){
        print "array...\n:";
    }

=cut

sub is_array {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for var to check');
	} elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	my $string = `yq "$opts{var}" $self->{qfile} 2> /dev/null`;
	if ( $string =~ /\[\]/ ) {
		return 1;
	} elsif ( $string =~ /\{\}/ ) {
		return 0;
	} elsif ( $string eq "null\n" ) {
		return 0;
	}

	my $yaml;
	eval { $yaml = Load($string); };
	if ($@) {
		$string = 'foo: ' . $string;
		$yaml   = Load($string) || die( $string . "\n\n" . $@ );
		if ( ref( $yaml->{foo} ) eq 'ARRAY' ) {
			return 1;
		}
		return 0;
	}

	if ( ref($yaml) eq 'ARRAY' ) {
		return 1;
	}

	return 0;
} ## end sub is_array

=head2 is_array_clear

Checks if a array is clear or not.

    - var :: Variable to check. If not matching /^\./,
             a period will be prepended.

    if ( $yq->is_array_clear(var=>'rule-files') ){
        print "clear...\n:";
    }

=cut

sub is_array_clear {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for var to check');
	} elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	if ( !$self->is_array( var => $opts{var} ) ) {
		die( '"' . $opts{var} . '" is not a array or is undef' );
	}

	my $string = `yq "$opts{var}" $self->{qfile} 2> /dev/null`;
	if ( $string =~ /\[\]/ ) {
		return 1;
	}

	return 0;
} ## end sub is_array_clear

=head2 is_defined

Checks if the specified variable is defined or not.

Will die if called on a item that is not a array.

    - var :: Variable to check. If not matching /^\./,
             a period will be prepended.

    if ( $yq->is_defined('vars.address-groups') ){
        print "defined...\n:";
    }

=cut

sub is_defined {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for var to check');
	} elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	my $string = `yq "$opts{var}" $self->{qfile} 2> /dev/null`;

	if ( $string eq "null\n" ) {
		return 0;
	}

	return 1;
} ## end sub is_defined

=head2 is_hash

Checks if the specified variable in a hash.

Will die if called on a item that is not a array.

    - var :: Variable to check. If not matching /^\./,
             a period will be prepended.

    if ( $yq->is_hash('vars.address-groups') ){
        print "hash...\n:";
    }

=cut

sub is_hash {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for var to check');
	} elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	my $string = `yq "$opts{var}" $self->{qfile} 2> /dev/null`;

	if ( $string =~ /\[\]/ ) {
		return 0;
	} elsif ( $string =~ /\{\}/ ) {
		return 1;
	} elsif ( $string eq "null\n" ) {
		return 0;
	}

	my $yaml = Load($string);

	if ( ref($yaml) eq 'HASH' ) {
		return 1;
	}

	return 0;
} ## end sub is_hash

=head2 is_hash_clear

Checks if a hash is clear or not.

Will die if called on a item that is not a hash.

    - var :: Variable to check. If not matching /^\./,
             a period will be prepended.

    if ( ! $yq->is_hash_clear(var=>'vars') ){
        print "not clear...\n:";
    }

=cut

sub is_hash_clear {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for var to check');
	} elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	if ( !$self->is_hash( var => $opts{var} ) ) {
		die( '"' . $opts{var} . '" is not a hash or is undef' );
	}

	my $string = `yq "$opts{var}" $self->{qfile} 2> /dev/null`;
	if ( $string =~ /\{\}/ ) {
		return 1;
	}

	return 0;
} ## end sub is_hash_clear

=head2 merge_yaml

Murges the specified YAML into the current YAML.

    - yaml :: The YAML to merge into into the current one.
            This value may not match /[\'\"]/.
        - Default :: undef

    - merge_mode :: Merge mode to use.
        - Default :: deeply

    $yq->merge_yaml(yaml=>'./some_other_file.yaml');

The merge modes are as below.

    - deeply :: Deeply merge arrays.
        - yq :: '. *d load("file2.yml")'

    - replace :: Replace arrays.
        - yq :: '. *= load("file2.yml")'

    - append :: Append arrays.
        - yq :: '. *+ load("file2.yml")'

    - existing :: Only merge existing fields.
        - yq :: '. *? load("file2.yml")'

    - new :: Only merge new fields.
        - yq :: '. *n load("file2.yml")'

=cut

sub merge_yaml {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{yaml} ) ) {
		die('Nothing specified for yaml');
	} elsif ( !-f $opts{yaml} ) {
		die( '"' . $opts{yaml} . '" does not exist' );
	} elsif ( $opts{yaml} =~ /[\"\']/ ) {
		die( '"' . $opts{yaml} . '" may not match /[\\\"\\\']/' );
	}

	if ( !defined( $opts{merge_mode} ) ) {
		$opts{merge_mode} = 'deeply';
	} elsif ( $opts{merge_mode} ne 'deeply'
		&& $opts{merge_mode} ne 'replace'
		&& $opts{merge_mode} ne 'append'
		&& $opts{merge_mode} ne 'existing'
		&& $opts{merge_mode} ne 'new' )
	{
		die( '"' . $opts{merge_mode} . '" is not a recognized merge mode' );
	}

	# default to deeply
	my $mode = '*d';
	if ( $opts{merge_mode} eq 'replace' ) {
		$mode = '*=';
	} elsif ( $opts{merge_mode} eq 'append' ) {
		$mode = '*+';
	} elsif ( $opts{merge_mode} eq 'existing' ) {
		$mode = '*?';
	} elsif ( $opts{merge_mode} eq 'new' ) {
		$mode = '*n';
	}

	my $toMerge = $opts{yaml};
	my $string  = `yq -i '. $mode load("$toMerge")' $self->{qfile}`;

	$self->ensure;
} ## end sub merge_yaml

=head2 push_array

Pushes the passed array onto the specified array.

Will die if called on a item that is not a array or the array
does not exist.

    - var :: Variable to check. If not matching /^\./,
             a period will be prepended.

    - vals :: Array of values to set the array to.

    $yq->push_array(var=>'rule-files',vals=>\@new_rules_files);

=cut

sub push_array {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{vals} ) ) {
		die('Nothing specified for vars');
	} else {
		if ( !defined $opts{vals}[0] ) {
			return;
		}
	}

	if ( !defined( $opts{dedup} ) ) {
		$opts{dedup} = 1;
	}

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for vals');
	} elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	if ( $opts{var} =~ /\[\]$/ ) {
		$opts{var} =~ s/\[\]$//;
	}

	my $string;
	if ( !$self->is_array( var => $opts{var} ) ) {
		die( '"' . $opts{var} . '" is not a array or is undef' );
	}

	$string = `yq "$opts{var}" $self->{qfile} 2> /dev/null`;
	my $yaml;
	if ( $string =~ /\[\]/ ) {
		print "blank\n";
		$yaml = [];
	} else {
		eval { $yaml = Load($string); }
			|| eval { $string = 'foo: ' . $string; $yaml = Load($string); $yaml = $yaml->{foo} };
	}

	my @new_array;
	push( @new_array, @{$yaml} );
	push( @new_array, @{ $opts{vals} } );

	$self->set_array( var => $opts{var}, vals => \@new_array );
} ## end sub push_array

=head2 set_array

Creates an array and sets it to the values.

If the array is already defined, it will clear it and set
the values to those specified.

Will die if called on a item that is not a array.

    - var :: Variable to check. If not matching /^\./,
             a period will be prepended.

    - vals :: Array of values to set the array to.

    $yq->set_array(var=>'rule-files',vals=>\@vals);

=cut

sub set_array {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{vals} ) ) {
		die('Nothing specified for vars');
	}

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for vals');
	} elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	my $string;
	if ( $self->is_defined( var => $opts{var} ) ) {
		$string = `yq -i '$opts{var}=[]' $self->{qfile}`;
	} else {
		$self->clear_array( var => $opts{var} );
	}

	if ( $opts{var} !~ /\[\]$/ ) {
		$opts{var} =~ s/\[\]$//;
	}

	my $int = 0;
	while ( defined( $opts{vals}[$int] ) ) {
		my $insert = $opts{var} . '[' . $int . ']="' . $opts{vals}[$int] . '"';
		$string = `yq -i '$insert' $self->{qfile}`;
		$int++;
	}

	$self->ensure;
} ## end sub set_array

=head2 set_hash

Creates an hash and sets it to the values.

If the hash is already defined, it will clear it and set
the values to those specified.

Will die if called on a item that is not a array.

    - var :: Variable to check. If not matching /^\./,
             a period will be prepended.

    - hash :: A hash to use for generating the hash to be
              added. Any undef value will be set to null.

    $yq->set_hash(var=>'vars',hash=>{a=>33,bar=>undef});

=cut

sub set_hash {
	my ( $self, %opts ) = @_;

	my @keys;
	if ( !defined( $opts{hash} ) ) {
		die('Nothing specified for hash');
	} else {
		if ( ref( $opts{hash} ) ne 'HASH' ) {
			die( 'The passed value for hash is a ' . ref( $opts{hash} ) . ' and not HASH' );
		}

		@keys = keys( %{ $opts{hash} } );

		foreach my $key (@keys) {
			if (   defined( $opts{hash}{$key} )
				&& ref( $opts{hash}{$key} ) ne 'SCALAR'
				&& ref( $opts{hash}{$key} ) ne '' )
			{
				die(      'The passed value for the key "'
						. $key
						. '" for the hash is a '
						. ref( $opts{hash}{$key} )
						. ' and not SCALAR or undef' );
			} ## end if ( defined( $opts{hash}{$key} ) && ref( ...))
		} ## end foreach my $key (@keys)
	} ## end else [ if ( !defined( $opts{hash} ) ) ]

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for vals');
	} elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	if ( $opts{var} =~ /\[\]$/ ) {
		die( 'vars, "' . $opts{var} . '", may not contains []' );
	}

	if ( $opts{var} !~ /\.$/ ) {
		$opts{var} =~ s/\.$//;
	}

	my $string;
	if ( !$self->is_defined( var => $opts{var} ) ) {
		$string = `yq -i '$opts{var}={}' $self->{qfile}`;
	} else {
		$self->clear_hash( var => $opts{var} );
	}

	foreach my $key (@keys) {
		my $insert;
		if ( defined( $opts{hash}{$key} ) ) {
			$insert = $opts{var} . '.' . $key . '="' . $opts{hash}{$key} . '"';
		} else {
			$insert = $opts{var} . '.' . $key . '=null';
		}
		$string = `yq -i '$insert' $self->{qfile}`;
	}

	$self->ensure;
} ## end sub set_hash

=head2 set_in_array

Ensures the values specified exist at any point in the array.

Will create the array if it does not already exist.

Will die if called on a item that is not a array.

    - var :: Variable to check. If not matching /^\./,
             a period will be prepended.

    - vals :: Array of values to set the array to.

    - dedup :: If it should deduplicate the existing items
               in the array or not.
      Default :: 1

    $yq->set_in_array(var=>'rule-files',vals=>\@vals);

=cut

sub set_in_array {
	my ( $self, %opts ) = @_;

	my $to_exist = {};
	if ( !defined( $opts{vals} ) ) {
		die('Nothing specified for vars');
	} else {
		if ( !defined $opts{vals}[0] ) {
			return;
		}

		my $int = 0;
		while ( defined( $opts{vals}[$int] ) ) {
			$to_exist->{ $opts{vals}[$int] } = 1;
			$int++;
		}

	} ## end else [ if ( !defined( $opts{vals} ) ) ]

	if ( !defined( $opts{dedup} ) ) {
		$opts{dedup} = 1;
	}

	if ( !defined( $opts{var} ) ) {
		die('Nothing specified for vals');
	} elsif ( $opts{var} !~ /^\./ ) {
		$opts{var} = '.' . $opts{var};
	}

	if ( $opts{var} =~ /\[\]$/ ) {
		$opts{var} =~ s/\[\]$//;
	}

	my $string;
	if ( !$self->is_defined( var => $opts{var} ) ) {
		$string = `yq -i '$opts{var}=[]' $self->{qfile}`;
	} else {
		if ( !$self->is_array( var => $opts{var} ) ) {
			die( '"' . $opts{var} . '" is not a array or is undef' );
		}

	}

	$string = `yq "$opts{var}" $self->{qfile} 2> /dev/null`;
	my $yaml;
	if ( $string =~ /\[\]/ ) {
		print "blank\n";
		$yaml = [];
	} else {
		eval { $yaml = Load($string); };
	}

	my $int = 0;
	my @exiting_a;
	my $existing_h = {};
	while ( defined( $yaml->[$int] ) ) {
		if ( defined( $to_exist->{ $yaml->[$int] } ) ) {
			delete( $to_exist->{ $yaml->[$int] } );
		}

		push( @exiting_a, $yaml->[$int] );

		$existing_h->{ $yaml->[$int] } = 1;

		$int++;
	} ## end while ( defined( $yaml->[$int] ) )

	my @new_array;
	if ( $opts{dedup} ) {
		push( @new_array, keys( %{$existing_h} ) );
		push( @new_array, keys( %{$to_exist} ) );
	} else {
		push( @new_array, @exiting_a );
		push( @new_array, keys( %{$to_exist} ) );
	}

	$self->set_array( var => $opts{var}, vals => \@new_array );
} ## end sub set_in_array

=head2 yaml_diff

This returns a diff between both YAMLs.

The two YAMLs are are copied to the a temp dir.

    - yaml :: The YAML use for the new side of the diff.
        - Default :: undef

=cut

sub yaml_diff {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{yaml} ) ) {
		die('Nothing specified for yaml');
	} elsif ( !-f $opts{yaml} ) {
		die( '"' . $opts{yaml} . '" does not exist' );
	} elsif ( !-r $opts{yaml} ) {
		die( '"' . $opts{yaml} . '" is not readable' );
	}

	my $dir = tempdir( CLEANUP => 1 );

	my $yaml1 = $dir . '/old';
	copy( $self->{file}, $yaml1 );
	my $string = `yq -i -P 'sort_keys(..) | ... comments=""' -o=props $yaml1`;

	my $yaml2 = $dir . '/new';
	copy( $opts{yaml}, $yaml2 );
	$string = `yq -i -P 'sort_keys(..) | ... comments=""' -o=props $yaml2`;

	my $old_dir = getcwd;

	chdir($dir);
	$string = `diff -u old new`;
	chdir($old_dir);

	return $string;
} ## end sub yaml_diff

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-yaml-yq-helper at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=YAML-yq-Helper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc YAML::yq::Helper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=YAML-yq-Helper>

=item * Search CPAN

L<https://metacpan.org/release/YAML-yq-Helper>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of YAML::yq::Helper
