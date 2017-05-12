package WebService::Steam::User;

use DateTime;
use IO::All;
use Moose;
use Moose::Util::TypeConstraints;
use WebService::Steam;

subtype 'SteamBool',   as 'Bool';
 coerce 'SteamBool', from 'Str', via { /^online$/ };

has      banned => ( is => 'ro', isa => 'Bool'     , init_arg => 'vacBanned'                );
has  custom_url => ( is => 'ro', isa => 'Str'      , init_arg => 'customURL'                );
has    __groups => ( is => 'ro', isa => 'ArrayRef' , init_arg => 'group'                    );
has     _groups => ( isa => 'ArrayRef[WebService::Steam::Group]'                             ,
                 handles => { groups => 'elements' }                                         ,
              lazy_build => 1                                                                ,
                  traits => [ 'Array' ]                                                     );
has    headline => ( is => 'ro', isa => 'Str'                                               );
has          id => ( is => 'ro', isa => 'Int'      , init_arg => 'steamID64'                );
has     limited => ( is => 'ro', isa => 'Bool'     , init_arg => 'isLimitedAccount'         );
has    location => ( is => 'ro', isa => 'Str'                                               );
has        name => ( is => 'ro', isa => 'Str'      , init_arg => 'realname'                 );
has        nick => ( is => 'ro', isa => 'Str'      , init_arg => 'steamID'                  );
has      online => ( is => 'ro', isa => 'SteamBool', init_arg => 'onlineState', coerce => 1 );
has      rating => ( is => 'ro', isa => 'Num'      , init_arg => 'steamRating'              );
has _registered => ( is => 'ro', isa => 'Str'      , init_arg => 'memberSince'              );
has  registered => ( is => 'ro', isa => 'DateTime' , lazy_build => 1                        );
has     summary => ( is => 'ro', isa => 'Str'                                               );

sub path { "http://steamcommunity.com/@{[ $_[1] =~ /^\d+$/ ? 'profiles' : 'id' ]}/$_[1]/?xml=1" }

sub _build__groups { [ WebService::Steam::steam_group( map $$_{ groupID64 }, @{ $_[0]->__groups } ) ] }

sub _build_registered
{
	my ( $month, $day, $year ) = split /,? /, $_[0]->_registered;

	my %months;
	   @months{ qw/January Febuary March April May June July August September October November December/ } = ( 1..12 );
	
	DateTime->new( year => $year, month => $months{ $month }, day => $day );
}

__PACKAGE__->meta->make_immutable;

1;
 
=head1 NAME

WebService::Steam::User

=head1 ATTRIBUTES

=head2 banned

A boolean of the user's VAC banned status.

=head2 custom_url

A string of the user's custom URL

=head2 headline

A string of the user's headline

=head2 id

An integer of the user's ID

=head2 limited

=head2 location

=head2 name

A string of the user's real life name.

=head2 nick

A string of the user's chosen nick name.

=head2 online

A boolean of the user's current online status.

=head2 rating

=head2 registered

A L<DateTime> of when the user registered their Steam account.

=head2 summary

=head2 groups