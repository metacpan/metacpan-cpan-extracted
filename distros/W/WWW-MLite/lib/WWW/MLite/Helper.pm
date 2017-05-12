package WWW::MLite::Helper; # $Id: Helper.pm 22 2014-07-24 14:09:51Z minus $
use strict;

=head1 NAME

WWW::MLite::Helper - WWW::MLite helper's interface

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use WWW::MLite::Helper;
    
    my $helper = new WWW::MLite::Helper (
            -ctk => $c,
            -dir => $userdir,
        );
    if ($helper) {
        $helper->build;
    } else {
        print "Operation aborted";
    }

=head1 DESCRIPTION

WWW::MLite helper's interface

=head2 METHODS

=over 8

=item B<new>

    my $helper = new WWW::MLite::Helper (
            -ctk => $c,
            -dir => '/foo/bar/baz',
        );

Creating Helper object

=item B<build>

    $helper->build if $helper;

Building project into /foo/bar/baz directory

=back

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

use vars qw($VERSION);
$VERSION = '1.00';

use Cwd;
use CTK::Util qw/ :BASE /;
use CTK::TFVals qw/ :ALL /;
use WWW::MLite::Helper::Skel;
use File::Temp qw/tempfile tempdir/;
use File::Copy;     # Export: copy / move
#use File::Path;     # Export: mkpath / rmtree
use File::Basename; # Export: dirname / basename
use File::Copy::Recursive qw(dircopy dirmove);

use constant {
        NOTSKEL     => "Skeleton is NOT builded! Please check your internet connection (http port)",
        PERM_RWX    => 0755,
        PERM_DIR    => 0777,
    };

sub new {
    my $class = shift;
    my @in = read_attributes(
            [
                [qw/ C CTK /],                      # 0
                [qw/ V VER VERSION /],              # 1
                [qw/ D DIR DIRECTORY /],            # 2
            ],
        ,@_);
    
    # CTK Object
    my $c   = $in[0];
    croak("CTK object undefined") unless $c && ref($c) eq 'CTK';
        
    # WWW::MLite version
    my $ver = $in[1] || WWW::MLite::Helper::Backward->get_version();
    carp("Can't use version of WWW::MLite. Please check -v argument") unless $ver && is_flt($ver);
    
    # Directory
    my $dir = $in[2] || '';
    
    # ServerName & ServerNameF & ServerNameC
    my $sname = $dir ? 'foo.localhost' : $c->cli_prompt('Server Name (Your site):', 'foo.localhost');
    my $servername = _cleanServerName($sname);
    my $servernamef = _cleanServerNameF($servername);
    my $servernamec = $servername; $servernamec =~ s/\:\d+$//;
    
    # Directory DST
    my $dirdst = $dir ? $dir : catdir(getcwd(), $servernamef);
    # Спрашиваем, ведь папка введена существующая
    return if $dirdst && -e $dirdst && $c->cli_prompt('Directory already exists! Are you sure you want to continue?:','no') !~ /^\s*y/i;
    croak("Can't prepare directory \"$dirdst\"") unless -e $dirdst or preparedir($dirdst, PERM_DIR);

    
    # Skeleton. 1 - Инициализация
    my $skel = new WWW::MLite::Helper::Skel( 
            -ctk => $c,
            -ver => $ver,
        );
    unless ($skel->checkstatus) { 
        unless ($skel->build) { 
            croak(NOTSKEL);
        }
    }
    
    # Skeleton. 2 - Получается список файлов (с их путями) для создания проекта из файла MANIFEST
    # MANIFEST и SUMMARY не должны быть приведены в файле MANIFEST!
    #start _ ">>> Reading MANIFEST file";
    my $manifest = $skel->readmanifest;
    croak("Can't read MANIFEST file") unless $manifest && ref($manifest) eq 'HASH';
    
    return bless({
            c           => $c,
            version     => $ver,
            gmt         => dtf("%w %MON %_D %hh:%mm:%ss %YYYY %Z", time(), 'GMT'),
            servername  => $servername,
            servernamef => $servernamef,
            servernamec => $servernamec,
            dirdst      => $dirdst,
            manifest    => $manifest,
            summary     => $skel->readsummary || '',
        }, $class);
}

sub build {
    my $self = shift;
    my $tmpdir = tempdir( CLEANUP => 1 );
    my $manifest = $self->{manifest} || {};
    my $servernamef = $self->{servernamef} || 'foo.localhost';
    my $dirdst = $self->{dirdst} || '';
    croak("Can't find destination directory") unless $dirdst;
    
    my $n = scalar(keys %$manifest);
    my $i = 0;
    foreach my $km (keys %$manifest) {$i++;
        CTK::debug sprintf('%d/%d> %s', $i, $n, $km);
        my $f_src   = $manifest->{$km};                         # Источник (файл)
        my $f_dst   = CTK::catfile($tmpdir,$servernamef,$km);   # Приемник (файл)
        my $dir_src = dirname($f_src);                          # Источник (каталог)
        my $dir_dst = dirname($f_dst);                          # Приемник (каталог)
        preparedir( $dir_dst ) or carp("Can't prepare directory \"$dir_dst\"") && next;
        
        # Обработка различныз файлов
        if (-B $f_src) { # Обработка двоичных файлов
            copy($f_src,$f_dst) or carp("Copy failed \"$f_src\" -> \"$f_dst\": $!") && next;
        } elsif ($km =~ /s?html?$/) { # Файлы SHTML и HTML копируем!
            copy($f_src,$f_dst) or carp("Copy failed \"$f_src\" -> \"$f_dst\": $!") && next;
        } elsif ($km =~ /(\.cgi)|(\.pl)|(\.sh)$/) { # Копируем с выставлением прав
            copy($f_src,$f_dst) or carp("Copy failed \"$f_src\" -> \"$f_dst\": $!") && next;
            chmod PERM_RWX, $f_dst;
        } else {
            my $f_dst_orig = $f_dst.".orig"; # Имя файла оригинала
            
            if ($km =~ /\.(conf|ht\w+)$/) { # Все файлы конфигурации должны быть сохранены!
                my $f_fd = CTK::catfile($dirdst,$km); # Самый конечный ресурс
                my $f_fd_old = $f_fd.".orig"; # Имя файла оригинала на конечном ресурсе
                if (-e $f_fd) {
                    # Файл конечный существует, значит есть над чем поработать!
                    if (-e $f_fd_old) {
                        # Нашелся ранее сохраненный файл оригинала. Копируем его в TMP
                        copy($f_fd_old,$f_dst_orig) or carp("Copy failed \"$f_fd_old\" -> \"$f_dst_orig\": $!");
                    } else {
                        # Никакого сохраненного ранее файл оригинала нет, 
                        # значит можем переименовать имеющийся конфигурауционный в .orig
                        copy($f_fd,$f_dst_orig) or carp("copy failed \"$f_fd\" -> \"$f_dst_orig\": $!");
                    }
                }
            }
            copy($f_src,$f_dst) or carp("Copy failed \"$f_src\" -> \"$f_dst\": $!") && next;
        }
        #CTK::debug "$f_src -> $f_dst";
    }
    
    # Копирование всей структуры в папку назначения
    my $dir_from = CTK::catdir($tmpdir,$servernamef);
    my $dir_into = $dirdst;
    unless (dirmove($dir_from,$dir_into)) {
        croak("Can't move directory \"$dir_from\" -> \"$dir_into\": $!");
    }
    
    # Выдаем сообщение SUMMARY
    my $summary = $self->{summary} || '';
    if ($summary) {
        printf $summary;
    } else {
        printf "Done. Your project is located in \"%s\" directory", $dirdst
    }
    
    return 1;
}

sub _cleanProjectName {
    my $pn = fv2void(shift);
    $pn =~ s/[^a-z0-9_]/X/ig;
    return $pn;
}
sub _cleanServerName {
    my $sn = lc(fv2void(shift));
    $sn =~ s/[^a-z0-9_\-.:]/X/ig;
    return $sn;
}
sub _cleanServerNameF {
    # Правка (чистка) имени сервера (сайта) в стандарте имен файлов
    my $sn = lc(fv2void(shift));
    $sn =~ s/[^a-z0-9_\-.]//ig;
    return $sn;
}


1;

package # hide me from PAUSE
        WWW::MLite::Helper::Backward;

use CTK::Util qw/ :API /;
use ExtUtils::MM;

sub get_version { 
    my $sf = '';
    foreach (@INC) {
        my $f = catfile($_,"WWW","MLite.pm");
        if (-e $f) {
            $sf = $f;
            last;
        }
    }
    my $v = ExtUtils::MM->parse_version($sf);
    croak "Method ExtUtils::MM->parse_version returns false!" unless $v;
    return $v;
}
sub get_make {
    return ExtUtils::MM->new->make();
}

1;
