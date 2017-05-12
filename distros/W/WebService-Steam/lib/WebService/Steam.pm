package WebService::Steam;

use strict;
use warnings;

use Exporter;
use IO::All;
use WebService::Steam::Group;
use WebService::Steam::User;
use XML::Bare;

our $AUTOLOAD;
our @EXPORT  = qw/steam_group steam_user/;
our @ISA     = 'Exporter';
our $VERSION = .4;

sub flatten { map { my $v = $_[0]{ $_ }; ref $v eq 'HASH' ? flatten( $v ) : ( $_ => $v ) } keys %{ $_[0] } }

sub AUTOLOAD
{
	$AUTOLOAD =~ s/steam_(\w)/\u$1/;

	my @objects = map {

		my $_ < io( $AUTOLOAD->path( $_ ) );

		/^<\?xml/ ? $AUTOLOAD->new( flatten( XML::Bare->new( text => $_ )->simple ) ) : ();

	} ref $_[0] ? @{ $_[0] } : @_;

	wantarray ? @objects : $objects[0];
}

1;
 
=head1 NAME

WebService::Steam - A Perl interface to the
L<Steam community data|https://partner.steamgames.com/documentation/community_data>

=head1 SYNOPSIS

	use WebService::Steam;

	my $user = steam_user 'jraspass';

	print $user->name,
	      ' joined steam in ',
	      $user->registered,
	      ', has a rating of ',
	      $user->rating,
	      ', is from ',
	      $user->location,
	      ', and belongs to the following ',
	      scalar( $user->groups ),
	      ' groups: ',
	      join( ', ', $user->groups );

=head1 EXPORTED METHODS

=head2 steam_group

Returns instance(s) of L<WebService::Steam::Group>, can take any combination of group names and IDs.

In scalar context returns the first element of the array.

	my $group  = steam_group(   'valve'                       );
	my $group  = steam_group(            103582791429521412   );
	my @groups = steam_group(   'valve', 103582791429521412   );
	my @groups = steam_group( [ 'valve', 103582791429521412 ] );

=head2 steam_user

Returns instance(s) of L<WebService::Steam::User>, can take any combination of usernames and IDs.

In scalar context returns the first element of the array.
 
	my $user  = steam_user(   'jraspass'                      );
	my $user  = steam_user(               76561198005755687   );
	my @users = steam_user(   'jraspass', 76561198005755687   );
	my @users = steam_user( [ 'jraspass', 76561198005755687 ] );