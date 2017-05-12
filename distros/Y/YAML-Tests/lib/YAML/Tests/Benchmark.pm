package YAML::Tests::Benchmark;
use strict;
use warnings;

use Storable;
use Benchmark;

sub run {
    my ($class, $yt_opts, $yaml_mods) = @_;

    my $options = $class->parse_options($yt_opts);

    my $default = 0;
    unless (@$yaml_mods) {
        @$yaml_mods = qw( YAML YAML::Syck YAML::LibYAML YAML::Tiny );
        $default = 1;
    }

    my @modules = grep {
        eval("require $_"); !$@
    } @$yaml_mods;

    my $reps = 16;
    my $n_runs = $options->{r};

    my %struct = (
       argh_hash   => { map { $_ => "Argh" } 0 .. $reps },
       argh_list  => [ map { "Argh" } 0 .. $reps ],
       argh_scalar => ("Argh" x 512)
      );

    my $current_struct = \%struct;
    my $current_frozen = Storable::nfreeze( $current_struct );

    my $current_yaml = do {
        no strict 'refs';
        &{"$modules[0]::Dump"}( $current_struct );
    };

#    if ($default || grep {$_ eq 'Storable'} @modules) {
        my %dump_methods = map {
            "dump " . $_ => eval("sub { ${_}::Dump( \$current_struct ) }")
        } @modules;

        my %load_methods = map {
            "load " . $_ => eval("sub { ${_}::Load( \$current_yaml ) }")
        } @modules;

        my %rt_methods = map {
            "rt " . $_ =>
                eval("sub { ${_}::Load( ${_}::Dump( \$current_struct ) ) }")
        } @modules;

        $dump_methods{'dump storable'} = sub {
            Storable::nfreeze( $current_struct );
        };

        $load_methods{'load storable'} = sub {
            Storable::thaw( $current_frozen );
        };

        $rt_methods{'rt storable'} = sub {
            Storable::thaw( Storable::nfreeze( $current_struct ));
        };
#    }

    Benchmark::cmpthese( $n_runs, $_ )
    for ( \%dump_methods, \%load_methods, \%rt_methods );
}

sub parse_options {
    my ($class, $yt_opts) = @_;
    my $options = {
        r => 1024 * 32,
    };
    for (@$yt_opts) {
        if (/^-r(\d+)$/) {
            $options->{r} = $1;
        }
    }
    return $options;
}

1;
