package Wx::Perl::FSHandler::LWP;

=head1 NAME

C<Wx::Perl::FSHandler::LWP> - file system handler based upon LWP

=head1 SYNOPSIS

  my $ua = LWP::UserAgent->new;

  # customize the User Agent, set proxy, supported protocols, ...

  my $handler = Wx::Perl::FSHandler::LWP->new( $ua );

  Wx::FileSystem::AddHandler( $handler );

=head1 DESCRIPTION

The C<Wx::Perl::FSHandler::LWP> is a C<wxFileSystemHandler>
implementation based upon C<LWP::UserAgent>, and is meant as a
superior replacement for C<wxInternetFSHandler>.

=cut

use Wx::FS;

use strict;
use base 'Wx::PlFileSystemHandler';

use LWP::UserAgent;
use IO::Scalar;

our $VERSION = '0.03';

=head2 new

  my $handler = Wx::Perl::FSHandler::LWP->new( $ua );

Creates a new instance. C<$ua> must be an object of class
C<LWP::UserAgent>, which will be used to handle requests.

=cut

sub new {
    my( $class, $ua ) = @_;
    my $self = $class->SUPER::new;

    $self->{user_agent} = $ua;

    return $self;
}

=head2 CanOpen

Called internally by C<Wx::FileSystem>. Calls C<is_protocol_supported>
on the user agent to determine if the location can be opened.

=cut

sub CanOpen {
    my( $self, $location ) = @_;
    my $uri = URI->new( $location );

    return $self->user_agent->is_protocol_supported( $uri->scheme );
}

=head2 OpenFile

Called internally by C<Wx::FileSystem>. Uses the user agent to fetch
the URL and returns a C<Wx::FSFile> representing the result.

=cut

sub OpenFile {
    my( $self, $fs, $location ) = @_;

    # work around bug in Wx::FileSystem: remove artificial '//'
    if(    index( $location, $fs->GetPath ) == 0
        && substr( $location, length( $fs->GetPath ) - 1, 2 ) eq '//' ) {
        substr $location, length( $fs->GetPath ) - 1, 2, '/';
    }
    my $uri = URI->new( $location );
    my $request = HTTP::Request->new( 'GET', $uri );
    my $response = $self->user_agent->request( $request, undef );

    return undef unless $response->is_success;

    my $value = $response->content;
    my $fh = IO::Scalar->new( \$value );
    my $file = Wx::FSFile->new( $fh, $response->base,
                                scalar $response->content_type,
                                $uri->fragment || '' );

    return $file;
}

=head2 user_agent

  my $ua = $handler->user_agent;

Returns the C<LWP::UserAgent> object used to handle requests.

=cut

sub user_agent   { $_[0]->{user_agent} }

=head1 ENVIRONMENTAL VARIABLES

See L<LWP::UserAgent|LWP::UserAgent>.

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=head1 LICENSE

Copyright (c) 2003, 2006 Mattia Barbon.

This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<LWP::UserAgent|LWP::UserAgent>

wxFileSystem and wxFileSystemHandler in wxPerl documentation.

=cut

1;
