#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;
use File::Copy;
use File::Path qw(make_path);
use File::Spec;
use Getopt::Long;
use YAML;

# Add lib paths
my $script_dir = dirname(__FILE__);
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use lib File::Spec->catdir(dirname(__FILE__), '..', 'Yote-SQLObjectStore', 'lib');

# Spiderpup lib path (sibling project)
my $sp_dir = File::Spec->catdir($script_dir, '..', 'spiderpup');
use lib File::Spec->catdir(dirname(__FILE__), '..', 'spiderpup', 'lib');

# --- Options ---
my $port      = $ENV{YAPI_PORT} || 5001;
my $data_dir  = '';
my $base_path = '';
my $watch_mode     = 0;
my $watch_interval = 5;

# Grab subcommand before Getopt parses
my $subcommand = '';
if (@ARGV && $ARGV[0] !~ /^-/) {
    $subcommand = shift @ARGV;
}

if ($subcommand eq 'compile') {
    my $config_file = '';
    GetOptions(
        'config=s' => \$config_file,
    ) or die "Usage: $0 compile [--config FILE] [<input> <output-dir>]\n";

    my $config = load_config($config_file);
    my ($input, $outdir) = @ARGV;

    # Fall back to config: yapi dir as input, lib path as output
    if ($config->{www_dir}) {
        $input  //= File::Spec->catdir($config->{www_dir}, 'yapi');
        $outdir //= $config->{lib_paths} ? $config->{lib_paths}[0] : undef;
    }
    die "Usage: $0 compile [--config FILE] [<input> <output-dir>]\n" unless $input && $outdir;

    require Yote::YapiServer::Compiler;
    Yote::YapiServer::Compiler::compile($input, $outdir);
}
elsif ($subcommand eq 'pages') {
    my $config_file = '';
    GetOptions(
        'config=s'    => \$config_file,
        'base-path=s' => \$base_path,
        'watch:i'     => sub { $watch_mode = 1; $watch_interval = $_[1] || 5 },
    ) or die "Usage: $0 pages [--config FILE] [--base-path PATH] [--watch [SECONDS]]\n";

    my $config = load_config($config_file);

    my $www_dir = $config->{spiderpup_dir}
                  // ($config->{www_dir} ? File::Spec->catdir($config->{www_dir}, 'spiderpup') : undef)
                  // File::Spec->catdir($sp_dir, 'www');
    my $webroot = $config->{webroot_dir};

    require Yote::Spiderpup;
    my $sp = Yote::Spiderpup->new(
        www_dir   => $www_dir,
        base_path => $base_path,
        ($webroot ? (webroot_dir => $webroot) : ()),
    );

    if ($watch_mode) {
        $sp->watch_and_compile($watch_interval);
    } else {
        $sp->compile_all;
    }
}
elsif ($subcommand eq 'init') {
    my $target = $ARGV[0] // '.';
    init_project($target);
}
elsif ($subcommand eq '') {
    my $config_file = '';
    my $port_given = 0;
    GetOptions(
        'config=s'    => \$config_file,
        'port=i'      => sub { $port = $_[1]; $port_given = 1 },
        'data-dir=s'  => \$data_dir,
        'watch:i'     => sub { $watch_mode = 1; $watch_interval = $_[1] || 5 },
    ) or die "Usage: $0 [--config FILE] [--port PORT] [--data-dir PATH] [--watch [SECONDS]]\n";

    my $config = load_config($config_file);

    # Config port used unless CLI --port was explicitly given
    $port = $config->{port} if $config->{port} && !$port_given;

    # Build db config: CLI --data-dir overrides config, which overrides default
    my $db = $config->{db} // {};
    $db->{type} //= 'SQLite';
    if ($data_dir) {
        # CLI --data-dir overrides config
        $db->{data_dir} = $data_dir;
    }
    $db->{data_dir} //= $ENV{DATA_DIR} // File::Spec->catdir($script_dir, 'data');

    # Add project lib paths from config to @INC
    my @project_libs;
    if ($config->{lib_paths}) {
        for my $lp (@{$config->{lib_paths}}) {
            my $abs = File::Spec->rel2abs($lp);
            push @project_libs, $abs;
            unshift @INC, $abs;
        }
    }

    # Pidfile: stop any existing server on the same port before starting
    my $pidfile = File::Spec->catfile(File::Spec->tmpdir(), "yapi-${port}.pid");
    stop_existing_server($pidfile);
    write_pidfile($pidfile);

    # Clean up pidfile on exit
    $SIG{TERM} = sub { unlink $pidfile; exit 0 };
    $SIG{INT}  = sub { unlink $pidfile; exit 0 };
    END { unlink $pidfile if defined $pidfile && -f $pidfile && ($$ == (read_pidfile($pidfile) // 0)) }

    require Yote::YapiServer;

    my $server = Yote::YapiServer->new(
        port          => $port,
        db            => $db,
        root_package  => $config->{root_package},
        max_file_size => $config->{max_file_size},
        webroot_dir   => $config->{webroot_dir},
        debug         => ($config->{mode} // '') eq 'debug',
        lib_paths     => [
            File::Spec->catdir($script_dir, 'lib'),
            @project_libs,
        ],
    );
    # Fork spiderpup watcher if --watch was given
    my $watcher_pid;
    if ($watch_mode) {
        my $www_dir    = $config->{www_dir};
        my $webroot    = $config->{webroot_dir};
        my $pup_dir    = $config->{spiderpup_dir}
                         // ($www_dir ? File::Spec->catdir($www_dir, 'spiderpup') : undef);

        if ($pup_dir && $webroot && -d $pup_dir) {
            $watcher_pid = fork();
            if (!defined $watcher_pid) {
                warn "Could not fork spiderpup watcher: $!\n";
            } elsif ($watcher_pid == 0) {
                # Child: run spiderpup watch
                require Yote::Spiderpup;
                my $sp = Yote::Spiderpup->new(
                    www_dir     => $pup_dir,
                    webroot_dir => $webroot,
                );
                print "Spiderpup watcher started (every ${watch_interval}s) on $pup_dir\n";
                $sp->watch_and_compile($watch_interval);
                exit 0;
            }
            # Parent: clean up watcher on exit
            my $orig_term = $SIG{TERM};
            my $orig_int  = $SIG{INT};
            $SIG{TERM} = sub { kill 'TERM', $watcher_pid; $orig_term->() };
            $SIG{INT}  = sub { kill 'TERM', $watcher_pid; $orig_int->()  };
        } else {
            warn "Warning: --watch requires www_dir and webroot_dir in config (spiderpup dir: "
                . ($pup_dir // 'not set') . ")\n";
        }
    }

    print "Yapi server starting on port $port (pidfile: $pidfile)\n";
    $server->run;
}
else {
    die "Unknown subcommand '$subcommand'.\nUsage: $0 [init|compile|pages] [OPTIONS]\n";
}

sub load_config {
    my ($config_file) = @_;
    my $explicit = $config_file && $config_file ne '';
    $config_file ||= 'config/yapi.yaml' if -f 'config/yapi.yaml';
    my $config = {};
    if ($config_file) {
        die "Config file not found: $config_file\n" if $explicit && ! -f $config_file;
        if (-f $config_file) {
            $config = YAML::LoadFile($config_file);
            print "Loaded config from $config_file\n";
        }
    }
    return $config;
}

sub read_pidfile {
    my ($pidfile) = @_;
    return unless -f $pidfile;
    open my $fh, '<', $pidfile or return;
    my $pid = <$fh>;
    close $fh;
    chomp $pid if defined $pid;
    return ($pid && $pid =~ /^\d+$/) ? $pid : undef;
}

sub write_pidfile {
    my ($pidfile) = @_;
    open my $fh, '>', $pidfile or die "Cannot write pidfile $pidfile: $!\n";
    print $fh $$;
    close $fh;
}

sub stop_existing_server {
    my ($pidfile) = @_;
    my $old_pid = read_pidfile($pidfile);
    return unless $old_pid;

    # Check if process is still running
    if (kill 0, $old_pid) {
        print "Stopping existing yapi server (PID $old_pid)...\n";
        kill 'TERM', $old_pid;

        # Wait up to 5 seconds for it to exit
        for (1..10) {
            last unless kill 0, $old_pid;
            select(undef, undef, undef, 0.5);
        }

        if (kill 0, $old_pid) {
            warn "Warning: old server (PID $old_pid) did not stop, sending KILL\n";
            kill 'KILL', $old_pid;
            select(undef, undef, undef, 0.5);
        }

        print "Previous server stopped.\n";
    }

    unlink $pidfile;
}

sub init_project {
    my ($target) = @_;

    if (-e $target && !-d $target) {
        die "Error: '$target' exists and is not a directory\n";
    }

    my @dirs = qw(
        config
        data
        webroot
        webroot/js
        lib
        spiderpup/pages
        spiderpup/recipes
        yapi
        yapi/apps
        yapi/modules
    );

    for my $dir (@dirs) {
        my $path = File::Spec->catdir($target, $dir);
        unless (-d $path) {
            make_path($path) or die "Cannot create $path: $!\n";
            print "  created $dir/\n";
        }
    }

    # Copy spiderpup.js
    my $sp_js_src = File::Spec->catfile($sp_dir, 'www', 'webroot', 'js', 'spiderpup.js');
    my $sp_js_dst = File::Spec->catfile($target, 'webroot', 'js', 'spiderpup.js');
    if (-f $sp_js_src) {
        copy($sp_js_src, $sp_js_dst) or die "Cannot copy spiderpup.js: $!\n";
        print "  copied  webroot/js/spiderpup.js\n";
    } else {
        warn "Warning: spiderpup.js not found at $sp_js_src\n";
    }

    # Copy yapi-provider.js
    my $yp_js_src = File::Spec->catfile($script_dir, 'www', 'webroot', 'js', 'yapi-provider.js');
    my $yp_js_dst = File::Spec->catfile($target, 'webroot', 'js', 'yapi-provider.js');
    if (-f $yp_js_src) {
        copy($yp_js_src, $yp_js_dst) or die "Cannot copy yapi-provider.js: $!\n";
        print "  copied  webroot/js/yapi-provider.js\n";
    } else {
        warn "Warning: yapi-provider.js not found at $yp_js_src\n";
    }

    # Create starter site.yaml
    my $site_yaml = File::Spec->catfile($target, 'yapi', 'site.yaml');
    unless (-f $site_yaml) {
        open my $fh, '>', $site_yaml or die "Cannot create $site_yaml: $!\n";
        print $fh <<'YAML';
type: server
package: MyProject::Site
base: Yote::YapiServer::Site

uses: []

apps: {}
YAML
        close $fh;
        print "  created yapi/site.yaml\n";
    }

    # Create starter index page
    my $index_yaml = File::Spec->catfile($target, 'spiderpup', 'pages', 'index.yaml');
    unless (-f $index_yaml) {
        open my $fh, '>', $index_yaml or die "Cannot create $index_yaml: $!\n";
        print $fh <<'YAML';
title: Welcome

html: |
  <h1>It works!</h1>
  <p>Edit spiderpup/pages/index.yaml to get started.</p>
YAML
        close $fh;
        print "  created spiderpup/pages/index.yaml\n";
    }

    # Create starter config
    my $config_yaml = File::Spec->catfile($target, 'config', 'yapi.yaml');
    unless (-f $config_yaml) {
        open my $fh, '>', $config_yaml or die "Cannot create $config_yaml: $!\n";
        print $fh <<'YAML';
# Server mode: debug returns stack traces in error responses
# mode: debug

# Database configuration
db:
  type: SQLite            # SQLite or MariaDB
  data_dir: data          # SQLite: directory for database files

  # MariaDB settings (used when type is MariaDB):
  # dbname: myproject
  # username: dbuser
  # password: dbpass

# Maximum file upload size in bytes (default: 5MB)
# max_file_size: 5000000

# Web root directory for serving files (default: www/webroot)
# webroot_dir: www/webroot
YAML
        close $fh;
        print "  created config/yapi.yaml\n";
    }

    print "\nProject initialized in $target/\n";
}

__END__

=head1 NAME

yapi.pl - Yote API server entry point

=head1 SYNOPSIS

    # Start API server
    perl yapi.pl --config config/yapi.yaml
    perl yapi.pl --port 5001

    # Start server + spiderpup file watcher
    perl yapi.pl --config config/yapi.yaml --watch
    perl yapi.pl --config config/yapi.yaml --watch 2  # check every 2s

    # Scaffold a new project
    perl yapi.pl init myproject

    # Compile YAML app definitions to Perl modules
    perl yapi.pl compile yaml/example.yaml lib/

    # Compile all spiderpup pages
    perl yapi.pl pages

    # Watch mode: recompile on changes
    perl yapi.pl pages --watch
    perl yapi.pl pages --watch 2

=head1 DESCRIPTION

Entry point for the Yote API server with project scaffolding and
compilation tools. Spiderpup page serving and watching should be run
separately via pupserver.

=over

=item Default (no subcommand)

Runs the YapiServer API server. Config lib_paths are added to @INC
automatically. With --watch, also forks a spiderpup file watcher that
recompiles pages/recipes on changes. Requires www_dir and webroot_dir
in config. Spiderpup sources are expected at www_dir/spiderpup (or
override with spiderpup_dir in config).

=item init [directory]

Scaffolds a new project directory with the standard layout and
starter files.

=item compile

Compiles YAML app definitions to Perl modules via Yote::YapiServer::Compiler.

=item pages

Compiles all Spiderpup pages (or watches for changes with --watch).

=back

=cut
