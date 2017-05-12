package WWW::MLite::Store::DBI; # $Id: DBI.pm 15 2014-06-04 06:24:25Z minus $
use strict;

=head1 NAME

WWW::MLite::Store::DBI - Database independent interface for WWW::MLite on CTK::DBI based

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use WWW::MLite::Store::DBI;

    # MySQL connect
    my $mysql = new WWW::MLite::Store::DBI (
        -mlite      => $mlite, # OPTIONAL
        -dsn        => 'DBI:mysql:database=TEST;host=192.168.1.1',
        -user       => 'login',
        -pass       => 'password',
        -connect_to => 5,
        -request_to => 60
        -attr       => {
                mysql_enable_utf8 => 1,
                RaiseError => 0,
                PrintError => 0,
            },
    ); # See CTK::DBI
    
    # MySQL connect (old style, without DSN)
    my $mysql = new WWW::MLite::Store::DBI (
        -mlite      => $mlite, # OPTIONAL
        
        -driver     => 'mysql', # Driver name. See DBI module
            # Available drivers:
            #  CSV, DBM, ExampleP, File, Gofer, ODBC, Oracle, 
            #  Pg, Proxy, SQLite, Sponge, mysql
        -host       => '192.168.1.1',
        -port       => '3306', # default
        -database   => 'TEST',
        
        -user       => 'login',
        -pass       => 'password',
        -attr       => {
                mysql_enable_utf8 => 1,
                RaiseError => 0,
                PrintError => 0,
            },
    );

    my $dbh = $mysql->connect;
    
    my $pingstat = $mysql->ping if $mysql;
    
    $mysql->reconnect() unless $pingstat;
    
    # Table select (as array)
    my @result = $mysql->table($sql, @inargs);

    # Table select (as hash)
    my %result = $mysql->tableh($key, $sql, @inargs); # $key - primary index field name

    # Record (as array)
    my @result = $mysql->record($sql, @inargs);

    # Record (as hash)
    my %result = $mysql->recordh($sql, @inargs);

    # Fiels (as scalar)
    my $result = $mysql->field($sql, @inargs);

    # SQL/PL-SQL
    my $sth = $mysql->execute($sql, @inargs);
    ...
    $sth->finish;

=head1 DESCRIPTION

Database independent interface for WWW::MLite on CTK::DBI based.

=head2 DEBUG

Set $WWW::MLite::Store::DBI::DEBUG_FORCE = 1 for enable debugging in STDERR where object $mlite undefined

Coming soon

=head1 METHODS

=over 8

=item B<ping>

    my $status = $mysql->ping();

Returns connection's life status

=item B<reconnect>

    $mysql->reconnect unless $mysql->ping();

=item B<err, errstr, state>

    my $err = $mysql->err;
    my $errstr = $mysql->errstr;
    my $state = $mysql->state;

Methods returns DBI values: err, errstr and state.

See L<DBI/"METHODS_COMMON_TO_ALL_HANDLES">

=back

=head1 EXAMPLES

=over 8

=item B<Example 1>

    use WWW::MLite::Store::DBI;
    # eval 'sub CTK::DBI::_error {1}'; # For supressing CTK::DBI errors
    
    my $mysql => new WWW::MLite::Store::DBI (
            -mlite  => $mlite,
            -dsn    => 'DBI:mysql:database=NAME;host=HOST',
            -user   => 'USER',
            -pass   => 'PASSWORD',
            -attr   => { 
                mysql_enable_utf8 => 1,
                RaiseError => 0,
                PrintError => 0,
                HandleError => sub { $m->log_error(shift || '') },
            },
        )
    
    ...
    
    my @data = $mysql->table('select * from table');

=item B<Example 2: with reconnection>

    use WWW::MLite::Store::DBI;
    
    my $mysql => new WWW::MLite::Store::DBI (
            -mlite  => $mlite, # OPTIONAL
            -dsn    => 'DBI:mysql:database=NAME;host=HOST',
            -user   => 'USER',
            -pass   => 'PASSWORD',
            -attr   => { 
                mysql_enable_utf8 => 1,
                RaiseError => 0,
                PrintError => 0,
                HandleError => sub { $m->log_error(shift || '') },
            },
        )

    ...

    $mysql->reconnect unless $mysql->ping;
    
    ...

    my @data = $mysql->table('select * from table');

=item B<Example 3: Oracle>

    # Oracle connect
    my $oracle = new WWW::MLite::Store::DBI (
        -mlite      => $mlite, # OPTIONAL
        -driver     => 'Oracle',
        -host       => '192.168.1.1',
        -database   => 'TEST',
        -user       => 'login',
        -pass       => 'password',
        -attr       => {
                RaiseError => 0,
                PrintError => 0,
            },
    )
    
    ...
    
    my $value = mysql->field('select sysdate from dual');


=item B<Simple example>

    use WWW::MLite::Store::DBI;

    $WWW::MLite::Store::DBI::DEBUG_FORCE = 1;
    my $dbi = new WWW::MLite::Store::DBI (
            -driver   => 'mysql',
            -name     => 'mylocaldb',
            -user     => 'user',
            -password => 'password'
      );
    ...
    my @table = $dbi->table("select * from tablename where date = ?", "01.01.2000");

=item B<Sponge example>

    use WWW::MLite::Store::DBI;

    $WWW::MLite::Store::DBI::DEBUG_FORCE = 1;
    my $o = new WWW::MLite::Store::DBI(
        -driver => 'Sponge',
        -attr   => { RaiseError => 1 },
    );
    my $dbh = $o->connect();
    my $sth = $dbh->prepare("select * from table", {
        rows => [
            [qw/foo bar baz/],
            [qw/qux quux corge/],
            [qw/grault garply waldo/],
        ],
        NAME => [qw/h1 h2 h3/],
    });

    $sth->execute();
    my $result = $sth->fetchall_arrayref;
    $sth->finish;
    print Dumper($result);

=back

=head1 HISTORY

See C<CHANGES> file

=head1 SEE ALSO

L<CTK::DBI>, L<DBI>

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://www.serzik.com> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2014 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use vars qw($VERSION $DEBUG_FORCE);
$VERSION = '1.01';

use constant {
        ATTR_NAMES => [
            ['M', 'MLITE', 'GLOBAL', 'GLOB', 'OBJECT'],                                                  # 0
            ['DSN','STRING','STR'],                                                                     # 1
            ['HOST','HOSTNAME','SERVER','SERVERNAME','ADDRESS','ADDR','SERVERADDR'],                    # 2
            ['DB','BD','DBNAME','DATABASE','NAME','DATABASENAME'],                                      # 3
            ['PORT',],                                                                                  # 4
            ['USER','USERNAME','LOGIN'],                                                                # 5
            ['PASSWORD','PASS'],                                                                        # 6
            ['DRIVER','DRIVERNAME'],                                                                    # 7
            ['TIMEOUT_CONNECT','CONNECT_TIMEOUT','CNT_TIMEOUT','TIMEOUT_CNT','TO_CONNECT','CONNECT_TO'],# 8
            ['TIMEOUT_REQUEST','REQUEST_TIMEOUT','REQ_TIMEOUT','TIMEOUT_REQ','TO_REQUEST','REQUEST_TO'],# 9
            ['ATTRIBUTES','ATTR','ATTRHASH','PARAMS'],                                                  # 10
        ],
    };

use DBI;
use base qw/CTK::DBI/;
use CTK::Util qw/ :API /;

sub new { 
    my $class = shift;
    my @in = read_attributes(ATTR_NAMES,@_);
    
    # Основные атрибуты соединения MySQL
    my $m       = $in[0];
    my $dsn     = $in[1] || '';
    my $host    = $in[2] || '';
    my $db      = $in[3] || '';
    my $port    = $in[4] || '';
    my $user    = $in[5] || '';
    my $pass    = $in[6] || '';
    my $driver  = $in[7] || '';
    my $toc     = $in[8] || 0;
    my $tor     = $in[9] || 0;
    my $attr    = $in[10] || undef;
    
    unless ($dsn) {
        my @adrivers = DBI->available_drivers();
        if (grep {$driver eq $_} @adrivers) {
            if ($driver =~ /mysql/i) {
                $dsn = "DBI:mysql:database=$db".($host?";host=$host":'').($port?";port=$port":'');
            } elsif ($driver =~ /Oracle/i) {
                if ($host) {
                    $dsn = "DBI:Oracle:host=$host".($db?";service_name=$db":'').($port?";port=$port":'');
                } else {
                    $dsn = "DBI:Oracle:".($db?"$db":'').($port?";port=$port":'');
                }
            } else {
                # dbi:DriverName:database=database_name;host=hostname;port=port
                $dsn = "DBI:".$driver.":"
                    .($db?"database=$db":'')
                    .($host?";host=$host":'')
                    .($port?";port=$port":'');
            }
        } else {
            carp("Driver \"$driver\" not availebled. Available drivers: ",join(", ",@adrivers));
        }
    }
    my %args = ( 
            -dsn  => $dsn,
            -user => $user,
            -pass => $pass,
            -timeout_connect => $toc,
            -timeout_request => $tor,
            -attr => $attr,
        );

    if ($dsn) {
        my $obj = $class->SUPER::new(%args);
        $obj = bless({}, $class) unless $obj && ref($obj) eq __PACKAGE__;
        $obj->{mlite} = $m;
        return $obj unless $obj->{dbh};
        if ($m && ref($m) eq 'WWW::MLite') {
            $m->debug("--- CONNECT {$dsn} AS $obj ---");
        } else {
            carp("--- CONNECT {$dsn} AS $obj ---") if $DEBUG_FORCE;
        }
        return $obj if $obj;
    } else {
        return bless({
                mlite=>$m,
            }, $class);
    }
    return undef;
}
sub ping {
    my $self = shift;
    return 0 unless $self && ref($self) eq __PACKAGE__;
    return 0 unless $self->{dsn};
    return 0 unless $self->{dbh};
    return 0 unless $self->{dbh}->can('ping');
    return $self->{dbh}->ping();
}
sub reconnect {
    my $self = shift;

    my $m = $self->{mlite};
    my $dsn = $self->{dsn};
    
    # See CTK::DBI::DBI_CONNECT
    $self->{dbh} = CTK::DBI::DBI_CONNECT(
            $dsn,
            $self->{user},
            $self->{password},
            $self->{attr},
            $self->{connect_to},
        );
    if ($self->{dbh}) {
        if ($m && ref($m) eq 'WWW::MLite') {
            $m->debug("--- RECONNECT {$dsn} AS $self ---");
        } else {
            carp("--- RECONNECT {$dsn} AS $self ---") if $DEBUG_FORCE;
        }
        return 1;
    }
    return undef;
}
sub err {
    my $self = shift;
    return $self->{dbh}->err if $self->{dbh} && $self->{dbh}->can('err');
    return defined $DBI::err ? $DBI::err : 0;
}
sub errstr {
    my $self = shift;
    return $self->{dbh}->errstr if $self->{dbh} && $self->{dbh}->can('errstr');
    return defined $DBI::errstr ? $DBI::errstr : '';
}
sub state {
    my $self = shift;
    return $self->{dbh}->state if $self->{dbh} && $self->{dbh}->can('state');
    return defined $DBI::state ? $DBI::state : '';
}
sub DESTROY {
    my $self = shift;
    my $dsn = '';
    $dsn = $self->{dsn} if $self->{dsn};
    my $m = '';
    $m = $self->{mlite} if $self->{mlite};
    
    if ($dsn && $self->{dbh}) {
        if($m && ref($m) eq 'WWW::MLite') {
            $m->debug("--- DISCONNECT {$dsn} ---");
        } else {
            carp("--- DISCONNECT {$dsn} ---") if $DEBUG_FORCE;
        }
    }
}

1;
