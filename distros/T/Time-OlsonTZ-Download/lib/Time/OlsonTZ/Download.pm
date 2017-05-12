=head1 NAME

Time::OlsonTZ::Download - Olson timezone database from source

=head1 SYNOPSIS

	use Time::OlsonTZ::Download;

	$version = Time::OlsonTZ::Download->latest_version;

	$download = Time::OlsonTZ::Download->new;

	$version = $download->version;
	$version = $download->code_version;
	$version = $download->data_version;
	$dir = $download->dir;
	$dir = $download->unpacked_dir;

	$names = $download->canonical_names;
	$names = $download->link_names;
	$names = $download->all_names;
	$links = $download->raw_links;
	$links = $download->threaded_links;
	$countries = $download->country_selection;

	$files = $download->data_files;
	$zic = $download->zic_exe;
	$dir = $download->zoneinfo_dir;

=head1 DESCRIPTION

An object of this class represents a local copy of the source of
the Olson timezone database, possibly used to build binary tzfiles.
The source copy always begins by being downloaded from the canonical
repository of the Olson database.  This class provides methods to help
with extracting useful information from the source.

=cut

package Time::OlsonTZ::Download;

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);
use File::Path 2.07 qw(rmtree);
use File::Temp 0.22 qw(tempdir);
use IO::Dir 1.03 ();
use IO::File 1.03 ();
use IPC::Filter 0.002 qw(filter);
use Net::FTP 1.21 ();
use Params::Classify 0.000 qw(is_undef is_string);
use String::ShellQuote 1.01 qw(shell_quote);

our $VERSION = "0.004";

sub _init_ftp($$) {
	my($self, $hostname) = @_;
	$self->{ftp_hostname} = $hostname;
	$self->{ftp} = Net::FTP->new($hostname)
		or die "FTP error on $hostname: $@\n";
}

sub _ftp_op($$@) {
	my($self, $method, @args) = @_;
	$self->{ftp}->$method(@args)
		or die "FTP error on @{[$self->{ftp_hostname}]}: ".
			$self->{ftp}->message;
}

sub _ftp_login($$$) {
	my($self, $hostname, $dirarray) = @_;
	_init_ftp($self, $hostname);
	_ftp_op($self, "login", "anonymous","-anonymous\@");
	_ftp_op($self, "binary");
	_ftp_op($self, "cwd", $_) foreach @$dirarray;
}

sub _ensure_ftp($) {
	my($self) = @_;
	unless($self->{ftp}) {
		# Always use IANA master.  Could possibly look at mirrors,
		# but the IANA site is probably reliable enough.
		_ftp_login($self, "ftp.iana.org", ["tz", "releases"]);
	}
}

sub _ftp_versions_in_dir($$) {
	my($self, $subdir) = @_;
	_ensure_ftp($self);
	my $filenames = _ftp_op($self, "ls", defined($subdir) ? ($subdir) : ());
	my(%cversions, %dversions);
	foreach(@$filenames) {
		if(m#(?:\A|/)tzcode([0-9]{2}(?:[0-9]{2})?[a-z])
				\.tar\.(?:gz|Z)\z#x) {
			$cversions{$1} = $_;
		}
		if(m#(?:\A|/)tzdata([0-9]{2}(?:[0-9]{2})?[a-z])
				\.tar\.(?:gz|Z)\z#x) {
			$dversions{$1} = $_;
		}
	}
	return { code => \%cversions, data => \%dversions };
}

sub _all_versions($) {
	my($self) = @_;
	return $self->{all_versions} ||= _ftp_versions_in_dir($self, undef);
}

sub _cmp_version($$) {
	my($a, $b) = @_;
	$a = "19".$a if $a =~ /\A[0-9][0-9][a-z]\z/;
	$b = "19".$b if $b =~ /\A[0-9][0-9][a-z]\z/;
	return $a cmp $b;
}

sub _latest_version($) {
	my($self) = @_;
	my $latest;
	my $curv = _all_versions($self);
	foreach(keys %{$curv->{data}}) {
		$latest = $_
			if !defined($latest) || _cmp_version($_, $latest) > 0;
	}
	unless(defined $latest) {
		die "no current timezone database found on ".
			"@{[$self->{ftp_hostname}]}\n";
	}
	return $latest;
}

=head1 CLASS METHODS

=over

=item Time::OlsonTZ::Download->latest_version

Returns the version number of the latest available version of the Olson
timezone database.  This requires consulting the repository, but is much
cheaper than actually downloading the database.

=cut

sub latest_version {
	my($class) = @_;
	croak "@{[__PACKAGE__]}->latest_version not called as a class method"
		unless is_string($class);
	return _latest_version({});
}

=back

=cut

sub DESTROY {
	my($self) = @_;
	local($., $@, $!, $^E, $?);
	rmtree($self->{cleanup_dir}, 0, 0) if exists $self->{cleanup_dir};
}

=head1 CONSTRUCTORS

=over

=item Time::OlsonTZ::Download->new([VERSION])

Downloads a copy of the source of the Olson database, and returns an
object representing that copy.

I<VERSION>, if supplied, is a version number specifying which version of
the database is to be downloaded.  If not supplied, the latest available
version will be downloaded.  Version numbers for the Olson database
currently consist of a year number and a lowercase letter, such as
"C<2010k>".  Availability of versions other than the latest is limited:
until 2011 there was no official archive, so this module is at the mercy
of historical mirror administrators' whims.

=cut

sub new {
	my($class, $version) = @_;
	die "malformed Olson version number `$version'\n"
		unless is_undef($version) ||
			(is_string($version) &&
				$version =~ /\A[0-9]{2}(?:[0-9]{2})?[a-z]\z/);
	my $self = bless({}, $class);
	my $latest_version = $self->_latest_version;
	$version ||= $latest_version;
	_cmp_version($version, $latest_version) <= 0
		or die "Olson DB version $version doesn't exist yet\n";
	$self->{version} = $version;
	$self->{dir} = $self->{cleanup_dir} = tempdir();
	my $vers = $self->_all_versions;
	unless(exists $vers->{data}->{$version}) {
		$vers = $self->_all_versions;
		unless(exists $vers->{data}->{$version}) {
			die "Olson DB version $version not available on ".
				"@{[$self->{ftp_hostname}]}\n";
		}
	}
	my @cversions = sort { _cmp_version($b, $a) }
		grep { _cmp_version($_, $version) <= 0 } keys %{$vers->{code}};
	die "no matching code available for data version $version\n"
		unless @cversions;
	my $cversion = $cversions[0];
	$self->{code_version} = $cversion;
	$self->{data_version} = $version;
	$self->_ftp_op("get", $vers->{code}->{$cversion},
		$self->dir."/tzcode.tar.gz");
	$self->_ftp_op("get", $vers->{data}->{$version},
		$self->dir."/tzdata.tar.gz");
	delete $self->{ftp};
	delete $self->{ftp_hostname};
	$self->{downloaded} = 1;
	return $self;
}

=item Time::OlsonTZ::Download->new_from_local_source(ATTR => VALUE)

Acquires Olson database source locally, without downloading, and returns
an object representing a copy of it ready to use like a download.
This can be used to work with locally-modified versions of the database.
The following attributes may be given:

=over

=item B<source_dir>

Local directory containing Olson source files.  Must be supplied.
The entire directory will be copied into a temporary location to be
worked on.

=item B<version>

Olson version number to attribute to the source files.  Must be supplied.

=item B<code_version>

=item B<data_version>

Olson version number to attribute to the code and data parts of the
source files.  Both default to the main version number.

=back

=cut

sub new_from_local_source {
	my $class = shift;
	my $self = bless({}, $class);
	my $srcdir;
	while(@_) {
		my $attr = shift;
		my $value = shift;
		if($attr eq "source_dir") {
			croak "source directory specified redundantly"
				if defined $srcdir;
			croak "source directory must be a string"
				unless is_string($value);
			$srcdir = $value;
		} elsif($attr =~ /\A(?:(?:code|data)_)?version\z/) {
			croak "$attr specified redundantly"
				if exists $self->{$attr};
			die "malformed Olson version number `$value'\n"
				unless is_string($value) &&
					$value =~ /\A
						[0-9]{2}(?:[0-9]{2})?[a-z]
					\z/x;
			$self->{$attr} = $value;
		} else {
			croak "unrecognised attribute `$attr'";
		}
	}
	croak "source directory not specified" unless defined $srcdir;
	croak "version number not specified" unless exists $self->{version};
	foreach(qw(code_version data_version)) {
		$self->{$_} = $self->{version} unless exists $self->{$_};
	}
	my $tdir = tempdir();
	$self->{cleanup_dir} = $tdir;
	$self->{dir} = "$tdir/c";
	filter("", "cp -pr @{[shell_quote($srcdir)]} ".
			"@{[shell_quote($self->{dir})]}");
	$self->{downloaded} = 1;
	$self->{unpacked} = 1;
	return $self;
}

=back

=head1 METHODS

=head2 Basic information

=over

=item $download->version

Returns the version number of the database of which a copy is represented
by this object.

The database consists of code and data parts which are updated
semi-independently.  The latest version of the database as a whole
consists of the latest version of the code and the latest version of
the data.  If both parts are updated at once then they will both get the
same version number, and that will be the version number of the database
as a whole.  However, in general they may be updated at different times,
and a single version of the database may be made up of code and data
parts that have different version numbers.  The version number of the
database as a whole will then be the version number of the most recently
updated part.

=cut

sub version {
	my($self) = @_;
	die "Olson database version not determined\n"
		unless exists $self->{version};
	return $self->{version};
}

=item $download->code_version

Returns the version number of the code part of the database of which a
copy is represented by this object.

=cut

sub code_version {
	my($self) = @_;
	die "Olson database code version not determined\n"
		unless exists $self->{code_version};
	return $self->{code_version};
}

=item $download->data_version

Returns the version number of the data part of the database of which a
copy is represented by this object.

=cut

sub data_version {
	my($self) = @_;
	die "Olson database data version not determined\n"
		unless exists $self->{data_version};
	return $self->{data_version};
}

=item $download->dir

Returns the pathname of the directory in which the files of this download
are located.  With this method, there is no guarantee of particular
files being available in the directory; see other directory-related
methods below that establish particular directory contents.

The directory does not move during the lifetime of the download object:
this method will always return the same pathname.  The directory and
all of its contents, including subdirectories, will be automatically
deleted when this object is destroyed.  This will be when the main
program terminates, if it is not otherwise destroyed.  Any files that
it is desired to keep must be copied to a permanent location.

=cut

sub dir {
	my($self) = @_;
	die "download directory not created\n"
		unless exists $self->{dir};
	return $self->{dir};
}

sub _ensure_downloaded {
	my($self) = @_;
	die "can't use download because downloading failed\n"
		unless $self->{downloaded};
}

sub _ensure_unpacked {
	my($self) = @_;
	unless($self->{unpacked}) {
		$self->_ensure_downloaded;
		foreach my $part (qw(tzcode tzdata)) {
			filter("", "cd @{[shell_quote($self->dir)]} && ".
					"gunzip < $part.tar.gz | tar xf -");
		}
		$self->{unpacked} = 1;
	}
}

=item $download->unpacked_dir

Returns the pathname of the directory in which the downloaded source
files have been unpacked.  This is the local temporary directory used
by this download.  This method will unpack the files there if they have
not already been unpacked.

=cut

sub unpacked_dir {
	my($self) = @_;
	$self->_ensure_unpacked;
	return $self->dir;
}

=back

=head2 Zone metadata

=over

=cut

sub _ensure_canonnames_and_rawlinks {
	my($self) = @_;
	unless(exists $self->{canonical_names}) {
		my %seen;
		my %canonnames;
		my %rawlinks;
		foreach(@{$self->data_files}) {
			my $fh = IO::File->new($_, "r")
				or die "data file $_ unreadable: $!\n";
			local $/ = "\n";
			while(defined(my $line = $fh->getline)) {
				if($line =~ /\AZone[ \t]+([!-~]+)[ \t\n]/) {
					my $name = $1;
					die "zone $name multiply defined\n"
						if exists $seen{$name};
					$seen{$name} = undef;
					$canonnames{$name} = undef;
				} elsif($line =~ /\ALink[\ \t]+
						([!-~]+)[\ \t]+
						([!-~]+)[\ \t\n]/x) {
					my($target, $name) = ($1, $2);
					die "zone $name multiply defined\n"
						if exists $seen{$name};
					$seen{$name} = undef;
					$rawlinks{$name} = $target;
				}
			}
		}
		$self->{raw_links} = \%rawlinks;
		$self->{canonical_names} = \%canonnames;
	}
}

=item $download->canonical_names

Returns the set of timezone names that this version of the database
defines as canonical.  These are the timezone names that are directly
associated with a set of observance data.  The return value is a reference
to a hash, in which the keys are the canonical timezone names and the
values are all C<undef>.

=cut

sub canonical_names {
	my($self) = @_;
	$self->_ensure_canonnames_and_rawlinks;
	return $self->{canonical_names};
}

=item $download->link_names

Returns the set of timezone names that this version of the database
defines as links.  These are the timezone names that are aliases for
other names.  The return value is a reference to a hash, in which the
keys are the link timezone names and the values are all C<undef>.

=cut

sub link_names {
	my($self) = @_;
	unless(exists $self->{link_names}) {
		$self->{link_names} =
			{ map { ($_ => undef) } keys %{$self->raw_links} };
	}
	return $self->{link_names};
}

=item $download->all_names

Returns the set of timezone names that this version of the database
defines.  These are the L</canonical_names> and the L</link_names>.
The return value is a reference to a hash, in which the keys are the
timezone names and the values are all C<undef>.

=cut

sub all_names {
	my($self) = @_;
	unless(exists $self->{all_names}) {
		$self->{all_names} = {
			%{$self->canonical_names},
			%{$self->link_names},
		};
	}
	return $self->{all_names};
}

=item $download->raw_links

Returns details of the timezone name links in this version of the
database.  Each link defines one timezone name as an alias for some
other timezone name.  The return value is a reference to a hash, in
which the keys are the aliases and each value is the preferred timezone
name to which that alias directly refers.  It is possible for an alias
to point to another alias, or to point to a non-existent name.  For a
more processed view of links, see L</threaded_links>.

=cut

sub raw_links {
	my($self) = @_;
	$self->_ensure_canonnames_and_rawlinks;
	return $self->{raw_links};
}

=item $download->threaded_links

Returns details of the timezone name links in this version of the
database.  Each link defines one timezone name as an alias for some
other timezone name.  The return value is a reference to a hash, in
which the keys are the aliases and each value is the canonical name of
the timezone to which that alias refers.  All such canonical names can
be found in the L</canonical_names> hash.

=cut

sub threaded_links {
	my($self) = @_;
	unless(exists $self->{threaded_links}) {
		my $raw_links = $self->raw_links;
		my %links = %$raw_links;
		while(1) {
			my $done_any;
			foreach(keys %links) {
				next unless exists $raw_links->{$links{$_}};
				$links{$_} = $raw_links->{$links{$_}};
				die "circular link at $_\n" if $links{$_} eq $_;
				$done_any = 1;
			}
			last unless $done_any;
		}
		my $canonical_names = $self->canonical_names;
		foreach(keys %links) {
			die "link from $_ to non-existent zone $links{$_}\n"
				unless exists $canonical_names->{$links{$_}};
		}
		$self->{threaded_links} = \%links;
	}
	return $self->{threaded_links};
}

=item $download->country_selection

Returns information about how timezones relate to countries, intended
to aid humans in selecting a geographical timezone.  This information
is derived from the C<zone.tab> and C<iso3166.tab> files in the database
source.

The return value is a reference to a hash, keyed by (ISO 3166 alpha-2
uppercase) country code.  The value for each country is a hash containing
these values:

=over

=item B<alpha2_code>

The ISO 3166 alpha-2 uppercase country code.

=item B<olson_name>

An English name for the country, possibly in a modified form, optimised
to help humans find the right entry in alphabetical lists.  This is
not necessarily identical to the country's standard short or long name.
(For other forms of the name, consult a database of countries, keying
by the country code.)

=item B<regions>

Information about the regions of the country that use distinct
timezones.  This is a hash, keyed by English description of the region.
The description is empty if there is only one region.  The value for
each region is a hash containing these values:

=over

=item B<olson_description>

Brief English description of the region, used to distinguish between
the regions of a single country.  Empty string if the country has only
one region for timezone purposes.  (This is the same string used as the
key in the B<regions> hash.)

=item B<timezone_name>

Name of the Olson timezone used in this region.  This is not necessarily
a canonical name (it may be a link).  Typically, where there are aliases
or identical canonical zones, a name is chosen that refers to a location
in the country of interest.  It is not guaranteed that the named timezone
exists in the database (though it always should).

=item B<location_coords>

Geographical coordinates of some point within the location referred to in
the timezone name.  This is a latitude and longitude, in ISO 6709 format.

=back

=back

This data structure is intended to help a human select the appropriate
timezone based on political geography, specifically working from a
selection of country.  It is of essentially no use for any other purpose.
It is not strictly guaranteed that every geographical timezone in the
database is listed somewhere in this structure, so it is of limited use
in providing information about an already-selected timezone.  It does
not include non-geographic timezones at all.  It also does not claim
to be a comprehensive list of countries, and does not make any claims
regarding the political status of any entity listed: the "country"
classification is loose, and used only for identification purposes.

=cut

sub country_selection {
	my($self) = @_;
	unless(exists $self->{country_selection}) {
		my $itabname = $self->unpacked_dir."/iso3166.tab";
		my $ztabname = $self->unpacked_dir."/zone.tab";
		local $/ = "\n";
		my %itab;
		my $itabfh = IO::File->new($itabname, "r")
			or die "data file $itabname unreadable: $!\n";
		while(defined(my $line = $itabfh->getline)) {
			if($line =~ /\A([A-Z]{2})\t([!-~][ -~]*[!-~])\n\z/) {
				die "duplicate $itabname entry for $1\n"
					if exists $itab{$1};
				$itab{$1} = $2;
			} elsif($line !~ /\A#[^\n]*\n\z/) {
				die "bad line in $itabname\n";
			}
		}
		my %sel;
		my $ztabfh = IO::File->new($ztabname, "r")
			or die "data file $ztabname unreadable: $!\n";
		while(defined(my $line = $ztabfh->getline)) {
			if($line =~ /\A([A-Z]{2})
				\t([-+][0-9]{4}(?:[0-9]{2})?
					[-+][0-9]{5}(?:[0-9]{2})?)
				\t([!-~]+)
				(?:\t([!-~][ -~]*[!-~]))?
			\n\z/x) {
				my($cc, $coord, $zn, $reg) = ($1, $2, $3, $4);
				$reg = "" unless defined $reg;
				$sel{$cc} ||= { regions => {} };
				die "duplicate $ztabname entry for $cc\n"
					if exists $sel{$cc}->{regions}->{$reg};
				$sel{$cc}->{regions}->{$reg} = {
					olson_description => $reg,
					timezone_name => $zn,
					location_coords => $coord,
				};
			} elsif($line !~ /\A#[^\n]*\n\z/) {
				die "bad line in $ztabname\n";
			}
		}
		foreach(keys %sel) {
			die "unknown country $_\n" unless exists $itab{$_};
			$sel{$_}->{alpha2_code} = $_;
			$sel{$_}->{olson_name} = $itab{$_};
			die "bad region description in $_\n"
				if keys(%{$sel{$_}->{regions}}) == 1 xor
					exists($sel{$_}->{regions}->{""});
		}
		$self->{country_selection} = \%sel;
	}
	return $self->{country_selection};
}

=back

=head2 Compiling zone data

=over

=item $download->data_files

Returns a reference to an array containing the pathnames of all the
source data files in the database.  These are located in the local
temporary directory used by this download.

There is approximately one source data file per continent.  Each data
file, in a human-editable textual format, describes the known civil
timezones used on the file's continent.  The textual format is not
standardised, and is peculiar to the Olson database, so parsing it
directly is in principle a dubious proposition, but in practice it is
very stable.

=cut

sub _ensure_standard_zonenames {
	my($self) = @_;
	unless(exists $self->{standard_zonenames}) {
		$self->_ensure_unpacked;
		my $mf = IO::File->new($self->dir."/Makefile", "r");
		my $mfc = $mf ? do { local $/ = undef; $mf->getline } : "";
		$self->{standard_zonenames} = !!($mfc =~ m#
			\nzonenames:[\ \t]+\$\(TDATA\)[\ \t]*\n
			\t[\ \t]*\@\$\(AWK\)\ '
			/\^Zone/\ \{\ print\ \$\$2\ \}
			\ /\^Link/\ {\ print\ \$\$3\ }
			'\ \$\(TDATA\)[\ \t]*\n\n
		#x);
	}
	die "format of zone name declarations is not what this code expects"
		unless $self->{standard_zonenames};
}

sub data_files {
	my($self) = @_;
	unless(exists $self->{data_files}) {
		$self->_ensure_standard_zonenames;
		$self->_ensure_unpacked;
		my $list = filter("", "cd @{[shell_quote($self->dir)]} && ".
					"make zonenames AWK=echo");
		$list =~ s#\A.*\{.*\} ##s;
		$list =~ s#\n\z##;
		$self->{data_files} =
			[ map { $self->dir."/".$_ } split(/ /, $list) ];
	}
	return $self->{data_files};
}

sub _ensure_zic_built {
	my($self) = @_;
	unless($self->{zic_built}) {
		$self->_ensure_unpacked;
		filter("", "cd @{[shell_quote($self->dir)]} && make zic");
		$self->{zic_built} = 1;
	}
}

=item $download->zic_exe

Returns the pathname of the C<zic> executable that has been built from
the downloaded source.  This is located in the local temporary directory
used by this download.  This method will build C<zic> if it has not
already been built.

=cut

sub zic_exe {
	my($self) = @_;
	$self->_ensure_zic_built;
	return $self->dir."/zic";
}

=item $download->zoneinfo_dir([OPTIONS])

Returns the pathname of the directory containing binary tzfiles (in
L<tzfile(5)> format) that have been generated from the downloaded source.
This is located in the local temporary directory used by this download,
and the files within it have names that match the timezone names (as
returned by L</all_names>).  This method will generate the tzfiles if
they have not already been generated.

The optional parameter I<OPTIONS> controls which kind of tzfiles are
desired.  If supplied, it must be a reference to a hash, in which these
keys are permitted:

=over

=item B<leaps>

Truth value, controls whether the tzfiles incorporate information about
known leap seconds offsets that account for the known leap seconds.
If false (which is the default), the tzfiles have no knowledge of leap
seconds, and are intended to be used on a system where C<time_t> is some
flavour of UT (as is conventional on Unix and is the POSIX standard).
If true, the tzfiles know about leap seconds that have occurred between
1972 and the date of the database, and are intended to be used on a
system where C<time_t> is (from 1972 onwards) a linear count of TAI
seconds (which is a non-standard arrangement).

=back

=cut

sub _foreach_nondir_under($$);
sub _foreach_nondir_under($$) {
	my($dir, $callback) = @_;
	my $dh = IO::Dir->new($dir) or die "can't examine $dir: $!\n";
	while(defined(my $ent = $dh->read)) {
		next if $ent =~ /\A\.\.?\z/;
		my $entpath = $dir."/".$ent;
		if(-d $entpath) {
			_foreach_nondir_under($entpath, $callback);
		} else {
			$callback->($entpath);
		}
	}
}

sub zoneinfo_dir {
	my($self, $options) = @_;
	$options = {} if is_undef($options);
	foreach(keys %$options) {
		die "bad option `$_'\n" unless /\Aleaps\z/;
	}
	my $type = $options->{leaps} ? "right" : "posix";
	my $zidir = $self->dir."/zoneinfo_$type";
	unless($self->{"zoneinfo_built_$type"}) {
		filter("", "cd @{[shell_quote($self->unpacked_dir)]} && ".
			"make ${type}_only TZDIR=@{[shell_quote($zidir)]}");
		my %expect_names = %{$self->all_names};
		my $skiplen = length($zidir) + 1;
		_foreach_nondir_under($zidir, sub {
			my($fname) = @_;
			my $lname = substr($fname, $skiplen);
			unless(exists $expect_names{$lname}) {
				die "unexpected file $lname\n";
			}
			delete $expect_names{$lname};
		});
		if(keys %expect_names) {
			die "missing file @{[(sort keys %expect_names)[0]]}\n";
		}
		$self->{"zoneinfo_built_$type"} = 1;
	}
	return $zidir;
}

=back

=head1 BUGS

Most of what this class does will only work on Unix platforms.  This is
largely because the Olson database source is heavily Unix-oriented.

It also won't be much good if you're not connected to the Internet.

This class is liable to break if the format of the Olson database source
ever changes substantially.  If that happens, an update of this class
will be required.  It should at least recognise that it can't perform,
rather than do the wrong thing.

=head1 SEE ALSO

L<DateTime::TimeZone::Tzfile>,
L<Time::OlsonTZ::Data>,
L<tzfile(5)>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2010, 2011, 2012 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
