package Time::ZoneInfo;
use strict;
use vars qw/$VERSION/;
$VERSION = '0.3';
use IO::File;

$Time::ZoneInfo::ERROR = "";

sub new {
	my ($class, @params) = @_;
	my $this = bless {}, ref($class) || $class;
	return undef unless ($this->init(@params));
	return $this;
}

sub init {
	my ($this, %params) = @_;
	# Read in and process the /usr/share/zoneinfo/zone.tab file
	# Create a REGIONS array (only region part) and ZONES (full part)
	my (@zones, %regions, $zone);
	
	my $filename = $params{zonetab} || "/usr/share/zoneinfo/zone.tab";
	my $fh = new IO::File;
	$fh->open($filename);
	if (!defined($fh)) {
		$Time::ZoneInfo::ERROR = "Can't find file ($filename) - $!";
		return 0;
	}
	
	while(my $line = <$fh>) {
		chomp $line;
		next if ($line =~ /^\s*#/);
		next if ($line =~ /^\s*$/);
		$line =~ s/#.*$//;
		if ($line =~ /^[^#](\S+)\s*\t\s*(\S+)\s*\t\s*(\S+)\s*(\t|$)/) {
			$zone = $3;
			if ($zone =~ m|^(.+?)/(.+)$|) {
				$regions{$1}++;
			}
			push @zones, $zone;
		}
	}
	$this->{REGIONS} = [keys %regions];
	$this->{ZONES} = \@zones;
	return 1;
}

sub regions {
	my ($this) = @_;
	return wantarray ? @{$this->{REGIONS}} : $this->{REGIONS};
}

sub zones {
	my ($this, $region) = @_;
	return $this->_zones if (!defined($region));

	my @ret = ();
	foreach my $zone ($this->_zones) {
		if ($zone =~ m|^$region/|) {
			push @ret, $zone;
		}
	}
	return wantarray ? @ret : \@ret;
}

sub _zones {
	my ($this) = @_;
	return wantarray ? @{$this->{ZONES}} : $this->{ZONES};
}

1;

__END__

=head1 NAME

Time::ZoneInfo - Perl extension for returning a list of Time Zones...

=head1 SYNOPSIS

	use Time::ZoneInfo;
	my $zones = Time::ZoneInfo->new();
	foreach my $zone ($zones->zones) {
		# print $zone->zone . ' - ' . $zone->offset . "\n";
		print $zone . "\n";
	}

=head1 DESCRIPTION

An OO interface to accessing a list of timezones. This is useful if you
want to provide an interface for your user to choose one of the available
time zones.

This will be the final release of Time::ZoneInfo as we hope it will be replaced
by code in the perl date time project - see L<http://datetime.perl.org/>.

Currently it is fairly hard coded to work on Debian Linux, but I will 
take any suggesitons on other locaitons so it can automatically fall
back to other file locations, and provide your own as an alternative.

=head1 METHODS

=head2 new

You can specify the zonetab file by passing in zonetab => 'file/location'

=head2 regions

Return an array (or array ref) to the list of regions

=head2 zones ([region])

Return zones (optionally just for one region)

=head1 ERRORS

You can read $Time::ZoneInfo::ERROR for an error message at any time.

=head1 CONTRIBUTIONS

Thanks to Richard Carver <cpan.org-rnc@thecarverzone.com> for finding
issues processing comments.

=head1 AUTHOR

Scot Penrose, E<lt>scott@cpan.orgE<gt>

=head1 SEE ALSO

=cut

