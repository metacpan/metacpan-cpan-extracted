package Zuzu::Module::CSV;

use strict;
use utf8;

our $VERSION = '0.007000';

use Encode ();
use Scalar::Util qw( blessed );
use Text::CSV_XS ();
use Zuzu::Error;
use Zuzu::Value::BinaryString;
use Zuzu::Util::NativeHelpers qw(
	native_class
	native_function
	native_object
	perl_to_zuzu
	zuzu_bool
	zuzu_to_perl
);

sub _path_tiny_from_object {
	my ( $path_obj, $method_name ) = @_;

	if (
		blessed($path_obj)
		and $path_obj->isa('Zuzu::Value::Object')
		and exists $path_obj->slots->{_path_tiny}
	) {
		return $path_obj->slots->{_path_tiny};
	}
	elsif ( ref($path_obj) eq 'HASH' and exists $path_obj->{_path_tiny} ) {
		return $path_obj->{_path_tiny};
	}

	die Zuzu::Error->new_runtime(
		message => "TypeException: $method_name expects Path as first argument",
		file => '<std/data/csv>',
		line => 0,
	);
}

sub _dbh_from_object {
	my ( $dbh_obj, $method_name ) = @_;

	if (
		blessed($dbh_obj)
		and $dbh_obj->isa('Zuzu::Value::Object')
		and exists $dbh_obj->slots->{_dbh}
	) {
		return $dbh_obj->slots->{_dbh};
	}
	elsif ( ref($dbh_obj) eq 'HASH' and exists $dbh_obj->{_dbh} ) {
		return $dbh_obj->{_dbh};
	}

	die Zuzu::Error->new_runtime(
		message => "TypeException: $method_name expects DatabaseHandle",
		file => '<std/data/csv>',
		line => 0,
	);
}

sub _dbi_call {
	my ( $code, $prefix ) = @_;

	my $result;
	eval {
		$result = $code->();
		1;
	} or do {
		my $err = $@;
		$err = "$err";
		chomp $err;
		my $message = $err;
		if ( defined $prefix and $prefix ne '' ) {
			$message = "$prefix: $err";
		}
		die Zuzu::Error->new_runtime(
			message => $message,
			file => '<std/data/csv>',
			line => 0,
		);
	};

	return $result;
}

sub _normalize_config {
	my ( $positional, $named ) = @_;

	my %config = %{ $named // {} };
	if ( @{ $positional // [] } ) {
		my $first = $positional->[0];
		if ( ref($first) ) {
			my $first_hash = zuzu_to_perl( $first );
			if ( ref($first_hash) eq 'HASH' ) {
				for my $key ( CORE::keys %{ $first_hash } ) {
					$config{$key} = $first_hash->{$key};
				}
			}
		}
	}

	return \%config;
}

sub _options_hash {
	my ( $value ) = @_;

	return {} if !defined $value;
	return $value if ref($value) eq 'HASH';

	my $perl = zuzu_to_perl( $value );
	return $perl if ref($perl) eq 'HASH';
	return {};
}

sub _hash_from_value {
	my ( $value ) = @_;

	my $hash = _options_hash( $value );
	return $hash if ref($hash) eq 'HASH';
	return {};
}

sub _array_from_value {
	my ( $value ) = @_;

	return [] if !defined $value;
	return $value if ref($value) eq 'ARRAY';

	my $perl = zuzu_to_perl( $value );
	return $perl if ref($perl) eq 'ARRAY';
	return [];
}

sub _config_merge {
	my ( @parts ) = @_;

	my %out;
	for my $part ( @parts ) {
		next if ref($part) ne 'HASH';
		for my $key ( CORE::keys %{$part} ) {
			$out{$key} = $part->{$key};
		}
	}
	return \%out;
}

sub _normalize_runtime_config {
	my ( $config ) = @_;

	$config = _config_merge( $config );

	for my $key ( qw(
		columns
		required_columns
		sniff_candidates
	) ) {
		$config->{$key} = _array_from_value( $config->{$key} )
			if exists $config->{$key};
	}

	for my $key ( qw(
		defaults
		rename_headers
		column_map
		column_types
		types
	) ) {
		$config->{$key} = _hash_from_value( $config->{$key} )
			if exists $config->{$key};
	}

	return $config;
}

sub _text_csv_config {
	my ( $config ) = @_;

	my %allowed = map { $_ => 1 } qw(
		allow_loose_quotes
		allow_loose_escapes
		allow_unquoted_escape
		allow_whitespace
		always_quote
		binary
		blank_is_undef
		empty_is_undef
		escape_char
		eol
		quote_char
		quote_empty
		quote_null
		quote_space
		sep_char
		verbatim
	);

	my %opts;
	for my $key ( CORE::keys %{ $config // {} } ) {
		next if !$allowed{$key};
		my $value = $config->{$key};
		if (
			$key =~ /\A(?:allow_|always_|binary|blank_|empty_|quote_|verbatim)/
		) {
			$opts{$key} = zuzu_bool( $value, 0 ) ? 1 : 0;
		}
		else {
			$opts{$key} = defined $value ? "$value" : undef;
		}
	}

	$opts{binary} = 1 if !exists $opts{binary};
	$opts{sep_char} = ',' if !exists $opts{sep_char};
	$opts{quote_char} = '"' if !exists $opts{quote_char};
	$opts{escape_char} = '"' if !exists $opts{escape_char};
	$opts{eol} = "\n" if !exists $opts{eol};

	return \%opts;
}

sub _encoding_name {
	my ( $config ) = @_;

	return 'UTF-8' if !defined $config;
	return 'UTF-8' if !exists $config->{encoding};
	return undef if !defined $config->{encoding};
	return "$config->{encoding}";
}

sub _assert_binary_string {
	my ( $value, $label ) = @_;

	return $value
		if blessed($value) and $value->isa('Zuzu::Value::BinaryString');

	my $type = !defined($value) ? 'Null' : ref($value) ? ref($value) : 'String';
	die Zuzu::Error->new_runtime(
		message => "TypeException: $label expects BinaryString, got $type",
		file => '<std/data/csv>',
		line => 0,
	);
}

sub _text_from_bytes {
	my ( $bytes, $config ) = @_;

	my $encoding = _encoding_name($config);
	return $bytes if !defined $encoding;
	return Encode::decode( $encoding, $bytes, Encode::FB_CROAK );
}

sub _bytes_from_text {
	my ( $text, $config ) = @_;

	$text = '' if !defined $text;
	my $encoding = _encoding_name($config);
	return "$text" if !defined $encoding;
	return Encode::encode( $encoding, "$text", Encode::FB_CROAK );
}

sub _new_csv_backend {
	my ( $config ) = @_;

	my $csv = Text::CSV_XS->new( _text_csv_config($config) );
	if ( !$csv ) {
		die Zuzu::Error->new_runtime(
			message => 'CSV backend initialization failed',
			file => '<std/data/csv>',
			line => 0,
		);
	}
	return $csv;
}

sub _open_input_handle {
	my ( $path_tiny, $config ) = @_;

	my $encoding = _encoding_name( $config );
	my $mode = defined $encoding
		? "<:encoding($encoding)"
		: '<';

	open my $fh, $mode, $path_tiny->stringify
		or die Zuzu::Error->new_runtime(
			message => "Could not open '$path_tiny' for reading: $!",
			file => '<std/data/csv>',
			line => 0,
		);

	return $fh;
}

sub _open_output_handle {
	my ( $path_tiny, $config ) = @_;

	my $encoding = _encoding_name( $config );
	my $append = zuzu_bool( $config->{append}, 0 ) ? 1 : 0;
	my $mode = $append ? '>>' : '>';
	$mode .= ":encoding($encoding)" if defined $encoding;

	open my $fh, $mode, $path_tiny->stringify
		or die Zuzu::Error->new_runtime(
			message => "Could not open '$path_tiny' for writing: $!",
			file => '<std/data/csv>',
			line => 0,
		);

	return $fh;
}

sub _string_input_handle {
	my ( $text ) = @_;

	my $scalar = defined $text ? "$text" : '';
	open my $fh, '<', \$scalar
		or die Zuzu::Error->new_runtime(
			message => "Could not open in-memory CSV source: $!",
			file => '<std/data/csv>',
			line => 0,
		);
	return $fh;
}

sub _string_output_handle {
	my $out = '';
	open my $fh, '>', \$out
		or die Zuzu::Error->new_runtime(
			message => "Could not open in-memory CSV sink: $!",
			file => '<std/data/csv>',
			line => 0,
		);
	return ( $fh, \$out );
}

sub _columns_from_config {
	my ( $config ) = @_;

	if ( exists $config->{columns} ) {
		my $cols = $config->{columns};
		if ( ref($cols) eq 'ARRAY' ) {
			return [ map { defined $_ ? "$_" : '' } @{ $cols } ];
		}
	}

	return undef;
}

sub _hashify_row {
	my ( $row, $headers ) = @_;

	my %out;
	for my $i ( 0 .. $#{ $headers } ) {
		$out{ $headers->[$i] } = $row->[$i];
	}
	return \%out;
}

sub _header_name {
	my ( $raw, $config ) = @_;

	$raw = defined $raw ? "$raw" : '';
	$raw =~ s/^\s+// if zuzu_bool( $config->{trim_headers}, 0 );
	$raw =~ s/\s+\z// if zuzu_bool( $config->{trim_headers}, 0 );
	$raw = lc($raw) if zuzu_bool( $config->{lowercase_headers}, 0 );

	my $rename = _hash_from_value( $config->{rename_headers} );
	$raw = $rename->{$raw} if exists $rename->{$raw};

	return $raw;
}

sub _normalize_headers {
	my ( $headers, $config ) = @_;

	return [] if ref($headers) ne 'ARRAY';
	my $duplicate_policy = exists $config->{duplicate_headers}
		? lc( "$config->{duplicate_headers}" )
		: 'overwrite';
	my %seen;
	my @out;

	for my $name ( @{$headers} ) {
		my $normalized = _header_name( $name, $config );
		if ( exists $seen{$normalized} ) {
			if ( $duplicate_policy eq 'error' ) {
				die Zuzu::Error->new_runtime(
					message => "Duplicate CSV header '$normalized'",
					file => '<std/data/csv>',
					line => 0,
				);
			}
			elsif ( $duplicate_policy eq 'suffix' ) {
				$seen{$normalized}++;
				$normalized = $normalized . '_' . $seen{$normalized};
			}
			elsif ( $duplicate_policy eq 'keep_first' ) {
				$normalized = $normalized . '__ignored_' . ( $seen{$normalized} + 1 );
				$seen{$normalized}++;
			}
			else {
				$seen{$normalized}++;
			}
		}
		else {
			$seen{$normalized} = 1;
		}
		push @out, $normalized;
	}

	return \@out;
}

sub _required_columns_check {
	my ( $headers, $config ) = @_;

	my $required = _array_from_value( $config->{required_columns} );
	return if !@{$required};

	my %have = map { $_ => 1 } @{ $headers // [] };
	for my $name ( @{$required} ) {
		next if $have{$name};
		die Zuzu::Error->new_runtime(
			message => "Required CSV column '$name' missing",
			file => '<std/data/csv>',
			line => 0,
		);
	}
}

sub _default_columns_for_row {
	my ( $row ) = @_;
	my @cols;
	for my $i ( 0 .. $#{ $row } ) {
		push @cols, 'column' . ( $i + 1 );
	}
	return \@cols;
}

sub _csv_error_detail {
	my ( $csv, $prefix, $state ) = @_;

	my $diag = $csv ? $csv->error_diag : undef;
	$diag = defined $diag ? "$diag" : 'unknown CSV error';

	my $message = $prefix . ': ' . $diag;
	if ( ref($state) eq 'HASH' ) {
		my @parts;
		push @parts, 'line ' . $state->{line_number}
			if defined $state->{line_number};
		push @parts, 'column ' . $state->{column_number}
			if defined $state->{column_number};
		push @parts, 'row ' . $state->{raw_line}
			if defined $state->{raw_line};
		$message .= ' (' . join( ', ', @parts ) . ')' if @parts;
	}

	return {
		message => $message,
		line_number => $state->{line_number},
		column_number => $state->{column_number},
		raw_line => $state->{raw_line},
	};
}

sub _die_csv_error {
	my ( $csv, $prefix, $state ) = @_;

	my $detail = _csv_error_detail( $csv, $prefix, $state );
	die Zuzu::Error->new_runtime(
		message => $detail->{message},
		file => '<std/data/csv>',
		line => 0,
	);
}

sub _coerce_scalar {
	my ( $value, $type ) = @_;

	return undef if !defined $value and ( defined $type and $type ne 'string' );
	return $value if !defined $type;

	$type = lc("$type");

	return undef if $type eq 'null';
	if ( $type eq 'integer' or $type eq 'int' ) {
		return 0 + int( $value // 0 );
	}
	if ( $type eq 'number' or $type eq 'float' or $type eq 'real' ) {
		return 0.0 + ( $value // 0 );
	}
	if ( $type eq 'boolean' or $type eq 'bool' ) {
		my $text = defined $value ? lc("$value") : '';
		return 1 if $text =~ /\A(?:1|true|yes|on)\z/;
		return 0 if $text =~ /\A(?:0|false|no|off|)\z/;
		return $value ? 1 : 0;
	}

	return defined $value ? "$value" : '';
}

sub _invoke_hook {
	my ( $runtime, $hook, @args ) = @_;

	return undef
		if !blessed($hook)
		or !$hook->isa('Zuzu::Value::Function');

	my @zuzu_args = map { perl_to_zuzu($_) } @args;
	my $result = $runtime->_call_function(
		$hook,
		\@zuzu_args,
		'<std/data/csv>',
		0,
	);
	return zuzu_to_perl( $result );
}

sub _column_hook_for {
	my ( $config, $key ) = @_;

	return undef if ref($config) ne 'HASH';
	my $map = $config->{parsers};
	$map = $config->{formatters} if $config->{_hook_mode} && $config->{_hook_mode} eq 'format';
	return undef if ref($map) ne 'HASH';
	return $map->{$key} if exists $map->{$key};
	return undef;
}

sub _value_type_for {
	my ( $config, $headers, $index ) = @_;

	my $types = $config->{types};
	return undef if !defined $types;

	if ( ref($types) eq 'ARRAY' ) {
		return $types->[$index];
	}
	if ( ref($types) eq 'HASH' ) {
		my $name = ref($headers) eq 'ARRAY' ? $headers->[$index] : undef;
		return $types->{$name} if defined $name and exists $types->{$name};
	}
	return undef;
}

sub _apply_row_rules {
	my ( $runtime, $row, $headers, $config ) = @_;

	my $state = $config->{_row_state} // {};

	if ( ref($headers) eq 'ARRAY' ) {
		my $expected = scalar @{$headers};
		my $actual = scalar @{$row};
		my $ragged = exists $config->{ragged}
			? lc( "$config->{ragged}" )
			: 'allow';
		my $fill_value = exists $config->{fill_value}
			? $config->{fill_value}
			: undef;

		if ( $actual < $expected ) {
			if ( $ragged eq 'fill' ) {
				push @{$row}, ($fill_value) x ($expected - $actual);
			}
			elsif ( $ragged eq 'error' ) {
				die Zuzu::Error->new_runtime(
					message => "CSV row has too few fields at line "
						. ( $state->{line_number} // '?' ),
					file => '<std/data/csv>',
					line => 0,
				);
			}
		}
		elsif ( $actual > $expected ) {
			if ( $ragged eq 'truncate' ) {
				splice @{$row}, $expected;
			}
			elsif ( $ragged eq 'error' ) {
				die Zuzu::Error->new_runtime(
					message => "CSV row has too many fields at line "
						. ( $state->{line_number} // '?' ),
					file => '<std/data/csv>',
					line => 0,
				);
			}
		}
	}

	for my $i ( 0 .. $#{ $row } ) {
		my $type = _value_type_for( $config, $headers, $i );
		my $hook = _column_hook_for(
			{
				%{$config},
				parsers => _hash_from_value( $config->{parsers} ),
			},
			( ref($headers) eq 'ARRAY' ? $headers->[$i] : $i ),
		);

		$row->[$i] = _coerce_scalar( $row->[$i], $type ) if defined $type;
		if ( defined $hook ) {
			$row->[$i] = _invoke_hook(
				$runtime,
				$hook,
				$row->[$i],
				{
					column => ref($headers) eq 'ARRAY' ? $headers->[$i] : $i,
					row_number => $state->{row_number},
					line_number => $state->{line_number},
				},
			);
		}
	}

	if ( ref($headers) eq 'ARRAY' ) {
		my $dict = _hashify_row( $row, $headers );
		my $defaults = _hash_from_value( $config->{defaults} );
		for my $key ( CORE::keys %{$defaults} ) {
			$dict->{$key} = $defaults->{$key}
				if !exists $dict->{$key} or !defined $dict->{$key} or $dict->{$key} eq '';
		}

		my $unknown_policy = exists $config->{unknown_columns}
			? lc( "$config->{unknown_columns}" )
			: 'keep';
		if ( $unknown_policy eq 'ignore' ) {
			my %allowed = map { $_ => 1 } @{$headers};
			$allowed{$_} = 1 for CORE::keys %{$defaults};
			for my $key ( CORE::keys %{$dict} ) {
				delete $dict->{$key} if !$allowed{$key};
			}
		}

		return $dict;
	}

	return $row;
}

sub _reader_state {
	my ( $self ) = @_;

	return {
		line_number => $self->slots->{_line_number} // 0,
		row_number => $self->slots->{_row_number} // 0,
		column_number => undef,
		raw_line => $self->slots->{_last_raw_line},
	};
}

sub _reader_next_raw {
	my ( $self ) = @_;

	return undef if zuzu_bool( $self->slots->{_closed}, 0 );

	my $csv = $self->slots->{_csv};
	my $fh = $self->slots->{_fh};
	while (1) {
		my $pos = tell($fh);
		my $raw_line = <$fh>;
		return undef if !defined $raw_line;

		$self->slots->{_line_number} = ( $self->slots->{_line_number} // 0 ) + 1;
		$self->slots->{_last_raw_line} = $raw_line;

		my $comment_char = $self->slots->{_config}{comment_char};
		if (
			defined $comment_char
			and $comment_char ne ''
			and substr( $raw_line, 0, length($comment_char) ) eq $comment_char
		) {
			next;
		}

		if (
			zuzu_bool( $self->slots->{_config}{skip_empty_rows}, 0 )
			and $raw_line =~ /\A\s*\z/
		) {
			next;
		}

		seek( $fh, $pos, 0 );
		my $row = $csv->getline($fh);
		if ( !$row ) {
			return undef if $csv->eof;
			return { __error__ => _csv_error_detail( $csv, 'CSV read failed', _reader_state($self) ) };
		}

		$self->slots->{_row_number} = ( $self->slots->{_row_number} // 0 ) + 1;
		return $row;
	}
}

sub _reader_fetch_array {
	my ( $runtime, $self ) = @_;

	while (1) {
		my $row = _reader_next_raw( $self );
		return undef if !defined $row;

		if ( ref($row) eq 'HASH' and exists $row->{__error__} ) {
			my $policy = exists $self->slots->{_config}{on_error}
				? lc( "$self->slots->{_config}{on_error}" )
				: 'die';
			push @{ $self->slots->{_errors} }, $row->{__error__};
			if ( $policy eq 'collect' ) {
				next;
			}
			die Zuzu::Error->new_runtime(
				message => $row->{__error__}{message},
				file => '<std/data/csv>',
				line => 0,
			);
		}

		$self->slots->{_config}{_row_state} = _reader_state($self);
		my $result = _apply_row_rules(
			$runtime,
			$row,
			$self->slots->{_headers},
			$self->slots->{_config},
		);

		return ref($result) eq 'HASH'
			? [ map { $result->{$_} } @{ $self->slots->{_headers} // [] } ]
			: $result;
	}
}

sub _reader_fetch_dict {
	my ( $runtime, $self ) = @_;

	my $headers = $self->slots->{_headers};
	if ( ref($headers) ne 'ARRAY' or !@{$headers} ) {
		die Zuzu::Error->new_runtime(
			message => 'CSVReader.next_dict requires headers or columns',
			file => '<std/data/csv>',
			line => 0,
		);
	}

	while (1) {
		my $row = _reader_next_raw( $self );
		return undef if !defined $row;

		if ( ref($row) eq 'HASH' and exists $row->{__error__} ) {
			my $policy = exists $self->slots->{_config}{on_error}
				? lc( "$self->slots->{_config}{on_error}" )
				: 'die';
			push @{ $self->slots->{_errors} }, $row->{__error__};
			if ( $policy eq 'collect' ) {
				next;
			}
			die Zuzu::Error->new_runtime(
				message => $row->{__error__}{message},
				file => '<std/data/csv>',
				line => 0,
			);
		}

		$self->slots->{_config}{_row_state} = _reader_state($self);
		my $result = _apply_row_rules(
			$runtime,
			$row,
			$headers,
			$self->slots->{_config},
		);
		return $result if ref($result) eq 'HASH';
		return _hashify_row( $result, $headers );
	}
}

sub _reader_default_mode {
	my ( $self ) = @_;
	return $self->slots->{_row_mode} // 'array';
}

sub _reader_to_iterator {
	my ( $runtime, $self ) = @_;

	return native_function(
		name => 'iterator',
		native => sub {
			my $row = _reader_default_mode($self) eq 'dict'
				? _reader_fetch_dict( $runtime, $self )
				: _reader_fetch_array( $runtime, $self );

			if ( !defined $row ) {
				my $exhausted = $runtime->_instantiate_builtin_object(
					$runtime->{_builtin_classes}{ExhaustedException},
					{
						message => 'iterator exhausted',
						file => '<std/data/csv>',
						line => 0,
					},
				);
				die {
					_zuzu_throw => 1,
					value => $exhausted,
				};
			}

			return perl_to_zuzu( $row );
		},
	);
}

sub _quote_identifier {
	my ( $name ) = @_;
	$name = defined $name ? "$name" : '';
	$name =~ s/"/""/g;
	return qq("$name");
}

sub _table_column_names {
	my ( $dbh, $table ) = @_;

	my $sth = _dbi_call(
		sub {
			return $dbh->prepare(
				'select * from ' . _quote_identifier($table) . ' where 1 = 0'
			);
		},
		'prepare table metadata query failed',
	);
	_dbi_call(
		sub {
			$sth->execute;
			return 1;
		},
		'execute table metadata query failed',
	);

	my $names = $sth->{NAME} // [];
	return [ map { defined $_ ? "$_" : '' } @{ $names } ];
}

sub _column_type_for_index {
	my ( $column_types, $columns, $index ) = @_;

	return 'TEXT' if !defined $column_types;
	if ( ref($column_types) eq 'ARRAY' ) {
		return defined $column_types->[$index] ? "$column_types->[$index]" : 'TEXT';
	}
	if ( ref($column_types) eq 'HASH' ) {
		my $name = $columns->[$index];
		return defined $column_types->{$name} ? "$column_types->{$name}" : 'TEXT';
	}
	return 'TEXT';
}

sub _create_table_if_needed {
	my ( $dbh, $table, $columns, $options ) = @_;

	return if !zuzu_bool( $options->{create_table}, 0 );

	my $if_exists = exists $options->{if_exists}
		? lc( "$options->{if_exists}" )
		: 'append';

	if ( $if_exists eq 'replace' ) {
		_dbi_call(
			sub {
				$dbh->do( 'drop table if exists ' . _quote_identifier($table) );
				return 1;
			},
			'drop table failed',
		);
	}

	my $column_types = $options->{column_types};
	my @defs;
	for my $i ( 0 .. $#{ $columns } ) {
		push @defs, join ' ',
			_quote_identifier( $columns->[$i] ),
			_column_type_for_index( $column_types, $columns, $i );
	}

	my $create_sql = 'create table ';
	$create_sql .= 'if not exists ' if $if_exists eq 'append';
	$create_sql .= _quote_identifier($table) . ' (' . join( ', ', @defs ) . ')';

	_dbi_call(
		sub {
			$dbh->do( $create_sql );
			return 1;
		},
		'create table failed',
	);
}

sub _output_columns_from_rows {
	my ( $rows, $config ) = @_;

	my $columns = _columns_from_config($config);
	return $columns if ref($columns) eq 'ARRAY' && @{$columns};

	for my $row ( @{ $rows // [] } ) {
		if ( ref($row) eq 'HASH' ) {
			my @keys = CORE::keys %{$row};
			@keys = sort @keys if zuzu_bool( $config->{sort_columns}, 0 );
			return \@keys;
		}
		if ( ref($row) eq 'ARRAY' ) {
			return _default_columns_for_row($row)
				if zuzu_bool( $config->{headers}, 0 );
			return undef;
		}
	}

	return undef;
}

sub _map_output_row {
	my ( $runtime, $row, $columns, $config ) = @_;

	my $formatters = _hash_from_value( $config->{formatters} );
	my @out;
	my $source = ref($row) eq 'HASH' ? $row : undef;
	my $array = ref($row) eq 'ARRAY' ? $row : undef;

	if ( ref($source) eq 'HASH' ) {
		for my $i ( 0 .. $#{ $columns // [] } ) {
			my $key = $columns->[$i];
			my $value = $source->{$key};
			if ( exists $formatters->{$key} ) {
				$value = _invoke_hook(
					$runtime,
					$formatters->{$key},
					$value,
					{ column => $key, index => $i },
				);
			}
			push @out, $value;
		}
		return \@out;
	}

	if ( ref($array) eq 'ARRAY' ) {
		for my $i ( 0 .. $#{ $array } ) {
			my $value = $array->[$i];
			if ( exists $formatters->{$i} ) {
				$value = _invoke_hook(
					$runtime,
					$formatters->{$i},
					$value,
					{ index => $i },
				);
			}
			push @out, $value;
		}
		return \@out;
	}

	return [ $row ];
}

sub _write_rows {
	my ( $runtime, $csv, $fh, $rows, $options ) = @_;

	my $headers = zuzu_bool( $options->{headers}, 0 ) ? 1 : 0;
	my $columns = _output_columns_from_rows( $rows, $options );
	my $wrote_header = zuzu_bool( $options->{append}, 0 ) ? 1 : 0;

	if ( !$wrote_header and $headers and ref($columns) eq 'ARRAY' ) {
		$csv->print( $fh, $columns )
			or _die_csv_error( $csv, 'CSV write header failed', {} );
		$wrote_header = 1;
	}

	for my $row ( @{ $rows // [] } ) {
		my $array = _map_output_row( $runtime, $row, $columns, $options );
		$csv->print( $fh, $array )
			or _die_csv_error( $csv, 'CSV write row failed', {} );
	}
}

sub _new_reader_object {
	my ( $class_obj, $csv, $fh, $headers, $row_mode, $config ) = @_;

	return native_object(
		class => $class_obj,
		slots => {
			_csv => $csv,
			_fh => $fh,
			_headers => $headers,
			_row_mode => $row_mode,
			_config => $config,
			_closed => 0,
			_line_number => 0,
			_row_number => 0,
			_last_raw_line => undef,
			_errors => [],
		},
		const => {
			_csv => 1,
			_fh => 1,
			_headers => 0,
			_row_mode => 0,
			_config => 0,
			_closed => 0,
			_line_number => 0,
			_row_number => 0,
			_last_raw_line => 0,
			_errors => 0,
		},
	);
}

sub _new_writer_object {
	my ( $class_obj, $csv, $fh, $config ) = @_;

	my $columns = _columns_from_config($config);
	return native_object(
		class => $class_obj,
		slots => {
			_csv => $csv,
			_fh => $fh,
			_config => $config,
			_columns => $columns,
			_wrote_header => zuzu_bool( $config->{append}, 0 ) ? 1 : 0,
			_closed => 0,
			_row_number => 0,
		},
		const => {
			_csv => 1,
			_fh => 1,
			_config => 0,
			_columns => 0,
			_wrote_header => 0,
			_closed => 0,
			_row_number => 0,
		},
	);
}

sub _writer_columns {
	my ( $self, $row ) = @_;

	my $columns = $self->slots->{_columns};
	return $columns if ref($columns) eq 'ARRAY' && @{$columns};

	if ( ref($row) eq 'HASH' ) {
		my @keys = CORE::keys %{$row};
		@keys = sort @keys if zuzu_bool( $self->slots->{_config}{sort_columns}, 0 );
		$columns = \@keys;
	}
	elsif ( ref($row) eq 'ARRAY' and zuzu_bool( $self->slots->{_config}{headers}, 0 ) ) {
		$columns = _default_columns_for_row($row);
	}

	$self->slots->{_columns} = $columns if ref($columns) eq 'ARRAY';
	return $columns;
}

sub _writer_maybe_header {
	my ( $runtime, $self, $columns ) = @_;

	return if $self->slots->{_wrote_header};
	return if !zuzu_bool( $self->slots->{_config}{headers}, 0 );
	return if ref($columns) ne 'ARRAY';

	$self->slots->{_csv}->print( $self->slots->{_fh}, $columns )
		or _die_csv_error( $self->slots->{_csv}, 'CSV write header failed', {} );
	$self->slots->{_wrote_header} = 1;
}

sub _writer_write_row {
	my ( $runtime, $self, $row ) = @_;

	die Zuzu::Error->new_runtime(
		message => 'CSVWriter is closed',
		file => '<std/data/csv>',
		line => 0,
	) if zuzu_bool( $self->slots->{_closed}, 0 );

	my $columns = _writer_columns( $self, $row );
	_writer_maybe_header( $runtime, $self, $columns );

	my $array = _map_output_row( $runtime, $row, $columns, $self->slots->{_config} );
	$self->slots->{_csv}->print( $self->slots->{_fh}, $array )
		or _die_csv_error( $self->slots->{_csv}, 'CSV write row failed', {} );

	$self->slots->{_row_number} = ( $self->slots->{_row_number} // 0 ) + 1;
	return perl_to_zuzu( $array );
}

sub _sniff_counts {
	my ( $text, $char ) = @_;
	my @lines = grep { $_ ne '' } split /\r?\n/, $text;
	my $count = 0;
	for my $line ( @lines[ 0 .. ( $#lines > 4 ? 4 : $#lines ) ] ) {
		my $c = () = $line =~ /\Q$char\E/g;
		$count += $c;
	}
	return $count;
}

sub _sniff_text {
	my ( $text, $config ) = @_;

	my @candidates = @{ _array_from_value( $config->{sniff_candidates} ) };
	@candidates = ( ',', "\t", ';', '|' ) if !@candidates;
	my $best = $candidates[0];
	my $best_score = -1;
	for my $char ( @candidates ) {
		my $score = _sniff_counts( $text, $char );
		if ( $score > $best_score ) {
			$best_score = $score;
			$best = $char;
		}
	}

	my @lines = grep { $_ !~ /\A\s*\z/ } split /\r?\n/, $text;
	my $first = $lines[0] // '';
	my $headers = 0;
	if ( $first ne '' ) {
		my @parts = split /\Q$best\E/, $first;
		$headers = 1 if @parts && !grep { /\A-?(?:\d+(?:\.\d+)?)\z/ } @parts;
	}

	return {
		sep_char => $best,
		headers => $headers ? 1 : 0,
		quote_char => '"',
	};
}

sub _conflict_clause {
	my ( $config ) = @_;

	my $policy = exists $config->{conflict}
		? lc( "$config->{conflict}" )
		: '';
	return '' if $policy eq '';
	return '' if $policy eq 'default';
	return "or " . uc($policy);
}

sub _mapped_columns {
	my ( $columns, $map ) = @_;

	return $columns if ref($map) ne 'HASH';
	my @out = map {
		exists $map->{$_} ? $map->{$_} : $_
	} @{ $columns // [] };
	return \@out;
}

sub _transaction_begin {
	my ( $dbh, $enabled ) = @_;
	return if !$enabled;
	_dbi_call(
		sub {
			$dbh->begin_work;
			return 1;
		},
		'CSV transaction begin failed',
	);
}

sub _transaction_commit {
	my ( $dbh, $enabled ) = @_;
	return if !$enabled;
	_dbi_call(
		sub {
			$dbh->commit;
			return 1;
		},
		'CSV transaction commit failed',
	);
}

sub _transaction_rollback {
	my ( $dbh, $enabled ) = @_;
	return if !$enabled;
	eval { $dbh->rollback; 1 };
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $csv_class = native_class( name => 'CSV' );
	my $reader_class = native_class( name => 'CSVReader' );
	my $writer_class = native_class( name => 'CSVWriter' );

	$csv_class->native_constructor( sub {
		my ( $rt, $klass, $positional, $named ) = @_;
		my $config = _normalize_config( $positional, $named );

		return native_object(
			class => $klass,
			slots => {
				_config => $config,
			},
			const => {
				_config => 1,
			},
		);
	} );

	$csv_class->methods->{sniff} = native_function(
		name => 'sniff',
		native => sub {
			my ( $self, $source ) = @_;
			my $config = _normalize_runtime_config( $self->slots->{_config} // {} );
			my $text;
			if (
				blessed($source)
				and $source->isa('Zuzu::Value::Object')
				and exists $source->slots->{_path_tiny}
			) {
				$runtime->assert_capability( 'fs', "CSV.sniff is denied by runtime policy" );
				$text = _text_from_bytes(
					$source->slots->{_path_tiny}->slurp_raw,
					$config,
				);
			}
			else {
				$text = defined $source ? "$source" : '';
			}
			return perl_to_zuzu( _sniff_text( $text, $config ) );
		},
	);

	$csv_class->methods->{sniff_binarystring} = native_function(
		name => 'sniff_binarystring',
		native => sub {
			my ( $self, $source ) = @_;
			my $config = _normalize_runtime_config( $self->slots->{_config} // {} );
			$source = _assert_binary_string( $source, 'CSV.sniff_binarystring' );
			return perl_to_zuzu(
				_sniff_text( _text_from_bytes( $source->bytes, $config ), $config )
			);
		},
	);

	$csv_class->methods->{transpose} = native_function(
		name => 'transpose',
		native => sub {
			my ( $self, $rows ) = @_;
			my $perl_rows = zuzu_to_perl( $rows );
			$perl_rows = [] if ref($perl_rows) ne 'ARRAY';
			my $max = 0;
			for my $row ( @{$perl_rows} ) {
				my $len = ref($row) eq 'ARRAY' ? scalar @{$row} : 1;
				$max = $len if $len > $max;
			}
			my @out;
			for my $i ( 0 .. ( $max ? $max - 1 : -1 ) ) {
				my @next;
				for my $row ( @{$perl_rows} ) {
					if ( ref($row) eq 'ARRAY' ) {
						push @next, $row->[$i];
					}
					else {
						push @next, ( $i == 0 ? $row : undef );
					}
				}
				push @out, \@next;
			}
			return perl_to_zuzu( \@out );
		},
	);

	$csv_class->methods->{decode} = native_function(
		name => 'decode',
		native => sub {
			my ( $self, $text ) = @_;
			my $config = _normalize_runtime_config( _config_merge( $self->slots->{_config} ) );
			my $csv = _new_csv_backend( $config );
			my $fh = _string_input_handle( $text );
			my $headers = _columns_from_config($config);

			if ( !defined $headers and zuzu_bool( $config->{headers}, 0 ) ) {
				my $header_row = $csv->getline($fh);
				_die_csv_error( $csv, 'CSV header read failed', { line_number => 1 } )
					if !$header_row and !$csv->eof;
				$headers = _normalize_headers( $header_row, $config );
			}
			_required_columns_check( $headers, $config ) if ref($headers) eq 'ARRAY';

			my $reader = _new_reader_object(
				$reader_class,
				$csv,
				$fh,
				$headers,
				ref($headers) eq 'ARRAY' ? 'dict' : 'array',
				$config,
			);

			my @rows;
			while (1) {
				my $row;
				my $ok = eval {
					$row = _reader_default_mode($reader) eq 'dict'
						? _reader_fetch_dict( $runtime, $reader )
						: _reader_fetch_array( $runtime, $reader );
					1;
				};
				if ( !$ok ) {
					my $err = $@;
					$err = "$err";
					chomp $err;
					push @{ $reader->slots->{_errors} }, {
						message => $err,
						line_number => $reader->slots->{_line_number},
						row_number => $reader->slots->{_row_number},
						raw_line => $reader->slots->{_last_raw_line},
					};
					last;
				}
				last if !defined $row;
				push @rows, $row;
			}
			close $fh;
			return perl_to_zuzu( \@rows );
		},
	);

	$csv_class->methods->{decode_binarystring} = native_function(
		name => 'decode_binarystring',
		native => sub {
			my ( $self, $raw ) = @_;
			my $config = _normalize_runtime_config(
				_config_merge( $self->slots->{_config} )
			);
			$raw = _assert_binary_string( $raw, 'CSV.decode_binarystring' );
			my $text = _text_from_bytes( $raw->bytes, $config );
			return $csv_class->methods->{decode}->{_native}->( $self, $text );
		},
	);

	$csv_class->methods->{decode_report} = native_function(
		name => 'decode_report',
		native => sub {
			my ( $self, $text ) = @_;
			my $config = _normalize_runtime_config(
				_config_merge( $self->slots->{_config}, { on_error => 'collect' } )
			);
			my $csv = _new_csv_backend( $config );
			my $fh = _string_input_handle( $text );
			my $headers = _columns_from_config($config);

			if ( !defined $headers and zuzu_bool( $config->{headers}, 0 ) ) {
				my $header_row = $csv->getline($fh);
				if ( !$header_row and !$csv->eof ) {
					my $detail = _csv_error_detail( $csv, 'CSV header read failed', { line_number => 1 } );
					close $fh;
					return perl_to_zuzu( { rows => [], errors => [ $detail ] } );
				}
				$headers = _normalize_headers( $header_row, $config );
			}

			my $reader = _new_reader_object(
				$reader_class,
				$csv,
				$fh,
				$headers,
				ref($headers) eq 'ARRAY' ? 'dict' : 'array',
				$config,
			);

			my @rows;
			while (1) {
				my $row;
				my $ok = eval {
					$row = _reader_default_mode($reader) eq 'dict'
						? _reader_fetch_dict( $runtime, $reader )
						: _reader_fetch_array( $runtime, $reader );
					1;
				};
				if ( !$ok ) {
					my $err = $@;
					$err = "$err";
					chomp $err;
					push @{ $reader->slots->{_errors} }, {
						message => $err,
						line_number => $reader->slots->{_line_number},
						row_number => $reader->slots->{_row_number},
						raw_line => $reader->slots->{_last_raw_line},
					};
					last;
				}
				last if !defined $row;
				push @rows, $row;
			}
			close $fh;
			return perl_to_zuzu(
				{
					rows => \@rows,
					errors => $reader->slots->{_errors},
				}
			);
		},
	);

	$csv_class->methods->{decode_report_binarystring} = native_function(
		name => 'decode_report_binarystring',
		native => sub {
			my ( $self, $raw ) = @_;
			my $config = _normalize_runtime_config(
				_config_merge( $self->slots->{_config}, { on_error => 'collect' } )
			);
			$raw = _assert_binary_string(
				$raw,
				'CSV.decode_report_binarystring',
			);
			my $text = _text_from_bytes( $raw->bytes, $config );
			my $temp = native_object(
				class => $self->class,
				slots => { _config => $config },
				const => { _config => 1 },
			);
			return $csv_class->methods->{decode_report}->{_native}->(
				$temp,
				$text,
			);
		},
	);

	$csv_class->methods->{encode} = native_function(
		name => 'encode',
		native => sub {
			my ( $self, $rows ) = @_;
			my $config = _normalize_runtime_config( _config_merge( $self->slots->{_config} ) );
			my $perl_rows = zuzu_to_perl( $rows );
			$perl_rows = [] if ref($perl_rows) ne 'ARRAY';
			my $csv = _new_csv_backend( $config );
			my ( $fh, $out_ref ) = _string_output_handle();
			_write_rows( $runtime, $csv, $fh, $perl_rows, $config );
			close $fh;
			return $$out_ref;
		},
	);

	$csv_class->methods->{encode_binarystring} = native_function(
		name => 'encode_binarystring',
		native => sub {
			my ( $self, @args ) = @_;
			my $config = _normalize_runtime_config(
				_config_merge( $self->slots->{_config} )
			);
			my $text = $csv_class->methods->{encode}->{_native}->(
				$self,
				@args,
			);
			return Zuzu::Value::BinaryString->new(
				bytes => _bytes_from_text( $text, $config ),
			);
		},
	);

	$csv_class->methods->{encode_row} = native_function(
		name => 'encode_row',
		native => sub {
			my ( $self, $row ) = @_;
			my $config = _normalize_runtime_config(
				_config_merge( $self->slots->{_config}, { headers => 0 } )
			);
			my $csv = _new_csv_backend( $config );
			my ( $fh, $out_ref ) = _string_output_handle();
			my $array = _map_output_row(
				$runtime,
				zuzu_to_perl($row),
				_columns_from_config($config),
				$config,
			);
			$csv->print( $fh, $array )
				or _die_csv_error( $csv, 'CSV encode_row failed', {} );
			close $fh;
			return $$out_ref;
		},
	);

	$csv_class->methods->{encode_row_binarystring} = native_function(
		name => 'encode_row_binarystring',
		native => sub {
			my ( $self, @args ) = @_;
			my $config = _normalize_runtime_config(
				_config_merge( $self->slots->{_config}, { headers => 0 } )
			);
			my $text = $csv_class->methods->{encode_row}->{_native}->(
				$self,
				@args,
			);
			return Zuzu::Value::BinaryString->new(
				bytes => _bytes_from_text( $text, $config ),
			);
		},
	);

	$csv_class->methods->{load} = native_function(
		name => 'load',
		native => sub {
			my ( $self, $path_obj ) = @_;
			$runtime->assert_capability( 'fs', "CSV.load is denied by runtime policy" );
			my $path_tiny = _path_tiny_from_object( $path_obj, 'CSV.load' );
			my $source = Zuzu::Value::BinaryString->new(
				bytes => $path_tiny->slurp_raw,
			);
			return $csv_class->methods->{decode_binarystring}->{_native}->(
				$self,
				$source,
			);
		},
	);

	$csv_class->methods->{load_report} = native_function(
		name => 'load_report',
		native => sub {
			my ( $self, $path_obj ) = @_;
			$runtime->assert_capability( 'fs', "CSV.load_report is denied by runtime policy" );
			my $path_tiny = _path_tiny_from_object( $path_obj, 'CSV.load_report' );
			my $config = _normalize_runtime_config(
				_config_merge( $self->slots->{_config}, { on_error => 'collect' } )
			);
			my $source = Zuzu::Value::BinaryString->new(
				bytes => $path_tiny->slurp_raw,
			);
			my $temp = native_object(
				class => $self->class,
				slots => { _config => $config },
				const => { _config => 1 },
			);
			return $csv_class->methods->{decode_report_binarystring}->{_native}->(
				$temp,
				$source,
			);
		},
	);

	$csv_class->methods->{dump} = native_function(
		name => 'dump',
		native => sub {
			my ( $self, $path_obj, $rows ) = @_;
			$runtime->assert_capability( 'fs', "CSV.dump is denied by runtime policy" );
			my $path_tiny = _path_tiny_from_object( $path_obj, 'CSV.dump' );
			my $config = _normalize_runtime_config( _config_merge( $self->slots->{_config} ) );
			my $perl_rows = zuzu_to_perl( $rows );
			$perl_rows = [] if ref($perl_rows) ne 'ARRAY';
			my $csv = _new_csv_backend( $config );
			my $fh = _open_output_handle( $path_tiny, $config );
			_write_rows( $runtime, $csv, $fh, $perl_rows, $config );
			close $fh;
			return $path_obj;
		},
	);

	$csv_class->methods->{open} = native_function(
		name => 'open',
		native => sub {
			my ( $self, $path_obj ) = @_;
			$runtime->assert_capability( 'fs', "CSV.open is denied by runtime policy" );
			my $path_tiny = _path_tiny_from_object( $path_obj, 'CSV.open' );
			my $config = _normalize_runtime_config( _config_merge( $self->slots->{_config} ) );
			my $csv = _new_csv_backend( $config );
			my $fh = _open_input_handle( $path_tiny, $config );

			my $skip = int( $config->{skip_lines} // 0 );
			while ( $skip > 0 ) {
				<$fh>;
				$skip--;
			}

			my $headers = _columns_from_config($config);
			if ( !defined $headers and zuzu_bool( $config->{headers}, 0 ) ) {
				my $header_row = $csv->getline($fh);
				_die_csv_error( $csv, 'CSV header read failed', { line_number => 1 } )
					if !$header_row and !$csv->eof;
				$headers = _normalize_headers( $header_row, $config );
			}
			_required_columns_check( $headers, $config ) if ref($headers) eq 'ARRAY';

			return _new_reader_object(
				$reader_class,
				$csv,
				$fh,
				$headers,
				ref($headers) eq 'ARRAY' ? 'dict' : 'array',
				$config,
			);
		},
	);

	$csv_class->methods->{open_writer} = native_function(
		name => 'open_writer',
		native => sub {
			my ( $self, $path_obj, $options ) = @_;
			$runtime->assert_capability( 'fs', "CSV.open_writer is denied by runtime policy" );
			my $path_tiny = _path_tiny_from_object( $path_obj, 'CSV.open_writer' );
			my $config = _normalize_runtime_config(
				_config_merge( $self->slots->{_config}, _options_hash($options) )
			);
			my $csv = _new_csv_backend( $config );
			my $fh = _open_output_handle( $path_tiny, $config );
			return _new_writer_object( $writer_class, $csv, $fh, $config );
		},
	);

	$csv_class->methods->{dump_table} = native_function(
		name => 'dump_table',
		native => sub {
			my ( $self, $path_obj, $dbh_obj, $table_name, $options ) = @_;
			$runtime->assert_capability( 'fs', "CSV.dump_table is denied by runtime policy" );
			$runtime->assert_capability( 'db', "CSV.dump_table is denied by runtime policy" );
			my $path_tiny = _path_tiny_from_object( $path_obj, 'CSV.dump_table' );
			my $dbh = _dbh_from_object( $dbh_obj, 'CSV.dump_table' );
			my $config = _normalize_runtime_config(
				_config_merge( $self->slots->{_config}, { headers => 1 }, _options_hash($options) )
			);
			my $query = exists $config->{query}
				? $config->{query}
				: 'select * from ' . _quote_identifier( $table_name );
			my $bind = _array_from_value( $config->{bind} );

			my $csv = _new_csv_backend( $config );
			my $fh = _open_output_handle( $path_tiny, $config );
			my $sth = _dbi_call(
				sub { $dbh->prepare( $query ) },
				'dump_table prepare failed',
			);
			_dbi_call(
				sub { $sth->execute( @{$bind} ); return 1; },
				'dump_table execute failed',
			);

			my $raw_columns = [ @{ $sth->{NAME} // [] } ];
			my $map = _hash_from_value( $config->{column_map} );
			my @out_columns = map {
				my $db_name = $_;
				my @hits = grep { $map->{$_} eq $db_name } CORE::keys %{$map};
				@hits ? $hits[0] : $db_name;
			} @{$raw_columns};
			$csv->print( $fh, \@out_columns )
				or _die_csv_error( $csv, 'CSV table header write failed', {} )
				if zuzu_bool( $config->{headers}, 1 );

			while ( my $row = $sth->fetchrow_hashref ) {
				my %mapped;
				for my $key ( CORE::keys %{$row} ) {
					my @hits = grep { $map->{$_} eq $key } CORE::keys %{$map};
					$mapped{ @hits ? $hits[0] : $key } = $row->{$key};
				}
				my $array = _map_output_row(
					$runtime,
					\%mapped,
					\@out_columns,
					$config,
				);
				$csv->print( $fh, $array )
					or _die_csv_error( $csv, 'CSV table row write failed', {} );
			}

			close $fh;
			return $path_obj;
		},
	);

	$csv_class->methods->{dump_query} = native_function(
		name => 'dump_query',
		native => sub {
			my ( $self, $path_obj, $dbh_obj, $sql, $bind, $options ) = @_;
			my $opt = _options_hash($options);
			$opt->{query} = defined $sql ? "$sql" : '';
			$opt->{bind} = _array_from_value($bind);
			return $csv_class->methods->{dump_table}->{_native}->(
				$self,
				$path_obj,
				$dbh_obj,
				'',
				$opt,
			);
		},
	);

	$csv_class->methods->{load_table} = native_function(
		name => 'load_table',
		native => sub {
			my ( $self, $path_obj, $dbh_obj, $table_name, $options ) = @_;
			$runtime->assert_capability( 'fs', "CSV.load_table is denied by runtime policy" );
			$runtime->assert_capability( 'db', "CSV.load_table is denied by runtime policy" );
			my $path_tiny = _path_tiny_from_object( $path_obj, 'CSV.load_table' );
			my $dbh = _dbh_from_object( $dbh_obj, 'CSV.load_table' );
			my $config = _normalize_runtime_config(
				_config_merge( $self->slots->{_config}, _options_hash($options) )
			);

			my $reader = $csv_class->methods->{open}->{_native}->(
				$self,
				$path_obj,
			);
			$reader->slots->{_config} = $config;

			my $headers = $reader->slots->{_headers};
			my $csv_columns = ref($headers) eq 'ARRAY' && @{$headers}
				? $headers
				: _columns_from_config($config);
			$csv_columns //= _table_column_names( $dbh, $table_name )
				if !zuzu_bool( $config->{create_table}, 0 );

			my $first;
			if ( !defined $csv_columns ) {
				$first = _reader_fetch_array( $runtime, $reader );
				$csv_columns = _default_columns_for_row($first) if defined $first;
			}

			die Zuzu::Error->new_runtime(
				message => 'CSV.load_table could not determine target columns',
				file => '<std/data/csv>',
				line => 0,
			) if !defined $csv_columns or !@{$csv_columns};

			my $column_map = _hash_from_value( $config->{column_map} );
			my $db_columns = _mapped_columns( $csv_columns, $column_map );

			_create_table_if_needed( $dbh, $table_name, $db_columns, $config );

			my $placeholders = join ', ', ('?') x scalar @{$db_columns};
			my $conflict = _conflict_clause($config);
			my $insert_sql = 'insert ';
			$insert_sql .= $conflict . ' ' if $conflict ne '';
			$insert_sql .= 'into '
				. _quote_identifier($table_name)
				. ' ('
				. join( ', ', map { _quote_identifier($_) } @{$db_columns} )
				. ') values ('
				. $placeholders
				. ')';

			my $sth = _dbi_call(
				sub { $dbh->prepare( $insert_sql ) },
				'load_table prepare failed',
			);

			my $transaction = exists $config->{transaction}
				? zuzu_bool( $config->{transaction}, 1 )
				: 1;
			my $batch_size = int( $config->{batch_size} // 0 );
			my $commit_interval = int( $config->{commit_interval} // 0 );
			my $inserted = 0;
			my $pending = 0;

			eval {
				_transaction_begin( $dbh, $transaction );

				if ( defined $first ) {
					_dbi_call(
						sub { $sth->execute( @{$first} ); return 1; },
						'load_table insert failed',
					);
					$inserted++;
					$pending++;
				}

				while (1) {
					my $row = ref($reader->slots->{_headers}) eq 'ARRAY'
						? _reader_fetch_dict( $runtime, $reader )
						: _reader_fetch_array( $runtime, $reader );
					last if !defined $row;

					my $array = ref($row) eq 'HASH'
						? [ map { $row->{$_} } @{$csv_columns} ]
						: $row;
					_dbi_call(
						sub { $sth->execute( @{$array} ); return 1; },
						'load_table insert failed',
					);
					$inserted++;
					$pending++;

					if (
						$transaction
						and (
							( $batch_size > 0 and $pending >= $batch_size ) or
							( $commit_interval > 0 and $pending >= $commit_interval )
						)
					) {
						_transaction_commit( $dbh, 1 );
						_transaction_begin( $dbh, 1 );
						$pending = 0;
					}
				}

				_transaction_commit( $dbh, $transaction );
				1;
			} or do {
				my $err = $@;
				_transaction_rollback( $dbh, $transaction );
				die $err;
			};

			close $reader->slots->{_fh} if !$reader->slots->{_closed};
			$reader->slots->{_closed} = 1;
			return $inserted;
		},
	);

	$reader_class->methods->{next} = native_function(
		name => 'next',
		native => sub {
			my ( $self ) = @_;
			my $row = _reader_default_mode($self) eq 'dict'
				? _reader_fetch_dict( $runtime, $self )
				: _reader_fetch_array( $runtime, $self );
			return undef if !defined $row;
			return perl_to_zuzu( $row );
		},
	);

	$reader_class->methods->{next_array} = native_function(
		name => 'next_array',
		native => sub {
			my ( $self ) = @_;
			my $row = _reader_fetch_array( $runtime, $self );
			return undef if !defined $row;
			return perl_to_zuzu( $row );
		},
	);

	$reader_class->methods->{next_dict} = native_function(
		name => 'next_dict',
		native => sub {
			my ( $self ) = @_;
			my $row = _reader_fetch_dict( $runtime, $self );
			return undef if !defined $row;
			return perl_to_zuzu( $row );
		},
	);

	$reader_class->methods->{all_array} = native_function(
		name => 'all_array',
		native => sub {
			my ( $self ) = @_;
			my @rows;
			while ( my $row = _reader_fetch_array( $runtime, $self ) ) {
				push @rows, $row;
			}
			return perl_to_zuzu( \@rows );
		},
	);

	$reader_class->methods->{all_dict} = native_function(
		name => 'all_dict',
		native => sub {
			my ( $self ) = @_;
			my @rows;
			while ( my $row = _reader_fetch_dict( $runtime, $self ) ) {
				push @rows, $row;
			}
			return perl_to_zuzu( \@rows );
		},
	);

	$reader_class->methods->{headers} = native_function(
		name => 'headers',
		native => sub {
			my ( $self ) = @_;
			return perl_to_zuzu( $self->slots->{_headers} // [] );
		},
	);

	$reader_class->methods->{columns} = native_function(
		name => 'columns',
		native => sub {
			my ( $self ) = @_;
			return perl_to_zuzu( $self->slots->{_headers} // [] );
		},
	);

	$reader_class->methods->{set_columns} = native_function(
		name => 'set_columns',
		native => sub {
			my ( $self, $columns ) = @_;
			my $cols = _array_from_value($columns);
			$self->slots->{_headers} = [ map { defined $_ ? "$_" : '' } @{$cols} ];
			$self->slots->{_row_mode} = @{$cols} ? 'dict' : 'array';
			return perl_to_zuzu( $self->slots->{_headers} );
		},
	);

	$reader_class->methods->{row_number} = native_function(
		name => 'row_number',
		native => sub {
			my ( $self ) = @_;
			return 0 + ( $self->slots->{_row_number} // 0 );
		},
	);

	$reader_class->methods->{skip_lines} = native_function(
		name => 'skip_lines',
		native => sub {
			my ( $self, $count ) = @_;
			my $n = int( $count // 0 );
			while ( $n > 0 ) {
				last if !defined scalar readline( $self->slots->{_fh} );
				$self->slots->{_line_number} = ( $self->slots->{_line_number} // 0 ) + 1;
				$n--;
			}
			return $self;
		},
	);

	$reader_class->methods->{errors} = native_function(
		name => 'errors',
		native => sub {
			my ( $self ) = @_;
			return perl_to_zuzu( $self->slots->{_errors} // [] );
		},
	);

	$reader_class->methods->{close} = native_function(
		name => 'close',
		native => sub {
			my ( $self ) = @_;
			if ( !zuzu_bool( $self->slots->{_closed}, 0 ) ) {
				close( $self->slots->{_fh} );
				$self->slots->{_closed} = 1;
			}
			return $self;
		},
	);

	$reader_class->methods->{to_Iterator} = native_function(
		name => 'to_Iterator',
		native => sub {
			my ( $self ) = @_;
			return _reader_to_iterator( $runtime, $self );
		},
	);

	$writer_class->methods->{columns} = native_function(
		name => 'columns',
		native => sub {
			my ( $self ) = @_;
			return perl_to_zuzu( $self->slots->{_columns} // [] );
		},
	);

	$writer_class->methods->{write_header} = native_function(
		name => 'write_header',
		native => sub {
			my ( $self, $columns ) = @_;
			my $cols = _array_from_value($columns);
			$self->slots->{_columns} = [ map { defined $_ ? "$_" : '' } @{$cols} ]
				if @{$cols};
			_writer_maybe_header( $runtime, $self, $self->slots->{_columns} );
			return perl_to_zuzu( $self->slots->{_columns} // [] );
		},
	);

	$writer_class->methods->{write_row} = native_function(
		name => 'write_row',
		native => sub {
			my ( $self, $row ) = @_;
			return _writer_write_row( $runtime, $self, zuzu_to_perl($row) );
		},
	);

	$writer_class->methods->{print_row} = native_function(
		name => 'print_row',
		native => sub {
			my ( $self, $row ) = @_;
			return _writer_write_row( $runtime, $self, zuzu_to_perl($row) );
		},
	);

	$writer_class->methods->{row_number} = native_function(
		name => 'row_number',
		native => sub {
			my ( $self ) = @_;
			return 0 + ( $self->slots->{_row_number} // 0 );
		},
	);

	$writer_class->methods->{close} = native_function(
		name => 'close',
		native => sub {
			my ( $self ) = @_;
			if ( !zuzu_bool( $self->slots->{_closed}, 0 ) ) {
				close( $self->slots->{_fh} );
				$self->slots->{_closed} = 1;
			}
			return $self;
		},
	);

	return {
		CSV => $csv_class,
		CSVReader => $reader_class,
		CSVWriter => $writer_class,
	};
}

1;

=pod

=head1 NAME

Zuzu::Module::CSV - std/data/csv bindings for ZuzuScript.

=head1 DESCRIPTION

Implements the runtime side of C<std/data/csv> using L<Text::CSV_XS>.
The module exposes:

=over

=item * C<CSV>

A configurable codec/IO helper for CSV-like formats.

=item * C<CSVReader>

A streaming reader with iterator support for C<for> loops.

=item * C<CSVWriter>

A streaming writer for large exports.

=back

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::CSV >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
