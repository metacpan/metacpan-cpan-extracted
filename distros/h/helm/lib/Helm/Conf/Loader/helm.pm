package Helm::Conf::Loader::helm;
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use Config::ApacheFormat;
use Helm::Conf;
use Helm::Server;

BEGIN {
    eval { require Config::ApacheFormat };
    die "Could not load Config::ApacheFormat. "
      . "It must be installed to use Helm's built-in configuration format: $@"
      if $@;
}

extends 'Helm::Conf::Loader';

sub load {
    my ($class, %args) = @_;
    my $uri = $args{uri};
    my $helm = $args{helm};
    my $file = $uri->path || $uri->authority;
    $helm->die("Config file $file does not exist!") unless -e $file;
    $helm->die("Config file $file is not readable!") unless -r $file;

    my $config = Config::ApacheFormat->new(
        expand_vars          => 1,
        duplicate_directives => 'combine',
    );
    try {
        $config->read($file);
    } catch {
        $helm->die("Cannot process config file $file: $_");
    };

    my @server_blocks = $config->get('Server');
    $helm->die("No servers listed in config file $file") unless @server_blocks;

    my @servers;
    my %seen_server_names;
    foreach my $server_block (@server_blocks) {
        my $server_name = $server_block->[1];
        my $conf_block  = $config->block(Server => $server_name);
        my @roles       = $conf_block->get('Role');
        my $port        = $conf_block->get('Port');

        # expand server names in case they have ranges
        my @names = Helm::Server->expand_server_names($server_name);
        foreach my $name (@names) {
            $helm->die("Already seen server $name in $file. Duplicate entries not allowed.")
              if $seen_server_names{$name};
            Helm->debug("Adding server $name with roles: "
                  . join(', ', @roles)
                  . ($port ? " on port $port" : ''));
            push(@servers, Helm::Server->new(name => $name, roles => \@roles, port => $port));
            $seen_server_names{$name}++;
        }
    }

    return Helm::Conf->new(servers => \@servers);
}

__PACKAGE__->meta->make_immutable;

1;
