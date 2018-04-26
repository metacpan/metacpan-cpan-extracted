#
#===============================================================================
#
#         FILE: Public.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01.10.2017 12:34:59
#     REVISION: ---
#===============================================================================
package Yandex::Disk::Public;

use 5.008001;
use strict;
use warnings;
use utf8;
use URI::Escape;
use Carp 'croak';
 
use base 'Yandex::Disk';

#Class for Public actions under Yandex Disk files and folders

our $VERSION = '0.04';

sub publicFile {
    my $self = shift;
    my %opt = @_;
    my $path = $opt{-path} || croak "Specify -path param";

    my $res = $self->__request('https://cloud-api.yandex.net/v1/disk/resources/publish?path=' . uri_escape($path), "PUT");
    my $code = $res->code;
    if ($code ne '200') {
        croak "Cant public file $path. Error: " . $res->status_line;
    }
    my $metainfo_href = $self->__fromJson($res->decoded_content)->{href};
    my $res_get_metainfo = $self->__getPublicUrl($metainfo_href);
    return $res_get_metainfo;
}

sub unpublicFile {
    my $self = shift;
    my %opt = @_;
    $self->{public_info} = {};
    my $path = $opt{-path} || croak "Specify -path param";

    my $res = $self->__request('https://cloud-api.yandex.net/v1/disk/resources/unpublish?path=' . uri_escape($path), "PUT");
    my $code = $res->code;
    if ($code ne '200') {
        croak "Cant unpublic file $path. Error: " . $res->status_line;
    }
    return 1;
}

sub listPublished {
    my $self = shift;
    my %opt = @_;
    my $limit = $opt{-limit};
    my $offset = $opt{-offset} || 0;
    my $type = $opt{-type};

    $limit = 999999 if not defined $limit;

    if ($type && ($type ne 'dir' && $type ne 'file')) {
        croak "Wrong -type value (dir/file)";
    }

    my $param = "limit=$limit&offset=$offset";
    $param .= "&type=$type" if $type;

    my $res = $self->__request('https://cloud-api.yandex.net/v1/disk/resources/public?' . $param, "GET");
    my $code = $res->code;
    if ($code ne '200') {
        croak "Cant get listPublished. Error: " . $res->status_line;
    }
    my $items = $self->__fromJson($res->decoded_content)->{items};
    return $items;
}

sub __getPublicUrl {
    my ($self, $href) = @_;
    my $res = $self->__request($href, "GET");
    my $code = $res->code;
    if ($code ne '200') {
        croak "Cant get public url by href: $href. Error: " . $res->status_line;
    }
    $self->{public_info} = $self->__fromJson($res->decoded_content);
    return 1;
}

sub publicUrl {
    return shift->{public_info}->{public_url};
}

sub publicType {
    return shift->{public_info}->{type};
}

1;

__END__
=pod

=encoding UTF-8

=head1 NAME

B<Yandex::Disk::Public> - public and unpublic yandex disk resources(files and folders)

=head1 VERSION

version 0.04

=head1 SYNOPSIS
    use Yandex::Disk;

    my $token = "my token";
    my $disk = Yandex::Disk( -token => $token);   #Create Yandex::Disk object
    my $public = $disk->public;                   #Create Yandex::Disk::Public object

    #Public file '/Temp/small_file'
    $public->publicFile (-path => '/Temp/small_file');

=head1 METHODS

=head2 publicFile(%opt)

Make file or folder as public
    $disk->publicFile ( -path => '/Temp/small_file' ) or die "Cant public file"; #Make file '/Temp/small_file' as public
    Options:
        -path               => Path to resource on yandex disk, where need public

=head2 unpublicFile(%opt)

Remove public access to resources
    $disk->unpublicFile( -path => '/Temp/small_file' ) or die "Cant unpublic file";
    Options:
        -path               => Path to resource on yandex disk, where need public

=head2 listPublished(%opt) 

Return array hashref with published files
    my $list = $disk->listPublished();
    Options:
        -limit              => Limit max files to output (default: unlimited)
        -offset             => Offset records from start (default: 0)
        -type               => dir/file (default: undef (display dirs and files)
    
=head2 publicUrl()

Get public url from published file. Return undef if error

=head2 publicType()

Get type of published resource. Retutn undef if error


=cut
