#!perl -T

use Test::More tests => 6;

use WebService::Futu;
use Data::Dumper;

use strict;
use warnings;

my $hash = {
	user => 'vaclav.dovrtel@gmail.com',
	pass => 'vasekd'
};

# Creation of a new object
my $futu = WebService::Futu->new(%$hash);
is_deeply( $futu->{_user}, $hash->{user},"User set properly" );
is_deeply( $futu->{_pass}, $hash->{pass},"Pass set properly" );
is_deeply( $futu->{_url}, 'https://www.futu.cz',"Default Url set properly" );

$hash = {
	id => 'vaclav.dovrtel@gmail.com',
	pass => 'vasekd',
	url => 'https://www.futu1.cz/'
};
$futu = WebService::Futu->new(%$hash);
is_deeply( $futu->{_id}, $hash->{id},"User set properly2" );
is_deeply( $futu->{_url}, 'https://www.futu1.cz/',"Manual Url set properly" );

$hash = {
	user => 'vaclav.dovrtel@gmail.com',
	id => 'vaclav.dovrtel@gmail.com',
	pass => 'vasekd'
};
$futu = WebService::Futu->new(%$hash);
is_deeply( $futu->{_user}, $hash->{user},"User set properly1" );
