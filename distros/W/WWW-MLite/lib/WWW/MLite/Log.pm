package WWW::MLite::Log; # $Id: Log.pm 44 2019-05-31 10:06:54Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

WWW::MLite::Log - WWW::MLite Logging as CTK plugin

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    my $server = new WWW::MLite (
        project     => "MyApp",
        ident       => "myapp",
        log         => "on",
        logfd       => fileno(STDERR),
        #logfile     => '/path/to/log/file.log',
    );
    $server->log_info("Yuppie! %s", __FILE__);

=head1 DESCRIPTION

WWW::MLite Logging as CTK plugin

=over 8

=item B<ident>

Specifies ident string for each log-record

See L<CTK::Log/"ident">

=item B<logfd>

    logfd => fileno(STDERR),

Sets IO file descriptor

See L<IO::Handle>

=item B<logfile>

Specifies log file

See L<CTK::Log/"file">

=back

=head1 METHODS

=over 8

=item B<logger>

    die $server->logger->error unless $server->logger->status;

Returns logger-object

=item B<logger_init>

    $server->logger_init( ... );

Init logger. See L<CTK::Log/"new">


=item B<log_debug>

    $server->log_debug( "format %s", "value", ... );

Sends debug message in sprintf fromat to log. See L<CTK::Log>

=item B<log_info>

    $server->log_info( "format %s", "value", ... );

Sends informational message in sprintf fromat to log. See L<CTK::Log>

=item B<log_notice>

    $server->log_notice( "format %s", "value", ... );

Sends notice message in sprintf fromat to log. See L<CTK::Log>

=item B<log_warning>, B<log_warn>

    $server->log_warning( "format %s", "value", ... );

Sends warning message in sprintf fromat to log. See L<CTK::Log>

=item B<log_error>

    $server->log_error( "format %s", "value", ... );

Sends error message in sprintf fromat to log. See L<CTK::Log>

=item B<log_crit>

    $server->log_crit( "format %s", "value", ... );

Sends critical message in sprintf fromat to log. See L<CTK::Log>

=item B<log_alert>

    $server->log_alert( "format %s", "value", ... );

Sends alert message in sprintf fromat to log. See L<CTK::Log>

=item B<log_emerg>

    $server->log_emerg( "format %s", "value", ... );

Sends emergency message in sprintf fromat to log. See L<CTK::Log>

=item B<log_fatal>

    $server->log_fatal( "format %s", "value", ... );

Sends fatal message in sprintf fromat to log. See L<CTK::Log>

=item B<log_except>, B<log_exception>

    $server->log_except( "format %s", "value", ... );

Sends exception message in sprintf fromat to log. See L<CTK::Log>

=back

=head2 init

Initializer method. Internal use only

=head1 HISTORY

See C<Changes> file

=head1 SEE ALSO

L<CTK>, L<CTK::Plugin>, L<CTK::Log>, L<CTK::Plugin::Log>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '1.01';

use base qw/CTK::Plugin/;

sub init {
    my $self = shift; # It is CTK object!
    $self->{logger} = undef;
    return 1;
}

__PACKAGE__->register_method(
    method    => "logger",
    callback  => sub { shift->{logger} });

__PACKAGE__->register_method(
    method    => "logger_init",
    callback  => sub {
        my $self = shift;
        my %args = @_;
        $args{ident} //= $self->{ident} // $self->project; # From args or object or is project
        return $self->{logger} = WWW::MLite::Log::IO->new(%args);
});

__PACKAGE__->register_method(
    method    => "log_debug",
    callback  => sub {
        my $self = shift;
        my $logger = $self->{logger} || return 0;
        return $logger->log_debug(@_);
});
__PACKAGE__->register_method(
    method    => "log_info",
    callback  => sub {
        my $self = shift;
        my $logger = $self->{logger} || return 0;
        return $logger->log_info(@_);
});
__PACKAGE__->register_method(
    method    => "log_notice",
    callback  => sub {
        my $self = shift;
        my $logger = $self->{logger} || return 0;
        return $logger->log_notice(@_);
});
__PACKAGE__->register_method(
    method    => "log_warning",
    callback  => sub {
        my $self = shift;
        my $logger = $self->{logger} || return 0;
        return $logger->log_warning(@_);
});
__PACKAGE__->register_method(
    method    => "log_warn",
    callback  => sub {
        my $self = shift;
        my $logger = $self->{logger} || return 0;
        return $logger->log_warn(@_);
});
__PACKAGE__->register_method(
    method    => "log_error",
    callback  => sub {
        my $self = shift;
        my $logger = $self->{logger} || return 0;
        return $logger->log_error(@_);
});
__PACKAGE__->register_method(
    method    => "log_crit",
    callback  => sub {
        my $self = shift;
        my $logger = $self->{logger} || return 0;
        return $logger->log_crit(@_);
});
__PACKAGE__->register_method(
    method    => "log_alert",
    callback  => sub {
        my $self = shift;
        my $logger = $self->{logger} || return 0;
        return $logger->log_alert(@_);
});
__PACKAGE__->register_method(
    method    => "log_emerg",
    callback  => sub {
        my $self = shift;
        my $logger = $self->{logger} || return 0;
        return $logger->log_emerg(@_);
});
__PACKAGE__->register_method(
    method    => "log_fatal",
    callback  => sub {
        my $self = shift;
        my $logger = $self->{logger} || return 0;
        return $logger->log_fatal(@_);
});
__PACKAGE__->register_method(
    method    => "log_except",
    callback  => sub {
        my $self = shift;
        my $logger = $self->{logger} || return 0;
        return $logger->log_except(@_);
});
__PACKAGE__->register_method(
    method    => "log_exception",
    callback  => sub {
        my $self = shift;
        my $logger = $self->{logger} || return 0;
        return $logger->log_exception(@_);
});

1;

package WWW::MLite::Log::IO;

use vars qw/$VERSION/;
$VERSION = '1.00';

use base qw/CTK::Log/;

use Carp;
use IO::Handle;

sub new {
    my $class = shift;
    my %args = @_;
    return $class->SUPER::new(%args) if $args{usesyslog} || defined($args{file});
    my $level = CTK::Log::_getLevel($args{level});
    carp(sprintf("Incorrect level %s", $args{level})) unless defined $level;
    my $fd = $args{fd};
    return $class->SUPER::new(%args) unless defined $fd;
    carp("Incorrect file descriptor (fd)") unless $fd;

    # Create object
    my $self = bless {
        status      => 0,
        error       => "",
        usesyslog   => 0,
        file        => "",
        level       => $level,
        ident       => $args{ident},
        syslogopts  => "",
        socketopts  => undef,
        facility    => $args{facility},
        separator   => $args{separator} // CTK::Log::SEPARATOR,
        "utf8"      => $args{"utf8"} // 1,
        pure        => $args{pure} // 0,
        fh          => undef,
    }, $class;

    my $fh = IO::Handle->new();
    unless ($fh->fdopen($fd, "a")) {
        $self->{error} = sprintf("Can't open file descriptor: %s", $! // 'unknown error');
        return $self;
    }
    binmode $$fh, ":raw:utf8" if $self->{"utf8"};
    $fh->autoflush(1);
    $self->{fh} = $fh;
    $self->{status} = 1;
    return $self;
}

1;

__END__

