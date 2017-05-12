package Weather::TW::Forecast;

use strict;
use warnings;
use utf8;
use LWP::Simple;
use Moose;
use Moose::Util::TypeConstraints;
use Mojo::DOM;
use DateTime;
use Carp;

my %area_zh_v7 = (
  台北市      => 'Taipei_City.htm',
  新北市      => 'New_Taipei_City.htm',
  台中市      => 'Taichung_City.htm',
  台南市      => 'Tainan_City.htm', 
  高雄市      => 'Kaohsiung_City.htm',
  基隆北海岸  => 'Keelung_North_Coast.htm',
  桃園        => 'Taoyuan.htm',
  新竹        => 'Hsinchu.htm',
  苗栗        => 'Miaoli.htm',
  彰化        => 'Changhua.htm',
  南投        => 'Nantou.htm',
  雲林        => 'Yunlin.htm',
  嘉義        => 'Chiayi.htm',
  屏東        => 'Pingtung.htm',
  恆春半島    => 'Hengchun_Peninsula.htm',
  宜蘭        => 'Yilan.htm',
  花蓮        => 'Hualien.htm',
  台東        => 'Taitung.htm',
  澎湖        => 'Penghu.htm',
  金門        => 'Kinmen.htm',
  馬祖        => 'Matsu.htm',
);

=encoding utf8

=head1 NAME

Weather::TW::Forecast - Get Taiwan forecasts

=head1 SYNOPSIS

    use Weather::TW::Forecast;
    my $weather = Weather::TW::Forecast->new(
      location => '台北',
    );
    foreach ($weather->short_forecasts){
      say $_->start;
      say $_->end;         # DateTime objects specify forecast time interval
      say $_->temperature; # Temperature string, ex: '23 ~ 25'
      say $_->weather;     # Weather string, ex "陰短暫陣雨" 
      say $_->confortable; # ex '舒適'
      say $_->rain;        # probabilty to rain, 0~100%
    }
    foreach ($weather->weekly_forecasts){
      say $_->day;         # DateTime object
      say $_->temperature; # Temperature string, ex: '23 ~ 25'
      say $_->weather;     # Weather string, ex "陰短暫陣雨" 
    }
    my $hash_ref = $weather->montly_mean;
    say $hash_ref->{temp_high}; # Maximum temperature
    say $hash_ref->{temp_low};  # Mininum temperature
    say $hash_ref->{rain};      # Rain precipitation (mm)

=head1 DESCRIPTION

This module reimplement L<Weather::TW> with new web address (from V6 to V7) and
new parser (use L<Mojo::DOM> instead of L<HTML::TreeBulder>). The methods in 
L<Weather::TW> will be deprecated and shiped to L<Weather::TW::Forecast>. More
submodules will be develop to handle obsevations and detail rain infos.
L<Weather::TW> will be a abstract class to access these submodules.

=head1 METHODS

=head2 C<new>

    my $weather = Weather::TW::Forecast->new(
      location => '台北',
    );

Construct a new Weather::TW::Forecast object.

Available locations are

    台北市 新北市 台中市 台南市 高雄市 基隆北海岸 桃園 新竹 苗栗 彰化 南投 雲林 嘉義 屏東 恆春半島 宜蘭 花蓮 台東 澎湖 金門 馬祖

Weather::TW::Forecast will do the fetching right after location is set.

=head2 C<location>

    $weather->location('台中市'); 
    # Change location to 台中市 and do the fetching
    
    $location = $weather->location();
    # Get the location string of $weather

Setter and getter of location.

=cut

has location => (
  is => 'rw',
  isa => enum([qw|台北市 新北市 台中市 台南市 高雄市 
    基隆北海岸 桃園 新竹 苗栗 彰化 南投 雲林      
    嘉義 屏東 恆春半島 宜蘭 花蓮 台東 澎湖 金門 馬祖|]),
  trigger => \&_fetch_forecast,
);

=head2 C<all_locations>

Simply return all available locations

=cut

sub all_locations {
  qw| 台北市 新北市 台中市 台南市 高雄市 基隆北海岸 桃園 新竹 苗栗 
  彰化 南投 雲林 嘉義 屏東 恆春半島 宜蘭 花蓮 台東 澎湖 金門 馬祖|;
}

=head2 C<short_forecast>

    foreach ($weather->short_forecasts){
      say $_->start;
      say $_->end;         # DateTime objects specify forecast time interval
      say $_->temperature; # Temperature string, ex: '23 ~ 25'
      say $_->weather;     # Weather string, ex "陰短暫陣雨" 
      say $_->confortable; # ex '舒適'
      say $_->rain;        # probabilty to rain, 0~100%
    }

This method returns an array of C<Weather::TW::Forecast::ShortForecast> objects.
The object owns six attributes, as shown as above.

=cut

has _short_forecasts => (
  traits => ['Array'],
  is => 'bare',
  isa => 'ArrayRef[Weather::TW::Forecast::ShortForecast]',
  clearer => '_clear_short_forecast',
  handles => { 
    _add_short_forecast => 'push',
    short_forecasts => 'elements',
  },
);

=head2 C<weekly>

    foreach ($weather->weekly_forecasts){
      say $_->day;         # DateTime object
      say $_->temperature; # Temperature string, ex: '23 ~ 25'
      say $_->weather;     # Weather string, ex "陰短暫陣雨" 
    }

Returns a sequence of L<Weather::TW::Weekly> objects, the contents of the object
is as same as above. 

=cut

has _weekly => (
  traits => ['Array'],
  is => 'bare',
  isa => 'ArrayRef[Weather::TW::Forecast::Weekly]',
  clearer => '_clear_weekly',
  handles => {
    weekly_forecasts => 'elements',
    _add_weekly => 'push',
  },
);

=head2 C<montly_mean>

    my $hash_ref = $weather->montly_mean;
    say $hash_ref->{temp_high}; # Maximum temperature
    say $hash_ref->{temp_low};  # Mininum temperature
    say $hash_ref->{rain};      # Rain precipitation (mm)

A hash references contains maximum temperature, minimun temperature, and rain
precipitation (mm).

=cut

has monthly_mean => (
  is => 'ro',
  isa => 'HashRef',
  writer => '_set_monthly_mean',
);


sub _fetch_forecast {
  my $self=shift;
  my $url = 'http://www.cwb.gov.tw/V7/forecast/taiwan/'. $area_zh_v7{$self->location()};
  my $content = get $url or croak "Can't fetch url $url";
  my $dom = Mojo::DOM->new($content);

  my @titles = $dom->find('h3.CenterTitle')->each;
  my @tables = $dom->find('table.FcstBoxTable01')->each;
  my $title; 
  my $table;

  # start to parse short forecasts
  $self->_clear_short_forecast;
  do {
    $title = shift @titles or croak "Can't get 今明預報 in $url";
    $table = shift @tables;
  }until $title->all_text =~ qr|今明預報.+(2\d\d\d)/\d+/\d+|;
  my $year = $1;  #get year information for DateTime

  $table->find('tbody > tr')->each(sub{
    my $e = shift;
    my @tds = $e->find('td')->each;
#  <tr>
#    <th scope="row">今晚至明晨 11/19 18:00~11/20 06:00</th>
#    <td>20 ~ 23</td>
#    <td> <img alt="陰短暫陣雨" src="../../symbol/weather/gif/night/26.gif" title="陰短暫陣雨" /></td>
#    <td>舒適</td>
#    <td>100 %</td>
#  </tr>
    my $time_range = $e->at('th')->all_text or croak "Can't get time range";
    my $temp_range = (shift @tds)->text or croak "Can't get temperature";
    my $weather = (shift @tds)->at('img')->attrs('title') or croak "Can't get weather info";
    my $confortable = (shift @tds)->text or croak "Can't get confortable info";
    my $rain = (shift @tds)->text or croak "Can't get rain info";
    $rain=~s/\s+%\s*//;

    $time_range =~ 
      qr|(\d+)/(\d+)\s(\d+):(\d+)~(\d+)/(\d+)\s(\d+):(\d+)|;

    $self->_add_short_forecast(Weather::TW::Forecast::ShortForecast->new(
      start => DateTime->new(
        year => $year, month => $1, day => $2, hour => $3, minute => $4,
        time_zone => 'Asia/Taipei'),
      end => DateTime->new(
        year => $year, month => $5, day=>$6, hour=>$7, minute=>$8,
        time_zone => 'Asia/Taipei'),
      temperature => $temp_range, 
      weather => $weather,
      confortable => $confortable, 
      rain => $rain,
    ));
  }); # end of parsing short forecasts

  # start parsing weekly forecasts
  $self->_clear_weekly;
  do {
    $title = shift @titles or croak "Can't get １週預報 in $url";
    $table = shift @tables;
  }until $title->all_text =~ qr|１週預報|;
  # skip left most th, it's 預報地區, not day info
  my $first_day = ($table->find('thead > tr > th')->each)[1];
  $first_day->all_text =~ qr|(\d+)/(\d+)|;
  my $week_day = DateTime->new( year => $year, month => $1, day => $2,);

  $table->find('tbody > tr > td')->each(sub{
    my $e = shift;
    my $temperature = $e->all_text or croak "Can't get temperature (weekly)";
    my $weather = $e->at('img')->attrs('title') or croak "can't get weather (weekly)";
    $self->_add_weekly(Weather::TW::Forecast::Weekly->new(
      day => $week_day,
      temperature => $temperature,
      weather => $weather,
    ));
    # use add (days=>1) can avoid bug when passing a year
    $week_day->add(days=>1);
  }); # end of parsing weekly forecasts
  
  # start parsing monthly mean
  do {
    $title = shift @titles or croak "Can't get 月平均 in $url";
    $table = shift @tables;
  }until $title->all_text =~ qr|月平均|;
  my @monthly = $table->find('td')->each;
  $self->_set_monthly_mean({
    temp_high => $monthly[0]->text,
    temp_low => $monthly[1]->text,
    rain => $monthly[2]->text,
  });
  #end of parsing monthly mean

};


package Weather::TW::Forecast::ShortForecast;
use DateTime;
use Moose;
has start => qw|is ro isa DateTime|;
has end => qw|is ro isa DateTime|;
has temperature => qw|is ro isa Str|;
has weather => qw|is ro isa Str|;
has confortable => qw|is ro isa Str|;
has rain => qw|is ro isa Int|;

package Weather::TW::Forecast::Weekly;
use DateTime;
use Moose;
has day => qw|is ro isa DateTime|;
has temperature => qw|is ro isa Str|;
has weather => qw|is ro isa Str|;


1;
__END__
