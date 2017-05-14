#!/usr/bin/env perl
# import translations from rails i18n project

use strict;
use warnings;
use utf8;
use YAML::Syck;
use JSON::PP;
use File::Find;
use FindBin;
use Cwd;

sub convert_one_locale {
    my ($code, $input_file, $output_file) = @_;

    my $dict = YAML::Syck::LoadFile($input_file)->{$code}{datetime}{distance_in_words};

    print "Processing $File::Find::name\n";
    my %lexicon = (
        "less then a minute" => $dict->{less_than_x_minutes}{one},
        "1 minute"           => $dict->{x_minutes}{one},
        "%1 minutes"         => $dict->{x_minutes}{other},
        "about 1 hour"       => $dict->{about_x_hours}{one},
        "%1 hours"           => $dict->{about_x_hours}{other},
        "one day"            => $dict->{x_days}{one},
        "%1 days"            => $dict->{x_days}{other},
        "over a year"        => $dict->{over_x_years}{one},
    );

    for my $k (keys %lexicon) {
        $lexicon{$k} =~ s/%\{count\}/%1/g;
    }

    my $j = JSON::PP->new;
    open(my $fh, ">", $output_file) or die "$output_file: $!";
    print $fh $j->encode(\%lexicon) . "\n";
    close $fh;
}

my $rails1i8n_dir = shift @ARGV or die;
my $out_i18n_dir = "$FindBin::Bin/../lib/Time/Verbal/i18n";

my $cwd = Cwd::getcwd();

find sub {
    /([^\/]+)\.yml/ or return;

    my $code = $1;
    my $output_file =  "$out_i18n_dir/$code.json";

    eval {
        convert_one_locale($code, $File::Find::name, $output_file);
        1;
    } or do {
        print STDERR "Failed to convert: $File::Find::name => $output_file: $@\n";
    };
}, "${rails1i8n_dir}/rails/locale";
