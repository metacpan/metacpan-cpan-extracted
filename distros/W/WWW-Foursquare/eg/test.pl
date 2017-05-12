#!/usr/bin/env perl

use v5.16;
use WWW::Foursquare;

my $fs = WWW::Foursquare->new(
    client_id     => 'client_id',
    client_secret => 'client_secret',
    redirect_uri  => 'redirect_uri',
);

# for more information visit https://developer.foursquare.com/docs/

# my $code = ''; you should get this code in your backend (callback url)
# my $access_token = $fs->get_access_token($code);

# here default access_token, for your account you need get it by youself
my $access_token = 'DKV03WTVTYJDFCVPOITK5ZYALRQ5YHI1MWXRZTIZCVOQE10D'; 
$fs->set_access_token($access_token);


# get checkins and name of Venue / Country / City
say "[get checkins]";
my $result = $fs->users()->checkins();

my $checkin_items = $result->{checkins}->{items};
for my $checkin (@$checkin_items) {

    my $venue_name = $checkin->{venue}->{name}; 
    my $country    = $checkin->{venue}->{location}->{country};
    my $city       = $checkin->{venue}->{location}->{city};

    say "$venue_name $city/$country"; 
}
say;


# search people and get their avatars
say "[search people]";
my $search = $fs->users()->search(name => 'Vlasov');

for my $user (@{$search->{results}}) {

    # pass blank avatars
    next if $user->{photo}->{suffix} =~ /blank/;

    my $photo   = $user->{photo}->{prefix} . $user->{photo}->{suffix};
    my $user_id = $user->{id};

    say "user id: $user_id photo url: $photo";
}
say;


# search tips by coordinates (lon,lat), and getting their text
say "[search tips]";
my $tips = $fs->tips()->search(ll => '40.7,-74');

TIP:
for my $tip_obj (@{$tips->{tips}}) {

    my $tip_id = $tip_obj->{id};
    my $user   = $tip_obj->{user}->{firstName};

    next TIP if not $tip_id;

    my $tip_info = $fs->tips($tip_id)->info();
    my $tip_text = $tip_info->{tip}->{text};

    say "$user tip: $tip_text";
}
