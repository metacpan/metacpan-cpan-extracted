package Yandex::Disk;

use 5.008001;
use strict;
use warnings;
use utf8;
use Yandex::Disk::Public;
use Carp qw/croak carp/;
use LWP::UserAgent;
use JSON::XS;
use File::Basename;
use URI::Escape;
use Encode;
use IO::Socket::SSL;

our $VERSION    = '0.04';

my $WAIT_RETRY  = 20;
my $BUFF_SIZE = 8192;

sub new {
    my $class       = shift;
    my %opt         = @_;
    my $self        = {};
    $self->{token}  = $opt{-token} || croak "Specify -token param";
    my $ua          = LWP::UserAgent->new;
    $ua->agent("Yandex::Disk perl module");
    $ua->default_header('Accept' => 'application/json');
    $ua->default_header('Content-Type'  => 'application/json');
    $ua->default_header('Connection'    => 'keep-alive');
    $ua->default_header('Authorization' => 'OAuth ' . $self->{token});
    $self->{ua}     = $ua;
    $self->{public_info} = {};
    return bless $self, $class;
}


sub getDiskInfo {
    my $self = shift;
    my $url = 'https://cloud-api.yandex.net/v1/disk/';
    my $res = $self->__request($url, "GET");
    if ($res->is_success) {
        return __fromJson($res->decoded_content);
    }
    else {
        croak "Cant execute request to $url: " . $res->status_line;
    }
}

sub uploadFile {
    my $self        = shift;
    my %opt         = @_;
    my $overwrite   = $opt{-overwrite};
    my $file        = $opt{-file} || croak "Specify -file param";
    my $remote_path = $opt{-remote_path} || croak "Specify -remote_path param";
    $overwrite = 1 if not defined $overwrite;

    if (not -f $file) {
        croak "File $file not exists";
    }

    $overwrite = $overwrite ? 'true' : 'false';

    #Delete end slash
    $remote_path =~ s/^\/|\/$//g;
    $remote_path = sprintf("/%s/%s", $remote_path, basename($file));

    my $param = "?path=" . uri_escape($remote_path) . "&overwrite=$overwrite";
    my $res = $self->__request('https://cloud-api.yandex.net/v1/disk/resources/upload' . $param, "GET");
    my $url_to_upload;
    my $code = $res->code;
    if ($code eq '409') {
        croak "Folder $remote_path not exists";
    }
    elsif ($code eq '200') {
        $url_to_upload = __fromJson($res->decoded_content)->{href};
    }
    else {
        croak "Cant uploadFile: " . $res->status_line;
    }
    
    my $upl_code = __upload_file($url_to_upload, $file);
    if ($upl_code ne '201') {
        croak "Cant upload file. Code: $code";
    }
    return 1;
}

sub createFolder {
    my $self        = shift;
    my %opt         = @_;
    my $path        = $opt{-path} || croak "Specify -path param";
    my $recursive   = $opt{-recursive};

    if ($recursive) {
        my @half_path;
        for my $l_path (split /\//, $path) {
            push @half_path, $l_path;
            $self->createFolder( -path => join('/', @half_path) );
        }
    }

    my $res = $self->__request('https://cloud-api.yandex.net/v1/disk/resources/?path=' . uri_escape($path), "PUT");
    my $code = $res->code;
    if ($code eq '409') {
        #Папка или существует или не создана родительская папка
        my $json_res = __fromJson($res->decoded_content);
        if ($json_res->{error} eq 'DiskPathPointsToExistentDirectoryError') {
            return 1;
        }
        croak $json_res->{description};
    }
    elsif ($code ne '201') {
        croak "Cant create folder $path. Error: " . $res->status_line;
    }

    return 1;
}

sub deleteResource {
    my $self = shift;
    my %opt = @_;
    my $path = $opt{-path} || croak "Specify -path param";
    my $wait = $opt{-wait};
    my $permanently = $opt{-permanently};

    $permanently = $permanently ? 'true' : 'false';

    my $res = $self->__request('https://cloud-api.yandex.net/v1/disk/resources?path=' . uri_escape($path) . "&permanently=$permanently", "DELETE");
    my $code = $res->code;
    if ($code eq '204') {
        #Free folder
        return 1;
    }
    elsif ($code eq '202') {
        if ($wait) {
            my $href = __fromJson($res->decoded_content)->{href};
            $self->__waitResponse($href, $WAIT_RETRY) or croak "Timeout to wait response. Try increase $WAIT_RETRY variable";
        }
        return 1;
    }
    else {
        croak "Cant delete $path. Error: " . $res->status_line;
    }
}

sub downloadFile {
    my $self = shift;
    my %opt = @_;
    my $path = $opt{-path} || croak "Specify -path param";
    my $file = $opt{-file} || croak "Specify -file param";

    my $res = $self->__request('https://cloud-api.yandex.net/v1/disk/resources/download?path=' . uri_escape($path), "GET");
    my $code = $res->code;
    if ($code ne '200') {
        croak "Error on request file $path: " . $res->status_line;
    }
    my $download_url = __fromJson($res->decoded_content)->{href};

    $self->__download($download_url, $file);
    return 1;
}

sub emptyTrash {
    my $self = shift;
    my %opt = @_;
    my $path = $opt{-path} || '';
    my $wait = $opt{-wait};

    my $param = $path ? '?path=' . uri_escape($path) : '';
    my $res = $self->__request('https://cloud-api.yandex.net/v1/disk/trash/resources/' . $path, 'DELETE');
    my $code = $res->code;
    if ($code eq '204') {
        return 1;
    }
    elsif ($code eq '202') {
        if ($wait) {
            my $href = __fromJson($res->decoded_content)->{href};
            $self->__waitResponse($href, $WAIT_RETRY) or croak "Timeout to wait response. Try increase $WAIT_RETRY variable";
        }
        return 1;
    }
    else {
        $path = "by path $path" if $path;
        croak "Cant empty trash$path. Error: " . $res->status_line;
    }
}

sub listFiles {
    my $self = shift;
    my %opt = @_;
    my $path = $opt{-path} || croak "Specify -path param";
    my $limit = $opt{-limit} || 999999;
    my $offset = $opt{-offset};
    $offset = 0 if not $offset;

    my $param = '?path=' . uri_escape($path) . "&limit=$limit&offset=$offset&fields=_embedded.items";
    my $res = $self->__request('https://cloud-api.yandex.net/v1/disk/resources' . $param, 'GET');
    my $code = $res->code;
    if ($code ne '200') {
        croak "Error on listFiles. Error: " . $res->status_line;
    }
    my $json_res = __fromJson($res->decoded_content);

    return $json_res->{_embedded}->{items};
}

sub listAllFiles {
    my $self = shift;
    my %opt = @_;
    my $limit = $opt{-limit} || 999999;
    my $media_type = $opt{-media_type};
    my $offset = $opt{-offset};
    $offset = 0 if not $offset;

    my $param = "?limit=$limit&offset=$offset";
    $param .= '&media_type=' . $media_type if $media_type;

    my $res = $self->__request('https://cloud-api.yandex.net/v1/disk/resources/files' . $param, 'GET');
    my $code = $res->code;
    if ($code ne '200') {
        croak "Error on listFiles. Error: " . $res->status_line;
    }
    my $json_res = __fromJson($res->decoded_content);

    return $json_res->{items};
}

sub lastUploadedFiles {
    my $self = shift;
    my %opt = @_;
    my $limit = $opt{-limit} || 999999;
    my $media_type = $opt{-media_type};

    my $param = "?limit=$limit";
    $param .= '&media_type=' . $media_type if $media_type;

    my $res = $self->__request('https://cloud-api.yandex.net/v1/disk/resources/last-uploaded' . $param, 'GET');
    my $code = $res->code;
    if ($code ne '200') {
        croak "Error on listFiles. Error: " . $res->status_line;
    }
    my $json_res = __fromJson($res->decoded_content);

    return $json_res->{items};
}


sub public {
    my $self = shift;
    return Yandex::Disk::Public->new( -token => $self->{token} );
}

sub __download {
    my ($self, $url, $fname) = @_;
    my $ua = $self->{ua};

    open my $FL, ">$fname" or croak "Cant open $fname to write $!";
    binmode $FL;
    my $res = $ua->get($url, ':read_size_hint' => $BUFF_SIZE, ':content_cb' => sub {print $FL $_[0];});
    close $FL;
    if ($res->code eq '200') {
        return 1;
    }
    croak "Cant download file $url to $fname. Error: " . $res->status_line;
}

sub __waitResponse {
    #Дожидается ответа о статусе операции
    my ($self, $url, $retry) = @_;

    while ($retry > 0) {
        my $res = $self->__request($url, "GET");
        my $code = $res->code;
        if ($code eq '200' && __fromJson($res->decoded_content)->{status} eq 'success') {
            return 1;
        }
        sleep 1;
        $retry--;
    }
    return;
}


sub __upload_file {
    #Buffered chunked upload file
    my ($url, $file) = @_;

    my $u1 = URI->new($url);

#    $IO::Socket::SSL::DEBUG = 3;
    my $host = $u1->host;
    my $port = $u1->port;
    my $path = $u1->path;

    my $sock = IO::Socket::SSL->new(
                                        PeerAddr    => $host,
                                        PeerPort    => $port,
                                        Proto       => 'tcp',
                                    ) or croak "Cant connect to $host:$port";
    binmode $sock;
    $sock->autoflush(1);

    $sock->print("PUT $path HTTP/1.1\n");
    $sock->print("HOST: $host\n");
    $sock->print("Connection: close\n");
    $sock->print("Content-Type: application/json\n");
    $sock->print("Transfer-Encoding: chunked\n");
    $sock->print("\n");

    open my $FH, "<$file" or croak "Cant open $file $!";
    binmode $FH;
    my $filebuf;
    while (my $bytes = read($FH, $filebuf, $BUFF_SIZE)) {
        my $hex = sprintf("%X", $bytes);
        $sock->print($hex) or croak "Cant print to socket";
        $sock->print("\r\n") or croak "Cant print to socket";

        $sock->print($filebuf) or croak "Cant print to socket";
        $sock->print("\r\n") or croak "Cant print to socket";
    }
    close $FH;

    $sock->print("0\r\n") or croak "Cant print to socket";
    $sock->print("\r\n") or croak "Cant print to socket";
                       
    my @answer = $sock->getlines();
    $sock->close();

    my ($code) = $answer[0] =~ /(\d{3})/;

    return $code;
}


sub __request {
    my ($self, $url, $type) = @_;

    my $ua = $self->{ua};
    my $req = HTTP::Request->new($type => $url);
    my $res = $ua->request($req);
    
    return $res;
}

sub __fromJson {
    my $string = ref($_[0]) ? $_[1] : $_[0];
    my $res = JSON::XS::decode_json($string);
    return $res;
}


sub errstr {
    return shift->{errstr};
}
 
1;

__END__
=pod

=encoding UTF-8

=head1 NAME

B<Yandex::Disk> - a simple API for Yandex Disk

=head1 VERSION

version 0.04

=head1 SYNOPSYS
    
    use Yandex::Disk;

    my $TOKEN = 'aaaabbbbccc'; #Auth token. You can get token from module L<Yandex::OAuth>
    my $disk = Yandex::Disk->new( -token => $TOKEN ); 
    
    #Get info about disk and print
    my $diskinfo = $disk->getDiskInfo();
    p $diskinfo;

    #Upload file from local disk to Yandex disk
    $disk->uploadFile(
                        -overwrite      => 1,
                        -file           => 'my_test_upload_file',  # Path to file on local disk
                        -remote_path    => "/Upload",              # Folder on Yandex Disk
                        ) or die "Cant upload file";

    #Download file form Yandex Disk to local disk
    $disk->downloadFile(
                        -path   => "/Upload/my_test_upload_file",   # Path to file on Yandex Disk
                        -file   => 'my_test_upload_file',           # Path to save file on local disk
                        ) or die "Cant download file";

    #Create folder on Yandex Disk
    $disk->createFolder(
                            -path       => '/Temp/new_folder',      # Path to new folder on Yandex Disk
                            -recursive  => 1,                       # Recursive create folder

    #Share file and get public link
    my $public = $disk->public();
    $public->publicFile(
                            -path   => "/Upload/my_test_upload_file",  # Path to file, which need share
                        ) or die "Cant public file";
    my $publicUrl = $public->publicUrl() or die "Cant get public url";




=head1 METHODS

=head2 getDiskInfo()

Return disk info data as hashref

    my $info = $disk->getDiskInfo();

    $info:
    Example output:
        {
            max_file_size    1073741824,
            revision         14987326771107,
            system_folders   {
                applications    "disk:/Приложения",
                downloads       "disk:/Загрузки/",
                facebook        "disk:/Социальные сети/Facebook",
                google          "disk:/Социальные сети/Google+",
                instagram       "disk:/Социальные сети/Instagram",
                mailru          "disk:/Социальные сети/Мой Мир",
                odnoklassniki   "disk:/Социальные сети/Одноклассники",
                photostream     "disk:/Фотокамера/",
                screenshots     "disk:/Скриншоты/",
                social          "disk:/Социальные сети/",
                vkontakte       "disk:/Социальные сети/ВКонтакте"
            },
            total_space      67645734912,
            trash_size       0,
            used_space       19942927435,
            user             {
                login   "login",
                uid     123456
            }
        }

=head2 uploadFile(%opt)

Upload file (-file) to Yandex Disk in folder (-remote_path). Return 1 if success

    $disk->uploadFile(-file => '/root/upload', -remote_path => 'Temp', -overwrite => 0);
    Options:
        -overwrite          => Owervrite file if exists (default: 1)
        -remote_path        => Path to upload file on disk
        -file               => Path to local file

=head2 createFolder(%opt)
    
Create folder on disk

    $disk->createFolder(-path => 'Temp/test', -recursive => 1);
    Options:
        -path               => Path to folder,
        -recursive          => Recursive create folder (default: 0)

=head2 deleteResource(%opt)

Delete file or folder from disk. Return 1 if success

    $disk->deleteResource(-path => 'Temp/test');
    Options:
        -path               => Path to delete file or folder
        -permanently        => Do not move to trash, delete permanently (default: 0(moving file to trash))
        -wait               => Wait delete resource (defailt: 0)

=head2 downloadFile(%opt)

Download file from Yandex Disk to local file. Method overwrites local file if exists. Return 1 if success

    $disk->downloadFile(-path => 'Temp/test', -file => 'test');
    Options:
        -path               => Path to file on Yandex Disk
        -file               => Path to local destination

=head2 emptyTrash(%opt)

Empty trash. If -path specified, delete -path resource, otherwise - empty all trash. Return 1 if success
    
    $disk->emptyTrash(-path => 'Temp/test');        #Delete '/Temp/test' from trash
    Options:
        -path               => Path to resource on Yandex Disk to delete from trash
        -wait               => Wait empty trash (defailt: 0)

    $disk->emptyTrash;      #Full empty trash

=head2 listFiles(%opt)

List files in folder. Return arrayref to hashref(keys: "path", "type", "name", "preview", "created", "modified", "md5", "mime_type", "size")

    $disk->listFiles(-path => 'Temp/test');
    Options:
        -path               => Path to resource (file or folder) on Yandex Disk for which need get info
        -limit              => Limit max files to output (default: unlimited)
        -offset             => Offset records from start (default: 0)

=head2 listAllFiles(%opt)

List all files on YandexDisk. Return arrayref to hashref(keys: "path", "type", "name", "preview", "created", "modified", "md5", "mime_type", "size")
    
    $disk->listAllFiles();
    Options:
        -media_type         => Type of file to return. Afaible types listed below. Multiple types can be specified by using a comma. (default: all types) 
        -limit              => Limit max files to output (default: unlimited)
        -offset             => Offset records from start (default: 0)

Media types:
audio, backup, book, compressed, data, development, diskimage, document, encoded, executable, flash, font, image, settings, spreadsheet, text, unknown, video, web

=head2 lastUploadedFiles(%opt)

List last uploaded files. Return arrayref to hashref(keys: "path", "type", "name", "preview", "created", "modified", "md5", "mime_type", "size")
    
    $disk->lastUploadedFiles();
    Options:
        -media_type         => Type of file to return. Afaible types same as listAllFiles. Multiple types can be specified by using a comma. (default: all types) 
        -limit              => Limit max files to output (default: unlimited)



=head2 Public files

my $public = $disk->public();  #Create L<Yandex::Disk::Public> object

=head1 CLI/API
Sparrow plugin https://sparrowhub.org/info/yandex-disk

=head1 DEPENDENCE

L<LWP::UserAgent>, L<JSON::XS>, L<URI::Escape>, L<IO::Socket::SSL>

=head1 AUTHORS

=over 4

=item *

Pavel Andryushin <vrag867@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Pavel Andryushin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
