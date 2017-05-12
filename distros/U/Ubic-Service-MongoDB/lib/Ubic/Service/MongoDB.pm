package Ubic::Service::MongoDB;
$Ubic::Service::MongoDB::VERSION = '0.02';
use strict;
use warnings;

# ABSTRACT: running MongoDB as Ubic service


use parent qw(Ubic::Service::Common);

use File::Copy qw(move);
use File::Spec::Functions qw(catfile);
use MongoDB 0.502; # MonboDB::MongoClient instead of MongoDB::Connection
use Params::Validate qw(:all);
use Ubic::Daemon qw(:all);
use Ubic::Result qw(:all);



sub new {
    my $class = shift;

    my $opt_str     = { type => SCALAR, optional => 1 };

    my $params = validate(@_, {
        config => { type => HASHREF },
        daemon => { type => SCALAR,
                    regex => qr/^mongo(d|s)$/,
                    default => 'mongod' },

        status   => { type => CODEREF, optional => 1 },
        user     => $opt_str,
        ubic_log => $opt_str,
        stdout   => $opt_str,
        stderr   => $opt_str,
        pidfile  => $opt_str,

        gen_cfg => $opt_str,
    });

    my $self = $params;
    bless $self, $class;

    $self->{port} = $self->{config}->{port} || 27017;

    if (!$params->{pidfile}) {
        $params->{pidfile} = "/tmp/$self->{daemon}." . $self->{port} .  '.pid';
    }
    if (!$params->{gen_cfg}) {
        $params->{gen_cfg} = "/tmp/$self->{daemon}." . $self->{port} . '.conf';
    }

    return bless $params => $class;
}

sub bin {
    my $self = shift;

    my @cmd = ($self->{daemon}, '--config', $self->{gen_cfg});

    return \@cmd;
}

sub create_cfg_file {
    my $self = shift;

    my $fname = $self->{gen_cfg};
    my $tmp_fname = $fname . ".tmp";

    open(my $tmp_fh, '>', $tmp_fname) or die "Can't open file [$tmp_fname]: $!";

    foreach my $k (keys %{$self->{config}}) {
        my $v = $self->{config}->{$k};
        print $tmp_fh "$k=$v\n";
    }

    close($tmp_fh) or die "Can't close file [$tmp_fname]: $!";
    move($tmp_fname, $fname) or die "Can't mova file [${tmp_fname}] to [$fname]: $!";
}

sub pidfile {
    my $self = shift;

    return $self->{pidfile};
}

sub user {
    my $self = shift;

    return $self->{user} if defined $self->{user};
    return $self->SUPER::user;
}

sub timeout_options {
    return {
        start => { trials => 15, step => 0.1 },
        stop  => { trials => 15, step => 0.1 }
    };
}

sub start_impl {
    my $self = shift;

    $self->create_cfg_file;

    my $daemon_opts = {
        bin          => $self->bin,
        term_timeout => 5
    };

    for (qw/ubic_log stdout stderr pidfile/) {
        $daemon_opts->{$_} = $self->{$_} if defined $self->{$_};
    }
    start_daemon($daemon_opts);
}

sub stop_impl {
    my $self = shift;

    return stop_daemon($self->pidfile, { timeout => 7 });
}

sub status_impl {
    my $self = shift;

    my $running = check_daemon($self->pidfile);
    return result('not running') unless ($running);

    my $status;
    eval {
        my $client = MongoDB::MongoClient->new(
            host => "mongodb://localhost:$self->{port}",
            timeout => 2000,
            query_timeout => 2000,
        );
        $client->connect;
        my $db = $client->get_database('admin');
        $status = $db->run_command({ serverStatus => 1 });
    };

    if ($@) {
        return result('broken', $@);
    } elsif (!$status || !$status->{ok} || $status->{ok} != 1) {
        return result('broken');
    } else {
        return result('running');
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ubic::Service::MongoDB - running MongoDB as Ubic service

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  # in your ubic service (/etc/ubic/service/mymongo, for example)
  use Ubic::Service::MongoDB;
  return Ubic::Service::MongoDB->new({
      config => {
          dbpath    => '/var/lib/mongodb',
          logpath   => "/var/log/mongodb/mongodb.log",
          logappend => "true",
      },
      daemon => 'mongod',
      user   => 'mongodb',
      ubic_log => '/var/log/mongodb/ubic.log',
      stdout   => '/var/log/mongodb/stdout.log',
      stderr   => '/var/log/mongodb/stderr.log',
  });

=head1 DESCRIPTION

This is a L<Ubic> service for MongoDB. You can start/stop C<mongod> and C<mongos> using this module.

=head1 METHODS

=over

=item C<new($params)>

Creates new MongoDB service. C<$params> is a hashref with the following parameters:

=over

=item I<config>

Hashref with keys and values for MongoDB .conf file. This conf file regenerates every time at start.

=item I<daemon> (optional)

What you want to start: C<mongod> or C<mongos>. Default is C<mongod>.

=item I<user> (optional)

User name that will be used as real and effective user identifier during exec of MongoDB.

=item I<status> (optional)

Coderef for checking MongoDB status. Takes current instance of C<Ubic::Service::MongoDB> as a first param.

Default implemetation uses C<serverStatus()> MongoDB command.

=item I<ubic_log> (optional)

Path to ubic log.

=item I<stdout> (optional)

Path to stdout log.

=item I<stderr> (optional)

Path to stderr log.

=item I<pidfile> (optional)

Pidfile for C<Ubic::Daemon> module.

If not specified it is a /tmp/mongo(d|s).<port>.pid.

=item I<gen_cfg> (optional)

Generated MongoDB config file name.

If not specified it is a /tmp/mongo(d|s).<port>.conf.

=back

=back

=head1 SEE ALSO

L<http://docs.mongodb.org/manual/reference/configuration-options/>

L<Ubic>

=head1 AUTHOR

Yury Zavarin <yury.zavarin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yury Zavarin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
