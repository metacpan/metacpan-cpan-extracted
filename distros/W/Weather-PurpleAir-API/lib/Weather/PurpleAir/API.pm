package Weather::PurpleAir::API;

## ABSTRACT: Client for using the purpleair.com air quality sensor API

use strict;
use warnings;
use v5.10.0;  # provides "say" and "state"

use JSON::MaybeXS;
use File::Valet;
use HTTP::Tiny;
use Time::HiRes;
use String::Similarity qw(similarity);

our $VERSION = '0.07';

# Litchfield  38887 38888   City of Santa Rosa Laguna Treatment Plant 22961 22962    Geek Orchard 26363 26364

=head1 NAME

Weather::PurpleAir::API -- Client interface to Purple Air air quality API

=head1 SYNOPSIS

  use Weather::PurpleAir::API;
  use Data::Dumper;

  my $api = Weather::PurpleAir::API->new();
  my @sensors = qw(38887 22961 26363);
  my $report = $api->report(\@sensors);
  for my $sensor_name (keys %$report) {
    print join("\t", ($sensor_name, @{$report->{$sensor_name}})), "\n";
  }

=head1 DESCRIPTION

C<Weather::PurpleAir::API> provides a convenient interface to the Purple Air air quality API.  It will 
pull down data for specified sensors, transform them as desired (for instance, converting from raw 
PM2.5 concentration to USA EPA AQI number, averaging results from dual-sensor nodes, etc) and provide 
a concise report by sensor name.

The Purple Air map of sensors is located at L<https://www.purpleair.com/map>.

This module is very much a work in progress and 0.x releases might not be suitable for use.

For a simple commandline script wrapping this module, see C<bin/aqi> in this package.

Please do not poll sensors too frequently or the Purple Air server might block your IP.

=head1 PACKAGE ATTRIBUTES

=over 4

=item C<$Weather::PurpleAir::API::VERSION> (string)

The version number of this package (#.## format).

=back

=head1 OBJECT ATTRIBUTES

=over 4

=item C<sensor_hr> (hashref)

Keys on sensor ID numbers, maps to sensor names.

It is empty until the C<report()> method is called.

=item C<name_hr> (hashref)

Keys on sensor names, maps to sensor ID numbers.

It is empty until the C<report()> method is called.

=item C<ok> (string)

Indicates status of most recent operation: "OK", "WARNING" or "ERROR".

=over 4

* "OK" means everything completed as expected.

* "WARNING" means everything completed and possibly-useful data was returned, but something suspicious happened.

* "ERROR" means something went horribly wrong and the operation was unable to complete.

=back

=item C<err> (string or arrayref)

Set by WARNING and ERROR conditions, describes details of what went wrong.

=item C<n_err> (integer)

Incremented every time an error occurs.

=item C<n_warn> (integer)

Incremented every time a warning occurs.

=item C<ex> (exception or exception string)

Set to $@ when an exception is caught (for instance, when a JSON string does not decode).

=item C<js_or> (C<JSON::MaybeXS> object reference)

Contains a reference to the JSON decoder object used internally.  May be overridden by the user when different behavior is desired.  The default instance has parameters C<ascii =E<gt> 1, allow_nonref =E<gt> 1, space_after =E<gt> 1>.

=back

=head1 METHODS

All functionality is available via a C<Weather::PurpleAir::API> object.  Start with C<new> and 
use the resulting object to generate reports.  Additional functionality (like finding sensors 
by name, or finding sensors near locations) will come in future releases.

=head2 C<new(%options)>

Instantiates and returns a C<Weather::PurpleAir::API> object.  Options passed here may be overridden 
by passing options to methods of the object.

All options have hopefully-sane defaults:

=over 4

=item C<api_url> =E<gt> string

Override the URL at which the API is queried.  Useful for testing, or if you have your own server.

Default is "https://www.purpleair.com/json?show=", to which the sensor ID is appended by the C<sensor_url> method.

=item C<average> =E<gt> 0 or 1

Averages AQI metrics from a node's sensors instead of returning the AQI metrics from each sensor in a node.

Default is 0 (do not average).

=item C<d> =E<gt> 0 or 1

Activate debugging logic, which will print horribly confusing things to STDOUT.  Default is 0 (off).

=item C<g> =E<gt> 0 or 1

Indicate that reports should include a "GUESSING" entry, providing a pruned average of all results from all sensors. In future releases it might incorporate other heuristics (like using older cached values when bad metrics are detected).

The format of this entry is a little different from the sensor entries.  Instead of $report->{GUESSING} referring 
to an array of AQI metrics, it refers to an array containing the guessed gestalt AQI metric and its standard 
deviation (a measure of statistical skew).  The higher the standard deviation, the lower the confidence you 
should have in the guessed metric.

For example:

    { GUESSING => [123.45, 1.09] }  # AQI is 123.45, with high confidence
    { GUESSING => [123.45, 10.3] }  # AQI is 123.45, with somewhat less confidence
    { GUESSING => [123.45, 67.5] }  # AQI is 123.45, with very low confidence!

Default is 0 (do not guess).

=item C<http_or> =E<gt> HTTP::Tiny object

Provide the C<HTTP::Tiny> instance used to query the API.  This is useful when you need to customize the query timeout, set a user agent string or specify an https proxy.

Default is undef (an C<HTTP::Tiny> object will be instantiated internally).

=item C<no_errors> =E<gt> 0 or 1

Set this to suppress writing error messages to stderr.  Default is 0 (errors will be displayed).

=item C<no_warnings> =E<gt> 0 or 1

Set this to suppress writing warning messages to stderr.  Default is 0 (warnings will be displayed).

=item C<now> =E<gt> 0 or 1

Normally reports will use the ten-minute average AQI from each sensor.  Specify C<now> to use the current AQI instead.

Default is 0 (report will use ten-minute average AQI metrics).

=item C<prune_threshold> =E<gt> fraction between 0 and 1

When the C<g> (GUESSING) option is set, the guessing heuristic may prune more then one high and one low outlier 
from the sensor data, if doing so will leave sufficient data left over for meaningful averaging.  The prune 
threshold determines how close to an outlier other data points must be, as a fraction of the outlier value, for 
them to be pruned as well.

For instance, if C<prune_threshold> = 0.1 (10%) and the high outlier is 90, then 90 * 0.1 = 9, so data points 
which are 81 or higher might also be pruned.  If C<prune_threshold> = 0.05 (5%) and the high outlier is 90, 
90 * 0.05 = 4.5, so data points which are 85.5 or higher might be pruned, etc.

Default is 0.1 (10%).

=item C<q> =E<gt> 0 or 1

"C<q>" is for "quiet".  Setting this is equivalent to setting C<no_errors> and C<no_warnings>.

Default is 0.

=item C<raw> =E<gt> 0 or 1

When set, C<report> will not convert the API's raw concentration numbers to USA EPA PM2.5 AQI scores (the 
metric displayed on the Purple Air website map).  Part-per-million concentrations of 2.5 micrometer diameter 
particles will be provided instead.

Default is 0 (concentrations will be converted to USA EPA PM2.5 AQI scores).

=item C<sensor> =E<gt> ID-number

=item C<sensor> =E<gt> [ID-number, ID-number, ...]

=item C<sensor> =E<gt> "ID-number ID-number ..."

Normally sensor IDs are passed to the C<report> method, but a default sensor or sensors can also be given 
to C<new> at object instantiation time.

Right now C<Weather::PurpleAir::API> can only work with numeric sensor IDs and there isn't a really good 
way to find the IDs of sensors.  If you point a browser at the Purple Air map, some browsers will expose 
the IDs of specific sensors and others will not.

If you download the all-sensors blob (either from the API at L<https://www.purpleair.com/json> or the
cached blob at L<http://ciar.org/h/sensors.all.json>) you can pick through the list and find IDs of
sensors of interest, which is a pain in the ass.

Future releases of C<Weather::PurpleAir::API> will support functions for finding sensors near a location, 
but this one doesn't, which is one of the reasons it's a 0.x release.

Some example sensors and their IDs:

    25407   Gravenstein School
    38887   Litchfield
    22961   City Of Santa Rosa Laguna Treatment Plant
    26363   Geek Orchard

The default is 25407 (Gravenstein School, in Sonoma County, California)

=item C<stash_path> =E<gt> path string

When a C<stash_path> is provided, C<report> will store a copy of each sensor's JSON blob in the 
specified directory, under the name C<aqi.$sensor_id.json>.

For example, if C<stash_path> = "/tmp" and C<sensor> = 25407, the JSON blob will be stored in file
"/tmp/aqi.25407.json".

The default is undef (not set, will not stash).

=item C<v> =E<gt> 0 or 1

"C<v>" is for verbosity.  When set, the reported-upon sensors (and gestalt guess, when C<g> parameter is 
set) will be printed to stdout.  This is normally set by the C<bin/aqi> utility.

Future releases might implement higher verbosity levels.

The default is 0 (do not print to stdout).

=back

=cut

sub new {
    my ($class, %opt_hr) = @_;
    my $self = {
        opt_hr   => \%opt_hr,
        ok       => 'OK',
        ex       => undef,  # stash caught exceptions here
        n_err    => 0,
        n_warn   => 0,
        err      => '',
        err_ar   => [],
        js_or    => JSON::MaybeXS->new(ascii => 1, allow_nonref => 1, space_after => 1),
        sensor_hr=> {},
        name_hr  => {},
    };
    bless ($self, $class);

    # convert keys of form "some-parameter" to "some_parameter":
    foreach my $k0 (keys %{$self->{opt_hr}}) {
        my $k1 = join('_', split(/-/, $k0));
        next if ($k0 eq $k1);
        $self->{opt_hr}->{$k1} = $self->{opt_hr}->{$k0};
        delete $self->{opt_hr}->{$k0};
    }

    return $self;
}

sub safely_to_json {
    my ($self, $r) = @_;
    my $js = eval { $self->{js_or}->encode($r); };
    $self->{ex} = $@ unless(defined($js));
    return $js;
}

sub safely_from_json {
    my ($self, $js) = @_;
    my $r = eval { $self->{js_or}->decode($js); };
    return $r if (defined $r);
    $self->{ex} = $@;
    $self->err("JSON decode failed", $@);
    return;
}

sub most_similar {
  my ($self, $thing, $ar, $opt_hr) = @_;
  my $best_match = '';
  my $best_score = $self->opt('min_score', 0, $opt_hr);
  for my $x (@$ar) {
    my $score = similarity($thing, $x);
    next unless($score >= $best_score);
    $best_score = $score;
    $best_match = $x;
  }
  return ($best_match, $best_score) if ($self->opt('best_match_and_score', 0, $opt_hr)); # for testing, mostly
  return $best_match;
}

sub opt {
    my ($self, $name, $default_value, $alt_hr) = @_;
    $alt_hr //= {};
    return $self->{opt_hr}->{$name} // $self->{conf_hr}->{$name} // $alt_hr->{$name} // $default_value;
}

# approximates python's "in" operator, because ~~ is unsane:
sub in {
    my $v = shift @_;
    return 0 unless (@_ && defined($_[0]));
    if (ref($_[0]) eq 'ARRAY') {
        foreach my $x (@{$_[0]}) { return 1 if defined($x) && $x eq $v; }
    } else {
        foreach my $x (@_) { return 1 if defined($x) && $x eq $v; }
    }
    return 0;
}

sub ok {
    my $self = shift(@_);
    $self->all_is_well();
    return ('OK', @_);
}

sub err {
    my $self = shift(@_);
    $self->{ok} = "ERROR";
    $self->{err} = [@_];
    $self->shout("ERROR", @_) unless ($self->opt('q') || $self->opt('no_errors'));
    $self->{n_err}++;
    return ('ERROR', @_);
}

sub warn {
    my $self = shift(@_);
    $self->{ok} = "WARNING";
    $self->{err} = [@_];
    $self->shout("WARNING", @_) unless ($self->opt('q') || $self->opt('no_warnings'));
    $self->{n_warn}++;
    return ('WARNING', @_);
}

sub shout {
  my $self = shift(@_);
  my $msg = join("\t", @_);
  print STDERR $msg, "\n";
  return;
}

sub all_is_well {
    my ($self) = @_;
    $self->{ok}  = 'OK';
    $self->{ex}  = undef;
    $self->{err} = '';
    $self->{err_ar} = [];
    return;
}

sub sensors {
  my ($self, $sensor_string, $opt_hr) = @_;
  $opt_hr //= {};
  my $sensor_list = $sensor_string // $self->opt('s', $self->opt('sensor', 25407, $opt_hr), $opt_hr);
  return $sensor_list if (ref $sensor_list eq 'ARRAY');
  return [split(/[^\d]+/, $sensor_list)];
}

sub sensor_url {
  my ($self, $sensor_id, $opt_hr) = @_;
  my $api_url = $self->opt('api_url', "https://www.purpleair.com/json?show=", $opt_hr);
  my $url = "$api_url$sensor_id";
  return $url
}

=head2 C<report()>

=head2 C<report([sensor-id, sensor-id, ...])>

=head2 C<report([sensor-id, sensor-id, ...], {option =E<gt> value, ...})>

=over 4

The C<report> method retrieves current data from each specified sensor and returns a hashref with
sensor name keys and arrayref values.  The values represent the air quality at the sensor's location 
(where higher values = more gunk in the air).  Higher than 50 is bad, lower than 20 is good.

If no list of sensor IDs is used, and no list was provided to C<new(sensor =E<gt> ...)> a default of 
25407 (Gravenstein School) will be used, which probably is not very useful to you.

See the notes under C<sensor> in the section for C<new> regarding sensor IDs and how to find them.

C<report> optionally accepts a hashref options, which are the same as those documented for C<new>.

Returns C<undef> on error and sets the object's C<ok> and C<err> attributes.

Returns a hashref as described on success and sets the object's C<ok> and C<err> attributes to "OK" and "" respectively.

=back

=cut

sub report {
  my ($self, $sensors, $opt_hr) = @_;
  $self->ok();
  $opt_hr //= $opt_hr;

  my $report_hr = $self->gather_sensors($sensors, $opt_hr);
  
  my ($best_guess_aqi, $guess_deviation) = (0, 0);
  if ($self->opt('g', 0, $opt_hr)) {
    ($best_guess_aqi, $guess_deviation) = $self->guess_best_aqi($report_hr, $opt_hr);

    my ($p_best, $p_dev) = ($best_guess_aqi, $guess_deviation);
    ($p_best, $p_dev) = (int($p_best+0.5), int($p_dev+0.5)) if ($self->opt('i', 0, $opt_hr));
    
    print "GUESSING\t$p_best\t$p_dev\n" if($self->opt('v', 0, $opt_hr));
    $report_hr->{GUESSING} = [$best_guess_aqi];
  }

  return ($report_hr, $guess_deviation);
}

=head2 C<concentration_to_epa($concentration)>

This method implements the official USA EPA guideline for converting PM2.5 
concentration to AQI, per 
L<https://www.airnow.gov/sites/default/files/2020-05/aqi-technical-assistance-document-sept2018.pdf>.

The sensors do not report AQI metrics, only raw concentrations, so conversion 
is necessary.  The C<report> method does this automatically (unless the C<raw> 
option is set).

The official equation is a dumb-ass piecewise function of linear interpolations, 
but nobody ever said government was smart.

Takes a PM2.5 concentration as input, returns an AQI metric as output.  The EPA 
guideline asserts that the AQI must be truncated to a whole integer.  I leave 
that as an exercise for the programmer.

=cut

sub concentration_to_epa {
  my ($self, $conc, $opt_hr) = @_;
  # ref: https://www3.epa.gov/airnow/aqi-technical-assistance-document-sept2018.pdf
  return $conc if ($conc > 500.0 || $conc < 0.05);
  my ($Ihi, $Ilo, $BPhi, $BPlo);
  if    ($conc <=  12.0) { ($Ihi, $Ilo, $BPhi, $BPlo) = ( 50,   0,  12.0,   0.0); }
  elsif ($conc <=  35.4) { ($Ihi, $Ilo, $BPhi, $BPlo) = (100,  51,  35.4,  12.0); }
  elsif ($conc <=  55.4) { ($Ihi, $Ilo, $BPhi, $BPlo) = (150, 101,  55.4,  35.5); }
  elsif ($conc <= 150.4) { ($Ihi, $Ilo, $BPhi, $BPlo) = (200, 151, 150.4,  55.5); }
  elsif ($conc <= 250.4) { ($Ihi, $Ilo, $BPhi, $BPlo) = (300, 201, 250.4, 150.5); }
  elsif ($conc <= 350.4) { ($Ihi, $Ilo, $BPhi, $BPlo) = (400, 301, 350.4, 250.5); }
  else                   { ($Ihi, $Ilo, $BPhi, $BPlo) = (500, 401, 500.4, 350.4); }
  my $epa = ($Ihi - $Ilo) * ($conc - $BPlo) / ($BPhi - $BPlo) + $Ilo;
  return $epa;
}

sub gather_sensors {
  my ($self, $sensors, $opt_hr) = @_;
  my $report_hr = {};
  my $http_or = $self->opt('http_or', undef, $opt_hr) // HTTP::Tiny->new();

  $self->ok();
  $sensors = $self->sensors($sensors, $opt_hr) unless (defined $sensors && ref $sensors eq "ARRAY");

  for my $sensor (@$sensors) {
    my $hr = $self->fetch_aqi($http_or, $sensor, $opt_hr);
    next unless(defined $hr);

    my ($name, $aqi_ar) = (undef, []);
    for my $results_hr (@{$hr->{results} // []}) {
      $name //= $results_hr->{Label};
      my $aqi = $results_hr->{pm2_5_atm};
      unless ($self->opt('now', 0, $opt_hr)) {
        my $stats_hr = $self->safely_from_json($results_hr->{Stats});
        if (defined $stats_hr) {
          $aqi = $stats_hr->{v1};  # ten-minute average
        } else {
          $self->warn("unable to parse ten-minute average, using current value");
        }
      }
      
      $aqi = $self->concentration_to_epa($aqi, $opt_hr) unless ($self->opt('raw', 0, $opt_hr)); # approx conversion from raw concentration to US EPA PM2.5
      push @{$aqi_ar}, $aqi if (defined $aqi);
    }

    $name //= $sensor;
    $self->{sensor_hr}->{$sensor} = $name;
    $self->{name_hr}->{$name} = $sensor;
    $report_hr->{$name} = $aqi_ar if (@$aqi_ar > 0);

    my $aqi = $self->aqi_calculate($aqi_ar, $opt_hr);

    if ($self->opt('v', 0, $opt_hr) && @$aqi_ar) {
      my @p_aqi = @$aqi;
      @p_aqi = map { int($_+0.5) } @p_aqi if ($self->opt('i', 0, $opt_hr));
      my $s_aqi = join("\t", @p_aqi);
      print "$name\t$s_aqi\n"
    }
  }

  return $report_hr;
}

sub fetch_aqi {
  my ($self, $http_or, $sensor, $opt_hr) = @_;
  my $stash_path = $self->opt('stash_path', undef, $opt_hr);
  my $url = $self->sensor_url($sensor, $opt_hr);
  my $resp = $http_or->get($url);
  my $hr;
  if ($resp->{success}) {
    my $js = $resp->{content};
    wr_f("$stash_path/aqi.$sensor.json", $js) if (defined $stash_path);
    $hr = $self->safely_from_json($js);
  } else {
    $self->err($resp->{status}, $resp->{reason});
  }
  return $hr;
}

sub aqi_calculate {
  my ($self, $aqi_ar, $opt_hr) = @_;
  my $aqi = 0;
  if ($self->opt('average', 0, $opt_hr)) {
    $aqi += $_ for(@$aqi_ar);
    $aqi /= @$aqi_ar;
    $aqi = [$aqi];
  } else {
    $aqi = $aqi_ar;
  }
  return $aqi;
}

sub guess_best_aqi {
  my ($self, $report_hr, $opt_hr) = @_;
  my $average = 0;
  my $deviation = 0;
  my $n_values  = 0;
  my $n_sensors = keys %$report_hr;
  my %hi = (sensor => undef, result => 0, ppm => 0);
  my %lo = (sensor => undef, result => 0, ppm => 1000000);
  my @v_list;  # superfluous, but simplifies stddev logic

  for my $k (keys %$report_hr) {
    my $ar = $report_hr->{$k};
    $n_values += @$ar;
    for my $ix (0..$#$ar) {
      my $ppm = $ar->[$ix];
      $average += $ppm;
      push @v_list, $ppm;
      %hi = (sensor => $k, result => $ix, ppm => $ppm) if ($ppm > $hi{ppm});
      %lo = (sensor => $k, result => $ix, ppm => $ppm) if ($ppm < $lo{ppm});
    }
  }

  # prune outliers if it will leave us with sufficient data for meaningful results
  my $have_pruned = 0;

  # first the high reading(s)
  if ($hi{sensor} && ($n_sensors + $n_values) > 3) {
    print "DEBUG\tpruning high outliers n_sensors=$n_sensors n_values=$n_values\n" if ($self->opt('d', 0, $opt_hr));
    my $ar = $report_hr->{$hi{sensor}};
    my $high_ppm = $hi{ppm};
    if ($n_sensors > 2) {
      # potentially prune out all results from this sensor
      for my $ppm (@$ar) {
        next unless(abs($ppm - $high_ppm) < $high_ppm * $self->opt('prune_threshold', 0.1, $opt_hr));
        print "DEBUG\tpruning high value $ppm\n" if ($self->opt('d', 0, $opt_hr));
        $average -= $ppm;
        $n_values--;
        $have_pruned++;
      }
    } else {
      # just prune the sensor's highest ppm
      print "DEBUG\tpruning highest value $high_ppm\n" if ($self->opt('d', 0, $opt_hr));
      $average -= $high_ppm;
      $n_values--;
      $have_pruned++;
    }
  }

  # now the low reading(s)
  my $prune_threshold = $have_pruned ? 2 : 3;
  if ($lo{sensor} && ($n_sensors + $n_values) > $prune_threshold) {
    print "DEBUG\tpruning low outliers n_sensors=$n_sensors n_values=$n_values\n" if ($self->opt('d', 0, $opt_hr));
    my $ar = $report_hr->{$lo{sensor}};
    my $low_ppm = $lo{ppm};
    if ($n_sensors > 2) {
      # potentially prune out all results from this sensor
      for my $ppm (@$ar) {
        # zzapp -- this might be unfair, since threshold for low ppm is intrinsically of smaller magnitude
        # maybe use different prune_threshold parameters for high and low?
        next unless(!$ppm || (abs($ppm - $low_ppm) < $low_ppm * $self->opt('prune_threshold', 0.1, $opt_hr)));
        print "DEBUG\tpruning low value $ppm\n" if ($self->opt('d', 0, $opt_hr));
        $average -= $ppm;
        $n_values--;
      }
    } else {
      # just prune the sensor's lowest ppm
      print "DEBUG\tpruning lowest value $low_ppm\n" if ($self->opt('d', 0, $opt_hr));
      $average -= $low_ppm;
      $n_values--;
    }
  }

  # calculate the average
  $n_values ||= 1;
  $average /= $n_values;

  # and now the standard deviation
  # zzapp -- this includes pruned values, and I'm not sure if that's a bug or a feature
  for my $v (@v_list) {
    my $square_diff = ($average - $v) ** 2;
    $deviation += $square_diff;
  }
  $deviation = ($deviation / @v_list) ** 0.5;

  return ($average, $deviation);
}

=head1 ABOUT RELIABILITY

The sensor readings are not always reliable.  A car starting or a person
smoking near the sensor can produce a false high reading.  Right now the
workaround is to specify multiple sensors and use the -g option.  Future
releases will provide alternative remedies.

=head1 AUTHOR

TTK Ciar, <ttk[at]ciar[dot]org>

=head1 COPYRIGHT AND LICENSE

Copyright 2020 by TTK Ciar

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 TO DO

Write more documentation.  Some methods are undocumented.

Write more unit tests.

Save some state and perform time averaging, perhaps throw out dramatic changes and reuse last known value.

Pull down and cache the all-sensors blob, implement relevant operations:

=over 4

* find sensors by name

* find sensors nearest a latitude/longitude, or near another sensor, maybe do some light GIS-fu

=back

=head1 HISTORY

This was originally a throw-away script that just yanked JSON from the API, parsed out the sensor name 
and first reading's PM2.5 concentration, and printed to stdout.

It was quickly apparent that this left something to be desired, so the script was refactored into this 
module and associated wrapper utility.

My friend Matt using the throw-away script made me feel embarrassed at its shortcomings, which provided 
some of the motivation to do better.

=head1 SEE ALSO

L<The PurpleAir Website|http://purpleair.com>

L<The PurpleAir API FAQ|https://github.com/bomeara/purpleairpy/blob/master/api.md> (stored in more convenient form by purpleairpy project)

L<Python API Client|https://github.com/ReagentX/purple_air_api> by ReagentX, providing a different approach to the interface.

L<Air Concentration to USA EPA PM2.5 AQI Calculator|https://aqicn.org/calculator/> an unfortunately crude tool corresponding PM2.5 concentration to the AQI metric.

L<USA EPA PM2.5 AQI Calculation Guidelines|https://www3.epa.gov/airnow/aqi-technical-assistance-document-sept2018.pdf>

=cut

1;
