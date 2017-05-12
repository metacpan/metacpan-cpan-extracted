=encoding utf8

=head1 WebService::CEPH::NetAmazonS3

Драйвер для CEPH на базе Net::Amazon::S3.

Сделан скорее не на базе Net::Amazon::S3, а на базе Net::Amazon::S3::Client
см. POD https://metacpan.org/pod/Net::Amazon::S3::Client, там отдельная документация
и сказано что это более новый интерфейс, при этом в докции Net::Amazon::S3 ссылки на это нет.

Лезет в приватные методы и не документированные возможности Net::Amazon::S3,
в связи с тем что Net::Amazon::S3 сложно назвать документированным в принципе, а публичного
функционала не хватает.

Стабильность такого решения обеспечивается интеграционным тестом netamazons3_integration,
который по идее потестирует всё-всё. Проблемы могут быть только если вы поставили этот
модуль, затем обновили Net::Amazon::S3 на новую, ещё не существующую версию, которая
сломала обратную совместимость приватных методов.

Интерфейс данного модуля документирован. Придерживайтесь того что документировано, WebService::CEPH
на всё это рассчитывает. Можете написать свой драйвер с таким же интерфейсом, но с другой реализацией.

=cut

package WebService::CEPH::NetAmazonS3;

our $VERSION = '0.014'; # VERSION

use strict;
use warnings;
use Carp;
use Net::Amazon::S3;
use HTTP::Status;
use Digest::MD5 qw/md5_hex/;

=head2 new

Конструктор

protocol - 'http' или 'https'

host - хост Amazon S3 или CEPH

bucket - (обязателен для всех операций кроме запроса списка бакетов) имя бакета, этот бакет будет использоваться для всех операций объекта

key - ключ доступа

secret - секретный секрет

=cut

sub new {
    my ($class, %args) = @_;

    my $self = bless +{}, $class;

    $self->{$_}     = delete $args{$_} // confess "Missing $_" for (qw/protocol host key secret/);
    $self->{bucket} = delete $args{bucket};

    confess "Unused arguments %args" if %args;
    confess "protocol should be 'http' or 'https'" unless $self->{protocol} =~ /^https?$/;

    my $s3 = Net::Amazon::S3->new({
        aws_access_key_id     => $self->{key},
        aws_secret_access_key => $self->{secret}, # TODO: фильтровать в логировании?
        host                  => $self->{host},
        secure                => $self->{protocol} eq 'https',
        retry                 => 1,
    });

    $self->{client} =  Net::Amazon::S3::Client->new( s3 => $s3 );
    $self;
}

=head2 _request_object

Приватный метод. Возвращает объект Net::Amazon::S3::Client::Bucket, который затем может использоваться.
Используется в коде несколько раз

=cut

sub _request_object {
    my ($self) = @_;

    confess "Missing bucket" unless $self->{bucket};

    $self->{client}->bucket(name => $self->{bucket});
}

=head2 get_buckets_ist

Returns buckets list

=cut

sub get_buckets_list {
    my ($self) = @_;

    return $self->{client}->buckets->{buckets};
}

=head2 upload_single_request

Закачивает данные.

Параметры:

1) $self

2) $key - имя объекта

3) сами данные (блоб)

4) Content-Type, не обязателен

Закачивает объект за один запрос (не-multipart upload), ставит приватный ACL,
добавляет кастомный заголовок x-amz-meta-md5, который равен md5 hex от файла

=cut

sub upload_single_request {
    my ($self, $key) = (shift, shift); # after shifts: $_[0] - value, $_[1] - content-type

    my $md5 = md5_hex($_[0]);
    my $object = $self->_request_object->object(
        key => $key,
        acl_short => 'private',
        $_[1] ? ( content_type => $_[1] ) : ()
    );
    $object->user_metadata->{'md5'} = $md5;
    $object->_put($_[0], length($_[0]), $md5); # private _put so we can re-use md5. only for that.
}

=head2 list_multipart_uploads

Возвращает список multipart_upload

Параметры:

нет

Возвращает:

    [
        {
            key       => 'Upload key',
            upload_id => 'Upload ID',
            initiated => 'Init date',
        },
        ...
    ]

=cut

sub list_multipart_uploads {
    my ($self) = @_;

    $self->{client}->bucket(name => $self->{bucket});

    my $http_request = Net::Amazon::S3::HTTPRequest->new(
        s3     => $self->{client}->s3,
        method => 'GET',
        path   => $self->{bucket} . '?uploads',
    )->http_request;

    my $xpc = $self->{client}->_send_request_xpc($http_request);

    my @uploads;
    foreach my $node ( $xpc->findnodes(".//s3:Upload") ) {
        push @uploads, {
            key       => $xpc->findvalue( ".//s3:Key", $node ),
            upload_id => $xpc->findvalue( ".//s3:UploadId", $node ),
            initiated => $xpc->findvalue( ".//s3:Initiated", $node ),
        };

    }

    return \@uploads;
}

=head2 delete_multipart_upload

Удаляет аплоад

Параметры:

    $key, $upload_id

=cut

sub delete_multipart_upload {
    my ($self, $key, $upload_id) = @_;

    $self->{client}->bucket(name => $self->{bucket});

    my $http_request = Net::Amazon::S3::Request::AbortMultipartUpload->new(
        s3                  => $self->{client}->s3,
        bucket              => $self->{bucket},
        key                 => $key,
        upload_id           => $upload_id,
    )->http_request;

    $self->{client}->_send_request_raw($http_request);
}

=head2 initiate_multipart_upload

Инициирует multipart upload

Параметры:

1) $self

2) $key - имя объекта

3) md5 от данных

Инициирует multipart upload, устанавливает x-amz-meta-md5 в значение md5 файла (нужно посчитать
заранее и передать как параметр).
Возвращает ссылку на структуру, недокументированной природы, которая в дальнейшем должна
использоваться для работы с этим multipart upload

=cut

sub initiate_multipart_upload {
    my ($self, $key, $md5, $content_type) = @_;

    confess "Missing bucket" unless $self->{bucket};

    my $object = $self->_request_object->object( key => $key, acl_short => 'private' );

    my $http_request = Net::Amazon::S3::Request::InitiateMultipartUpload->new(
        s3     => $self->{client}->s3,
        bucket => $self->{bucket},
        key    => $key,
        headers => +{
            'X-Amz-Meta-Md5' => $md5,
            $content_type ? ( 'Content-type' => $content_type ) : ()
        }
    )->http_request;

    my $xpc = $self->{client}->_send_request_xpc($http_request);
    my $upload_id = $xpc->findvalue('//s3:UploadId');
    confess "Couldn't get upload id from initiate_multipart_upload response XML"
      unless $upload_id;

    +{ key => $key, upload_id => $upload_id, object => $object, md5 => $md5};
}

=head2 upload_part

Закачивает часть данных при multipart upload'е

Параметры:

1) $self

2) $multipart_upload - ссылка, полученная из initiate_multipart_upload

3) $part_number - номер части, от 1 и выше.

Работает только если части закачивались по очереди, с возрастающими номерами
(что естественно, если это последовательная закачка, и делает невозможным паралллельную
закачку из разных процессов)

Ничего не возвращает

=cut

sub upload_part {
    my ($self, $multipart_upload, $part_number) = (shift, shift, shift);

    $multipart_upload->{object}->put_part(
        upload_id => $multipart_upload->{upload_id},
        part_number => $part_number,
        value => $_[0]
    );

    # TODO:Part numbers should be in accessing order (in case someone uploads in parallel) !
    push @{$multipart_upload->{parts} ||= [] }, $part_number;
    push @{$multipart_upload->{etags} ||= [] }, md5_hex($_[0]);
}

=head2 complete_multipart_upload

Финализирует multipart upload

Параметры:

1) $self

2) $multipart_upload - ссылка, полученная из initiate_multipart_upload

ничего не возвращает. падает с исчлючением, если что-то не так.

=cut

sub complete_multipart_upload {
    my ($self, $multipart_upload) = @_;

    $multipart_upload->{object}->complete_multipart_upload(
        upload_id => $multipart_upload->{upload_id},
        etags => $multipart_upload->{etags},
        part_numbers => $multipart_upload->{parts}
    );
}

=head2 download_with_range

Скачивает объект с заголовком HTTP Range (т.е. часть данных).

Параметры:

1) $self

2) $key - имя объекта

3) $first - первый байт для Range

4) $last - последний байт для Range

Если $first, $last отсутствуют или undef, скачивается весь файл, без заголовка Range
Если $last отсутствует, скачивает данные с определённой позиции и до конца (так же как в спецификации Range)
Если объект отсутствует, возвращает пустой список. Если другая ошибка - исключение.

Возвращает:

1) Scalar Ref на скачанные данные

2) Количество оставшихся байтов, которые ещё можно скачать (или undef, если параметра $first не было)

3) ETag заголовок с удалёнными кавычками (или undef если его нет)

4) X-Amz-Meta-Md5 заголовок (или undef, если его нет)

=cut

sub download_with_range {
    my ($self, $key, $first, $last) = @_;

    confess "Missing bucket" unless $self->{bucket};

    # TODO: How and when to validate ETag here?
    my $http_request = Net::Amazon::S3::Request::GetObject->new(
        s3     => $self->{client}->s3,
        bucket => $self->{bucket},
        key    => $key,
        method => 'GET',
    )->http_request;

    if (defined $first) {
        $last //= '';
        $http_request->headers->header("Range", "bytes=$first-$last");
    }

    my $http_response = $self->{client}->_send_request_raw($http_request);
    #print $http_request->as_string, $http_response->as_string ;
    if ( $http_response->code == 404 && $http_response->decoded_content =~ m!<Code>NoSuchKey</Code>!) {
        return;
    }
    elsif (is_error($http_response->code)) {
        my ($err) = $http_response->decoded_content =~ m!<Code>(.*)</Code>!;
        $err //= 'none';
        confess "Unknown error ".$http_response->code." $err";
    } else {
        my $left = undef;
        if (defined $first) {
            my $range = $http_response->header('Content-Range') // confess;
            my ($f, $l, $total) = $range =~ m!bytes (\d+)\-(\d+)/(\d+)! or confess;
            $left = $total - ( $l + 1);
        }

        my $etag = $http_response->header('ETag');
        if ($etag) {
            $etag =~ s/^"//;
            $etag =~ s/"$//;
        }

        my $custom_md5 = $http_response->header('X-Amz-Meta-Md5');

        return (\$http_response->decoded_content, $left, $etag, $custom_md5);
    }
}

=head2 size

Получает размер объекта с помощью HTTP HEAD запроса.

Параметры:

1) $self

2) $key - имя объекта

Если объект отсутствует, возвращает undef. Если другая ошибка - исключение.
Возвращает размер, в байтах.

=cut

sub size {
    my ($self, $key) = @_;

    confess "Missing bucket" unless $self->{bucket};

    my $http_request = Net::Amazon::S3::Request::GetObject->new(
        s3     => $self->{client}->s3,
        bucket => $self->{bucket},
        key    => $key,
        method => 'HEAD',
    )->http_request;

    my $http_response = $self->{client}->_send_request_raw($http_request);
    if ( $http_response->code == 404) { # It's not possible to distinct between NoSuchkey and NoSuchBucket??
        return undef;
    }
    elsif (is_error($http_response->code)) {
        confess "Unknown error ".$http_response->code;
    }
    else {
        return $http_response->header('Content-Length') // 0;
    }



}

=head2 delete

Удаляет объект

Параметры:

1) $self

2) $key - имя объекта

Ничего не возвращает. Если объект не сузществовал, никак об этом не сигнализирует.

=cut

sub delete {
    my ($self, $key) = @_;

    $self->_request_object->object( key => $key )->delete;
}

=head2 query_string_authentication_uri

Возвращает Query String Authentication URL для ключа $key, с экспайром $expires

=cut

sub query_string_authentication_uri {
    my ($self, $key, $expires) = @_;

    $self->_request_object->object( key => $key, expires => $expires )->query_string_authentication_uri;
}


1;
