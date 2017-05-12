package Zucchini::TestConfig;
# vim: ts=8 sts=4 et sw=4 sr sta
use Moose; # automatically turns on strict and warnings

use FindBin;
use Path::Class;
use File::Temp qw(tempdir);
use Zucchini::Config;

# class data
has testdir => (
    reader  => 'get_testdir',
    writer  => 'set_testdir',
    isa     => 'Str',
);
has templatedir => (
    reader  => 'get_templatedir',
    writer  => 'set_templatedir',
    isa     => 'Path::Class::Dir',
    default => sub {
        dir(
            $FindBin::Bin,
            'testdata',
            'templates'
        )
    },
);
has includedir => (
    reader  => 'get_includedir',
    writer  => 'set_includedir',
    isa     => 'Path::Class::Dir',
    default => sub {
        dir(
            $FindBin::Bin,
            'testdata',
            'includes'
        )
    },
);
has outputdir => (
    reader  => 'get_outputdir',
    writer  => 'set_outputdir',
    isa     => 'Str',
    default => sub {
        tempdir( CLEANUP => 1 )
    },
);
has rsyncpath => (
    reader  => 'get_rsyncpath',
    writer  => 'set_rsyncpath',
    isa     => 'Str',
    default => sub {
        tempdir( CLEANUP => 1 )
    },
);
has config => (
    reader  => 'get_config',
    writer  => 'set_config',
    isa     => 'Zucchini::Config',
);

sub BUILD {
    my ( $self, $arg_ref ) = @_;
    my ( $zcfg );

    # create a new config object
    $zcfg = Zucchini::Config->new(
        {
            config_data => $self->site_config,
        }
    );
    $self->set_config($zcfg);

    return;
}

sub site_config {
    my $self = shift;

    my $test_config = {
        default_site => 'testdata',
        site => {
            'testdata' => {
                ignore_dirs     => ["CVS", ".svn", "tmp"],
                ignore_files    => ["\\.swp\\z"],
                includes_dir    => "XXWILLBEOVERRIDDENXX",
                output_dir      => "XXWILLBEOVERRIDDENXX",
                source_dir      => "XXWILLBEOVERRIDDENXX",
                template_files  => "\\.html\\z",
                website         => "http://www.chizography.net/",

                ftp => {
                    hostname  => "localhost",
                    passive   => 1,
                    password  => "sekrit",
                    path      => "/somewhere/",
                    username  => "ftpuser",
                },
                __ftp_ignore_dirs => [
                    "CVS",
                    ".svn",
                    "tmp",
                ],

                rsync => {
                    hostname    => "localhost",
                    path        => "XXWILLBEOVERRIDDENXX",
                },

                tags => {
                    author      => "Chisel Wright",
                    copyright   => "&copy; 2006-2008 Chisel Wright. All rights reserved.",
                    email       => "c&#104;isel&#64;chizography.net",
                },
            },
            'second_site' => {
                source_dir      => 'XXWILLBEOVERRIDDENXX',
                includes_dir    => 'XXWILLBEOVERRIDDENXX',
                output_dir      => 'XXWILLBEOVERRIDDENXX',
                template_files  => "\\.html\\z",
                ignore_dirs     => ["CVS", ".svn", "tmp"],
                ignore_files    => ["\\.swp\\z"],
                tags => {
                    author      => "Chisel Wright",
                    copyright   => "&copy; 2006-2008 Chisel Wright. All rights reserved.",
                    email       => "c&#104;isel&#64;chizography.net",
                },
            },
            'ttoption_site' => {
                source_dir      => 'XXWILLBEOVERRIDDENXX',
                includes_dir    => 'XXWILLBEOVERRIDDENXX',
                output_dir      => 'XXWILLBEOVERRIDDENXX',
                template_files  => "\\.html\\z",
                ignore_dirs     => ["CVS", ".svn", "tmp"],
                ignore_files    => ["\\.swp\\z"],
                tags => {
                    author      => "Chisel Wright",
                    copyright   => "&copy; 2006-2008 Chisel Wright. All rights reserved.",
                    email       => "c&#104;isel&#64;chizography.net",
                },

                tt_options => {
                    PRE_PROCESS     => 'my_header',
                    POST_PROCESS    => 'my_footer',
                    EVAL_PERL       => 1,
                },
            },
            impressum => {
                ignore_dirs     => ["CVS", ".svn", "tmp"],
                ignore_files    => ["\\.swp\\z"],
                includes_dir    => "XXWILLBEOVERRIDDENXX",
                output_dir      => "XXWILLBEOVERRIDDENXX",
                source_dir      => "XXWILLBEOVERRIDDENXX",
                template_files  => [
                    "\\.html\\z",
                    "\\.imp\\z",
                ],

                tags => { },

                always_process  => [
                    q{impressum.html},
                    q{\\.imp},
                ],
            },
        },
    };

    # override some values (because they're dynamic in some way)
    foreach my $site (keys %{ $test_config->{site} }) {
        my $site_data = $test_config->{site}{$site};
        $site_data->{includes_dir}    = $self->get_includedir;
        $site_data->{source_dir}      = $self->get_templatedir;
        $site_data->{output_dir}      = $self->get_outputdir;
        $site_data->{rsync}{path}     = $self->get_rsyncpath;
    }

    return $test_config;
}

sub site_config_with_cli_defaults {
    my $self = shift;

    # get the test config
    my $test_config = $self->site_config;

    # add the defaults
    $test_config->{cli_defaults} = {
        site    => 'second_site',
    };

    return $test_config;
}

1;

__END__
