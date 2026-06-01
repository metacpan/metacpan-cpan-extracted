package Zuzu::Module::DB;

use utf8;

our $VERSION = '0.001003';

use DBI ();
use Scalar::Util qw( blessed );
use Zuzu::Error;
use Zuzu::Value::Boolean;

use Zuzu::Util::NativeHelpers qw(
	native_class
	native_function
	native_object
	perl_to_zuzu
	zuzu_bool
	zuzu_to_perl
);

sub _normalize_path {
	my ( $value ) = @_;

	return '' if not defined $value;

	if (
		blessed($value)
		and $value->isa('Zuzu::Value::Object')
		and exists $value->slots->{_path_tiny}
	) {
		return $value->slots->{_path_tiny}->stringify;
	}

	return "$value";
}

sub _connection_options {
	my ( $settings ) = @_;

	my $opts = {};
	if ( defined $settings ) {
		$opts = zuzu_to_perl( $settings );
		$opts = {} if ref($opts) ne 'HASH';
	}

	my $dbi_opts = {
		RaiseError => exists $opts->{raise_error}
			? zuzu_bool( $opts->{raise_error}, 1 )
			: 1,
		PrintError => exists $opts->{print_error}
			? zuzu_bool( $opts->{print_error}, 0 )
			: 0,
		AutoCommit => exists $opts->{auto_commit}
			? zuzu_bool( $opts->{auto_commit}, 1 )
			: 1,
	};

	if ( exists $opts->{sqlite_unicode} ) {
		$dbi_opts->{sqlite_unicode}
			= zuzu_bool( $opts->{sqlite_unicode}, 1 );
	}

	return {
		dbi => $dbi_opts,
		isolation_level => exists $opts->{isolation_level}
			? lc( "$opts->{isolation_level}" )
			: undef,
	};
}

sub _connect {
	my ( $dsn, $settings ) = @_;
	my $connect_options = _connection_options( $settings );

	return _dbi_call(
		sub {
			return DBI->connect(
				$dsn,
				undef,
				undef,
				$connect_options->{dbi},
			);
		},
		"connect failed for DSN '$dsn'",
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
			file => '<std/db>',
			line => 0,
		);
	};

	return $result;
}

sub _new_dbh_object {
	my ( $dbh_class, $dbh, $settings ) = @_;

	return native_object(
		class => $dbh_class,
		slots => {
			_dbh => $dbh,
			_isolation_level => $settings->{isolation_level},
		},
		const => {
			_dbh => 1,
		},
	);
}

sub _new_sth_object {
	my ( $sth_class, $sth ) = @_;

	return native_object(
		class => $sth_class,
		slots => {
			_sth => $sth,
		},
		const => {
			_sth => 1,
		},
	);
}

sub _columns_metadata {
	my ( $sth ) = @_;
	my $names = eval { $sth->{NAME} } // [];
	my $types = eval { $sth->{TYPE} } // [];

	my @columns;
	for my $index ( 0 .. $#{ $names } ) {
		push @columns, {
			name => $names->[$index],
			type_code => $types->[$index],
			type_name => undef,
		};
	}

	return \@columns;
}

sub _coerce_value {
	my ( $value, $meta ) = @_;

	return undef if not defined $value;
	return $value if ref $value;

	my $type_name = lc( $meta->{type_name} // '' );
	my $type_code = defined $meta->{type_code}
		? 0 + $meta->{type_code}
		: undef;

	if ( $type_name =~ /\b(bool|boolean)\b/ ) {
		return Zuzu::Value::Boolean->new(
			value => $value ? 1 : 0
		);
	}

	if (
		$type_name =~ /\b(int|integer|real|float|double|decimal|numeric)\b/
		or (
			defined $type_code
			and (
				$type_code == DBI::SQL_INTEGER()
				or $type_code == DBI::SQL_SMALLINT()
				or $type_code == DBI::SQL_TINYINT()
				or $type_code == DBI::SQL_BIGINT()
				or $type_code == DBI::SQL_DECIMAL()
				or $type_code == DBI::SQL_NUMERIC()
				or $type_code == DBI::SQL_REAL()
				or $type_code == DBI::SQL_FLOAT()
				or $type_code == DBI::SQL_DOUBLE()
			)
		)
	) {
		if ( "$value" =~ /\A-?\d+\z/ ) {
			return int( $value );
		}
		if ( "$value" =~ /\A-?(?:\d+\.\d*|\d*\.\d+)(?:[eE]-?\d+)?\z/ ) {
			return 0.0 + $value;
		}
	}

	return $value;
}

sub _coerce_row_array {
	my ( $row, $columns ) = @_;
	my @out;
	for my $index ( 0 .. $#{ $row } ) {
		push @out, _coerce_value( $row->[$index], $columns->[$index] // {} );
	}
	return \@out;
}

sub _coerce_row_dict {
	my ( $row, $columns ) = @_;
	my %column_by_name = map { $_->{name} => $_ } @{ $columns };
	my %out;
	for my $name ( CORE::keys %{ $row } ) {
		$out{$name} = _coerce_value( $row->{$name}, $column_by_name{$name} // {} );
	}
	return \%out;
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $db_class = native_class(
		name => 'DB',
	);
	my $dbh_class = native_class(
		name => 'DatabaseHandle',
	);
	my $sth_class = native_class(
		name => 'StatementHandle',
	);

	$db_class->static_methods->{connect} = native_function(
		name => 'connect',
		native => sub {
			my ( $self, $dsn, $settings ) = @_;
			my $connect_settings = _connection_options( $settings );
			my $dbh = _connect( defined $dsn ? "$dsn" : '', $settings );
			return _new_dbh_object( $dbh_class, $dbh, $connect_settings );
		},
	);

	$db_class->static_methods->{temp} = native_function(
		name => 'temp',
		native => sub {
			my ( $self, $settings ) = @_;
			my $connect_settings = _connection_options( $settings );
			my $dbh = _connect( 'dbi:SQLite:dbname=:memory:', $settings );
			return _new_dbh_object( $dbh_class, $dbh, $connect_settings );
		},
	);

	$db_class->static_methods->{open} = native_function(
		name => 'open',
		native => sub {
			my ( $self, $path, $settings ) = @_;
			$runtime->assert_capability( 'fs', "DB.open is denied by runtime policy" );
			my $string_path = _normalize_path( $path );
			my $dsn = "dbi:SQLite:dbname=$string_path";
			my $connect_settings = _connection_options( $settings );
			my $dbh = _connect( $dsn, $settings );
			return _new_dbh_object( $dbh_class, $dbh, $connect_settings );
		},
	);

	$dbh_class->methods->{prepare} = native_function(
		name => 'prepare',
		native => sub {
			my ( $self, $sql ) = @_;
			my $stmt = defined $sql ? "$sql" : '';
			my $sth = _dbi_call(
				sub {
					return $self->slots->{_dbh}->prepare( $stmt );
				},
				'prepare failed',
			);
			return _new_sth_object( $sth_class, $sth );
		},
	);

	$dbh_class->methods->{quote} = native_function(
		name => 'quote',
		native => sub {
			my ( $self, $value ) = @_;
			return _dbi_call(
				sub {
					return $self->slots->{_dbh}->quote( defined $value ? "$value" : undef );
				},
				'quote failed',
			);
		},
	);

	$dbh_class->methods->{begin} = native_function(
		name => 'begin',
		native => sub {
			my ( $self ) = @_;
			my $mode = $self->slots->{_isolation_level} // '';
			if ( $mode =~ /\A(?:immediate|exclusive|deferred)\z/ ) {
				_dbi_call(
					sub {
						$self->slots->{_dbh}->do(
							"begin $mode transaction"
						);
						return 1;
					},
					'begin failed',
				);
			}
			else {
				_dbi_call(
					sub {
						$self->slots->{_dbh}->begin_work;
						return 1;
					},
					'begin failed',
				);
			}
			return $self;
		},
	);

	$dbh_class->methods->{commit} = native_function(
		name => 'commit',
		native => sub {
			my ( $self ) = @_;
			_dbi_call(
				sub {
					$self->slots->{_dbh}->commit;
					return 1;
				},
				'commit failed',
			);
			return $self;
		},
	);

	$dbh_class->methods->{rollback} = native_function(
		name => 'rollback',
		native => sub {
			my ( $self ) = @_;
			_dbi_call(
				sub {
					$self->slots->{_dbh}->rollback;
					return 1;
				},
				'rollback failed',
			);
			return $self;
		},
	);

	$dbh_class->methods->{execute_batch} = native_function(
		name => 'execute_batch',
		native => sub {
			my ( $self, $sql, $rows ) = @_;
			my $stmt = defined $sql ? "$sql" : '';
			my $bind_rows = zuzu_to_perl( $rows );
			$bind_rows = [] if ref($bind_rows) ne 'ARRAY';
			_dbi_call(
				sub {
					my $sth = $self->slots->{_dbh}->prepare( $stmt );
					for my $bind ( @{ $bind_rows } ) {
						my @args = ref($bind) eq 'ARRAY'
							? @{ $bind }
							: ( $bind );
						$sth->execute( @args );
					}
					return 1;
				},
				'execute_batch failed',
			);
			return $self;
		},
	);

	$sth_class->methods->{execute} = native_function(
		name => 'execute',
		native => sub {
			my ( $self, @bind ) = @_;
			_dbi_call(
				sub {
					$self->slots->{_sth}->execute( @bind );
					return 1;
				},
				'execute failed',
			);
			return $self;
		},
	);

	$sth_class->methods->{next_array} = native_function(
		name => 'next_array',
		native => sub {
			my ( $self ) = @_;
			my $row = _dbi_call(
				sub {
					return $self->slots->{_sth}->fetchrow_arrayref;
				},
				'fetch row failed',
			);
			return undef if not defined $row;
			return perl_to_zuzu( [ @{ $row } ] );
		},
	);

	$sth_class->methods->{next_dict} = native_function(
		name => 'next_dict',
		native => sub {
			my ( $self ) = @_;
			my $row = _dbi_call(
				sub {
					return $self->slots->{_sth}->fetchrow_hashref;
				},
				'fetch row failed',
			);
			return undef if not defined $row;
			return perl_to_zuzu( { %{ $row } } );
		},
	);

	$sth_class->methods->{all_array} = native_function(
		name => 'all_array',
		native => sub {
			my ( $self ) = @_;
			my $rows = _dbi_call(
				sub {
					return $self->slots->{_sth}->fetchall_arrayref( [] );
				},
				'fetch all rows failed',
			);
			return perl_to_zuzu( $rows );
		},
	);

	$sth_class->methods->{all_dict} = native_function(
		name => 'all_dict',
		native => sub {
			my ( $self ) = @_;
			my $rows = _dbi_call(
				sub {
					return $self->slots->{_sth}->fetchall_arrayref( {} );
				},
				'fetch all rows failed',
			);
			return perl_to_zuzu( $rows );
		},
	);

	$sth_class->methods->{execute_batch} = native_function(
		name => 'execute_batch',
		native => sub {
			my ( $self, $rows ) = @_;
			my $bind_rows = zuzu_to_perl( $rows );
			$bind_rows = [] if ref($bind_rows) ne 'ARRAY';
			_dbi_call(
				sub {
					for my $bind ( @{ $bind_rows } ) {
						my @args = ref($bind) eq 'ARRAY'
							? @{ $bind }
							: ( $bind );
						$self->slots->{_sth}->execute( @args );
					}
					return 1;
				},
				'execute_batch failed',
			);
			return $self;
		},
	);

	$sth_class->methods->{column_names} = native_function(
		name => 'column_names',
		native => sub {
			my ( $self ) = @_;
			my $meta = _columns_metadata( $self->slots->{_sth} );
			return perl_to_zuzu(
				[ map { $_->{name} } @{ $meta } ]
			);
		},
	);

	$sth_class->methods->{column_types} = native_function(
		name => 'column_types',
		native => sub {
			my ( $self ) = @_;
			my $meta = _columns_metadata( $self->slots->{_sth} );
			return perl_to_zuzu(
				[
					map {
						{
							code => $_->{type_code},
							name => $_->{type_name},
						}
					} @{ $meta }
				]
			);
		},
	);

	$sth_class->methods->{next_typed_array} = native_function(
		name => 'next_typed_array',
		native => sub {
			my ( $self ) = @_;
			my $row = _dbi_call(
				sub {
					return $self->slots->{_sth}->fetchrow_arrayref;
				},
				'fetch row failed',
			);
			return undef if not defined $row;
			my $meta = _columns_metadata( $self->slots->{_sth} );
			return perl_to_zuzu( _coerce_row_array( $row, $meta ) );
		},
	);

	$sth_class->methods->{next_typed_dict} = native_function(
		name => 'next_typed_dict',
		native => sub {
			my ( $self ) = @_;
			my $row = _dbi_call(
				sub {
					return $self->slots->{_sth}->fetchrow_hashref;
				},
				'fetch row failed',
			);
			return undef if not defined $row;
			my $meta = _columns_metadata( $self->slots->{_sth} );
			return perl_to_zuzu( _coerce_row_dict( $row, $meta ) );
		},
	);

	$sth_class->methods->{all_typed_array} = native_function(
		name => 'all_typed_array',
		native => sub {
			my ( $self ) = @_;
			my $rows = _dbi_call(
				sub {
					return $self->slots->{_sth}->fetchall_arrayref( [] );
				},
				'fetch all rows failed',
			);
			my $meta = _columns_metadata( $self->slots->{_sth} );
			my @coerced = map {
				_coerce_row_array( $_, $meta )
			} @{ $rows };
			return perl_to_zuzu( \@coerced );
		},
	);

	$sth_class->methods->{all_typed_dict} = native_function(
		name => 'all_typed_dict',
		native => sub {
			my ( $self ) = @_;
			my $rows = _dbi_call(
				sub {
					return $self->slots->{_sth}->fetchall_arrayref( {} );
				},
				'fetch all rows failed',
			);
			my $meta = _columns_metadata( $self->slots->{_sth} );
			my @coerced = map {
				_coerce_row_dict( $_, $meta )
			} @{ $rows };
			return perl_to_zuzu( \@coerced );
		},
	);

	$sth_class->methods->{to_Iterator} = native_function(
		name => 'to_Iterator',
		native => sub {
			my ( $self ) = @_;
			my $sth = $self->slots->{_sth};
			my $meta = _columns_metadata( $sth );
			return native_function(
				name => 'iterator',
				native => sub {
					my $row = _dbi_call(
						sub {
							return $sth->fetchrow_hashref;
						},
						'fetch row failed',
					);
					if ( not defined $row ) {
						my $exhausted = $runtime->_instantiate_builtin_object(
							$runtime->{_builtin_classes}{ExhaustedException},
							{
								message => 'iterator exhausted',
								file => '<std/db>',
								line => 0,
							},
						);
						die {
							_zuzu_throw => 1,
							value => $exhausted,
						};
					}
					return perl_to_zuzu( _coerce_row_dict( $row, $meta ) );
				},
			);
		},
	);

	return {
		DB => $db_class,
		DatabaseHandle => $dbh_class,
		StatementHandle => $sth_class,
	};
}

1;

=pod

=head1 NAME

Zuzu::Module::DB - C<std/db> builtin module bridge.

=head1 DESCRIPTION

This package implements the runtime side of C<std/db>.
It exposes DBI-backed classes to ZuzuScript code:

=over

=item * C<DB>

Static constructor helpers:

=over

=item * C<connect(dsn)>

Creates a database handle from a DBI DSN.

=item * C<temp()>

Creates an in-memory SQLite connection.

=item * C<open(path)>

Opens a SQLite database by file path.
Accepts either a string or a C<std/io> C<Path> object.

=back

=item * C<DatabaseHandle>

Provides C<prepare(sql)>, C<quote(value)>,
C<begin>, C<commit>, C<rollback>, and
C<execute_batch(sql, rows)>.

=item * C<StatementHandle>

Provides C<execute(...)>, C<execute_batch(rows)>,
C<column_names>, C<column_types>, C<next_array>,
C<next_dict>, C<all_array>, C<all_dict>,
C<next_typed_array>, C<next_typed_dict>,
C<all_typed_array>, C<all_typed_dict>, and
C<to_Iterator> (for C<for> loops yielding
typed C<Dict> rows).

=back

All DBI operations are wrapped so DBI failures become
runtime errors, which are catchable as exceptions
from ZuzuScript.

=head1 METHODS

=head2 IMPORT

Returns module exports for the runtime importer.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::DB >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
