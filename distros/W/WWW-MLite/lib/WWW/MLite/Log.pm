package WWW::MLite::Log; # $Id: Log.pm 10 2014-05-22 14:05:32Z minus $
use strict; # use Data::Dumper; $Data::Dumper::Deparse = 1;

=head1 NAME

WWW::MLite::Log - CTK Logging methods

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    $config->set(debug => 0); # 0 - off / 1 - on
    $config->set(loglevel => 'emerg'); # or '7'
    $config->set(logfile => 'test.log'); # File name. Optional. Default - undef
    $config->set(syslog => 0); 0 - off / 1 - on (Apache log file)
    
    $mlite->debug( " ... Blah-Blah-Blah ... ", $verbose, $file );
    $mlite->log( " ... Blah-Blah-Blah ... ", "info", $file, $separator );
    $mlite->syslog( " ... Blah-Blah-Blah ... ", $level );
    $mlite->exception( " ... Blah-Blah-Blah ... " );

    $mlite->log_except();  # 9 exception
    $mlite->log_fatal();   # 8 fatal
    $mlite->log_emerg();   # 7 system is unusable
    $mlite->log_alert();   # 6 action must be taken immediately
    $mlite->log_crit();    # 5 critical conditions
    $mlite->log_error();   # 4 error conditions
    $mlite->log_warning(); # 3 warning conditions
    $mlite->log_notice();  # 2 normal but significant condition
    $mlite->log_info();    # 1 informational
    $mlite->log_debug();   # 0 debug-level messages (default)

=head1 DESCRIPTION

All of methods are returned by log-records

=over 8

=item B<exception>

    my $excstat = $mlite->exception( $message );

Write exception information to file

=item B<debug>

    my $debugstat = $mlite->debug( $message, $verbose, $file );

Write debugging information to logfile

    $message - Log (debug) message
    
    $verbose - System information flag. 1 - verbose mode, on / 0 - regular mode, off

    $file - Log file (absolute). Default - STDOUT (Apache logging).
    If the flag syslog the value is ignored - the message is written to the Apache logfile.

It should be noted that if the flag is omitted then the output information debug be ignored.    

=item B<log>

    my $logstat = $mlite->log( $message, $level, $file, $separator );

Main logging method

    $message - Log message

    $level - logging level. It may be either a numeric or string value of the form:
    
        debug   -- 0 (default)
        info    -- 1
        notice  -- 2
        warning -- 3
        error   -- 4
        crit    -- 5
        alert   -- 6
        emerg   -- 7
        fatal   -- 8
        except  -- 9
    
    $file - Log File (absolute). Default - STDOUT (Apache logging). 
    If the flag syslog the value is ignored - the message is written to the Apache logfile
    
    $separator - Log-record separator char's string. Default as char(32): ' '

=item B<log_debug>

Alias for call: $mlite->log( $message, 'debug' )

=item B<log_info>

Alias for call: $mlite->log( $message, 'info' )

=item B<log_notice>

Alias for call: $mlite->log( $message, 'notice' )

=item B<log_warning>

Alias for call: $mlite->log( $message, 'warning' )

=item B<log_warn>

Alias for call: $mlite->log( $message, 'warning' )

=item B<log_error>

Alias for call: $mlite->log( $message, 'error' )

=item B<log_err>

Alias for call: $mlite->log( $message, 'error' )

=item B<log_crit>

Alias for call: $mlite->log( $message, 'crit' )

=item B<log_alert>

Alias for call: $mlite->log( $message, 'alert' )

=item B<log_emerg>

Alias for call: $mlite->log( $message, 'emerg' )

=item B<log_fatal>

Alias for call: $mlite->log( $message, 'fatal' )

=item B<log_except>

Alias for call: $mlite->log( $message, 'except' )

=item B<log_exception>

Alias for call: $mlite->log( $message, 'except' )

=item B<syslog, logsys>

    my $logstat = $mlite->syslog( $message, $level );

Apache logging to the Apache logfile (ErrorLog of your virtualhost)

$level can take the following values:

    debug, info, notice, warning, error, crit, alert, emerg, fatal, except

The function returns work status

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

use vars qw/$VERSION/;
$VERSION = '1.00';

use constant {
    LOGLEVELS       => { 
        'debug'   => 0,
        'info'    => 1,
        'notice'  => 2,
        'warning' => 3,
        'error'   => 4,
        'crit'    => 5,
        'alert'   => 6,
        'emerg'   => 7,
        'fatal'   => 8,
        'except'  => 9,
    },
};

use FileHandle;
use CTK::Util qw/ :BASE /; # Утилитарий
use WWW::MLite::Util;

sub log {
    #
    # Процедура логирования данных.
    #
    # IN:
    #   message - сообщение.
    #   level   - Уровень записи лога (см. процедуру syslog())
    #   file    - АБСОЛЮТНЫЙ путь и имя файла куда писать. По умолчанию используется файл default.log TEMP-директории
    #   sep     - Разделитель значений. По умолчанию пробел
    #
    my $self    = shift;
    my $message = shift; $message = '' unless defined $message;
    my $level   = shift || 'debug';
    my $file    = shift || $self->conf->logfile;
    my $sep     = shift; $sep = ' ' unless defined $sep;
    
    # Определяем уровень переданный в процедуру
    my $ll = _level($level);
    my $llc = _level2index($ll); # числовое значени переданного в процедуру уровня
        
    # Смотрим на уровень лога f($ll), если он установлен < чем LogLevl заданный конфигурацией то просто выходим
    my $llsys = _level2index(_level(lc( defined($self->conf->loglevel) ? $self->conf->loglevel : 'emerg' )) );

    #unless (($llc == 0) && $self->conf->debug) { # если передан level=debug и установлен флаг дебага - пропскаем проверку!
    #    return 0 if $llc < $llsys;
    #}
    return 0 if $llc < $llsys;
    
    # Формируем выходную строку
    my $usesyslog = $self->conf->syslog ? 1 : 0;
    $usesyslog = 1 unless defined($file); # Использовать системное логирование, если файл не задан
    
    my @sl;
    unless ($usesyslog) {
        @sl = (
            sprintf('[%s]',dtf("%w %MON %DD %hh:%mm:%ss %YYYY")), # Tue Feb 02 16:15:18 2013
            sprintf('[%s]',$ll),
            sprintf('[client %s]',$self->conf->remote_addr),
        );
    }
    push @sl, sprintf('[sid %s]',$self->conf->sid);
    push @sl, sprintf('[user %s]',$self->conf->remote_user) if $self->conf->remote_user;
    push @sl, sprintf('[uri %s]',$self->conf->request_uri);
    push @sl, $message;
    my $logstring = join($sep, @sl);

    # Запись!
    return syslog($self,$logstring,$level) if $usesyslog; # В системный лог
    return _log_flush($file, $logstring); # В свой лог. Тут сложнее, идет заморочка с файлами
}
sub log_debug { shift->log(shift,'debug') };
sub log_info { shift->log(shift,'info') };
sub log_notice { shift->log(shift,'notice') };
sub log_warning { shift->log(shift,'warning') };
sub log_warn { goto &log_warning };
sub log_error { shift->log(shift,'error') };
sub log_err { goto &log_error };
sub log_crit { shift->log(shift,'crit') };
sub log_alert { shift->log(shift,'alert') };
sub log_emerg { shift->log(shift,'emerg') };
sub log_fatal { shift->log(shift,'fatal') };
sub log_except { shift->log(shift,'except') };
sub log_exception { goto &log_except };

sub syslog {
    #
    # Процедура использует функцию апача для вставки записей в лог
    #
    # IN:
    #   message - сообщение.
    #   level   - Уровень записи лога (см. процедуру syslog())
    #
    my $self    = shift;
    my $message = shift;
    my $level   = shift || ''; # emerg(), alert(), crit(), error(), warn(), notice(), info(), debug()
    my $msg = translate(defined($message) ? $message : '');
    
    if ($level) {
        printf STDERR "[%s] %s\n",uc(_level($level)), $msg;
    } else {
        printf STDERR "%s\n", $msg;
    }
    return 1;
    
}
sub logsys { goto &syslog };
sub debug {
    #
    # Процедура отладки. Записывает в отладочный файл информацию.
    # !!! Используется для ПРИКЛАДНЫХ а не системных нужд
    #
    # IN:
    #    $message - сообщение
    #    $verbose - флаг системной информации. 1 - включить добавление системной информации / 0 - выкл
    #    $file    - ИМЯ файла для отладки. По умолчанию используется файл лога
    #
    my $self    = shift;
    my $message = shift; $message = '' unless defined $message;
    my $verbose = shift || 0;
    my $file    = shift;
    
    return 0 unless $self->conf->debug;
    
    # Берем значение по умолчанию если оно не задано
    my $buff = '';
    if ($verbose) {
        my ($pkg, $fn, $ln) = caller;
        my $tm = sprintf "%+.*f",4, (getHiTime() - $self->conf->hitime);
        $buff = "[time $tm] [package $pkg] [file $fn] [line $ln]".($message ? ' '  : '').$message;
    } else {
        $buff = $message;
    }
    $self->log($buff,'debug',$file);
}
sub exception {
    # Процедура реагирования на exception
    my $self = shift;
    my $message = shift;
    $message = '' unless defined $message;
    $self->log_except($message);
}


sub _log_flush {
    # сбрасываем буфер в файл, возвращая статус операции
    my $fn = shift;
    my $buffer = shift;
    return 0 unless defined $fn;
        
    my $fh = FileHandle->new($fn,'a');
    unless ($fh) {
        carp(defined($!) ? $! : "Can't open file \"$fn\"");
        return 0;
    }
    
    $fh->print(defined($buffer) ? $buffer : '',"\n");
    $fh->close();

    return 1;
}
sub _level {
    # Определяем уровень переданный в процедуру
    my $level = shift;
    my $loglevels = LOGLEVELS;
    my %levels  = %$loglevels;
    my %rlevels = reverse %$loglevels;
    my $ll;
    if (defined($level) && ($level =~ /^[0-9]+$/) && defined $rlevels{$level}) {
        $ll = $rlevels{$level};
    } elsif (defined($level) && ($level =~ /^[a-z0-9]+$/i) && defined $levels{lc($level)}) {
        $ll = lc($level);
    } else {
        $ll = 'debug'; # Обработчик по умолчанию
    }
    return $ll;
}
sub _level2index {
    my $level = shift;
    my $loglevels = LOGLEVELS;
    return 0 unless $level;
    return $loglevels->{$level};
}
1;
__END__

subtype 'LogLevels'
    => as 'Int'
    => where   { $_ >= 0 and $_ <= 9 }
    => message { "The LogLevel $_ not valid" };

coerce 'LogLevels'
    => from 'Str'
    => via { ($_ && LOGLEVELS->{$_}) ? LOGLEVELS->{$_} : 0 };

has 'loglevel' => (
    is         => 'rw', 
    isa        => 'LogLevels', 
    default    => 0,
    lazy       => 1,
    coerce     => 1,
);

has 'logfile' => (
    is         => 'rw',
    isa        => 'Str',
    default    => '',
    trigger => sub {
            my $self = shift;
            my $val = shift || '';
            my $old_val = shift || '';
            $self->handle($val) if $val && $val ne $old_val;
        },

);

subtype 'LogSeparators'
    => as 'Str'
    => where   { defined($_) && $_ ne '' }
    => message { "The logseparator not valid" };

has 'logseparator' => (
    is         => 'rw', 
    isa        => 'LogSeparators', 
    default    => ' ',
    lazy       => 1,
);

subtype 'LogHandler'
    => as 'FileHandle'
    => where   { $_->opened },
    => message { "File's handler do't opened!" };

coerce 'LogHandler'
    => from 'Str'
    => via { FileHandle->new($_,'a') };

has 'handle'   => (
    is         => 'rw', # 'ro',
    isa        => 'LogHandler',
    coerce     => 1,
    predicate  => 'sethandle',
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    #CTK::debug("BUILDARGS called");
    #CTK::debug(Dumper(\@_));

    if ( @_ && ! ref($_[0]) ) {
        my %p = @_;
        unless (defined $p{handle}) {
            # =х чрфрэ ярЁрьхЄЁ handle, яюфёЄрты хь чэрўхэшх ёрьш, шч logfile, шэрўх -- эшўхую!
            if (defined $p{logfile}) {
                $p{handle} = $p{logfile};
            }
        }
        return $class->$orig(%p);
    } elsif ( @_ && ref($_[0]) eq 'HASH' ) {
        my $p = $_[0];
        unless (defined $p->{handle}) {
            # =х чрфрэ ярЁрьхЄЁ handle, яюфёЄрты хь чэрўхэшх ёрьш, шч logfile, шэрўх -- эшўхую!
            if (defined $p->{logfile}) {
                $p->{handle} = $p->{logfile};
            }
        }
        
    }
    return $class->$orig(@_);

};

after DEMOLISH => sub {
    my $self = shift;
    #CTK::debug("DEMOLISH called");
    
    if ($self->sethandle()) {
        my $fh = $self->handle;
        $fh->close() if $fh;
        #warn("DEMOLISH called: handle cleaned !!") if $fh;
    }
};

sub log {
    my $self  = shift;
    my $level = shift;
    my @l = @_;
    
    my $loglevels = LOGLEVELS;
    my %levels  = %$loglevels;
    my %rlevels = reverse %$loglevels;
    
    my $proc = 'log_debug'; # +сЁрсюЄўшъ яю єьюыўрэш¦
    if (defined($level) && ($level =~ /^[0-9]+$/) && defined $rlevels{$level}) {
        $proc = 'log_'.$rlevels{$level};
        #CTK::debug ("FIRST: $proc");
    } elsif (defined($level) && ($level =~ /^[a-z0-9]+$/i) && defined $levels{lc($level)}) {
        $proc = 'log_'.lc($level);
        #CTK::debug ("SECOND: $proc");
    } else {
        unshift @l, $level if defined $level;
        #CTK::debug (@l);
    }
    
    # ¦ряєёърхь юсЁрсюЄўшъ яю шьхэш яЁюЎхфєЁv
    confess "Undefinned the LogLevel!" unless $proc;
    my $lcode = __PACKAGE__->can("$proc");
    if ($lcode && ref($lcode) eq 'CODE') {
        return $self->$proc(@l); #return &{$lcode}($self,@l);
    } else {
        confess "Can't call method or procedure \"$proc\"!";
    }
    return undef;
}
