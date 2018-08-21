#!perl

package Weather::Fetch;

use XML::LibXML;

our $VERSION = 0.02;

sub new {
	my $class = shift;
	my $self = {
		_metric => shift,
		_code => shift,
		_lang => shift,
		_country => shift,
		_city => shift
	};

	bless $self, $class;

	return $self;
}

sub getXml {
	my( $self ) = @_;
    my $city = $self->{_city};
    my $lang = $self->{_lang};
    my $code = $self->{_code};
    my $country = $self->{_country};
    my $metric = $self->{_metric};
    
    if ($metric eq "C" || $metric eq "c") {
    	$metric = "1";
	} else {
		$metric = "0";
	}

    my $var = qx{curl -s "http://rss.accuweather.com/rss/liveweather_rss.asp?metric=$metric&locCode=$lang|$country|$code|$city"};
    return $var;
}

sub getWeather {
	my ( $self, $xml, $type ) = @_;
	
	$xml = XML::LibXML->load_xml(string=>$xml);
	my $str;
	foreach my $title ($xml->findnodes('/rss/channel/item/title')) {
		if($title =~ /Currently/){
			my ($junk, $cond, $temp) = split("\:", $title->to_literal());
			if($type eq "temp"){
				$str = $temp;
			} else {
				$str = $cond;
			}
			last;
		} else {
			$str = "ERROR!!";
		}   	
	}
	$str =~ s/^\s+//;
	return $str;
}

sub getForecast {
	my ( $self, $xml ) = @_;	
	$xml = XML::LibXML->load_xml(string=>$xml);
	my $str;
	my $count = 0;
	foreach my $description ($xml->findnodes('/rss/channel/item/description')) {
		if($description =~ /High:/){			
			my @arr = split("<", $description->to_literal());
			if($count == 0){
				$str = "Today: " . $arr[0] . "\n";
			} else {
				$str .= "Tomorrow: " . $arr[0] . "\n";
			}

			if($count == 1){
				last;
			} else {
				$count += 1;
			}
		} else {
			$str = "ERROR!!";
		}
	}
	chomp($str);
	return $str;
}

=head1 NAME

Weather::Fetch - a module that fetches the weather

=head1 DESCRIPTION

This is a module that can be used to make a weather app.
see F<script/weather.pl> for example

=head1 AUTHOR

Brad Heffernan

=head1 LICENSE

FreeBSD

=cut

1;