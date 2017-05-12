package WebService::Nextbus::Agency::SFMUNI;
use 5.006;
use strict;
use warnings;
use integer;
use Storable;
use base qw(WebService::Nextbus::Agency);

our $VERSION = '0.12';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = $class->SUPER::new;
	$self->nameCode('sf-muni');
	$self->routeRegExp('([fjklmns]|22)');
	$self->dirRegExp('(fishwarf|castro|downtown|balboa|zoo|caltrain|judah|castro|marina|3rdstreet|[34bcdfijmnsz])');

	# This hack is the only way I could figure to find the serialized data
	my $fileDir = $INC{'WebService/Nextbus/Agency/SFMUNI.pm'};
	$fileDir =~ s/SFMUNI.pm$//;
	$self->routes(retrieve($fileDir . 'SFMUNI.store'));

	bless ($self, $class);
}

# A little hacking by an SF native for convenience
sub parseDir {
	my $self = shift;
	my ($str) = @_;  
	my $dirRegExp = $self->dirRegExp();   

	my ($dir) = ($str =~ /$dirRegExp/i);
	$str =~ s/$dir\s*//;
	$dir = lc($dir);

	# Various translations for limited backward compatibility
	if ($dir eq 'i') { $dir = 'downtown' }
	if ($dir eq 'n') { $dir = 'marina' }
	if ($dir eq 's') { $dir = 'marina' }

	# Standard translations
	if ($dir eq '3') { $dir = '3rdstreet' }
	if ($dir eq '4') { $dir = 'caltrain' } # 4 for 4th and King
	if ($dir eq 'b') { $dir = 'balboa' }
	if ($dir eq 'c') { $dir = 'castro' }
	if ($dir eq 'd') { $dir = 'downtown' }
	if ($dir eq 'f') { $dir = 'fishwarf' }
	if ($dir eq 'j') { $dir = 'judah' }
	if ($dir eq 'm') { $dir = 'marina' }
	if ($dir eq 'z') { $dir = 'zoo' }

	return ($dir, $str);
}

1
__END__
=head1 NAME

WebService::Nextbus::Agency::SFMUNI - A helper subclass of WebService::Nextbus::Agency for the sf-muni agency


=head1 SYNOPSIS

	use WebService::Nextbus::Agency::SFMUNI;
	$muniAgency = new WebService::Nextbus::Agency::SFMUNI;
	@stopCodes = $muniAgency->str2stopCodes('N', 'judah', 'Duboce and Fillmore');

C<$stopCodes> can now be used as valid GET arguments on the nextbus webpage.


=head1 DESCRIPTION

Objects of the SFMUNI class are L<WebService::Nextbus::Agency> inheritors and 
already know much of the data about sf-muni, e.g. available routes, stops, etc..

WebService::Nextbus::Agency is a class used as a data structure to store and 
intelligently recall the information that L<WebService::Nextbus> will download 
from the Nextbus website.  It class can also be used by initializing inheriting 
helper subclasses such as SFMUNI, which will automatically load up the data 
relevant for the given agency without having to go to the web.

The L</SYNOPSIS> indicates how the object can be used to retrieve the GET
argument that the website requires for returning GPS information for a 
particular stop on a particular route of the sf-muni agency.  Once the proper
GET code has been retrieved, a web useragent can use the argument to build
a URL for the desired information.  This is another function that will 
eventually be provided by WebService::Nextbus. 


=head2 EXPORT

None by default.


=head1 ERROR CHECKING

Watch out!  No error checking yet...


=head1 REQUIRES

Started using serialized data via L<Storable> for storing and retrieving the
prepared agency data.

Requires and packaged with L<WebService::Nextbus::Agency>.

Tests (packages with Agency) require Test::More.


=head1 AUTHOR

Peter H. Li<lt>phli@cpan.org<gt>


=head1 COPYRIGHT

Licensed by Creative Commons
http://creativecommons.org/licenses/by-nc-sa/2.0/


=head1 SEE ALSO

L<WebService::Nextbus::Agency>, L<Storable>, L<perl>.

=cut
~
