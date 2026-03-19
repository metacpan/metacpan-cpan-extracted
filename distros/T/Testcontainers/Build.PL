use strict;
use warnings;
use Module::Build;

# Parse cpanfile to avoid duplicating dependency versions
my (%requires, %recommends, %test_requires);
my $current_phase = 'runtime';

if (open my $fh, '<', 'cpanfile') {
    while (my $line = <$fh>) {
        chomp $line;
        if ($line =~ /^on\s+'test'/) {
            $current_phase = 'test';
        } elsif ($line =~ /^on\s+'develop'/) {
            $current_phase = 'develop';
        } elsif ($line =~ /^\s*requires\s+'([^']+)'(?:\s*,\s*'([^']*)')?/) {
            my ($mod, $ver) = ($1, $2 // '0');
            if    ($current_phase eq 'runtime') { $requires{$mod} = $ver }
            elsif ($current_phase eq 'test')    { $test_requires{$mod} = $ver }
        } elsif ($line =~ /^\s*recommends\s+'([^']+)'(?:\s*,\s*'([^']*)')?/) {
            $recommends{$1} = $2 // '0';
        } elsif ($line =~ /^\};/) {
            $current_phase = 'runtime';
        }
    }
    close $fh;
} else {
    die "cpanfile not found in the distribution root; cannot determine dependencies.\n"
      . "Please ensure cpanfile exists before running perl Build.PL.\n";
}

my $perl_ver = delete $requires{'perl'};

my $builder = Module::Build->new(
    module_name        => 'Testcontainers',
    license            => 'perl',
    dist_author        => 'Testcontainers Contributors',
    dist_abstract      => 'Testcontainers for Perl - Docker containers for testing',
    dist_version_from  => 'lib/Testcontainers.pm',
    release_status     => 'stable',

    configure_requires => {
        'Module::Build' => '0.4004',
    },

    requires       => { ($perl_ver ? (perl => $perl_ver) : ()), %requires },
    recommends     => \%recommends,
    test_requires  => \%test_requires,

    meta_merge => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/testcontainers/testcontainers-perl5.git',
                web  => 'https://github.com/testcontainers/testcontainers-perl5',
            },
            bugtracker => {
                web => 'https://github.com/testcontainers/testcontainers-perl5/issues',
            },
        },
    },

    recursive_test_files => 1,
);

$builder->create_build_script;
