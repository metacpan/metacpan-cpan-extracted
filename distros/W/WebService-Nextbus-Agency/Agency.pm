package WebService::Nextbus::Agency;
use 5.006;
use strict;
use warnings;
use integer;
     
our $VERSION = '0.12';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = {
		_nameCode		=> undef,
		_routeRegExp	=> undef,
		_dirRegExp		=> undef,
		_routes		=> {},
	};
	bless ($self, $class);
}

# Input or check the name code for this agency, e.g. sf-muni
sub nameCode {
	my $self = shift;
	if (@_) { $self->{_nameCode} = shift }
	return $self->{_nameCode};
}

# Input or check the RegExps used for default parsing
sub routeRegExp {
	my $self = shift;
	if (@_) { $self->{_routeRegExp} = shift }
	return $self->{_routeRegExp};
}

sub dirRegExp {
	my $self = shift;
	if (@_) { $self->{_dirRegExp} = shift }
	return $self->{_dirRegExp};
}

# For building or checking the tree structure of routes, dirs, stops
sub routes {
	my $self = shift;
	if (@_) { %{$self->{_routes}} = %{$_[0]} }
	return \%{$self->{_routes}};
}

sub dirs {
	my $self = shift;
	my ($route, $newDirs) = @_;
	if ($newDirs) { %{$self->routes()->{$route}} = %$newDirs }
	return \%{$self->routes()->{$route}};
}

sub stops {
	my $self = shift;
	my ($route, $dir, $newStops) = @_;
	if ($newStops) { %{$self->dirs($route)->{$dir}} = %$newStops }
	return \%{$self->dirs($route)->{$dir}};
}

# Input or check a particular stop code given the route, dir, and name of stop.
sub stopCode {
	my $self = shift;
	my ($route, $dir, $stopName, $newCode) = @_;
	if ($newCode) { $self->stops($route, $dir)->{$stopName} = $newCode }
	return $self->stops($route, $dir)->{$stopName};
}

# Spit out the stop names (keys) or codes (values)
sub allStopNames {
	my $self = shift;
	my ($route, $dir) = @_;
	return keys(%{$self->stops($route, $dir)});
}

sub allStopCodes {
	my $self = shift;
	my ($route, $dir) = @_;
	return values(%{$self->stops($route, $dir)});
}

# Default parsing of input string according to object's stored RegExps
sub parseRoute {
	my $self = shift;
	my ($str) = @_;
	my $routeRegExp = $self->routeRegExp();
	my ($route) = ($str =~ /$routeRegExp/i);

	$str =~ s/$route\s*//;
	return (ucfirst($route), $str);
}

sub parseDir {
	my $self = shift;				
	my ($str) = @_;			 
	my $dirRegExp = $self->dirRegExp();
	my ($dir) = ($str =~ /$dirRegExp/i);

	$str =~ s/$dir\s*//;
	return ($dir, $str);
}

# Search for stop codes in current tree.  First, check whether the input string
# directly matches a stop code.  Otherwise, assume the input string is a stop
# name and search the names for a match.  The matching is done word by word:
# first split the input at whitespaces, then match each word in turn, narrowing
# the list of stopnames at each step (but if the word makes no matches, then
# leave the list alone).  At the end, return all remaining matches.
sub str2stopCodes {
	my $self = shift;
	my ($route, $dir, $stopStr) = @_;

	my @stopCodes = $self->allStopCodes($route, $dir);
	if ((my @retCodes = grep(/$stopStr/i, @stopCodes)) == 1) {
		return @retCodes;
	}

	my @stopNames = $self->allStopNames($route, $dir);
	foreach my $word (split(/\s+/, $stopStr)) {
		if (my @temp = grep(/$word/i, @stopNames)) {
			@stopNames = @temp;
		}
	}

	my @retCodes;
	foreach my $stopName (@stopNames) {
		my $retCode = $self->stopCode($route, $dir, $stopName);
		push(@retCodes, $retCode);
	}
	return @retCodes;
}

# To dump the routes tree in human readable format.  Essentially the same as
# Data::Dumper in case you don't want to load that library.
sub routesAsString {
	my $self = shift;

	foreach my $routeKey (keys(%{$self->routes()})) {
		print "$routeKey =>\n";
		my $routeVal = $self->routes()->{$routeKey};
		foreach my $dirKey (keys(%$routeVal)) {
			print "	$dirKey =>\n";
			my $dirVal = $routeVal->{$dirKey};
			foreach my $stopKey (keys(%$dirVal)) {
				print "		$stopKey => ";
				my $stopVal = $dirVal->{$stopKey};
				print $stopVal . "\n";
			}
		}
	}
}

1
__END__

=head1 NAME

WebService::Nextbus::Agency - Superclass for data structures designed for Nextbus website (www.nextbus.com)


=head1 SYNOPSIS

  use WebService::Nextbus;
  $nb = new WebService::Nextbus;
  $nb->buildAgency('sf-muni'); # Scraping the webpages repeatedly can take time
  @stops = $nb->agencies->{'sf-muni'}->str2stopCodes('N', 'judah', 'Chu Dub');

  # OR...

  use WebService::Nextbus::Agency::SFMUNI;
  $muniAgency = new WebService::Nextbus::Agency::SFMUNI;
  @stops = $muniAgency->str2stopCodes('N', 'judah', 'Church and Duboce');

C<@stops> can now be used as valid GET arguments on the nextbus webpage.


=head1 DESCRIPTION

WebService::Nextbus::Agency implements a basic data structure for storing and
retrieving information on the various agencies monitored by the Nextbus website
(www.nextbus.com).  Nextbus provides a GPS system for predicting the arrival
times of transit vehicles.  In order to screen scrape the website effectively,
one must be familiar with the GET arguments used by the site.  This module
provides the data structure for storing this info once it has been determined
for a particular transit agency.

The L</SYNOPSIS> indicates how the object can be used to retrieve the GET 
argument that the website requires for returning GPS information for a 
particular stop on a particular route of the sf-muni agency.  There are 
basically two methods: determine the relevant GET arguments by screen scraping
the Nextbus website using L<WebService::Nextbus>, or load a prepared data
structure from a helper subclass.  

So far, only the L<WebService::Nextbus::Agency::SFMUNI> subclass has been 
implemented.  With the screen scraping of WebService::Nextbus available, 
however, it should be simple to create more helper subclasses by running 
WebService::Nextbus->buildAgency for the agency of choice and then using 
Storable to serialize the resulting routes tree for retrieval by the new helper 
subclass.

Once the proper GET code has been retrieved, a web useragent can use the 
argument to build a URL for the desired information.  This useragent function 
will probably eventually be incorporated into L<WebService::Nextbus>, which is 
already a L<LWP::UserAgent>.

The entire functionality of this module will eventually be made obsolete by the
anticipated development of an official WebService (W3C standard) by the Nextbus
team.  However, this is useful in the interim, and if Nextbus ends up charging
for their service, then this will continue to be developed.

=head2 EXPORT

None by default; OO interface.


=head1 ERROR CHECKING

Watch out!  No error checking yet...


=head1 REQUIRES

Tests require the Test::More module.
Subclass SFMUNI (and likely any additional subclasses created for other
agencies) requires the L<Storable> module. 


=head1 AUTHOR

Peter H. Li<lt>phli@cpan.org<gt>


=head1 COPYRIGHT

Licensed by Creative Commons
http://creativecommons.org/licenses/by-nc-sa/2.0/


=head1 SEE ALSO

L<WebService::Nextbus>, L<WebService::Nextbus::Agency::SFMUNI>, L<Storable>, 
L<LWP::UserAgent>, L<perl>.

=cut
~
