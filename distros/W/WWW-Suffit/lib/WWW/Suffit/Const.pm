package WWW::Suffit::Const;
use strict;
use utf8;
use feature ':5.16';

=encoding utf8

=head1 NAME

WWW::Suffit::Const - The Suffit constants

=head1 SYNOPSIS

    use WWW::Suffit::Const;

=head1 DESCRIPTION

This module contains constants definitions

=head2 TAGS

=over 8

=item B<:DIR>

Exports FHS DIR constants

See L<See https://www.pathname.com/fhs/pub/fhs-2.3.html>,
L<http://www.gnu.org/software/autoconf/manual/html_node/Installation-Directory-Variables.html>,
L<Sys::Path>

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

our $VERSION = '1.03';

use base qw/Exporter/;

use Config qw//;
use File::Spec qw//;

use constant {
    DEFAULT_URL         => 'http://localhost',

    # System constants
    IS_TTY              => (-t STDOUT) ? 1 : 0,
    IS_ROOT             => ($> == 0) ? 1 : 0,

    # Date and time formats (see strftime(3))
    DATE_FORMAT         => '%Y-%m-%d', # POSIX::strftime(DATE_FORMAT, localtime($t))
    TIME_FORMAT         => '%H:%M:%S', # POSIX::strftime(TIME_FORMAT, localtime($t))
    DATETIME_FORMAT     => '%Y-%m-%dT%H:%M:%S', # POSIX::strftime(DATETIME_FORMAT, localtime($t))
    DATE_TIME_FORMAT    => '%Y-%m-%d %H:%M:%S', # POSIX::strftime(DATE_TIME_FORMAT, localtime($t))

    # Session
    SESSION_EXPIRATION  => 3600, # 1 hour
    SESSION_EXPIRE_MAX  => 86400 * 30, # 30 days
    TOKEN_HEADER_NAME   => 'X-Token',
    TOKEN_EXPIRATION    => 86400, # 1 day (for session and access tokens only)
    TOKEN_EXPIRE_MAX    => 86400 * 30, # 30 days (for session and access tokens only)
    TOKEN_FILE_FORMAT   => 'token-%s.tkn',

    # Files
    AUTHDBFILE          => 'suffit-auth.db',

    # Security and Cryptography
    DEFAULT_SECRET      => 'Suffit!AP1$ecret%String_r.673-@w',
    PRIVATEKEYFILE      => 'rsa-private.key',
    PUBLICKEYFILE       => 'rsa-public.key',
    DIGEST_ALGORITHMS   => [qw/MD5 SHA1 SHA224 SHA256 SHA384 SHA512/],
    DEFAULT_ALGORITHM   => 'SHA256',

    # JWT/JTI
    JWT_REGEXP          => qr/^[A-Za-z0-9_-]{2,}(?:\.[A-Za-z0-9_-]{2,}){2}$/,
    JTI_REGEXP          => qr/[a-zA-Z0-9\-_]{8,64}/,

    # Misc
    USERNAME_REGEXP     => qr/(?![_.\-])(?!.*[_.\-]{2,})[a-zA-Z0-9_.\-]+(?<![_.\-])/,
    EMAIL_REGEXP        => qr/^[a-zA-Z0-9.!#$%&'*+\/\=?^_`{|}~\-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/,

    # MIME Content Types
    CONTENT_TYPE_HTML   => "text/html; charset=utf-8",
    CONTENT_TYPE_TXT    => "text/plain; charset=utf-8",
    CONTENT_TYPE_JSON   => "application/json",

    # Server
    SERVER_UPGRADE_TIMEOUT => 30,
    SERVER_TIMEOUT      => 60,
    SERVER_MAX_CLIENTS  => 1000, # See Mojo::Server::Prefork
    SERVER_MAX_REQUESTS => 100, # See Mojo::Server::Prefork
    SERVER_MAX_MESSAGE_SIZE => 16*1024*1024, # '16MiB' See MOJO_MAX_MESSAGE_SIZE
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
    AUTHZ_PROVIDERS => [qw[
        Default
        User/Group
        Host
        Env
        Header
    ]],
    AUTHZ_ENTITIES => {
      # Provider           Entities
        'Default'       => [qw/Allow Deny/], # allowed granted denied
        'User/Group'    => [qw/User Group Valid-User/],
        'Host'          => [qw/Host IP/],
        'Env'           => [qw/LANG LOGNAME MOJO_MODE USER USERNAME USR1 USR2 USR3/],
        'Header'        => [qw/Accept Host User-Agent X-Token X-Auth X-OWL-Auth X-Usr1 X-Usr2 X-Usr3/],
    },
    AUTHZ_OPERATOTS => [
        {name => 'eq', operator => '==', title => 'equal to'},
        {name => 'ne', operator => '!=', title => 'not equal'},
        {name => 'gt', operator => '>',  title => 'greater than'},
        {name => 'lt', operator => '<',  title => 'less than'},
        {name => 'ge', operator => '>=', title => 'greater than or equal to'},
        {name => 'le', operator => '<=', title => 'less than or equal to'},
        {name => 're', operator => '=~', title => 'regexp match'},
        {name => 'rn', operator => '!~', title => 'regexp not match'},
    ],

};

# Named groups of exports
our %EXPORT_TAGS = (
    'GENERAL' => [qw/
        IS_TTY IS_ROOT
        DEFAULT_URL
        DATE_FORMAT TIME_FORMAT DATETIME_FORMAT DATE_TIME_FORMAT
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
        CONTENT_TYPE_HTML CONTENT_TYPE_TXT CONTENT_TYPE_JSON
    /],
    'MISC' => [qw/
        USERNAME_REGEXP EMAIL_REGEXP
        JWT_REGEXP JTI_REGEXP
    /],
    'DICTS' => [qw/
        HTTP_METHODS
        AUTHZ_PROVIDERS AUTHZ_ENTITIES AUTHZ_OPERATOTS
    /],
    'SERVER' => [qw/
        SERVER_TIMEOUT SERVER_UPGRADE_TIMEOUT
        SERVER_MAX_CLIENTS SERVER_MAX_REQUESTS
        SERVER_MAX_MESSAGE_SIZE
        SERVER_ACCEPTS SERVER_SPARE SERVER_WORKERS
    /],
    'DIR' => [qw/
        PREFIX LOCALSTATEDIR SYSCONFDIR SRVDIR
        BINDIR SBINDIR DATADIR DOCDIR LOCALEDIR MANDIR LOCALBINDIR
        CACHEDIR LOGDIR SPOOLDIR RUNDIR LOCKDIR SHAREDSTATEDIR WEBDIR
    /],
    'FILE' => [qw/
        AUTHDBFILE
    /],
);

# Items to export into callers namespace by default
# (move infrequently used names to @EXPORT_OK below)
our @EXPORT = (
        @{$EXPORT_TAGS{GENERAL}},
    );

# Other items we are prepared to export if requested
our @EXPORT_OK = (
        map {@{$_}} values %EXPORT_TAGS
    );

# Correct tags: makes lowercase tags as aliases of original uppercase tags
foreach my $k (keys %EXPORT_TAGS) {
    next if exists $EXPORT_TAGS{(lc($k))};
    $EXPORT_TAGS{(lc($k))} = $EXPORT_TAGS{$k} if $k =~ /^[A-Z_]+$/;
}

#
# Filesystem Hierarchy Standard
#
# See http://www.gnu.org/software/autoconf/manual/html_node/Installation-Directory-Variables.html
# See https://www.pathname.com/fhs/pub/fhs-2.3.html
#
my $prefix = $Config::Config{'prefix'} // '';
my $bindir = $Config::Config{'bin'} // File::Spec->catdir($prefix, 'bin');
my $localstatedir = $prefix eq '/usr' ? '/var' : File::Spec->catdir($prefix, 'var');
my $sysconfdir = $prefix eq '/usr' ? '/etc' : File::Spec->catdir($prefix, 'etc');
my $srvdir = $prefix eq '/usr' ? '/srv' : File::Spec->catdir($prefix, 'srv');

# Root dirs
*PREFIX = sub { $prefix };                  # prefix              /usr
*LOCALSTATEDIR = sub { $localstatedir };    # localstatedir       /var
*SYSCONFDIR = sub { $sysconfdir };          # sysconfdir          /etc
*SRVDIR = sub { $srvdir };                  # srvdir              /srv

# Prefix related dirs
*BINDIR = sub { $bindir };                                                              # bindir    /usr/bin
*SBINDIR = sub { state $sbindir = File::Spec->catdir($prefix, 'sbin') };                # sbindir   /usr/sbin
*DATADIR = sub { state $datadir = File::Spec->catdir($prefix, 'share') };               # datadir   /usr/share
*DOCDIR = sub { state $docdir = File::Spec->catdir($prefix, 'share', 'doc') };          # docdir    /usr/share/doc
*LOCALEDIR = sub { state $localedir = File::Spec->catdir($prefix, 'share', 'locale') }; # localedir /usr/share/locale
*MANDIR = sub { state $mandir = File::Spec->catdir($prefix, 'share', 'man') };          # mandir    /usr/share/man
*LOCALBINDIR = sub { state $localbindir = File::Spec->catdir($prefix, 'local', 'bin') };# localbindir  /usr/local/bin

# Local State related Dirs
*CACHEDIR = sub { state $cachedir = File::Spec->catdir($localstatedir, 'cache') };      # cachedir  /var/cache
*LOGDIR = sub { state $logdir = File::Spec->catdir($localstatedir, 'log') };            # logdir    /var/log
*SPOOLDIR = sub { state $spooldir = File::Spec->catdir($localstatedir, 'spool') };      # spooldir  /var/spool
*RUNDIR = sub { state $rundir = File::Spec->catdir($localstatedir, 'run') };            # rundir    /var/run
*LOCKDIR = sub { state $lockdir = File::Spec->catdir($localstatedir, 'lock') };         # lockdir   /var/lock
*SHAREDSTATEDIR = sub { state $sharedstatedir = File::Spec->catdir($localstatedir, 'lib') }; # sharedstatedir  /var/lib
*WEBDIR = sub { state $webdir =  File::Spec->catdir($localstatedir, 'www') };           # webdir    /var/www

1;

__END__
