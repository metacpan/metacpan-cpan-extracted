package WWW::MLite::Config; # $Id: Config.pm 15 2014-06-04 06:24:25Z minus $
use strict;

=head1 NAME

WWW::MLite::Config - Configuration of WWW::MLite

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use WWW::MLite::Config;

    my $config = new WWW::MLite::Config(
        file => '/var/www/MySite/config/mysite.conf',
        dirs => [qw/foo bar baz/]
    );

    my $foo = $config->get('foo');

=head1 DESCRIPTION

The module works with the configuration data.

=head1 METHODS

=over 8

=item B<new>

    my $config = new WWW::MLite::Config(
        file => '/var/www/MySite/config/mysite.conf',
        dirs => [qw/foo bar baz/]
    );

Returns configuration object

=item B<get, conf, get_conf, config, get_config>

    my $value = $config->get( 'key' );

=item B<set, set_conf, set_config>

    $config->set( 'key', $value );

=back

=head1 HISTORY

See C<CHANGES> file

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

use CTK::Util qw/ :BASE /; # Утилитарий
use WWW::MLite::Util;
use Config::General;
use Try::Tiny;

use vars qw/$VERSION/;
$VERSION = '1.01';

use constant {
        CONFDIR => 'conf',
    };

sub new {
    my $class   = shift;
    my %args    = (@_);
    
    my $file = $args{file};
    my $dirs = $args{dirs};
    
    # Установка директорий по умолчанию, если не заданы данные директории
    unless ($dirs && (ref($dirs) eq 'ARRAY') && @$dirs) {
        my $bd = $ENV{DOCUMENT_ROOT} || '.';
        $dirs = [ $bd, catdir($bd, CONFDIR) ];
    }
    
    my %cfg = _loadconfig($file, $dirs);
    
    # Чтение данных переменных окружения
    $cfg{lc($_)} = $ENV{$_} for keys %ENV;
    
    # Установка дополнительных данных
    $cfg{sid} = getSID(16,'m'); # ID Сессии (SID) - Для контроля сессии
    $cfg{hitime} = getHiTime();
    
    # Корректировка системных параметров конфигурации (умолчания)
    
    # WWW::MLite::Log
    $cfg{debug}     = $cfg{debug} ? 1 : 0;
    $cfg{syslog}    = $cfg{syslog} ? 1 : 0;
    $cfg{loglevel}  = exists($cfg{loglevel}) && defined($cfg{loglevel}) ? $cfg{loglevel} : 'emerg';
    $cfg{logfile}   = exists($cfg{logfile}) && defined($cfg{logfile}) ? $cfg{logfile} : undef;

    my $self = bless { %cfg }, $class;
    return $self;
}
sub get {
    # Прочитать указанный параметр конфигурации
    my $self = shift;
    my $key  = shift;
    return undef unless $self;
    return $self->{$key};
}
sub get_conf { goto &get };
sub conf { goto &get };
sub config { goto &get };
sub get_config { goto &cget };
sub set {
    # Установить указанный параметр конфигурации
    my $self = shift;
    my $key  = shift;
    my $val  = shift;
    croak("Object WWW::MLite::Config not exists") unless $self;
    $self->{$key} = $val;
}
sub set_conf { goto &set };
sub set_config { goto &set };
sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    my $AL = $AUTOLOAD;
    my $ss = undef;
    $ss = $1 if $AL=~/\:\:([^\:]+)$/;
    if ($ss && defined($self->{$ss})) {
        return $self->{$ss};
    } else {
        return undef;
    }
    return undef;
}
sub DESTROY {
    my $self = shift;
    #print STDERR "Object WWW::MLite::Config destroyed\n";
    return 1;
}

sub _loadconfig {
    # Чтение конфигурационного файла или создание пустого
    my $cfile = shift || '';
    my $cdirs = shift || [];

    my %config = (
        loadstatus => 0
    );
    
    # Пытаемся прочитать конфигурационные данные если указан файл
    if ($cfile && -e $cfile) {
        my $conf;
        try {
            $conf = new Config::General( 
                -ConfigFile         => $cfile, 
                -ConfigPath         => $cdirs,
                -ApacheCompatible   => 1,
                -LowerCaseNames     => 1,
                -AutoTrue           => 1,
            );
        } catch {
            carp($_);
        };
        if ($conf && $conf->can('getall')) {
            %config = $conf->getall;
            $config{loadstatus} = 1;
        }
        $config{configfiles} = [];
        $config{configdirs} = $cdirs;
        $config{configfiles} = [$conf->files] if $conf && $conf->can('files');;
    }
    
    return %config;
}

1;
