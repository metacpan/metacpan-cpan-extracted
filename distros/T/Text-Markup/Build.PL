use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
    class => 'My::Builder',
    code => q{
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

my $build = $class->new(
    module_name        => 'Text::Markup',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    configure_requires => { 'Module::Build' => '0.4209' },
    build_requires     => {
        'File::Spec::Functions' => 0,
        'Module::Build'         => '0.4209',
        'Test::More'            => '0.96',
    },
    requires => {
        'File::BOM'             => '0.14',
        'HTML::Entities'        => 0,
        'HTML::Tagset'          => 0, # Needed by Text::MediawikiFormat
        'IPC::Open3'            => 0,
        'perl'                  => 5.008001,
        'Pod::Simple::XHTML'    => '3.15',
        'Symbol'                => 0,
        'Text::Markdown'        => '1.000004',
        'Text::MultiMarkdown'   => '1.000028',
        'Text::MediawikiFormat' => '1.0',
        'Text::Textile'         => '2.10',
        'Text::Trac'            => '0.10',
        'Parse::BBCode'         => '0.15',
        'Text::WikiCreole'      => '0.07',
    },
    recommmends => {
        'CommonMark'            => '0.290000',
    },
    meta_merge => {
         "meta-spec" => { version => 2 },
        resources => {
            homepage   => 'https://metacpan.org/pod/Text::Markup',
            bugtracker => 'https://github.com/theory/text-markup/issues/',
            repository => 'https://github.com/theory/text-markup',
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
);
$build->add_build_element('py');
$build->create_build_script;
