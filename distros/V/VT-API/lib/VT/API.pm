package VT::API;
use strict;
use Carp;

use JSON;
use HTTP::Request::Common;
use LWP::UserAgent;

our $VERSION = '0.12';

sub new {
    croak('Options to VT::API should be key/value pairs, '.
          'not HASH reference') if ref($_[1]) eq 'HASH';

    my ($class, %opts) = @_;
    my $self = {};

    # Public Key.
    $self->{key} = $opts{key} or
        croak('You should specify public API key');

    # LWP::UserAgent Object.
    $self->{ua} = LWP::UserAgent->new(
        agent   => $opts{agent}   || 'Perl/VT-API',
        timeout => $opts{timeout} || 180,
    );

    return bless $self, $class;
}


sub get_file_report {
    my ($self, $resource) = @_;

    croak('You have not specified a resource (md5/sha1/sha256 or permalink '.
          'identifier') if !defined $resource;

    $self->{res} = $self->{ua}->request(
        POST 'https://www.virustotal.com/api/get_file_report.json', [
            resource => $resource,
            key      => $self->{key},
        ],
    );

    return $self->_parse_json();
}


sub scan_file {
    my ($self, $file) = @_;

    croak('You have not specified a file') if !defined $file;

    $self->{res} = $self->{ua}->request(
        POST 'https://www.virustotal.com/api/scan_file.json',
        Content_Type => 'form-data',
        Content      => [
            file => [$file],
            key  => $self->{key},
        ],  
    );

    return $self->_parse_json();
}


sub get_url_report {
    my ($self, $resource) = @_;

    croak('You have not specified a resource (URL or permalink '.
          'identifier') if !defined $resource;

    $self->{res} = $self->{ua}->request(
        POST 'https://www.virustotal.com/api/get_url_report.json', [
            resource => $resource,
            key      => $self->{key},
        ],
    );

    return $self->_parse_json();
}


sub scan_url {
    my ($self, $url) = @_;

    croak('You have not specified a URL that should be '.
          'scanned') if !defined $url;

    $self->{res} = $self->{ua}->request(
        POST 'https://www.virustotal.com/api/scan_url.json', [
            url => $url,
            key => $self->{key},
        ],
    );

    return $self->_parse_json();
}


sub make_comment {
    my ($self, $file_or_url, $comment, $tags) = @_;

    croak('You have not specified a file (md5/sha1/sha256 hash) or URL')
        if !defined $file_or_url;
    croak('You have not specified a comment')
        if !defined $comment;

    $self->{res} = $self->{ua}->request(
        POST 'https://www.virustotal.com/api/make_comment.json', [
            ($file_or_url =~ /^https?:\/\//) ?
                (url  => $file_or_url)       :
                (file => $file_or_url),

            (comment => $comment),

            (defined $tags)                                                   ?
                (tags => (ref($tags) eq 'ARRAY' ? join(',', @$tags) : $tags)) :
                (),

            (key => $self->{key}),
        ],
    );

    return $self->_parse_json();
}


sub _parse_json {
    my ($self) = @_;
    return if !defined $self->{res};

    my $parsed;
    if ($self->{res}->is_success()) {
        undef $self->{errstr};

        eval { $parsed = from_json($self->{res}->content()) };
        if ($@) {
            $@ =~ s/ at .*//;
            $self->{errstr} = $@;
        }
    }
    else {
        $self->{errstr} = $self->{res}->status_line;
    }

    return $parsed;
}


sub errstr {
    my ($self) = @_;
    return $self->{errstr};
}


1;
__END__

=pod

=head1 NAME

VT::API - Perl implementation of VirusTotal Public API


=head1 VERSION

This documentation refers to VT::API version 0.12


=head1 SYNOPSIS

    use VT::API;
    
    # OO-interface.
    my $api = VT::API->new(key => 'YOUR_PUBLIC_KEY');
    
    # Retrieve a file scan report.
    # If query successfull hash reference returned.
    my $res1 = $api->get_file_report('md5/sha1/sha256 or permalink identifier');
    
    # Send and scan a file.
    my $res2 = $api->scan_file('/file/path');
    
    # Retrieve a URL scan report
    my $res3 = $api->get_url_report('http://www.example.com/');
    
    # Submit and scan a URL.
    my $res4 = $api->scan_url('http://www.example.com/');
    my $scan_id;
    
    if ($res4->{result}) {
        $scan_id = $res->{scan_id};
    }
    
    # Make comments on files and URLs.
    my $res5 = $api->make_comment('file hash or URL', 'Comment', ['tag1', 'tag2']);
    
    ...


=head1 DESCRIPTION

VT::API provides unofficial OO interface to VirusTotal Public API.
Please see the terms of use for more information.


=head1 OPTIONS

The options bellow are passed through the constructor of interface.

=head2 C<key =E<gt> I<Your Key>>

Your API key. You will find your personal API key in the inbox of your account.

=head2 C<agent =E<gt> I<string>>

Defines a User-Agent. Default is Perl/VT-API.

=head2 C<timeout =E<gt> I<value>>

Timeout value in seconds. The default value is 180.


=head1 METHODS

VT::API methods.

=head2 my $api = VT::API->new(key => 'Public Key')

=head2 $api->get_file_report($resource)

=head2 $api->scan_file($file)

=head2 $api->get_url_report($resource)

=head2 $api->scan_url($url)

=head2 $api->make_comment($file_or_url, $comment, $tags)

=head2 errstr()


=head1 BUGS AND LIMITATIONS

None known at this time.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc VT::API


=head1 INFORMATION

You can also look for information at:

=over 4

=item * VirusTotal official website

L<http://virustotal.com/>

=item * VirusTotal terms of use

L<http://www.virustotal.com/terms.html>


=back

=head1 AUTHOR

Written by Alexander Nusov.


=head1 COPYRIGHTS AND LICENSE

Copyright (C) 2010, Alexander Nusov <alexander.nusov+cpan <at> gmail.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
