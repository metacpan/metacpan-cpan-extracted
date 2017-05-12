package YAWF::Setup::Database;

use strict;
use warnings;

use DBIx::Class::Schema::Loader ();

use YAWF::Setup::Base;

our @ISA = 'YAWF::Setup::Base';

sub new {
    my $class = shift;

    my $self = bless {
        WEB_METHODS => { index => 1, reload => 1 },
        SESSION     => 1,
        LOGIN       => 0,
        @_
    }, $class;

    return $self;
}

sub index {
    my $self = shift;

    return 1 unless $self->auth;

    $self->{yawf}->reply->template('yawf_setup/database');

    return 1;
}

sub reload {
    my $self = shift;

    return 1 unless $self->auth;

    my $config = $self->{yawf}->config;

    $self->{yawf}->reply->template('yawf_setup/database');

    DBIx::Class::Schema::Loader::make_schema_at(
        $config->database->{class},
        {
            debug          => 0,
            dump_directory => './lib',
            naming         => 'v4',
            db_schema => $config->database->{db_schema},
        },
        [
            $config->database->{dbi}
            . ';database='
            . $config->database->{database}
            . ';dbname='
            . $config->database->{database},
            $config->database->{username}, $config->database->{password},
            undef,
            {on_connect_do => $config->database->{sql_postconnect}},
        ]
    );

    $self->{yawf}->reply->{data}->{reloaded} = 1;

    return 1;
}

1;
