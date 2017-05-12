=encoding utf8

=head1 NAME

WebService::CEPH

=head1 DESCRIPTION

CEPH client for simple workflow, supporting multipart uploads. Most docs are in Russian.

Клинт для CEPH, без низкоуровневого кода для общения с библиотекой Amazon S3
(она вынесена в отдельный класс).

Обработка ошибок (исключения их тип итп; повторы неудачных запросов) - на совести более низкоуровневой библиотеки,
если иное не гарантируется в этой документации.

Параметры конструктора:

Обязательные параметры:

protocol - http/https

host - хост бэкэнда

key - ключ для входа

secret - secret для входа

Необязательные параметры:

bucket - имя бакета (не нужен только для получения списка бакетов)

driver_name - в данный момент только 'NetAmazonS3'

multipart_threshold - после какого размера файла (в байтах) начинать multipart upload

multisegment_threshold - после какого размера файла (в байтах) будет multisegment download

query_string_authentication_host_replace - протокол-хост на который заменять URL в query_string_authentication_uri
должен начинаться с протокола (http/https), затем хост, на конце может быть, а может не быть слэша.
нужен если вы хотите сменить хост для отдачи клиентам (у вас кластер) или протокол (https внешним клиентам)

=cut

package WebService::CEPH;

our $VERSION = '0.014'; # VERSION

use strict;
use warnings;
use Carp;
use WebService::CEPH::NetAmazonS3;
use Digest::MD5 qw/md5_hex/;
use Fcntl qw/:seek/;

use constant MINIMAL_MULTIPART_PART => 5*1024*1024;

sub _check_ascii_key { confess "Key should be ASCII-only" unless $_[0] !~ /[^\x00-\x7f]/ }

=head2 new

Конструктор. Параметры см. выше.

=cut

sub new {
    my ($class, %args) = @_;

    my $self = bless +{}, $class;

    # mandatory
    $self->{$_} = delete $args{$_} // confess "Missing $_"
        for (qw/protocol host key secret/);
    # optional
    for (qw/bucket driver_name multipart_threshold multisegment_threshold query_string_authentication_host_replace/) {
        if (defined(my $val = delete $args{$_})) {
            $self->{$_} = $val;
        }
    }

    confess "Unused arguments: @{[ %args]}" if %args;

    $self->{driver_name} ||= "NetAmazonS3";
    $self->{multipart_threshold} ||= MINIMAL_MULTIPART_PART;
    $self->{multisegment_threshold}  ||= MINIMAL_MULTIPART_PART;

    confess "multipart_threshold should be greater or eq. MINIMAL_MULTIPART_PART (5Mb) (now multipart_threshold=$self->{multipart_threshold}"
        if $self->{multipart_threshold} < MINIMAL_MULTIPART_PART;

    my $driver_class = __PACKAGE__."::".$self->{driver_name}; # should be loaded via "use" at top of file
    $self->{driver} = $driver_class->new(map { $_ => $self->{$_} } qw/protocol host key secret bucket/ );

    $self;
}




=head2 upload

Загружает файл в CEPH. Если файл уже существует - он заменяется.
Если данные больше определённого размера, происходим multipart upload
Ничего не возвращает

Параметры:

0-й - $self

1-й - имя ключа

2-й - скаляр, данные ключа

3-й - Content-type. Если undef, используется дефолтный binary/octet-stream

=cut

sub upload {
    my ($self, $key) = (shift, shift); # после этого $_[0] - данные, $_[1] - Content-type
    $self->_upload($key, sub { substr($_[0], $_[1], $_[2]) }, length($_[0]), md5_hex($_[0]), $_[1], $_[0]);
}

=head2 upload_from_file

То же, что upload, но происходит чтение из файла.

Параметры:

0-й - $self

1-й - имя ключа

2-й - имя файла (если скаляр), иначе открытый filehandle

3-й - Content-type. Если undef, используется дефолтный binary/octet-stream

Дваждый проходит по файлу, высчитывая md5. Файл не должен быть пайпом, его размер не должен меняться.

=cut

sub upload_from_file {
    my ($self, $key, $fh_or_filename, $content_type) = @_;
    my $fh = do {
        if (ref $fh_or_filename) {
            $fh_or_filename
        }
        else {
            open my $f, "<", $fh_or_filename;
            binmode $f;
            $f;
        }
    };

    my $md5 = Digest::MD5->new;
    $md5->addfile($fh);
    seek($fh, 0, SEEK_SET);

    $self->_upload(
        $key,
        sub { read($_[0], my $data, $_[2]) // confess "Error reading data $!\n"; $data },
        -s $fh, $md5->hexdigest, $content_type, $fh
    );
}

=head2 _upload

Приватный метод для upload/upload_from_file

Параметры

1) self

2) ключ

3) итератор с интерфейсом (данные, оффсет, длина). "данные" должны соответствовать последнему
параметру этой функции (т.е. (6))

4) длина данных

5) заранее высчитанный md5 от данных

6) Content-type. Если undef, используется дефолтный binary/octet-stream

7) данные. или скаляр. или filehandle

=cut


sub _upload {
    # after that $_[0] is data (scalar or filehandle)
    my ($self, $key, $iterator, $length, $md5_hex, $content_type) = (shift, shift, shift, shift, shift, shift);

    confess "Bucket name is required" unless $self->{bucket};

    _check_ascii_key($key);

    if ($length > $self->{multipart_threshold}) {
        my $multipart = $self->{driver}->initiate_multipart_upload($key, $md5_hex, $content_type);

        my $len = $length;
        my $offset = 0;
        my $part = 0;
        while ($offset < $len) {
            my $chunk = $iterator->($_[0], $offset, $self->{multipart_threshold});

            $self->{driver}->upload_part($multipart, ++$part, $chunk);

            $offset += $self->{multipart_threshold};
        }
        $self->{driver}->complete_multipart_upload($multipart);
    }
    else {
        $self->{driver}->upload_single_request($key, $iterator->($_[0], 0, $length), $content_type);
    }

    return;
}

=head2 download

Скачивает данные объекта с именем $key и возвращает их.
Если объект не существует, возвращает undef.

Если размер объекта по факту окажется больше multisegment_threshold,
объект будет скачан несколькими запросами с заголовком Range (т.е. multi segment download).

В данный момент есть workaround для бага http://lists.ceph.com/pipermail/ceph-users-ceph.com/2016-June/010704.html,
в связи с ним всегда делается лишний HTTP запрос - запрос длины файла. Плюс не исключён Race condition.

=cut

sub download {
    my ($self, $key) = @_;
    my $data;
    # workaround for CEPH bug http://lists.ceph.com/pipermail/ceph-users-ceph.com/2016-June/010704.html
    my $cephsize = $self->size($key);
    if (defined($cephsize) && $cephsize == 0) {
        return '';
    } else {
        # / workaround for CEPH bug
        _download($self, $key, sub { $data .= $_[0] }) or return;
        return $data;
    }
}

=head2 download_to_file

Скачивает данные объекта с именем $key в файл $fh_or_filename.
Если объект не существует, возвращает undef (при этом выходной файл всё равно будет испорчен и, возможно,
частично записан в случае race condition - удаляйте эти данные сами; если удалять тяжело - пользуйтесь
методом download)
Иначе возвращает размер записанных данных.

Выходной файл открывается в режиме перезаписи, если это имя файла, если это filehandle,
то образается на нулевую длину и пишется с начала.

Если размер объекта по факту окажется больше multisegment_threshold,
объект будет скачан несколькими запросами с заголовком Range (т.е. multi segment download).

В данный момент есть workaround для бага http://lists.ceph.com/pipermail/ceph-users-ceph.com/2016-June/010704.html,
в связи с ним всегда делается лишний HTTP запрос - запрос длины файла. Плюс не исключён Race condition.

=cut

sub download_to_file {
    my ($self, $key, $fh_or_filename) = @_;

    my $fh = do {
        if (ref $fh_or_filename) {
            seek($fh_or_filename, SEEK_SET, 0);
            truncate($fh_or_filename, 0);
            $fh_or_filename
        }
        else {
            open my $f, ">", $fh_or_filename;
            binmode $f;
            $f;
        }
    };

    # workaround for CEPH bug http://lists.ceph.com/pipermail/ceph-users-ceph.com/2016-June/010704.html
    my $cephsize = $self->size($key);
    if (defined($cephsize) && $cephsize == 0) {
        return 0;
    }
    else {
        # / workaround for CEPH bug
        my $size = 0;
        _download($self, $key, sub {
            $size += length($_[0]);
            print $fh $_[0] or confess "Error writing to file $!"
        }) or return;
        return $size;
    }
}

=head2 _download

Приватный метод для download/download_to_file

Параметры:

1) self

2) имя ключа

3) appender - замыкание в которое будут передаваться данные для записи. оно должно аккумулировать их куда-то
себе или писать в файл, который оно само знает.

=cut

sub _download {
    my ($self, $key, $appender) = @_;

    confess "Bucket name is required" unless $self->{bucket};

    _check_ascii_key($key);

    my $offset = 0;
    my $check_md5 = undef;
    my $md5 =  Digest::MD5->new;
    my $got_etag = undef;
    while() {
        my ($dataref, $bytesleft, $etag, $custom_md5) = $self->{driver}->download_with_range($key, $offset, $offset + $self->{multisegment_threshold});

        # Если объект не найден - возвращаем undef
        # даже если при мультисегментном скачивании объект неожиданно исчез на каком-то сегменте, значит
        # его кто-то удалил, нужно всё же вернуть undef
        # При этом, при скачивании в файл, часть данных может быть уже записана. Удаляйте их сами.
        return unless ($dataref);

        if (defined $got_etag) {
            # Во время скачивания, кто-то подменил файл (ETag изменился), В соотв. с HTTP, ETag гарантированно
            # будет разным для разных файлов (но не факт что одинаковым для одинаковых)
            # В этом случае падаем.. Наверное можно в будущем делать retry запросов..
            confess "File changed during download. Race condition. Please retry request"
                unless $got_etag eq $etag;
        }
        else {
            $got_etag = $etag;
        }

        # Проверяем md5 только если ETag "нормальный" с md5 (был не multipart upload)
        if (!defined $check_md5) {
            my ($etag_md5) = $etag =~ /^([0-9a-f]+)$/;

            confess "ETag looks like valid md5 and x-amz-meta-md5 presents but they do not match"
                if ($etag_md5 && $custom_md5 && $etag_md5 ne $custom_md5);
            if ($etag_md5) {
                $check_md5 = $etag_md5;
            } elsif ($custom_md5) {
                $check_md5 = $custom_md5;
            } else {
                $check_md5 = 0;
            }
        }
        if ($check_md5) {
            $md5->add($$dataref);
        }

        $offset += length($$dataref);
        $appender->($$dataref);
        last unless $bytesleft;
    };
    if ($check_md5) {
        my $got_md5 = $md5->hexdigest;
        confess "MD5 missmatch, got $got_md5, expected $check_md5" unless $got_md5 eq $check_md5;
    }
    1;
}

=head2 size

Возвращает размер объекта с именем $key в байтах,
если ключ не существует, возвращает undef

=cut

sub size {
    my ($self, $key) = @_;

    confess "Bucket name is required" unless $self->{bucket};

    _check_ascii_key($key);

    $self->{driver}->size($key);
}

=head2 delete

Удаляет объект с именем $key, ничего не возвращает. Если объект
не существует, не выдаёт ошибку

=cut

sub delete {
    my ($self, $key) = @_;

    confess "Bucket name is required" unless $self->{bucket};

    _check_ascii_key($key);

    $self->{driver}->delete($key);
}

=head2 query_string_authentication_uri

Возвращает Query String Authentication URL для ключа $key, с экспайром $expires

$expires - epoch время. но низкоуровневая библиотека может принимать другие форматы. убедитесь
что входные данные валидированы и вы передаёте именно epoch

Заменяет хост, если есть опция query_string_authentication_host_replace (см. конструктор)

=cut

sub query_string_authentication_uri {
    my ($self, $key, $expires) = @_;

    _check_ascii_key($key);
    $expires or confess "Missing expires";

    my $uri = $self->{driver}->query_string_authentication_uri($key, $expires);
    if ($self->{query_string_authentication_host_replace}) {
        my $replace = $self->{query_string_authentication_host_replace};
        $replace .= '/' unless $replace =~ m!/$!;
        $uri =~ s!^https?://[^/]+/!$replace!;
    }
    $uri;
}

=head2 get_buckets_ist

Returns buckets list

WARNING

Метод падает c ошибкой
Attribute (owner_id) does not pass the type constraint because: Validation failed for 'OwnerId'
Уведомления направлены разрабтчикам:
http://tracker.ceph.com/issues/16806 и https://github.com/rustyconover/net-amazon-s3/issues/18

=cut

sub get_buckets_list {
    my ($self) = @_;

    return $self->{driver}->get_buckets_list;
}

=head2 list_multipart_uploads

Возвращает список multipart загрузок в бакете

=cut

sub list_multipart_uploads {
    my ($self) = @_;

    confess "Bucket name is required" unless $self->{bucket};

    return $self->{driver}->list_multipart_uploads();
}

=head2 delete_multipart_upload

Удаляет multipart загрузку в бакете

Параметры позиционные: $key, $upload_id

Ничего не возвращает

=cut

sub delete_multipart_upload {
    my ( $self, $key, $upload_id ) = @_;

    confess "Bucket name is required" unless $self->{bucket};
    confess "key and upload ID is required" unless $key && $upload_id;

    $self->{driver}->delete_multipart_upload($key, $upload_id);
}

1;
