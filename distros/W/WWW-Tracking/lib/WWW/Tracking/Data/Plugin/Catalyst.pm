package WWW::Tracking::Data::Plugin::Catalyst;

use strict; 
use warnings;
our $VERSION = '0.05';

1;

package WWW::Tracking::Data;

use Carp::Clan 'croak';

sub from_catalyst {
	my $self = shift;
	my $args = shift;
	
	my $c = delete $args->{'c'} or croak '$c is mandatory argument';
	my %headers_args = %{$args};
	
	my $req = $c->request;
	
	return $self->from(
		'headers' => {
			'headers'     => $req->headers,
			'request_uri' => $req->uri,
			'remote_ip'   => $req->address,
			%headers_args,
		},
	);	
}

1;

__END__

=head1 NAME

WWW::Tracking::Data::Plugin::Catalyst - create C<WWW::Tracking::Data> object from Catalyst::Engine C<$c>

=head1 SYNOPSIS

	my $wt = WWW::Tracking->new->from(
		'catalyst' => {
			'c' => $c,
			'visitor_cookie_name' => '__vcid',
		},
	);	

=head1 DESCRIPTION

Takes L<Catalyst::Engine> C<$c> object and extract data for tracking to
generate L<WWW::Tracking::Data> object from it.

=cut
