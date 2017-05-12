package WebService::ScormCloud::Service::Upload;

use Moose::Role;

with 'WebService::ScormCloud::Service';

=head1 NAME

WebService::ScormCloud::Service::Upload - ScormCloud API "upload" namespace

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use WebService::ScormCloud;

    my $ScormCloud = WebService::ScormCloud->new(
                        app_id      => '12345678',
                        secret_key  => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    );

    my $token = $ScormCloud->getUploadToken;

    my $remote_filename = $ScormCloud->uploadFile($file, $token);

    my $progress = $ScormCloud->getUploadProgress($token);

    my $uploaded_files = $ScormCloud->listFiles;

=head1 DESCRIPTION

This module defines L<WebService::ScormCloud> API methods in the "upload"
namespace.  See L<WebService::ScormCloud> for more info.

=cut

use Carp;

requires 'process_request';

=head1 METHODS

=head2 getUploadToken

Get and return an upload token to be used with a file upload.

=cut

sub getUploadToken    ## no critic (NamingConventions::Capitalization)
{
    my ($self) = @_;

    return $self->process_request(
        {method => 'upload.getUploadToken'},
        sub {
            my ($response) = @_;

            return $response->{token}->{id};
        }
    );
}

=head2 getUploadProgress ( I<token> )

Given an upload token, get progress info for the corresponding
upload.

=cut

sub getUploadProgress    ## no critic (NamingConventions::Capitalization)
{
    my ($self, $token) = @_;

    croak 'Missing token' unless $token;

    return $self->process_request(
        {method => 'upload.getUploadProgress', token => $token},
        sub {
            my ($response) = @_;

            return {} if exists $response->{empty};
            return $response->{upload_progress};
        }
    );
}

=head2 uploadFile ( I<file> [ , I<token> ] )

Upload a file.  Will generate an upload token is none is supplied.

Returns the generated destination path on the remote filesystem.

=cut

sub uploadFile    ## no critic (NamingConventions::Capitalization)
{
    my ($self, $file, $token) = @_;

    croak 'Missing file' unless $file;

    $token ||= $self->getUploadToken;

    croak 'Cannot generate upload token' unless $token;

    return $self->process_request(
        {method => 'upload.uploadFile', token => $token},
        sub {
            my ($response) = @_;

            return $response->{location};
        },
        {request_content => [file => [$file]]}
                                 );
}

=head2 listFiles

Return a list of files that have been uploaded using the given AppID.

=cut

sub listFiles    ## no critic (NamingConventions::Capitalization)
{
    my ($self) = @_;

    return $self->process_request(
        {method => 'upload.listFiles'},
        sub {
            my ($response) = @_;

            die "bad\n" unless exists $response->{dir};
            if ($response->{dir}->{file})
            {
                return $response->{dir}->{file};
            }
            else
            {
                return [];    # empty list
            }
        },
        {xml_parser => {ForceArray => ['file']}}
                                 );
}

=head2 deleteFiles ( I<file> )

Delete a file that was uploaded.

Note: This method only handles one file at a time even though the
API service can accept multiple files for deletion in a single
request.

=cut

sub deleteFiles    ## no critic (NamingConventions::Capitalization)
{
    my ($self, $file) = @_;

    croak 'Missing file' unless $file;

    return $self->process_request(
        {method => 'upload.deleteFiles', file => $file},
        sub {
            my ($response) = @_;

            die "bad\n" unless $response->{results}->[0]->{file} eq $file;
            die "bad\n" unless $response->{results}->[0]->{deleted} eq 'true';
            return 1;
        },
        {
         xml_parser => {
                        ForceArray => ['result'],
                        GroupTags  => {'results' => 'result',},
                       }
        }
    );
}

1;

__END__

=head1 SEE ALSO

L<WebService::ScormCloud>

=head1 AUTHOR

Larry Leszczynski, C<< <larryl at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-scormcloud at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-ScormCloud>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

Patches more than welcome, especially via GitHub:
L<https://github.com/larryl/ScormCloud>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::ScormCloud::Service::Upload

You can also look for information at:

=over 4

=item * GitHub

L<https://github.com/larryl/ScormCloud>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-ScormCloud>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-ScormCloud>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-ScormCloud>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-ScormCloud/>

=back

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Larry Leszczynski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

