package Virani;

use 5.006;
use strict;
use warnings;
use TOML;
use File::Slurp;
use Net::Subnet;
use File::Find::IncludesTimeRange;
use File::Find::Rule;
use Digest::MD5 qw(md5_hex);
use File::Spec;
use IPC::Cmd qw(run);
use File::Copy "cp";
use Sys::Syslog;
use JSON;

=head1 NAME

Virani - PCAP retrieval for a FPC setup writing to PCAP files.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Virani;

    my $virani = Virani->new();
    ...

=head1 METHODS

=head2 new_from_conf

Initiates the Virani object from the specified file.

    - conf :: The config TOML to use.
        - Default :: /usr/local/etc/virani.toml

=cut

sub new_from_conf {
	my ( $blank, %opts ) = @_;

	if ( !defined( $opts{conf} ) ) {
		$opts{conf} = '/usr/local/etc/virani.toml';
	}

	if ( !-f $opts{conf} ) {
		die( "'" . $opts{conf} . "' is not a file or does not exist" );
	}

	my $raw_toml;
	eval { $raw_toml = read_file( $opts{conf} ); };
	if ( $@ || !defined($raw_toml) ) {
		my $error = 'Failed to read config file, "' . $opts{conf} . '"';
		if ($@) {
			$error = $error . ' ' . $@;
		}
		die($error);
	}

	my $toml;
	eval { $toml = from_toml($raw_toml); };
	if ($@) {
		die($@);
	}

	return Virani->new( %{$toml} );
}

=head2 new

Initiates the object.

    - allowed_subnets :: The allowed subnets for fetching PCAPs for mojo-varini.
        Defaults :: [ '192.168.0.0/', '127.0.0.1/8', '::1/127', '172.16.0.0/12' ]

    - apikey :: Optional API key for mojo-varini.
        Defaults :: undef

    - auth_by_IP_only :: Auth by IP only and don't use a API key.
        Default :: 1

    - default_set :: The default set to use.
        Default :: default

    - cache :: Cache directory to write to.
        Default :: /var/cache/virani

    - default_regex :: The regex to use for getting the timestamp. The regex to pass to
                       File::Find::IncludesTimeRange for finding PCAP files with timestamps
                       that include the range in question.
        Default :: (?<timestamp>\\d\\d\\d\\d\\d\\d+)(\\.pcap|(?<subsec>\\.\\d+)\\.pcap)$

    - verbose_to_syslog :: Send verbose items to syslog. This is used by mojo-virani.
        Default :: 0

    - verbose :: Print verbose info.
        Default :: 1

    - type :: Either tcpdump or tshark, which to use for filtering PCAP files in the
              specified time slot. tcpdump is faster, but in general will not nicely handles
              some VLAN types. For that tshark is needed, but it is signfigantly slower.
        Default :: tcpdump

    - padding :: How many seconds to add to the start and end time stamps to ensure the specified
                 time slot is definitely included.
        Default :: 5

    - sets :: A hash of hashes of available sets.
        Default :: { default => { path => '/var/log/daemonlogger' } }

For sets, the following keys are usable, of which only path is required.

    - path :: The base path of which the PCAPs are located.

    - padding :: Padding value for this set.

    - regex :: The timestamp regex to use with this set.

    - type :: The default filter type to use with this set.

=cut

sub new {
	my ( $blank, %opts ) = @_;

	my $self = {
		allowed_subnets   => [ '192.168.0.0/', '127.0.0.1/8', '::1/127', '172.16.0.0/12' ],
		apikey            => undef,
		auth_by_IP_only   => 1,
		default_set       => 'default',
		cache             => '/var/cache/virani',
		default_regex     => '(?<timestamp>\\d\\d\\d\\d\\d\\d+)(\\.pcap|(?<subsec>\\.\\d+)\\.pcap)$',
		default_max_time  => '3600',
		verbose_to_syslog => 0,
		verbose           => 1,
		type              => 'tcpdump',
		padding           => 5,
		sets              => {
			default => {
				path => '/var/log/daemonlogger',
			}
		},

	};
	bless $self;

	if ( defined( $opts{allowed_subnets} ) && ref( $opts{allowed_subnets} ) eq 'ARRAY' ) {
		$self->{allowed_subnets} = $opts{allowed_subnets};
	}
	elsif ( defined( $opts{allowed_subnets} ) && ref( $opts{allowed_subnets} ) ne 'ARRAY' ) {
		die("$opts{allowed_subnets} defined, but not a array");
	}

	if ( defined( $opts{sets} ) && ref( $opts{sets} ) eq 'HASH' ) {
		$self->{sets} = $opts{sets};
	}
	elsif ( defined( $opts{sets} ) && ref( $opts{allowed_subnets} ) ne 'HASH' ) {
		die("$opts{sets} defined, but not a hash");
	}

	# real in basic values
	my @real_in
		= ( 'apikey', 'default_set', 'cache', 'default_max_time', 'verbose_to_syslog', 'verbose', 'auth_by_IP_only' );
	for my $key (@real_in) {
		if ( defined( $opts{$key} ) ) {
			$self->{$key} = $opts{$key};
		}
	}

	return $self;
}

=head2 filter_clean

Removes starting and trailing whitespace as well as collapsing
consecutive whitespace to a single space.

The purpose for this is to make sure that tshark/BPF filters passed
are consistent for cacheing, even if their white space differs.

A undef passed to it will return ''.

Will die if the filter matches /^\w*\-/ as it starts with a '-', which
tcpdump will interpret as a switch.

    my $cleaned_bpf=$virani->filter_clean($bpf);

=cut

sub filter_clean {
	my $self   = $_[0];
	my $string = $_[1];

	if ( !defined($string) ) {
		return '';
	}

	if ( $string =~ /^\w*\-/ ) {
		die( 'The filter, "' . $string . '", begins with a "-", which dieing for safety reasons' );
	}

	# remove white space at the start and end
	$string =~ s/^\s*//g;
	$string =~ s/\s+$//g;

	# replace all multiple white space characters with a single space
	$string =~ s/\s\s+/ /g;

	return $string;
}

=head1 check_apikey

Checks the API key.

If auth_via_IP_only is 1, this will always return true.

	my $apikey=$c->param('apikey');
	if (!$virani->check_apikey($apikey)) {
		$c->render( text => "Invalid API key\n", status=>403, );
		return;
	}

=cut

sub check_apikey {
	my $self   = $_[0];
	my $apikey = $_[1];

	if ( $self->{auth_by_IP_only} ) {
		return 1;
	}

	if ( !defined($apikey) ) {
		return 0;
	}

	if ( !defined( $self->{apikey} ) || $self->{apikey} eq '' ) {
		return 0;
	}

	if ( $apikey ne $self->{apikey} ) {
		return 0;
	}

	return 1;
}

=head1 check_remote_ip

Checks if the remote IP is allowed or not.

    if ( ! $virani->check_remote_ip( $c->{tx}{original_remote_address} )){
		$c->render( text => "IP or subnet not allowed\n", status=>403, );
		return;
    }

=cut

sub check_remote_ip {
	my $self = $_[0];
	my $ip   = $_[1];

	if ( !defined($ip) ) {
		return 0;
	}

	if ( !defined( $self->{allowed_subnets}[0] ) ) {
		return 0;
	}

	my $allowed_subnets;
	eval { $allowed_subnets = subnet_matcher( @{ $self->{allowed_subnets} } ); };
	if ($@) {
		die( 'Failed it init subnet matcher... ' . $@ );
	}
	elsif ( !defined($allowed_subnets) ) {
		die('Failed it init subnet matcher... sub_matcher returned undef');
	}

	if ( $allowed_subnets->($ip) ) {
		return 1;
	}

	return 0;
}

=head1 check_type

Verify if the check is valid or note

Returns 0/1 based on if it a known type or not.

    if ( ! $virani->check_type( $type )){
        print $type." is not known\n";
    }

=cut

sub check_type {
	my $self = $_[0];
	my $type = $_[1];

	if ( !defined($type) ) {
		return 0;
	}

	if ( $type ne 'tshark' && $type ne 'tcpdump' ) {
		return 0;
	}

	return 1;
}

=head2 get_default_set

Returns the deefault set to use.

    my $set=$virani->get_default_set;

=cut

sub get_default_set {
	my ($self) = @_;

	return $self->{default_set};
}

=head2 get_cache_file

Takes the same args as get_pcap_lcal.

Returns the path to the file.

    my $cache_file=$virani->get_cache_file(%opts);
    if (! -f $cache_file.'json'){
        echo "Cache file metadata does not exist, so either get_pcap_local died or it has not been ran\n";
    }

=cut

sub get_cache_file {
	my ( $self, %opts ) = @_;

	# make sure we have something for type and check to make sure it is sane
	if ( !defined( $opts{type} ) ) {
		$opts{type} = $self->{type};
		if ( defined( $self->{sets}{ $opts{set} }{type} ) ) {
			$opts{type} = $self->{sets}{ $opts{set} }{type};
		}
	}

	# check it here incase the config includes something off
	if ( !$self->check_type( $opts{type} ) ) {
		die( 'type "' . $opts{type} . '" is not a supported type, tcpdump or tshark,' );
	}

	# basic sanity checking
	if ( !defined( $opts{start} ) ) {
		die('$opts{start} not defined');
	}
	elsif ( !defined( $opts{end} ) ) {
		die('$opts{start} not defined');
	}
	elsif ( ref( $opts{start} ) ne 'Time::Piece' ) {
		die('$opts{start} is not a Time::Piece object');
	}
	elsif ( ref( $opts{end} ) ne 'Time::Piece' ) {
		die('$opts{end} is not a Time::Piece object');
	}
	elsif ( defined( $opts{padding} ) && $opts{padding} !~ /^\d+/ ) {
		die('$opts{padding} is not numeric');
	}

	if ( !defined( $opts{auto_no_cache} ) ) {
		$opts{auto_no_cache} = 1;
	}

	if ( !defined( $opts{set} ) || $opts{set} eq '' ) {
		$opts{set} = $self->get_default_set;
	}

	# make sure the set exists
	if ( !defined( $self->{sets}->{ $opts{set} } ) ) {
		die( 'The set "' . $opts{set} . '" is not defined' );
	}
	elsif ( !defined( $self->{sets}->{ $opts{set} }{path} ) ) {
		die( 'The path for set "' . $opts{set} . '" is not defined' );
	}
	elsif ( !-d $self->{sets}->{ $opts{set} }{path} ) {
		die(      'The path for set "'
				. $opts{set} . '", "'
				. $self->{sets}->{ $opts{set} }{path}
				. '" is not exist or is not a directory' );
	}

	# get the paddimg, make sure it is sane, and apply it
	if ( !defined( $opts{padding} ) ) {
		$opts{padding} = $self->{padding};
		if ( defined( $self->{sets}{ $opts{set} }{padding} ) ) {
			$opts{padding} = $self->{sets}{ $opts{set} }{padding};
		}
	}

	# clean the filter
	$opts{filter} = $self->filter_clean( $opts{filter} );

	my $cache_file;
	if ( defined( $opts{file} ) ) {
		my ( $volume, $directories, $file ) = File::Spec->splitpath( $opts{file} );

		# make sure the directory the output file is using exists
		if ( $directories ne '' && !-d $directories ) {
			die(      '$opts{file} is set to "'
					. $opts{file}
					. '" but the directory part,"'
					. $directories
					. '", does not exist' );
		}

		# figure what what to use as the cache file
		if ( $opts{no_cache} ) {
			$cache_file = $opts{file};
		}
		elsif ( $opts{auto_no_cache} && ( !-d $self->{cache} || !-w $self->{cache} ) ) {
			$cache_file = $opts{file};

		}
		elsif ( $opts{auto_no_cache} && ( -d $self->{cache} || -w $self->{cache} ) ) {
			$cache_file
				= $self->{cache} . '/'
				. $opts{set} . '-'
				. $opts{type} . '-'
				. $opts{start}->epoch . '-'
				. $opts{end}->epoch . "-"
				. lc( md5_hex( $opts{filter} ) );
		}
		elsif ( !$opts{auto_no_cache} && ( !-d $self->{cache} || !-w $self->{cache} ) ) {
			die(      '$opts{auto_no_cache} is false and $opts{no_cache} is false, but the cache dir "'
					. $self->{dir}
					. '" does not exist, is not a dir, or is not writable' );
		}
	}
	else {
		# make sure the cache is usable
		if ( !-d $self->{cache} ) {
			die( 'Cache dir,"' . $self->{cache} . '", does not exist or is not a dir' );
		}
		elsif ( !-w $self->{cache} ) {
			die( 'Cache dir,"' . $self->{cache} . '", is not writable' );
		}

		$cache_file
			= $self->{cache} . '/'
			. $opts{set} . '-'
			. $opts{start}->epoch . '-'
			. $opts{type} . '-'
			. $opts{end}->epoch . "-"
			. lc( md5_hex( $opts{filter} ) );
	}

	return $cache_file;
}

=head2 get_pcap_local

Generates a PCAP locally and returns the path to it.

    - start :: A L<Time::Piece> object of when to start looking.
        - Default :: undef

    - end :: A L<Time::Piece> object of when to stop looking.
        - Default :: undef

    - padding :: Number of seconds to pad the start and end with.
        - Default :: 5

    - filter :: The BPF or tshark filter to use.
        - Default :: ''

    - set :: The PCAP set to use. Will use what ever the default is set to if undef or blank.
        - Default :: $viarni->get_default_set

    - file :: The file to output to. If undef it just returns the path to
              the cache file.
        - Default :: undef

    - no_cache :: If cached, don't return that, but regen and if applicable re-cache.
        - Default :: 0

    - auto_no_cache :: If the cache dir is being used and not writeable and a file
                       as been specified, don't die, but use the output file name
                       as the basis of for the tmp file.
        - Default :: 1

    - type :: 'tcpdump' or 'tshark', depending on what one wants the filter todo.
        - Default :: tcpdump

The return is a hash reference that includes the following keys.

    - pcaps :: A array of PCAPs used.

    - pcap_count :: A count of used PCAPs.

    - failed :: A hash of PCAPs that failed. PCAP path as key and value being the reason.

    - failed_count :: A count of failed PCAPs.

    - path :: The path to the results file. If undef, unable it was unable
              to process any of them.

    - success_found :: A count of successfully processed PCAPs.

    - filter :: The used filter.

    - total_size :: The size of all PCAP files checked.

    - failed_size :: The size of the PCAP files that failed.

    - success_size :: the size of the PCAP files that successfully processed

    - type :: The value of $opts{type}

    - padding :: The value of padding.

    - start_s :: Start time in seconds since epoch, not including pading.

    - end :: Send time in the format '%Y-%m-%dT%H:%M:%S%z'.

    - end_s :: End time in seconds since epoch, not including pading.

    - end :: End time in the format '%Y-%m-%dT%H:%M:%S%z'.

    - using_cache :: If the cache was used or not.

=cut

sub get_pcap_local {
	my ( $self, %opts ) = @_;

	# make sure we have something for type and check to make sure it is sane
	if ( !defined( $opts{type} ) ) {
		$opts{type} = $self->{type};
		if ( defined( $self->{sets}{ $opts{set} }{type} ) ) {
			$opts{type} = $self->{sets}{ $opts{set} }{type};
		}
	}

	# check it here incase the config includes something off
	if ( !$self->check_type( $opts{type} ) ) {
		die( 'type "' . $opts{type} . '" is not a supported type, tcpdump or tshark,' );
	}

	# basic sanity checking
	if ( !defined( $opts{start} ) ) {
		die('$opts{start} not defined');
	}
	elsif ( !defined( $opts{end} ) ) {
		die('$opts{start} not defined');
	}
	elsif ( ref( $opts{start} ) ne 'Time::Piece' ) {
		die('$opts{start} is not a Time::Piece object');
	}
	elsif ( ref( $opts{end} ) ne 'Time::Piece' ) {
		die('$opts{end} is not a Time::Piece object');
	}
	elsif ( defined( $opts{padding} ) && $opts{padding} !~ /^\d+/ ) {
		die('$opts{padding} is not numeric');
	}

	if ( !defined( $opts{auto_no_cache} ) ) {
		$opts{auto_no_cache} = 1;
	}

	if (!defined($opts{no_cache})) {
		$opts{no_cache}=0;
	}

	if ( !defined( $opts{set} ) || $opts{set} eq '' ) {
		$opts{set} = $self->get_default_set;
	}

	# make sure the set exists
	if ( !defined( $self->{sets}->{ $opts{set} } ) ) {
		die( 'The set "' . $opts{set} . '" is not defined' );
	}
	elsif ( !defined( $self->{sets}->{ $opts{set} }{path} ) ) {
		die( 'The path for set "' . $opts{set} . '" is not defined' );
	}
	elsif ( !-d $self->{sets}->{ $opts{set} }{path} ) {
		die(      'The path for set "'
				. $opts{set} . '", "'
				. $self->{sets}->{ $opts{set} }{path}
				. '" is not exist or is not a directory' );
	}

	# get the paddimg, make sure it is sane, and apply it
	if ( !defined( $opts{padding} ) ) {
		$opts{padding} = $self->{padding};
		if ( defined( $self->{sets}{ $opts{set} }{padding} ) ) {
			$opts{padding} = $self->{sets}{ $opts{set} }{padding};
		}
	}

	# clean the filter
	$opts{filter} = $self->filter_clean( $opts{filter} );

	# get the cache file to use
	my $cache_file;
	eval { $cache_file = $self->get_cache_file(%opts); };
	if ($@) {
		die( '$self->get_cache_files(%opts) failed... ' . $@ );
	}

	# if applicable return the cache file
	my $return_cache=0;
	if (
		defined( $opts{file} )
		&& $opts{file} ne $cache_file
		&& !$opts{no_cache}
		&& -f $cache_file
		&& -f $cache_file . '.json'

		)
	{
		$return_cache=1;
	}
	elsif ( !defined( $opts{file} ) && !$opts{no_cache} && -f $cache_file && -f $cache_file . '.json' ) {
		$return_cache=1;
	}
	if ($return_cache) {
		my $cache_message='Already cached... "' . $cache_file . '"';
		if (defined($opts{file}) && $opts{file} ne $cache_file ) {
			$cache_message=$cache_message.' -> "' . $opts{file} . '"';
		}
		$self->verbose( 'info',  $cache_message);
		if (defined($opts{file})) {
			cp( $cache_file, $opts{file} );
		}
		my $to_return;
		eval {
			my $cache_meta_raw = read_file( $cache_file . '.json' );
			$to_return = decode_json($cache_meta_raw);
		};
		if ($@) {
			die( 'Failed to read cache metadata JSON, "' . $cache_file . '.json"' );
		}
		$to_return->{using_cache} = 1;
		return $to_return;
	}

	# check it here incase the config includes something off
	if ( $opts{padding} !~ /^[0-9]+$/ ) {
		die( '"' . $opts{padding} . '" is not a numeric' );
	}

	# set the padding
	my $start = $opts{start} - $opts{padding};
	my $end   = $opts{end} + $opts{padding};

	# get the set
	my $set_path = $self->get_set_path( $opts{set} );
	if ( !defined($set_path) ) {
		die( 'The set "' . $opts{set} . '" does not either exist or the path value for it is undef' );
	}

	# get the pcaps
	my @pcaps = File::Find::Rule->file()->name("*.pcap*")->in($set_path);

	# get the ts_regexp to use
	my $ts_regexp;
	if ( defined( $self->{sets}{ $opts{set} }{regex} ) ) {
		$ts_regexp = $self->{sets}{ $opts{set} }{regex};
	}
	else {
		$ts_regexp = $self->{default_regex};
	}

	my $to_check = File::Find::IncludesTimeRange->find(
		items => \@pcaps,
		start => $start,
		end   => $end,
		regex => $ts_regexp,
	);

	# The path to return.
	my $to_return = {
		pcaps         => $to_check,
		pcap_count    => 0,
		failed        => {},
		failed_count  => 0,
		success_count => 0,
		path          => $cache_file,
		filter        => $opts{filter},
		total_size    => 0,
		failed_size   => 0,
		success_size  => 0,
		tmp_size      => 0,
		final_size    => 0,
		type          => $opts{type},
		padding       => $opts{padding},
		start_s       => $opts{start}->epoch,
		start         => $opts{start}->strftime('%Y-%m-%dT%H:%M:%S%z'),
		end_s         => => $opts{end}->epoch,
		end           => $opts{end}->strftime('%Y-%m-%dT%H:%M:%S%z'),
	};

	$self->verbose( 'info', 'Filter: ' . $opts{filter} );

	# used for tracking the files to cleanup
	my @tmp_files;

	# the merge command
	my $to_merge = [ 'mergecap', '-w', $cache_file ];
	foreach my $pcap ( @{$to_check} ) {

		# get stat info for the file
		my ( $dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks )
			= stat($pcap);
		$to_return->{total_size} += $size;

		$self->verbose( 'info', 'Processing ' . $pcap . ", size=" . $size . " ..." );

		my $tmp_file = $cache_file . '-' . $to_return->{pcap_count};

		my ( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf );
		if ( $opts{type} eq 'tcpdump' ) {
			( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) = run(
				command => [ 'tcpdump', '-r', $pcap, '-w', $tmp_file, $opts{filter} ],
				verbose => 0
			);
		}
		else {
			( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) = run(
				command => [ 'tshark', '-r', $pcap, '-w', $tmp_file, $opts{filter} ],
				verbose => 0
			);
		}
		if ($success) {
			$to_return->{success_count}++;
			$to_return->{success_size} += $size;
			push( @{$to_merge}, $tmp_file );
			push( @tmp_files,   $tmp_file );

			# get stat info for the tmp file
			( $dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks )
				= stat($tmp_file);
			$to_return->{tmp_size} += $size;

		}
		else {
			$to_return->{failed}{$pcap} = $error_message;
			$to_return->{failed_count}++;
			$to_return->{failed_size} += $size;

			$self->verbose( 'warning', 'Failed ' . $pcap . " ... " . $error_message );

			unlink $tmp_file;
		}

		$to_return->{pcap_count}++;
	}

	# only try merging if we had more than one success
	if ( $to_return->{success_count} > 0 ) {

		$self->verbose( 'info', "Merging PCAPs... " . join( ' ', @{$to_merge} ) );

		my ( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) = run(
			command => $to_merge,
			verbose => 0
		);
		if ($success) {
			$self->verbose( 'info', "PCAPs merged into " . $cache_file );
		}
		else {
			# if verbose print different messages if mergecap generated a ouput file or not when it fialed
			if ( -f $cache_file ) {
				$self->verbose( 'warning', "PCAPs partially(output file generated) failed " . $error_message );
			}
			else {
				$self->verbose( 'err', "PCAPs merge completely(output file not generated) failed " . $error_message );
			}
		}

		# remove each tmp file
		foreach my $tmp_file (@tmp_files) {
			unlink($tmp_file);
		}

		# don't bother checking size if the file was not generated
		if ( -f $cache_file ) {
			my ( $dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks )
				= stat($cache_file);
			$to_return->{final_size} = $size;
		}

	}
	else {
		$self->verbose( 'err', "No PCAPs to merge" );
	}

	$self->verbose( 'info',
			  "PCAP sizes... failed_size="
			. $to_return->{failed_size}
			. " success_size="
			. $to_return->{success_size}
			. " total_size="
			. $to_return->{total_size}
			. " tmp_size="
			. $to_return->{tmp_size}
			. " final_size="
			. $to_return->{final_size} );

	$self->verbose( 'info', 'Creating metadata JSON at "' . $cache_file . '.json" ' );
	my $json     = JSON->new->allow_nonref->pretty->canonical(1);
	my $raw_json = $json->encode($to_return);
	write_file( $cache_file . '.json', $raw_json );

	# if the file and cache file are the same, then the cache dir not accessing, so no need to copy it
	if ( defined( $opts{file} ) && $cache_file ne $opts{file} ) {
		$self->verbose( 'info', 'Copying "' . $cache_file . '" to "' . $opts{file} . '"' );
		cp( $cache_file, $opts{file} );
	}

	$to_return->{using_cache} = 0;

	return $to_return;
}

=head2 get_set_path

Returns the path to a set.

If no set is given, the default is used.

Will return undef if the set does not exist or if the set does not have a path defined.

    my $path=$viarni->get_set_path($set);

=cut

sub get_set_path {
	my ( $self, $set ) = @_;

	if ( !defined($set) ) {
		$set = $self->get_default_set;
	}

	if ( !defined( $self->{sets}{$set} ) ) {
		return undef;
	}

	if ( !defined( $self->{sets}{$set}{path} ) ) {
		return undef;
	}

	return $self->{sets}{$set}{path};
}

=head2 set_verbose

Set if it should be verbose or not.

    # be verbose
    $virani->verbose(1);

    # do not be verbose
    $virani->verbose(0);

=cut

sub set_verbose {
	my ( $self, $verbose ) = @_;

	$self->{verbose} = $verbose;
}

=head2 set_verbose_to_syslog

Set if it should be verbose or not.

    # send verbose messages to syslog
    $viarni->set_verbose_to_syslog(1);

    # do not send verbose messages to syslog
    $viarni->set_verbose_to_syslog(0);

=cut

sub set_verbose_to_syslog {
	my ( $self, $to_syslog ) = @_;

	$self->{verbose_to_syslog} = $to_syslog;
}

=head2 verbose

Prints out error messages. This is inteded to be internal.

Only sends the string if verbose is enabled.

There is no need to add a "\n" as it will automatically if not sending to syslog.

Two variables are taken. The first is level the second is the message. Level is only used
for syslog. Default level is info.

    - Levels :: emerg, alert, crit, err, warning, notice, info, debug

    $self->verbose('info', 'some string');

=cut

sub verbose {
	my ( $self, $level, $string ) = @_;

	if ( !defined($string) || $string eq '' ) {
		return;
	}

	if ( !defined($level) ) {
		$level = 'info';
	}

	if ( $self->{verbose} ) {
		if ( $self->{verbose_to_syslog} ) {
			openlog( 'viarni', undef, 'daemon' );
			syslog( $level, $string );
			closelog();
		}
		else {
			print $string. "\n";
		}
	}

	return;
}

=head2 CONFIG

The config format used toml, processed via L<TOML>.

'new_from_conf' will initiate virani by reading it in and feeding it to 'new'.

=head2 DAEMONLOGGER ON FREEBSD

With daemonlogger setup along the lines of like below...

    daemonlogger_enable="YES"
    daemonlogger_flags="-f /usr/local/etc/daemonlogger.bpf -d -l /var/log/daemonlogger -t 120"

The following can be made available via mojo-varini or locally via varini with the set name of
default as below.

    default_set='default'
    allowed_subnets=["192.168.14.0/23", "127.0.0.1/8"]
    [sets.default]
    path='/var/log/daemonlogger'
    regex='(?<timestamp>\d\d\d\d\d\d+)(\.pcap|(?<subsec>\.\d+)\.pcap)$'

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-virani at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Virani>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Virani


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Virani>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Virani>

=item * Search CPAN

L<https://metacpan.org/release/Virani>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999


=cut

1;    # End of Virani
