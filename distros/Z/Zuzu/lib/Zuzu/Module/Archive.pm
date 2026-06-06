package Zuzu::Module::Archive;

use utf8;

our $VERSION = '0.001005';

use Archive::Tar ();
use Archive::Zip qw( :ERROR_CODES );
use File::Basename qw( basename );
use File::Temp qw( tempfile );
use IO::Compress::Bzip2 qw( bzip2 $Bzip2Error );
use IO::Compress::Gzip qw( gzip $GzipError );
use IO::Uncompress::Bunzip2 qw( bunzip2 $Bunzip2Error );
use IO::Uncompress::Gunzip qw( gunzip $GunzipError );
use Scalar::Util qw( blessed );

use Zuzu::Error;
use Zuzu::Util::NativeHelpers qw(
	native_class
	native_function
	perl_to_zuzu
	zuzu_to_perl
);
use Zuzu::Value::BinaryString;

sub _type_name {
	my ( $value ) = @_;

	return 'Null' if not defined $value;
	return 'BinaryString'
		if blessed($value) and $value->isa('Zuzu::Value::BinaryString');
	return 'Array'
		if blessed($value) and $value->isa('Zuzu::Value::Array');
	return 'Dict'
		if blessed($value) and $value->isa('Zuzu::Value::Dict');
	return 'Object'
		if blessed($value) and $value->isa('Zuzu::Value::Object');
	return 'String';
}

sub _error {
	my ( $message ) = @_;

	die Zuzu::Error->new_runtime(
		message => $message,
		file => '<std/archive>',
		line => 0,
	);
}

sub _assert_binary_string {
	my ( $value, $label ) = @_;

	return $value->bytes
		if blessed($value) and $value->isa('Zuzu::Value::BinaryString');

	my $type = _type_name( $value );
	_error( "TypeException: $label expects BinaryString, got $type" );
}

sub _path_tiny_from_object {
	my ( $path_obj, $method_name ) = @_;

	if (
		blessed($path_obj)
		and $path_obj->isa('Zuzu::Value::Object')
		and exists $path_obj->slots->{_path_tiny}
	) {
		return $path_obj->slots->{_path_tiny};
	}
	if ( ref($path_obj) eq 'HASH' and exists $path_obj->{_path_tiny} ) {
		return $path_obj->{_path_tiny};
	}

	_error( "TypeException: $method_name expects Path as first argument" );
}

sub _normalize_format {
	my ( $raw ) = @_;

	return 'auto' if !defined $raw or $raw eq '';
	my $format = lc "$raw";
	$format =~ s/\A\.//;

	my %map = (
		auto => 'auto',
		zip => 'zip',
		tar => 'tar',
		'tar.gz' => 'tar.gz',
		tgz => 'tar.gz',
		'gzip+tar' => 'tar.gz',
		'tar.bz2' => 'tar.bz2',
		tbz => 'tar.bz2',
		tbz2 => 'tar.bz2',
		'bzip2+tar' => 'tar.bz2',
		gz => 'gz',
		gzip => 'gz',
		bz2 => 'bz2',
		bzip2 => 'bz2',
	);

	return $map{$format} if exists $map{$format};
	_error( "Unsupported archive format '$raw'" );
}

sub _format_from_name {
	my ( $name ) = @_;

	return undef if !defined $name or $name eq '';
	my $lower = lc "$name";

	return 'tar.gz' if $lower =~ /\.tar\.gz\z/;
	return 'tar.gz' if $lower =~ /\.tgz\z/;
	return 'tar.bz2' if $lower =~ /\.tar\.bz2\z/;
	return 'tar.bz2' if $lower =~ /\.tbz2?\z/;
	return 'zip' if $lower =~ /\.zip\z/;
	return 'tar' if $lower =~ /\.tar\z/;
	return 'gz' if $lower =~ /\.gz\z/;
	return 'bz2' if $lower =~ /\.bz2\z/;

	return undef;
}

sub _looks_like_tar {
	my ( $bytes ) = @_;

	return 0 if !defined $bytes or length($bytes) < 512;
	return 1 if substr( $bytes, 257, 5 ) eq 'ustar';
	return 0;
}

sub _gunzip_bytes {
	my ( $bytes ) = @_;

	my $out = '';
	gunzip( \$bytes => \$out )
		or _error( "Archive decode failed: $GunzipError" );

	return $out;
}

sub _bunzip2_bytes {
	my ( $bytes ) = @_;

	my $out = '';
	bunzip2( \$bytes => \$out )
		or _error( "Archive decode failed: $Bunzip2Error" );

	return $out;
}

sub _detect_format_from_bytes {
	my ( $bytes ) = @_;

	if ( substr( $bytes, 0, 4 ) =~ /\APK[\x03\x05\x07][\x04\x06\x08]/ ) {
		return 'zip';
	}
	if ( substr( $bytes, 0, 2 ) eq "\x1f\x8b" ) {
		my $raw = _gunzip_bytes($bytes);
		return _looks_like_tar( $raw ) ? 'tar.gz' : 'gz';
	}
	if ( substr( $bytes, 0, 3 ) eq 'BZh' ) {
		my $raw = _bunzip2_bytes($bytes);
		return _looks_like_tar( $raw ) ? 'tar.bz2' : 'bz2';
	}
	if ( _looks_like_tar($bytes) ) {
		return 'tar';
	}

	_error( 'Could not detect archive format from bytes' );
}

sub _read_all_bytes {
	my ( $path_tiny ) = @_;

	return $path_tiny->slurp;
}

sub _write_all_bytes {
	my ( $path_tiny, $bytes ) = @_;

	$path_tiny->spew( $bytes );
	return;
}

sub _archive_to_zuzu {
	my ( $format, $entries ) = @_;

	return perl_to_zuzu(
		{
			format => $format,
			entries => $entries,
		},
	);
}

sub _entry_data_bytes {
	my ( $entry, $label ) = @_;

	if ( exists $entry->{data_value} and defined $entry->{data_value} ) {
		return _assert_binary_string(
			$entry->{data_value},
			"$label.data",
		);
	}

	if ( exists $entry->{data_from_path} and defined $entry->{data_from_path} ) {
		my $path_tiny = $entry->{data_from_path};
		return $path_tiny->slurp;
	}

	_error( "TypeException: $label expects BinaryString data or Path data_from" );
}

sub _entries_from_archive_value {
	my ( $archive_value, $label ) = @_;

	my $archive = zuzu_to_perl($archive_value);
	_error( "TypeException: $label expects Dict archive, got " . _type_name( $archive_value ) )
		if ref($archive) ne 'HASH';

	my $entries = $archive->{entries};
	_error( "TypeException: $label expects archive.entries to be an Array" )
		if ref($entries) ne 'ARRAY';

	my @out;
	for my $idx ( 0 .. $#{ $entries } ) {
		my $entry = $entries->[$idx];
		_error( "TypeException: $label expects archive.entries[$idx] to be a Dict" )
			if ref($entry) ne 'HASH';

		my $path = exists $entry->{path}
			? ( defined $entry->{path} ? "$entry->{path}" : undef )
			: undef;
		my %normalized = (
			path => $path,
			label => "$label archive.entries[$idx]",
		);
		if ( exists $entry->{data} and defined $entry->{data} ) {
			$normalized{data_value} = $entry->{data};
		}
		elsif ( exists $entry->{data_from} and defined $entry->{data_from} ) {
			$normalized{data_from_path} = _path_tiny_from_object(
				$entry->{data_from},
				"$label archive.entries[$idx].data_from",
			);
		}
		else {
			_error( "TypeException: $label archive.entries[$idx] expects BinaryString data or Path data_from" );
		}

		push @out, \%normalized;
	}

	return (
		\@out,
		_normalize_format( $archive->{format} ),
	);
}

sub _encode_tar {
	my ( $entries, $format ) = @_;

	my $tar = Archive::Tar->new;
	for my $entry ( @{ $entries } ) {
		_error( 'Archive.encode requires path for tar entries' )
			if !defined $entry->{path} or $entry->{path} eq '';
		$tar->add_data(
			$entry->{path},
			_entry_data_bytes( $entry, $entry->{label} ),
		);
	}

	my ( $fh, $filename ) = tempfile( UNLINK => 0 );
	close $fh;

	my $compress = 0;
	$compress = Archive::Tar::COMPRESS_GZIP() if $format eq 'tar.gz';
	$compress = Archive::Tar::COMPRESS_BZIP() if $format eq 'tar.bz2';
	my $ok = $tar->write( $filename, $compress );
	_error( 'Archive encode failed while writing tar data' ) if !$ok;

	open my $in, '<:raw', $filename
		or _error( "Archive encode failed while reopening '$filename': $!" );
	local $/;
	my $bytes = <$in>;
	close $in;
	unlink $filename;

	return $bytes;
}

sub _decode_tar {
	my ( $bytes, $format ) = @_;

	my ( $fh, $filename ) = tempfile( UNLINK => 0 );
	binmode $fh;
	print {$fh} $bytes;
	close $fh;

	my $compress = 0;
	$compress = Archive::Tar::COMPRESS_GZIP() if $format eq 'tar.gz';
	$compress = Archive::Tar::COMPRESS_BZIP() if $format eq 'tar.bz2';

	my $tar = Archive::Tar->new;
	my $ok = $tar->read( $filename, $compress );
	my $err = $Archive::Tar::error;
	unlink $filename;
	_error( "Archive decode failed: $err" ) if !$ok;

	my @entries;
	for my $member ( $tar->get_files ) {
		next if $member->is_dir;
		next if !$member->is_file;
		push @entries, {
			path => $member->full_path,
			data => Zuzu::Value::BinaryString->new(
				bytes => $member->get_content,
			),
		};
	}

	return \@entries;
}

sub _encode_zip {
	my ( $entries ) = @_;

	my $zip = Archive::Zip->new;
	for my $entry ( @{ $entries } ) {
		_error( 'Archive.encode requires path for zip entries' )
			if !defined $entry->{path} or $entry->{path} eq '';
		$zip->addString(
			_entry_data_bytes( $entry, $entry->{label} ),
			$entry->{path},
		);
	}

	my ( $fh, $filename ) = tempfile(
		SUFFIX => '.zip',
		UNLINK => 0,
	);
	close $fh;

	my $status = $zip->writeToFileNamed($filename);
	_error( 'Archive encode failed while writing zip data' )
		if $status != AZ_OK;

	open my $in, '<:raw', $filename
		or _error( "Archive encode failed while reopening '$filename': $!" );
	local $/;
	my $bytes = <$in>;
	close $in;
	unlink $filename;

	return $bytes;
}

sub _decode_zip {
	my ( $bytes ) = @_;

	my ( $fh, $filename ) = tempfile(
		SUFFIX => '.zip',
		UNLINK => 0,
	);
	binmode $fh;
	print {$fh} $bytes;
	close $fh;

	my $zip = Archive::Zip->new;
	my $status = $zip->read($filename);
	_error( 'Archive decode failed while reading zip data' )
		if $status != AZ_OK;

	my @entries;
	for my $member ( $zip->members ) {
		next if $member->isDirectory;
		push @entries, {
			path => $member->fileName,
			data => Zuzu::Value::BinaryString->new(
				bytes => scalar $member->contents,
			),
		};
	}
	unlink $filename;

	return \@entries;
}

sub _encode_gzip_like {
	my ( $entries, $format ) = @_;

	_error( "Archive.encode with format '$format' expects exactly one entry" )
		if scalar @{ $entries } != 1;

	my $entry = $entries->[0];
	my $bytes = '';
	if ( $format eq 'gz' ) {
		my %opts;
		$opts{Name} = $entry->{path}
			if defined $entry->{path} and $entry->{path} ne '';
		my $input = _entry_data_bytes( $entry, $entry->{label} );
		gzip( \$input => \$bytes, %opts )
			or _error( "Archive encode failed: $GzipError" );
	}
	else {
		my $input = _entry_data_bytes( $entry, $entry->{label} );
		bzip2( \$input => \$bytes )
			or _error( "Archive encode failed: $Bzip2Error" );
	}

	return $bytes;
}

sub _decode_gzip_like {
	my ( $bytes, $format, $default_name ) = @_;

	my $content;
	my $path = $default_name;

	if ( $format eq 'gz' ) {
		my $gunzip = IO::Uncompress::Gunzip->new( \$bytes )
			or _error( "Archive decode failed: $GunzipError" );
		my $out = '';
		while ( my $read = $gunzip->read( my $chunk ) ) {
			$out .= $chunk;
		}
		_error( "Archive decode failed: $GunzipError" )
			if !defined $gunzip or $gunzip->error;
		my $info = $gunzip->getHeaderInfo;
		$path = $info->{Name}
			if defined $info and defined $info->{Name} and $info->{Name} ne '';
		$content = $out;
	}
	else {
		$content = _bunzip2_bytes($bytes);
	}

	return [
		{
			path => $path,
			data => Zuzu::Value::BinaryString->new( bytes => $content ),
		},
	];
}

sub _derive_single_entry_name_from_path {
	my ( $path_tiny, $format ) = @_;

	my $name = basename( $path_tiny->stringify );
	return undef if !defined $name or $name eq '';

	if ( $format eq 'gz' ) {
		$name =~ s/\.(?:gz|gzip)\z//i;
	}
	elsif ( $format eq 'bz2' ) {
		$name =~ s/\.bz2\z//i;
	}

	return $name;
}

sub _resolve_format_for_encode {
	my ( $path_name, $archive_format, $given_format ) = @_;

	my $path_format = _format_from_name($path_name);
	my $format = _normalize_format($given_format);
	$format = $archive_format if $format eq 'auto' and $archive_format ne 'auto';
	$format = $path_format if $format eq 'auto' and defined $path_format;
	_error( 'Archive format is required when it cannot be inferred from path' )
		if $format eq 'auto';

	return $format;
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $archive_class = native_class(
		name => 'Archive',
	);

	$archive_class->static_methods->{decode} = native_function(
		name => 'decode',
		native => sub {
			my ( $class_value, $bytes_value, $format_value ) = @_;
			my $bytes = _assert_binary_string( $bytes_value, 'Archive.decode' );
			my $format = _normalize_format($format_value);
			$format = _detect_format_from_bytes($bytes)
				if $format eq 'auto';

			my $entries;
			if ( $format eq 'zip' ) {
				$entries = _decode_zip($bytes);
			}
			elsif ( $format eq 'tar' or $format eq 'tar.gz' or $format eq 'tar.bz2' ) {
				$entries = _decode_tar( $bytes, $format );
			}
			elsif ( $format eq 'gz' or $format eq 'bz2' ) {
				$entries = _decode_gzip_like( $bytes, $format, undef );
			}
			else {
				_error( "Unsupported archive format '$format'" );
			}

			return _archive_to_zuzu( $format, $entries );
		},
	);

	$archive_class->static_methods->{encode} = native_function(
		name => 'encode',
		native => sub {
			my ( $class_value, $archive_value, $format_value ) = @_;
			my ( $entries, $archive_format ) = _entries_from_archive_value(
				$archive_value,
				'Archive.encode',
			);
			my $format = _normalize_format($format_value);
			$format = $archive_format
				if $format eq 'auto' and $archive_format ne 'auto';
			_error( 'Archive.encode requires an explicit format' )
				if $format eq 'auto';

			my $bytes;
			if ( $format eq 'zip' ) {
				$bytes = _encode_zip($entries);
			}
			elsif ( $format eq 'tar' or $format eq 'tar.gz' or $format eq 'tar.bz2' ) {
				$bytes = _encode_tar( $entries, $format );
			}
			elsif ( $format eq 'gz' or $format eq 'bz2' ) {
				$bytes = _encode_gzip_like( $entries, $format );
			}
			else {
				_error( "Unsupported archive format '$format'" );
			}

			return Zuzu::Value::BinaryString->new( bytes => $bytes );
		},
	);

	$archive_class->static_methods->{load} = native_function(
		name => 'load',
		native => sub {
			my ( $class_value, $path_obj, $format_value ) = @_;
			$runtime->assert_capability(
				'fs',
				'Archive.load is denied by runtime policy',
			);
			my $path_tiny = _path_tiny_from_object( $path_obj, 'Archive.load' );
			my $format = _normalize_format($format_value);
			my $path_name = $path_tiny->stringify;
			$format = _format_from_name($path_name)
				if $format eq 'auto';
			my $bytes = _read_all_bytes($path_tiny);
			$format = _detect_format_from_bytes($bytes)
				if !defined $format or $format eq 'auto';

			my $entries;
			if ( $format eq 'zip' ) {
				$entries = _decode_zip($bytes);
			}
			elsif ( $format eq 'tar' or $format eq 'tar.gz' or $format eq 'tar.bz2' ) {
				$entries = _decode_tar( $bytes, $format );
			}
			elsif ( $format eq 'gz' or $format eq 'bz2' ) {
				my $default_name = _derive_single_entry_name_from_path(
					$path_tiny,
					$format,
				);
				$entries = _decode_gzip_like(
					$bytes,
					$format,
					$default_name,
				);
			}
			else {
				_error( "Unsupported archive format '$format'" );
			}

			return _archive_to_zuzu( $format, $entries );
		},
	);

	$archive_class->static_methods->{dump} = native_function(
		name => 'dump',
		native => sub {
			my ( $class_value, $path_obj, $archive_value, $format_value ) = @_;
			$runtime->assert_capability(
				'fs',
				'Archive.dump is denied by runtime policy',
			);
			my $path_tiny = _path_tiny_from_object( $path_obj, 'Archive.dump' );
			my $path_name = $path_tiny->stringify;
			my ( $entries, $archive_format ) = _entries_from_archive_value(
				$archive_value,
				'Archive.dump',
			);
			my $format = _resolve_format_for_encode(
				$path_name,
				$archive_format,
				$format_value,
			);

			my $bytes;
			if ( $format eq 'zip' ) {
				$bytes = _encode_zip($entries);
			}
			elsif ( $format eq 'tar' or $format eq 'tar.gz' or $format eq 'tar.bz2' ) {
				$bytes = _encode_tar( $entries, $format );
			}
			elsif ( $format eq 'gz' or $format eq 'bz2' ) {
				$bytes = _encode_gzip_like( $entries, $format );
			}
			else {
				_error( "Unsupported archive format '$format'" );
			}

			_write_all_bytes( $path_tiny, $bytes );
			return $path_obj;
		},
	);

	return {
		Archive => $archive_class,
	};
}

1;

=pod

=head1 NAME

Zuzu::Module::Archive - std/archive bindings for ZuzuScript.

=head1 DESCRIPTION

Implements the C<std/archive> module, exporting the C<Archive> class.

This first backend concentrates on a small, portable surface:
C<decode>, C<encode>, C<load>, and C<dump>.

Archive values are represented as a dict:

  {
    format: "zip",
    entries: [
      { path: "hello.txt", data: BinaryString },
      { path: "nested/world.txt", data: BinaryString },
    ],
  }

Only regular file entries are preserved in this API. Directory entries
and other archive metadata are intentionally ignored to keep the
surface small and portable.

=head1 CLASS

=head2 Archive

Static methods:

=over

=item * C<Archive.decode(bytes, format?)>

Decodes C<BinaryString> archive bytes into an archive dict. When the
format is omitted or C<auto>, the backend attempts to detect it from
the bytes.

=item * C<Archive.encode(archive, format?)>

Encodes an archive dict into C<BinaryString> bytes. The format may be
taken from C<archive.format>.

=item * C<Archive.load(path, format?)>

Reads archive bytes from a C<std/io> C<Path> and decodes them.

=item * C<Archive.dump(path, archive, format?)>

Encodes an archive dict and writes it to a C<std/io> C<Path>.

=back

Perl currently supports C<zip>, C<tar>, C<tar.gz>, C<tar.bz2>,
C<gz>, and C<bz2>.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::Archive >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
