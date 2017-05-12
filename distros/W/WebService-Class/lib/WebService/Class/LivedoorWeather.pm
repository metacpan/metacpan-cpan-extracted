package WebService::Class::LivedoorWeather;
use strict;
use base qw(WebService::Class::AbstractHTTPRequestClass);
use utf8;
binmode STDOUT, ":utf8";
__PACKAGE__->mk_accessors(qw(city));
__PACKAGE__->mk_classdata('define_city' =>'http://weather.livedoor.com/forecast/rss/forecastmap.xml');
__PACKAGE__->base_url('http://weather.livedoor.com/forecast/webservice/rest/v1');

sub init{
	my $self = shift;
	$self->SUPER::init(@_);
	$self->load_city_id;
}

sub load_city_id{
	my $self = shift;
	
	my $result = $self->request_api()->request('GET',$self->define_city,{})->parse_xml();
	$self->city({});
	foreach my $area (@{$result->{channel}->{"ldWeather:source"}->{area}}){
			my ($area_id) = ($area->{source} =~ /([0-9]*)\.xml/);
			print $area_id;
			if(ref $area->{pref} eq "ARRAY"){
				foreach my $pref (@{$area->{pref}}){
					my ($pref_id) = ($pref->{warn}->{source} =~ /([a-z]*)\.xml/);
					print $pref_id;
					if(ref $pref->{city} eq "HASH"){
						if(exists $pref->{city}->{source}){
							$self->city->{$pref->{city}->{id}} = $pref->{city}->{title};
						}
						else{
							foreach my $key (keys %{$pref->{city}}){
								$self->city->{$key} = $pref->{city}->{$key}->{title};
							}
						}
					}
				}
		}
	}
}

sub weather{
	my $self = shift;
	my $city = shift;
	my $day  = shift;
	return $self->request_api()->request('GET',$self->define_city,{'city'=>$city,'day'=>$day})->parse_xml();
}


