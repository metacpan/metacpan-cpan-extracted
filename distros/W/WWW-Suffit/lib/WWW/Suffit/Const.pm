package WWW::Suffit::Const;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Const - The Suffit constants

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use WWW::Suffit::Const;

=head1 DESCRIPTION

This module contains constants definitions

=head2 TAGS

=over 8

=item B<:GENERAL>

Exports common constants

=item B<:SESSION>

Exports session and token constants

=item B<:SECURITY>

Exports security and cryptography constants

=item B<:MIME>

Exports MIME constants

=item B<:MISC>

Exports miscellaneous constants

=item B<:DICTS>

Exports dictionaries

=item B<:SERVER>

Exports server constants

=back

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<WWW::Suffit>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS/;
$VERSION = '1.00';

use base qw/Exporter/;

use constant {
    PROJECTNAME         => 'Suffit',
    PROJECTNAMEL        => 'suffit',
    PROJECT_ABSTRACT    => 'The Suffit core library',
    DEFAULT_URL         => 'http://localhost',

    # System constants
    IS_TTY              => (-t STDOUT) ? 1 : 0,
    IS_ROOT             => ($> == 0) ? 1 : 0,

    # UID/GID for daemons
    USERNAME            => 'suffit',
    GROUPNAME           => 'suffit',

    # Directories
    DATADIR             => 'suffit',
    HTMLDIR             => 'suffit',

    # Date and time formats
    DATE_FORMAT         => '%Y-%m-%d', # See strftime(3)
    DATETIME_FORMAT     => '%Y-%m-%dT%H:%M:%SZ', # See strftime(3)

    # Session
    SESSION_EXPIRATION  => 3600, # 1 hour
    SESSION_EXPIRE_MAX  => 86400 * 30, # 30 days
    TOKEN_HEADER_NAME   => 'X-Token',
    TOKEN_EXPIRATION    => 86400, # 1 day (for session and access tokens only)
    TOKEN_EXPIRE_MAX    => 86400 * 30, # 30 days (for session and access tokens only)
    TOKEN_FILE_FORMAT   => 'token-%s.tkn',

    # Security and Cryptography
    DEFAULT_SECRET      => 'The_Suffit_API_secret_string_673', # 32 chars
    PRIVATEKEYFILE      => 'rsa-private.key',
    PUBLICKEYFILE       => 'rsa-public.key',
    DIGEST_ALGORITHMS   => [qw/MD5 SHA1 SHA224 SHA256 SHA384 SHA512/],
    DEFAULT_ALGORITHM   => 'SHA256',

    # Misc
    USERNAME_REGEXP     => qr/(?![_.\-])(?!.*[_.\-]{2,})[a-zA-Z0-9_.\-]+(?<![_.\-])/,
    EMAIL_REGEXP        => qr/^[a-zA-Z0-9.!#$%&'*+\/\=?^_`{|}~\-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/,

    # MIME Content Types
    CONTENT_TYPE_TXT    => "text/plain; charset=utf-8",
    CONTENT_TYPE_JSON   => "application/json",

    # Server
    SERVER_UPGRADE_TIMEOUT => 30,
    SERVER_TIMEOUT      => 60,
    SERVER_MAX_CLIENTS  => 1000, # See Mojo::Server::Prefork
    SERVER_MAX_REQUESTS => 100, # See Mojo::Server::Prefork
    SERVER_ACCEPTS      => 0, # See Mojo::Server::Prefork
    SERVER_SPARE        => 2, # See Mojo::Server::Prefork
    SERVER_WORKERS      => 4, # See Mojo::Server::Prefork

    # Dictionaries
    HTTP_METHODS => [qw/
        CONNECT OPTIONS HEAD GET
        POST PUT PATCH DELETE
        TRACE
        ANY MULTI
    /],
};

# Named groups of exports
%EXPORT_TAGS = (
    'GENERAL' => [qw/
        IS_TTY IS_ROOT
        PROJECTNAME PROJECTNAMEL PROJECT_ABSTRACT
        DEFAULT_URL
        DATADIR HTMLDIR
        DATE_FORMAT DATETIME_FORMAT
    /],
    'SESSION' => [qw/
        SESSION_EXPIRATION SESSION_EXPIRE_MAX
        TOKEN_HEADER_NAME TOKEN_EXPIRATION TOKEN_EXPIRE_MAX TOKEN_FILE_FORMAT
    /],
    'SECURITY' => [qw/
        DEFAULT_SECRET
        PRIVATEKEYFILE PUBLICKEYFILE DIGEST_ALGORITHMS DEFAULT_ALGORITHM
    /],
    'MIME' => [qw/
        CONTENT_TYPE_TXT CONTENT_TYPE_JSON
    /],
    'MISC' => [qw/
        USERNAME_REGEXP EMAIL_REGEXP
    /],
    'DICTS' => [qw/
        HTTP_METHODS
    /],
    'SERVER' => [qw/
        SERVER_TIMEOUT SERVER_UPGRADE_TIMEOUT
        SERVER_MAX_CLIENTS SERVER_MAX_REQUESTS
        SERVER_ACCEPTS SERVER_SPARE SERVER_WORKERS
    /],
);

# Items to export into callers namespace by default
# (move infrequently used names to @EXPORT_OK below)
@EXPORT = (
        @{$EXPORT_TAGS{GENERAL}},
    );

# Other items we are prepared to export if requested
@EXPORT_OK = (
        map {@{$_}} values %EXPORT_TAGS
    );

1;

__END__
