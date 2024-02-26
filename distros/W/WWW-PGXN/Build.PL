use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
    class => 'PGXN::Build',
    code => q{
        sub valid_licenses { { postgresql => 'PostgreSQL' } }
        sub ACTION_tarball_name { print shift->dist_dir . ".tar.gz\n" }
        sub ACTION_latest_changes {
            my $self = shift;
            (my $dv = $self->dist_version) =~ s/^v//;
            open my $in, '<:raw', 'Changes' or die "Cannot open Changes: $!\n";
            open my $out, '>:raw', 'latest_changes.md' or die "Cannot open latest_changes.md: $!\n";
            while (<$in>) { last if /^\Q$dv\E\b/ }
            print {$out} "Changes for v$dv\n";
            while (<$in>) {
                last if /^\s*$/;
                chomp;
                if (s/^\s+-/-  /) {
                    print {$out} "\n";
                } else {
                    s/^\s+/ /;
                }
                print {$out} $_;
            }
            $self->add_to_cleanup('latest_changes.md');
        }
    },
);

$class->new(
    module_name        => 'WWW::PGXN',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    configure_requires => { 'Module::Build' => '0.4209' },
    test_requires      => {
        'File::Spec::Functions' => 0,
        'Test::MockModule'      => '0.05',
        'Test::More'            => '0.96',
    },
    requires => {
        'Carp'          => 0,
        'File::Spec'    => 0,
        'HTTP::Tiny'    => 0,
        'JSON'          => 0,
        'perl'          => 5.010,
        'URI::Template' => '0.16',
    },
    meta_merge => {
        'meta-spec' => { version => 2 },
        resources => {
            homepage   => 'https://metacpan.org/dist/WWW-PGXN',
            bugtracker => 'https://github.com/pgxn/www-pgxn/issues/',
            repository => 'https://github.com/pgxn/www-pgxn',
        },
        prereqs => {
            develop => {
                requires => {
                    'Test::Pod'           => '1.41',
                    'Test::Pod::Coverage' => '1.06',
                    'Test::Spelling'      => '0.25',
                },
            },
        },
    },
)->create_build_script;
