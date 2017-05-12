package LiveGeez::Apache;

BEGIN
{
use strict;
use vars qw( $config );
use Apache::Constants qw(:common);
use Apache::Request;
use Apache::URI;

use LiveGeez::Request;
use LiveGeez::Services;

require LiveGeez::Config;
$config = new LiveGeez::Config;

}


sub handler
{
	my $ap = new Apache::Request ($_[0]);

	my $args = $ap->args;

	if ( $args ) {
		$args =~ s/\/$//;
		$args = "file=$args" unless ( $args =~ "=" );
		if ( $args =~ /&/ ) {
			my $first = $args;
			$first =~ s/^(.*?)\&(.*)$/$1/;
			$args = "file=$args" unless ( $first =~ "=" );
		}
		$ap->args ( $args );
	}
	else {
		my $uri  = $ap->uri;
		$uri =~ s/^\///;
		$uri =~ s|http:/(\w)|http://$1|;  # IE4 hoses this
		unless ( $uri ) {
			$ap->internal_redirect ( "/index.html" );
			return OK;
		}
		$uri = "file=$uri" unless ( $uri =~ "=" );
		$ap->args ( $uri );
	}


 	my $r = new LiveGeez::Request ( $config, $_[0] );
	printf STDERR "Request Begin[$$] $r->{file}\n";

	ProcessRequest ( $r ) || $r->DieCgi ( "Unrecognized Request." );
	
	$r = undef;

	printf STDERR "Returning[$$]\n";
	OK;
}
1;
