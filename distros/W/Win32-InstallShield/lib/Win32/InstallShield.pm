package Win32::InstallShield;

use Carp;
use IO::File;
use XML::Parser;
use Data::Dumper;
use Encode;

use strict;
use warnings;

our $AUTOLOAD;
our $VERSION = 0.7;

my %component_attr_values = (
	LocalOnly                 => 0,
	SourceOnly                => 1,
	Optional                  => 2,
	RegistryKeyPath           => 4,
	SharedDllRefCount         => 8,
	Permanent                 => 16,
	ODBCDataSource            => 32,
	Transitive                => 64,
	NeverOverwrite            => 128,
	'64bit'                   => 256,
	DisableRegistryReflection => 512,
	UninstallOnSupersedence   => 1024,
	AttributesShared          => 2048,
);

my %component_attr_names = map { $component_attr_values{$_} => $_ } keys %component_attr_values;

=head1 NAME

Win32::InstallShield - InstallShield data file interface

=head1 SYNOPSIS

  use InstallShield;

  # Constructors
  $is = Win32::InstallShield->new();
  $is = Win32::InstallShield->new( $ism_file );

=head1 ABSTRACT

An OO interface for manipulating InstallShield XML .ism files

=head1 DESCRIPTION

This module provides an interface to add, remove and modifify rows
in an InstallShield .ism file. It only supports versions of
InstallShield that save their data as XML.

=head1 EXAMPLES

This example updates the product version.

  use Win32::InstallShield;

  $is = Win32::InstallShield->new( $ism_file );
  $is->UpdateProperty(
      { 
          Property => 'ProductVersion',
          Value    => '1.2.3.4',
      }
  );

  $is->savefile( $ism_file );

=head1 METHODS

=over 4

=item I<new>

  $is = Win32::InstallShield->new();
  $is = Win32::InstallShield->new( $installshield_filename );
  $is = Win32::InstallShield->new( $io_file_handle );

The constructor. Can optionally be called with the same 
arguments as I<loadfile>.

=cut
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = {
		parser		=> XML::Parser->new(Style => 'Tree'),
		summary_fields  => [], # list of valid summary fields from the DTD
		parsed		=> {}, # tables that the user has read or modified
		sections	=> {}, # the contents of the original file
		order		=> [], # the order in which sections appear in the file
		tables		=> {}, # the tables that appear in the ism file
		foreign_keys	=> {}, # tables referenced by foreign keys
		correct_case	=> {}, # stores case-sensitive table names
		filename	=> undef,
		encoding        => undef,
	};

	bless $self, $class;
	
	if(@_) {
		$self->loadfile( shift );
	}

	return $self;
}

sub DESTROY {
}

sub AUTOLOAD {
	my $self = shift;
	my $name = $AUTOLOAD;
	$name =~ s/.*://;
	if($name =~ /^(addorupdate|searchhash|searcharray|gethash|getarray|add|del|update|purge)_?(.*)$/i) {
		my ($op, $table) = (lc($1), lc($2));

		if($table eq 'row') {
			$table = lc(shift @_);
		}

		unless($self->{'sections'}{$table}) {
			carp("No such table: $2");
			return;
		}

		if($op eq 'gethash') {
			return $self->_get_row_hash($table, @_);
		} elsif($op eq 'getarray') {
			return $self->_get_row_array($table, @_);
		} elsif($op eq 'searchhash') {
			return $self->_search_row_hash($table, @_);
		} elsif($op eq 'searcharray') {
			return $self->_search_row_array($table, @_);
		} elsif($op eq 'addorupdate') {
			return $self->_add_or_update_row($table, @_);
		} elsif($op eq 'add') {
			return $self->_add_row($table, @_);
		} elsif($op eq 'del') {
			return $self->_del_row($table, @_);
		} elsif($op eq 'update') {
			return $self->_update_row($table, @_);
		} elsif($op eq 'purge') {
			return $self->_purge_row($table, @_);
		}

	} else {
		croak("Invalid method $name");
	}
}

# internal function, opens a file and returns the
# IO::File filehandle if given a filename. if called
# with an IO::File filehandle, it just returns the filehandle.
sub _openfile {
	my ($file, $mode) = @_;

	if(!defined($file)) {
		carp("File name or handle required\n");
		return (undef, 0);
	}

	if(ref($file)) {
		if(ref($file) eq 'IO::File') {
			return ($file, 0);
		} else {
			carp("Invalid file argument: " . ref($file) . "\n");
			return (undef, 0);
		}
	} else {
		my $fh = IO::File->new($file, $mode);
		my $long_mode = ($mode eq 'r') ? 'read' : 'write';
		unless(defined($fh)) {
			carp("Unable to $long_mode $file $!");
			return (undef, 0);
		}
		return ($fh, 1);
	}

}

=item I<set_encoding>

  $is->set_encoding('');

Sets the encoding that will be used when writing tables that
have been modified. By default, the encoding will be whatever
appears in the XML declaration at the beginning of the ism.
If none appears, no encoding will be done.

=cut
sub set_encoding {
	my ($self, $encoding) = @_;
	$self->{'encoding'} = $encoding;
}

=item I<get_encoding>

  my $encoding = $is->get_encoding();

Returns the encoding that will be used when writing tables
that have been modified. Returns undef if the encoding is
unknown, in which case no encoding will be done.

=cut
sub get_encoding {
	my ($self) = @_;
	return $self->{'encoding'};
}

=item I<loadfile>

  $is->loadfile( $filename );
  $is->loadfile( $io_file_handle );

Loads an InstallShield ism file. Can be called
with either a filename or an IO::File object that is
opened in read ("r") mode.
Returns 1 on success, 0 on failure.

=cut
sub loadfile {
	my ($self, $file) = @_;

	my ($fh, $i_opened_file) = _openfile($file, "r");

	unless(defined($fh)) {
		return 0;
	}

	my $return = $self->load( join('', <$fh>) );
	if($i_opened_file) {
		$fh->close();
		$self->{'filename'} = $file;
	}
	return $return;
}

=item I<load>

  $is->load( $ism_text );

Loads the supplied text of an InstallShield ism file.
Returns 1 on success, 0 on failure.

=cut
sub load {
	my ($self, $data) = @_;

	# loading wipes out whatever was previously loaded
	$self->{'parsed'} = {};
	$self->{'sections'} = {};
	$self->{'order'} = [];
	$self->{'tables'} = {};
	$self->{'foreign_keys'} = {};
	$self->{'correct_case'} = {};
	$self->{'filename'} = undef;
	$self->{'encoding'} = undef;

	my $section = 'header';
	my $lastsection = $section;

	push(@{$self->{'order'}}, $section);

	my @lines = split("\n", $data);

	foreach (@lines) {
		if(/^<!DOCTYPE msi \[/) {
			$section = 'dtd';
		} elsif(/^<msi/) {
			$section = 'msi';
		} elsif(/^\s*<summary>/) {
			$section = 'summary';
		} elsif(/^\s*<table name="([^"]+)"/) {
			$section = lc($1);
			$self->{'correct_case'}{$section} = $1;
			# remember which sections are tables
			$self->{'tables'}{$1} = 1;
		} elsif(/^<\/msi>/) {
			$section = 'trailer';
		}
		
		if($section ne $lastsection) {
			$lastsection = $section;
			push(@{$self->{'order'}}, $section);
		}

		# remember what tables each foreign key appears in
		if(/^\s*<col [^>]+>([^<]+)</) {
			my $colname = $1;
			if($colname =~ /_$/) {
				unless(exists($self->{'foreign_keys'}{$colname})) {
					$self->{'foreign_keys'}{$colname} = [];
				}
				push(@{$self->{'foreign_keys'}{$colname}}, $section);
			}
		}

		push(@{$self->{'sections'}{$section}}, $_);
	}

	# find the file encoding
	foreach my $line (@{$self->{sections}->{header}}) {
		if($line =~ /\sencoding="([^"]+)"/) {
			$self->{'encoding'} = $1;
			last;
		}
	}

	return 1;
}

=item I<savefile>

  $is->savefile( );
  $is->savefile( $filename );
  $is->savefile( $io_file_handle );

Stores the ism data in a file. Can be called
with either a filename or an IO::File object that is
opened in write ("w") mode. If no argument is passed,
and the last load was via a filename, savefile will
default to the filename previously supplied.
Returns 1 on success, 0 on failure.

=cut
sub savefile {
	my ($self, $file) = @_;
	
	unless(defined($file)) {
		if(defined($self->{'filename'})) {
			$file = $self->{'filename'};
		} else {
			carp("You must provide a filename to save to");
			return 0;
		}
	}
	
	my ($fh, $i_opened_file) = _openfile($file, "w");

	unless(defined($fh)) {
		return 0;
	}

	print $fh $self->save();
	$fh->close() if($i_opened_file);
	return 1;
}

=item I<save>

  $is->save();

Returns the ism data as a string.

=cut
sub save {
	my ($self) = @_;
	
	my $encoding = $self->{'encoding'};
	my $has_encoding = defined($encoding);

	my $text = '';

	foreach my $section (@{$self->{'order'}}) {
		if($self->{'parsed'}{$section}) {
			# the table has been (possibly) modified, so rebuild it
			if($section eq 'summary') {
				$text .= ($has_encoding) ?
					encode($encoding, $self->_save_summary) :
					$self->_save_summary;
			} else {
				$text .= ($has_encoding) ?
					encode($encoding, $self->_save_table($section)) :
					$self->_save_table($section);
			}

		} else {
			# when the last table gets modified, we end up with an
			# extra newline
			if($section eq 'trailer') {
				$text =~ s/\n\n$/\n/;
			}
			# section wasn't touched, just spit out the stored text
			$text .= join("\n", @{$self->{'sections'}{$section}}) . "\n";
		}
	}
	return $text;
}

sub _save_summary {
	my ($self) = @_;

	my $count = 0;
	my %order =
		map { $_ => $count++ }
		$self->summary_fields;

	my $summary = $self->{'parsed'}{'summary'};

	my $text = "\t<summary>\n";

	foreach my $field (sort { $order{$a} <=> $order{$b} } keys %order) {
		if(exists($summary->{$field})) {
			if(!defined($summary->{$field}) || $summary->{$field} eq '') {
				$text .= "\t\t<$field/>\n";
			} else {
				$text .= "\t\t<$field>" . $summary->{$field} . "</$field>\n";
			}
		}
	}

	$text .= "\t</summary>\n\t\n";

	return $text;
}

# internal function. formats the data in a table that has
# been modified back to the appropriate output format
sub _save_table {
	my ($self, $table) = @_;

	my $p = $self->_parsed($table);
	my $text = "\t<table";
	foreach my $key (sort keys %{$p->{'attributes'}}) {
		$text .= " $key=\"$p->{'attributes'}{$key}\"";
	}
	$text .= ">\n";

	foreach my $col (@{$p->{'columns'}}) {
		$text .= "\t\t<col";
		if($col->{'is_key'}) {
			$text .= ' key="yes"';
		}
		$text .= ' def="' . $col->{'type'} . $col->{'width'} . '"';
		$text .= ">$col->{'name'}</col>\n";
	}
	foreach my $key (sort keys %{$p->{'data'}}) {
		my $row = $p->{'data'}{$key};
		$text .= "\t\t<row>";
		foreach my $col (@$row) {
			if(defined($col) and length($col) > 0) {
				$text .= "<td>" . _xml_escape($col) . "</td>";
			} else {
				$text .= "<td/>";
			}
		}
		$text .= "</row>\n";
	}

	$text .= "\t</table>\n\n";

	return $text;
}

# internal function. parses the text of an IS table
# so that it can be easily manipulated
sub _parse_table {
	my ($self, $table) = @_;
	
	$table = lc($table);
	return if($self->{'parsed'}{$table});
	
	my $text = $self->{'sections'}{$table};
	unless(defined($text)) {
		carp("No such table $table");
		return;
	}

	my @cols;
	my %data;

	my $xml = join("\n", @$text);
	my @parsed = @{$self->{'parser'}->parse($xml)->[1]};

	my $attributes = shift @parsed;

	while(@parsed) {
		my $type = shift @parsed;
		if($type eq 'col') {
			my $columns = shift @parsed;
			my $column_name = $columns->[2];
			my $is_key = ( defined($columns->[0]{'key'}) and $columns->[0]{'key'} eq 'yes' );
			my ($type, $width) = ($columns->[0]{'def'} =~ /(\w)(\d+)/);
			push(@cols, {
				name	=> $column_name,
				is_key	=> $is_key,
				type	=> $type,
				width	=> $width,
			});
		} elsif($type eq 'row') {
			my $columns = shift @parsed;
			my @row;
			my $lookup_key = '';
			foreach my $i (0..$#cols) {
				my $value = $columns->[ ($i+1)*2 ][2];
				$row[$i] = $value;

				if($cols[$i]{'is_key'}) {
					my $key_value = $value;
					unless(defined($key_value)) { $key_value = ''; }
					$lookup_key .= sprintf("%-" . $cols[$i]{'width'} . "s", $key_value)
				}
			}
			$data{ $lookup_key } = \@row;
		} else {
			# ignore text
			shift @parsed;
		}
	}
	
	$self->{'parsed'}{$table} = {
		attributes	=> $attributes,
		columns		=> \@cols,
		data		=> \%data,
	};
}

sub _parsed {
	my ($self, $table) = @_;
	$table = lc($table);
	unless(exists($self->{'parsed'}{$table})) {
		$self->_parse_table($table);
	}
	return $self->{'parsed'}{$table};
}

=item I<tables>

  my $tables = $is->tables();

Returns an arrayref containing a list of all the tables
that were found in the ISM file.

=cut
sub tables {
	my ($self) = @_;
	return [ sort keys %{$self->{'tables'}} ];
}

=item I<has_table>

  if($is->has_table( 'ModuleSignature' ) {
    print "This is a merge module\n";
  }

Returns true if a table exists with the supplied name, false otherwise.
Table names are case-insensitive.

=cut
sub has_table {
	my ($self, $table) = @_;
	return exists($self->{'sections'}{lc($table)});
}

=item I<column_is_key>

  my $is_key = $is->column_is_key( $table, $column_name );

Returns true if the column is a key column, false
other wise. Returns undef if the column doesn't exist.

=cut
sub column_is_key { 
	my ($self, $table, $column) = @_;
	my $p = $self->_parsed($table);
	foreach my $col (@{$p->{'columns'}}) {
		if($col->{'name'} eq $column) {
			return $col->{'is_key'};
		}
	}
	return;
}

=item I<column_width>

  my $width = $is->column_width( $table, $column_name );

Returns the width of the named column. Returns undef if
the column doesn't exist.

=cut
sub column_width {
	my ($self, $table, $column) = @_;
	my $p = $self->_parsed($table);
	return $p->{'columns'}{$column}{'width'};
}

=item I<column_type>

  my $type = $is->column_type( $table, $column_name );

Returns the type of the named column. Returns undef if the 
column doesn't exist.

=cut
sub column_type {
	my ($self, $table, $column) = @_;
	my $p = $self->_parsed($table);
	return $p->{'columns'}{$column}{'type'};
}

=item I<columns>

  my $columns = $is->columns( $table );

Returns an array ref containing the names of the columns
in the given table.

=cut
sub columns {
	my ($self, $table) = @_;
	my $p = $self->_parsed($table);
	my @cols;
	foreach my $col (@{$p->{'columns'}}) {
		push(@cols, $col->{'name'});
	}
	return \@cols;
}

=item I<key_columns>

  my $key_columns = $is->key_columns( $table );

Returns an array ref containing the names of the
key columns in the given table.

=cut
sub key_columns {
	my ($self, $table) = @_;
	my $p = $self->_parsed($table);
	my @keys;
	foreach my $col (@{$p->{'columns'}}) {
		if($col->{'is_key'}) {
			push(@keys, $col->{'name'});
		}
	}
	return \@keys;
}

sub _find_row {
	my ($self, $table, $rowdata) = @_;
	my $p = $self->_parsed($table);

	my $lookup_key = $self->_build_key( $table, $rowdata );

	if(exists($p->{'data'}{$lookup_key})) {
		return $lookup_key;
	} else {
		return;
	}
}

sub _search_row {
	my ($self, $table, $rowdata) = @_;
	my @results;
	my $p = $self->_parsed($table);
	foreach my $row (values %{$p->{'data'}}) {
		my $match = 1;
		foreach my $i (0..$#{$rowdata}) {
			# undef means they don't care about this column
			if(defined($rowdata->[$i])) {
				# empty string from the user matches undef in the data
				if(defined($row->[$i])) {
					if(ref($rowdata->[$i]) eq 'Regexp') {
						if($row->[$i] !~ /$rowdata->[$i]/) { 
							$match = 0;
							last;
					    	}
					} elsif($rowdata->[$i] ne $row->[$i]) {
						$match = 0;
						last;
					}
				} elsif($rowdata->[$i] ne '') {
					$match = 0;
					last;
				}
			}
		}
		if($match) {
			push(@results, $row);
		}
	}
	return \@results;
}

# the lookup key is just the primary key columns concatenated together,
# with padding to the full column length. this function builds the key
# given the column values
sub _build_key {
	my ($self, $table, $values) = @_;

	my $p = $self->_parsed($table);
	my $lookup_key = '';

	# build the lookup key by concatenating the key columns
	foreach my $i (0..$#{$p->{'columns'}}) {
		if($p->{'columns'}[$i]{'is_key'}) {
			my $width = $p->{'columns'}[$i]{'width'};
			$lookup_key .= sprintf("%-${width}s",
				(defined($values->[$i])) ? $values->[$i] : '');
		}
	}

	return $lookup_key;
}

# takes the various formats allowed for specifying row data,
# and returns a consistent structure to be used by other methods.
# also fills in any missing columns with undef
sub _reformat_args {
	my ($self, $table, @args) = @_;

	my $p = $self->_parsed($table);
	my $row = [];

	if(ref($args[0]) eq 'ARRAY') {
		$row = $args[0];
	} elsif(ref($args[0]) eq 'HASH') {
		my $h = $args[0];
		foreach my $col (@{$p->{'columns'}}) {
			push(@$row, $h->{ $col->{'name'} });
		}
	} else {
		$row = \@args;
	}

	# if the user left columns off the end, fill them
	# with undef
	my $missing_columns = $#{$p->{'columns'}} - $#{$row};
	if($missing_columns > 0) {
		for( 1..$missing_columns ) {
			push(@{$row}, undef);
		}
	}
	return $row;
}

sub _check_args {
	my ($self, $table, @args) = @_;

	my $p = $self->_parsed($table);
	my $row = $self->_reformat_args($table, @args);

	unless( $#{$row} eq $#{$p->{'columns'}} ) {
		carp("Wrong number of columns supplied for table $table");
		return;
	}

	foreach my $i (0..$#{$row}) {
		next unless(defined($row->[$i]));
		my $type = $p->{'columns'}[$i]{'type'};
		if($type =~ /^i$/i) {
			if($row->[$i] =~ /[^\d-]/) {
				croak("Value in $p->{'columns'}[$i]{'name'} column must be numeric");
				return;
			}
		} else {
			my $width = $p->{'columns'}[$i]{'width'};
			if($width > 0 and length($row->[$i]) > $width) {
				croak("Value in $p->{'columns'}[$i]{'name'} column is too long");
				return;
			}
		}
	}

	return $row;
}

=item I<property>

  my $version = $is->property('ProductVersion');
  my $success = $is->property('ProductVersion', $version);

Gets or sets the value associated with a property.  If a value is
supplied, it will attempt to update the property and return 1 
on success and 0 on failure. undef is returned if the property does not exist.

=cut
sub property {
	my ($self, $property, $value) = @_;
	unless(defined($self->getHash_Property({ Property=>$property }))) {
		return;
	}
	if(defined($value)) {
		$self->update_Property({ Property=>$property, Value=>$value });
	}
	return $self->getHash_Property({ Property=>$property });
}

=item I<summary>

  my $summary_value = $is->summary( $summary_field );
  my $success = $is->summary( $summary_field, $value );

  my $summary_table = $is->summary;

Gets or sets the value associated with a field in the summary table.
If no field name is provided, a reference to a hash containing all
of the summary field/value pairs.

=cut
sub summary {
	my ($self, $field, $value) = @_;

	unless(exists($self->{'parsed'}{'summary'})) {
		$self->_parse_summary;
	}
	
	my $data = $self->{'parsed'}{'summary'};

	return $data unless(defined($field));

	if(defined($value)) {
		# make sure this summary field is allowed by the DTD
		return 0 unless($self->valid_summary_field($field));
		$data->{$field} = $value;
		return 1;
	} else {
		return $data->{$field};
	}
}

=item I<summary_fields>

  my @field_names = $is->summary_fields;

Returns a list of the valid fields for the summary table, as they appear
in the DTD embedded in the ISM file.

=cut
sub summary_fields {
	my ($self) = @_;
	
	$self->_parse_summary unless(defined($self->{'parsed'}{'summary'}));

	return @{$self->{'summary_fields'}};
}

=item I<valid_summary_field>
  
  my $is_valid = $is->valid_summary_field( $field_name );

Returns 1 if the field $field_name is valid according to the DTD
in the ISM file, 0 otherwise.

=cut
sub valid_summary_field {
	my ($self, $field) = @_;

	return 0 unless(defined($field));

	foreach my $valid_field ($self->summary_fields) {
		return 1 if($field eq $valid_field);
	}

	return 0;
}

# get the list of valid summary fields from the DTD
sub _parse_summary_fields {
	my ($self) = @_;

	my $text = join('', @{$self->{'sections'}{'dtd'}});

	my ($summary_fields_text) = $text =~ /<!ELEMENT summary\s+\(([^)]+)\)/;

	$summary_fields_text =~ s/[\?\s]//g;
	
	my @summary_fields = split(',', $summary_fields_text);
	
	$self->{'summary_fields'} = \@summary_fields;
}

# turn the XML for the summary table into something we can manipulate easily
sub _parse_summary {
	my ($self) = @_;

	$self->_parse_summary_fields;

	my $text = $self->{'sections'}{'summary'};
	unless(defined($text)) {
		carp("No summary found");
		return;
	}

	my %data;

	my $xml = join("\n", @$text);
	my @parsed = @{$self->{'parser'}->parse($xml)->[1]};

	my $attributes = shift @parsed;

	while(@parsed) {
		my $type = shift @parsed;

		# ignore text
		if($type eq '0') {
			shift @parsed;
			next;
		}

		my $value = shift @parsed;
		$data{ $type } = $value->[2];

	}

	$self->{'parsed'}{'summary'} = \%data;
}

=item I<featureComponents>

  my $components = $is->featureComponents( $feature );

Returns an arrayref of the components in the named feature. Returns
undef if the feature does not exist.

=cut
sub featureComponents {
	my ($self, $feature) = @_;
	my $list = $self->searchHash_FeatureComponents({ Feature_=>$feature });
	unless(@{$list}) {
		return;
	}

	my @components = sort map { $_->{'Component_'} } @{$list};

	return \@components;
}

=back

=head1 COMPONENT ATTRIBUTES


All of the attribute methods can accept an attribute as either
a name or a value. The name can be prefixed with msidbComponentAttributes
as it is in the MSI documentation, but it is not required.

Valid attributes:
  LocalOnly                  0
  SourceOnly                 1
  Optional                   2
  RegistryKeyPath            4
  SharedDllRefCount          8
  Permanent                  16
  ODBCDataSource             32
  Transitive                 64
  NeverOverwrite             128
  64bit                      256
  DisableRegistryReflection  512
  UninstallOnSupersedence    1024
  AttributesShared           2048

=over 4

=item I<set_component_attribute>

  my $success = $is->set_component_attribute( $component_name, '64bit', 1 );

Update the value of a single component attribute flag. Returns 1 on success,
0 on failure.

=cut
sub set_component_attribute {
	my ($self, $component_name, $attribute, $bit_on) = @_;

	my $attr_num = $self->get_component_attribute_value( $attribute );

	return 0 unless(defined($attr_num));

	if($attr_num == 0) {
		$attr_num = 1;
		$bit_on = !$bit_on;
	}

	my $component = $self->getHash_Component($component_name);

	return 0 unless(defined($component));

	if($bit_on) {
		$component->{'Attributes'} |= $attr_num;
	} else {
		my $inverted_attr_num = ~$attr_num;
		$component->{'Attributes'} &= $inverted_attr_num;
	}

	return $self->update_component($component);

}

=item I<get_component_attribute>

  my $is_64bit = $is->get_component_attribute( $component_name, '64bit' );
  my $is_shared = $is->get_component_attribute( $component_name, 8 );

Returns 1 if the named component has the given attribute set, 0 otherwise.
Returns undef if the component does not exist, or the attribute is invalid.
The attribute name or value can be used.

=cut
sub get_component_attribute {
	my ($self, $component_name, $attribute) = @_;

	my $invert = 0;
	my $attr_num = $self->get_component_attribute_value( $attribute );
	
	return unless(defined($attr_num));

	# for some reason, the docs have bit 1 listed twice, once for
	# on and once for off (as hex value 0x0)
	if($attr_num == 0) {
		$attr_num = 1;
		$invert = 1;
	}

	my $component = $self->getHash_Component($component_name);
	
	# must find exactly one component with this name
	return unless(defined($component));

	my $set = ($component->{'Attributes'} & $attr_num) ? 1 : 0;
	
	$set = !$set if($invert);

	return $set;
}

=item I<get_component_attribute_value>

  my $attr_number = $is->get_component_attribute_value( 'LocalOnly' );

Given a component attribute name, returns the bit value associated
with the attribute. The msidbComponentAttributes prefix for attribute names
is accepted, but not required. Given a valid attribute value, simply returns
the value. Returns undef on invalid input.

=cut
sub get_component_attribute_value {
	my ($self, $attribute) = @_;
	
	$attribute =~ s/^msidbComponentAttributes//;
	if($attribute =~ /^\d+$/) {
		if(exists($component_attr_names{$attribute})) {
			return $attribute;
		}
	} elsif(exists($component_attr_values{$attribute})) {
		return $component_attr_values{$attribute};
	}

	return;
}

=item I<get_component_attribute_name>

  my $attr_name = $is->get_component_attribute_name( 512 );

Given a component attribute value, returns the name associated
with the value. Given a valid attribute name, simply returns
the name. The msidbComponentAttributes prefix for attribute names
is accepted, but not required. Returns undef on invalid input.

=cut
sub get_component_attribute_name {
	my ($self, $attribute) = @_;
	
	$attribute =~ s/^msidbComponentAttributes//;
	if($attribute =~ /^\d+$/) {
		if(exists($component_attr_names{$attribute})) {
			return $component_attr_values{$attribute};
		}
	} elsif(exists($component_attr_values{$attribute})) {
		return $component_attr_names{$attribute};
	}

	return;
}

=item I<valid_component_attributes>

  my @attr_names = $is->valid_component_attributes;

Returns a list of valid attribute names.

=cut
sub valid_component_attributes {
	return map { $component_attr_names{$_} } sort { $a <=> $b } keys %component_attr_names;
}

=back

=head1 ROW MANIPULATION METHOD SYNTAX

Row manipulation methods can be called in different ways.
First, they are all case insensitve, and the '_' is
optional, so for the 'Property' table, these are equivilent:

  $is->add_row( 'Property', $rowdata );
  $is->AddRow( 'Property', $rowdata );

Also, you can call each method using the table name in
place of the word 'row', so these are equivilent to the
two above:

  $is->add_property( $rowdata );
  $is->AddProperty( $rowdata );

All row manipulation methods are called with a set of data
describing a row. In the methods below, it is represented by
the variable $rowdata. It can be passed to the function in
one of three formats: a list, an array ref or a hash ref.

List

You can simply put the columns in an array in the correct
order (which you can get by looking at the ism or calling
the I<columns> method), and pass it to the method.

  my @rowdata = ( 'Column_1_Value', 'Column_2_value' );
  $success = $is->update_row( $table, @rowdata );

Array ref

You can do the same as above, but pass it as a single
array reference.

  $success = $is->update_row( $table, \@rowdata );

Hash ref

You can also pass a hash ref, using column names
as keys.

  my %rowdata = (
      Property   => 'ProductVersion',
      Value      => '1.2.3.4',
      ISComments => '',
  );
  $success = $is->update_row( $table, \%rowdata );

=head1 ROW MANIPULATION METHODS

=over 4

=item I<getHash_row>

  my $row = $is->getHash_row( $table, $rowdata );

Returns a hash ref containing the data that matches the keys
supplied in $rowdata. Returns undef if the row is not found.

=cut
sub _get_row_hash {
	my ($self, $table, @args) = @_;
	my $args = $self->_reformat_args($table, @args);
	my $rowkey = $self->_find_row($table, $args);
	if(defined($rowkey)) {
		my %rowdata;
		my $p = $self->_parsed($table);
		
		foreach my $i (0..$#{$p->{'columns'}}) {
			$rowdata{ $p->{'columns'}[$i]{'name'} } = $p->{'data'}{$rowkey}[$i];
		}
		return \%rowdata;
	} else {
		return;
	}
}

=item I<getArray_row>

  my $row = $is->getArray_row( $table, $rowdata );

Returns an array ref containing the data that matches the keys
supplied in $rowdata. Returns undef if the row is not found.

=cut
sub _get_row_array {
	my ($self, $table, @args) = @_;
	my $args = $self->_reformat_args($table, @args);
	my $rowkey = $self->_find_row($table, $args);
	if(defined($rowkey)) {
		my $p = $self->_parsed($table);
		return $p->{'data'}{$rowkey};
	} else {
		return;
	}
}

=item I<update_row>

  my $success = $is->update_row( $table, $rowdata );

Updates the row that matches the keys supplied in
$rowdata. Any columns for which an undef is supplied
will remain unchanged. An empty string will force
the column to be empty. Returns 1 on success, 0 on
failure.

=cut
sub _update_row {
	my ($self, $table, @args) = @_;
	my $rowdata = $self->_check_args($table, @args);
	unless(defined($rowdata)) {
		return 0;
	}
	my $rowkey = $self->_find_row($table, $rowdata);
	unless(defined($rowkey)) {
		carp("Failed to locate row in $table for update");
		return 0;
	}
	my $p = $self->_parsed($table);
	foreach my $i (0..$#{$rowdata}) {
		if(defined($rowdata->[$i])) {
			$p->{'data'}{$rowkey}[$i] = $rowdata->[$i];
		}
	}
	return 1;
}

=item I<add_row>

  my $success = $is->add_row( $table, $rowdata );

Adds a row containing the data in $rowdata. Returns
1 on success, 0 on failure.

=cut
sub _add_row {
	my ($self, $table, @args) = @_;
	my $rowdata = $self->_check_args($table, @args);
	unless(defined($rowdata)) {
		return 0;
	}
	my $rowkey = $self->_find_row($table, $rowdata);
	if(defined($rowkey)) {
		carp("Row to add in '$table' table already exists");
		return 0;
	}
	$rowkey = $self->_build_key($table, $rowdata);
	unless(defined($rowkey)) {
		return 0;
	}
	my $p = $self->_parsed($table);
	$p->{'data'}{$rowkey} = $rowdata;
	return 1;
}

=item I<del_row>

  my $success = $is->del_row( $table, $rowdata );

Deletes the row that matches the keys supplied in
$rowdata. Returns 1 on success, 0 on failure.

=cut
sub _del_row {
	my ($self, $table, @args) = @_;
	my $args = $self->_reformat_args($table, @args);
	my $rowkey = $self->_find_row($table, $args);
	unless(defined($rowkey)) {
		carp("Failed to locate row in $table for delete");
		return 0;
	}
	my $p = $self->_parsed($table);
	delete($p->{'data'}{$rowkey});
	return 1;
}

=item I<purge_row>

  $is->purge_row( $table, $rowdata );
  $is->purge_row( 'Component', 'Awesome.dll' );
  $is->PurgeComponent( 'Awesome.dll' );

Removes the row that matches the key in $rowdata from the given table, and any rows
in other tables with foreign keys that reference it. Key values are
case sensitive. This only works for tables with a key column that has
the same name as the table, which seems to be the only way you can use
foreign keys in an ISM in any case. Returns 1 on success, 0 on failure.

=cut
sub _purge_row {
	my ($self, $table, $key_value) = @_;

	# make sure the key exists in the table
	my $rowkey = $self->_find_row($table, $self->_reformat_args($table, $key_value));
	unless(defined($rowkey)) {
		return 0;
	}

	$self->_del_row($table, $rowkey);

	my $foreign_key_col = $self->{'correct_case'}{$table} . '_';

	foreach my $table (@{$self->{'foreign_keys'}{$foreign_key_col}}) {
		my $rows_to_delete = $self->_search_row_array($table, { $foreign_key_col => $key_value });
		if(@{$rows_to_delete}) {
			foreach my $row (@{$rows_to_delete}) {
				$self->_del_row($table, $row) or return 0;
			}
		}
	}

	return 1;
}

=item I<add_or_update_row>

  my $success = $is->add_or_update_row( $table, $rowdata );

Adds a row if no row exists with the supplied keys, updates
the matching row otherwise.

=cut
sub _add_or_update_row {
	my ($self, $table, @args) = @_;
	my $args = $self->_reformat_args($table, @args);
	my $rowkey = $self->_find_row($table, $args);
	if(defined($rowkey)) {
		return $self->_update_row($table, $args);
	} else {
		return $self->_add_row($table, $args);
	}
}

=item I<searchHash_row>

  my $rows = $is->searchHash_row( $table, $rowdata );

Returns any rows in the given table that match the supplied 
columns. The return value is an arrayref, where each entry is
a hash as would be returned by I<getHash_row>. Returns an empty
arrayref if no matches are found. Returns the entire table if
no $rowdata argument is provided.

Columns with undefined values will be ignored for matching purposes.
Values used for matching can be either literal strings, in which
case an exact match is required, or quoted regular expressions such as:

  my $rows = $is->searchHash_row( 'Property', { Property=>qr/^_/ } );

This would search for all properties that begin with an underscore.

=cut
sub _search_row_hash {
	my ($self, $table, @args) = @_;
	my $args = $self->_reformat_args($table, @args);
	my $results = $self->_search_row($table, $args);

	my @hash_results;
	my $p = $self->_parsed($table);
	
	foreach my $row (@{$results}) {
		my %rowdata;
		foreach my $i (0..$#{$p->{'columns'}}) {
			$rowdata{ $p->{'columns'}[$i]{'name'} } = $row->[$i];
		}
		push(@hash_results, \%rowdata);
	}

	return \@hash_results;
}

=item I<searchArray_row>

  my $rows = $is->searchArray_row( $table, $rowdata );

Works the same as I<searchHash_row>, but returns an arrayref containing
arrayrefs, like I<getArray_row> instead of hashrefs.

=cut
sub _search_row_array {
	my ($self, $table, @args) = @_;
	my $args = $self->_reformat_args($table, @args);
	return $self->_search_row($table, $args);
}

# this is (almost) a copy of the xml_escape function in XML::Parser::Expat.
# The version there doesn't seem to work properly on data that was read
# in via XML::Parser, because a call to study causes subsequent matches to
# fail
sub _xml_escape {
	my $text = shift @_;

	$text =~ s/\&/\&amp;/g;
	$text =~ s/</\&lt;/g;
	$text =~ s/>/\&gt;/g;

	foreach (@_) {
		die "xml_escape: '$_' isn't a single character" if length($_) > 1;

		if ($_ eq '"') {
			$text =~ s/\"/\&quot;/;
		}
		elsif ($_ eq "'") {
			$text =~ s/\'/\&apos;/;
		}
		else {
			my $rep = '&#' . sprintf('x%X', ord($_)) . ';';
			if (/\W/) {
				my $ptrn = "\\$_";
				$text =~ s/$ptrn/$rep/g;
			}
			else {
				$text =~ s/$_/$rep/g;
			}
		}
	}
	$text;
}

=back

=head1 AUTHOR

Kirk Baucom, E<lt>kbaucom@schizoid.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Kirk Baucom

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__DATA__

msidbComponentAttributesLocalOnly 0
msidbComponentAttributesSourceOnly 1
msidbComponentAttributesOptional 2
msidbComponentAttributesRegistryKeyPath 4
msidbComponentAttributesSharedDllRefCount 8
msidbComponentAttributesPermanent 16
msidbComponentAttributesODBCDataSource 32
msidbComponentAttributesTransitive 64
msidbComponentAttributesNeverOverwrite 128
msidbComponentAttributes64bit 256
msidbComponentAttributesDisableRegistryReflection 512
 

