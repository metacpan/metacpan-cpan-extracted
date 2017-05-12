=encoding utf8



=head1 WebService::CEPH::FileShadow

Потомок WebService::CEPH.

Опции конструктора те же самые, что и у WebService::CEPH, плюс ещё есть:

mode - 's3' или 's3-fs' или 'fs'

fs_shadow_path - путь к файловой системе, указывает на директорию, финальный слэш не обязателен.

В режиме s3 всё работает, как WebService::CEPH, файлы скачиваются и закачиваются в CEPH по протоколу s3.
В режиме 's3-fs' при закачке файла, создаётся его копия в файловой системе. Сначала файл закачивается в s3, потом
в файловую систему, если в это время случится исключение, предыдущий шаг не отменяется.
Скачивание файлов происходит с 's3', при ошибке скачивания, никакого фейловера на файловую систему не производится.
В режиме 'fs' закачивание и скачивание файлов происходит только в файловую систему.

Метаинформация (x-amz-meta-md5, content-type в файловой системе не сохраняется).

В методах download_to_file, upload_from_file в режиме файловой системы, работа с локальными файлами
делается максимально совместимо с режимом 's3' (права (umask) при создании файла, режимы truncate и seek при работе
с filehandles)

Имя ключа объекта не должно содержать символов, опасных для файловой системы (например '../', '/..') иначе
будет исключение. Однако по-настоящему заботится о безопасности должен вызывающий.

=cut

package WebService::CEPH::FileShadow;

our $VERSION = '0.014'; # VERSION

use strict;
use warnings;
use Carp;
use Fcntl qw/:seek/;
use File::Copy;
use File::Slurp qw/read_file/;
use File::Path qw(make_path);
use parent qw( WebService::CEPH );


sub new {
    my ($class, %options) = @_;
    my %new_options;

    $new_options{$_} = delete $options{$_} for (qw/fs_shadow_path mode/);

    !defined or m!/$! or $_ .= '/' for $new_options{fs_shadow_path};
    confess "mode should be 's3', 's3-fs' or 'fs', but it is '$new_options{mode}'"
        unless $new_options{mode} =~ /^(s3|s3\-fs|fs)$/;

    confess "you specified mode to work with filesystem ($new_options{mode}), please define fs_shadow_path then"
        if $new_options{mode} =~ /fs/ && !$new_options{fs_shadow_path};

    my $self = $class->SUPER::new(%options);

    $self->{$_} = $new_options{$_} for keys %new_options;

    $self;
}

sub _filepath {
    my ($self, $key, $should_mkpath) = @_;
    confess "key expected" unless defined $key;
    confess "unsecure key" if $key eq '.';
    confess "unsecure key" if $key =~ m!\.\./!;
    confess "unsecure key" if $key =~ m!/\.\.!;
    confess "constructor should normalize path" unless $self->{fs_shadow_path} =~ m!/$!;
    my $dir = $self->{fs_shadow_path}.$self->{bucket}."/";
    make_path($dir) if ($should_mkpath);
    $dir.$key;
}
sub upload {
    my ($self, $key) = (shift, shift);

    if ($self->{mode} =~ /s3/) {
        $self->SUPER::upload($key, $_[0], $_[1]);
    }
    if ($self->{mode} =~ /fs/) {
        my $path = $self->_filepath($key, 1);
        open my $f, ">", $path or confess;
        binmode $f;
        print $f $_[0] or confess;
        close $f or confess;
    }
}

sub upload_from_file {
    my ($self, $key, $fh_or_filename, $content_type) = @_;

    if ($self->{mode} =~ /s3/) {
        $self->SUPER::upload_from_file($key, $fh_or_filename, $content_type);
    }
    if ($self->{mode} =~ /fs/) {
        my $path = $self->_filepath($key, 1);
        seek($fh_or_filename, 0, SEEK_SET) if (ref $fh_or_filename);
        copy($fh_or_filename, $path);
    }
}

sub download {
    my ($self, $key) = @_;

    if ($self->{mode} =~ /s3/) {
        return $self->SUPER::download($key);
    }
    elsif ($self->{mode} =~ /fs/) {
        return scalar read_file( $self->_filepath($key), binmode => ':raw' )
    }
}

sub download_to_file {
    my ($self, $key, $fh_or_filename) = @_;

    if ($self->{mode} =~ /s3/) {
        $self->SUPER::download_to_file($key, $fh_or_filename);
    }
    elsif ($self->{mode} =~ /fs/) {
        copy( $self->_filepath($key), $fh_or_filename );
    }
}

sub size {
    my ($self, $key) = @_;

    if ($self->{mode} =~ /s3/) {
        return $self->SUPER::size($key);
    }
    elsif ($self->{mode} =~ /fs/) {
        return -s $self->_filepath($key);
    }
}

sub delete {
    my ($self, $key) = @_;

    if ($self->{mode} =~ /s3/) {
        $self->SUPER::delete($key);
    }
    elsif ($self->{mode} =~ /fs/) {
        unlink($self->_filepath($key));
    }
}

sub query_string_authentication_uri {
    my ($self, $key, $expires) = @_;

    if ($self->{mode} =~ /s3/) {
        $self->SUPER::query_string_authentication_uri($key, $expires);
    }
    else {
        confess "Unimplemented in fs mode";
    }
}

1;
