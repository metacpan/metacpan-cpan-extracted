package XAS::Lib::Curl::FTP;

our $VERSION = '0.01';

BEGIN {
    no warnings 'redefine';

    use WWW::Curl::Easy;

    eval {

        # these constants are not always defined for libcurl on RHEL 5,6,7.
        # but they are, if you compile libcurl on Windows

        unless (CURLAUTH_ONLY) {

            sub CURLAUTH_ONLY { (1 << 31); } # defined in curl.h

        }

    };

}

use DateTime;
use Data::Dumper;

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base',
  accessors => 'curl transfer_speed transfer_time',
  mutators  => 'retcode',
  utils     => ':validation dotid trim',
  constants => 'TRUE FALSE',
  vars => {
    PARAMS => {
      -ssl_verify_peer => { optional => 1, default => 1 },
      -ssl_verify_host => { optional => 1, default => 0 },
      -fail_on_error   => { optional => 1, default => 0 },
      -keep_alive      => { optional => 1, default => 0 },
      -connect_timeout => { optional => 1, default => 300 },
      -ssl_cacert      => { optional => 1, default => undef },
      -ssl_keypasswd   => { optional => 1, default => undef },
      -ssl_cert        => { optional => 1, default => undef, depends => [ '-ssl_key' ] },
      -ssl_key         => { optional => 1, default => undef, depends => [ '-ssl_cert' ] },
      -password        => { optional => 1, default => undef, depends => [ '-username' ] },
      -username        => { optional => 1, default => undef, depends => [ '-password' ] },
    }
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub list {
    my $self = shift;
    my ($url) = validate_params(\@_, [
        { isa => 'Badger::URL' },
    ]);

    my @buffer;

    my $write_callback = sub {
        my $data    = shift;
        my $pointer = shift;

        push(@{$pointer}, $data);

        return length($data);

    };

    $self->curl->setopt(CURLOPT_URL, $url->text);
    $self->curl->setopt(CURLOPT_WRITEDATA, \@buffer);
    $self->curl->setopt(CURLOPT_WRITEFUNCTION, $write_callback);

    unless (($self->{'retcode'} = $self->curl->perform) == 0) {

        $self->throw_msg(
            dotid($self->class) . '.list',
            'curl',
            $self->retcode, lc($self->curl->strerror($self->retcode))
        );

    }

    return wantarray ? @buffer : \@buffer;

}

sub info {
    my $self = shift;
    my ($url) = validate_params(\@_, [
        { isa => 'Badger::URL' },
    ]);

    my @buffer;
    my $dt = undef;
    my $size = undef;

    my $write_callback = sub {
        my $data    = shift;
        my $pointer = shift;

        push(@{$pointer}, $data);

        return length($data);

    };

    $self->curl->setopt(CURLOPT_URL, $url->text);
    $self->curl->setopt(CURLOPT_NOBODY, 1);
    $self->curl->setopt(CURLOPT_FILETIME, 1);
    $self->curl->setopt(CURLOPT_WRITEDATA, \@buffer);
    $self->curl->setopt(CURLOPT_WRITEFUNCTION, $write_callback);

    if (($self->{'retcode'} = $self->curl->perform) == 0) {

        $size = $self->curl->getinfo(CURLINFO_CONTENT_LENGTH_DOWNLOAD);

        my $time = $self->curl->getinfo(CURLINFO_FILETIME);
        if (defined($time)) {

            $dt = DateTime->from_epoch(epoch => $time);

        }

    } else {

        $self->throw_msg(
            dotid($self->class) . '.info',
            'curl',
            $self->retcode, lc($self->curl->strerror($self->retcode))
        );

    }

    return $size, $dt;

}

sub get {
    my $self = shift;
    my ($url, $file) = validate_params(\@_, [
        { isa => 'Badger::URL' },
        { isa => 'Badger::Filesystem::File' },
    ]);

    my $stat = FALSE;
    my $fd   = $file->open('w');

    my $write_callback = sub {
        my $buffer = shift;
        my $fd     = shift;

        return $fd->syswrite($buffer);

    };

    $self->curl->setopt(CURLOPT_WRITEDATA, $fd);
    $self->curl->setopt(CURLOPT_URL, $url->text);
    $self->curl->setopt(CURLOPT_WRITEFUNCTION, $write_callback);

    if (($self->{'retcode'} = $self->curl->perform) == 0) {

        $stat = TRUE;

        $self->{'transfer_time'}  = $self->curl->getinfo(CURLINFO_TOTAL_TIME);
        $self->{'transfer_speed'} = $self->curl->getinfo(CURLINFO_SPEED_DOWNLOAD);

        $fd->close;

    } else {

        $fd->close;

        $self->throw_msg(
            dotid($self->class) . '.get',
            'curl',
            $self->retcode, lc($self->curl->strerror($self->retcode))
        );

    }

    return $stat;

}

sub put {
    my $self = shift;
    my ($file, $url) = validate_params(\@_, [
        { isa => 'Badger::Filesystem::File' },
        { isa => 'Badger::URL' },
    ]);

    my $stat = FALSE;
    my $fd   = $file->open('r');
    my $size = ($file->stat)[7];

    my $read_callback = sub {
        my $size = shift;
        my $fd   = shift;

        my $buffer;
        my $rc = $fd->sysread($buffer, $size);

        return ($rc > 0) ? $buffer : '';

    };

    $self->curl->setopt(CURLOPT_UPLOAD, 1);
    $self->curl->setopt(CURLOPT_READDATA, $fd);
    $self->curl->setopt(CURLOPT_URL, $url->text);
    $self->curl->setopt(CURLOPT_INFILESIZE_LARGE, $size);
    $self->curl->setopt(CURLOPT_READFUNCTION, $read_callback);

    if (($self->{'retcode'} = $self->curl->perform) == 0) {

        $stat = TRUE;

        $self->{'transfer_time'}  = $self->curl->getinfo(CURLINFO_TOTAL_TIME);
        $self->{'transfer_speed'} = $self->curl->getinfo(CURLINFO_SPEED_UPLOAD);

        $fd->close;

    } else {

        $fd->close;

        $self->throw_msg(
            dotid($self->class) . '.put',
            'curl',
            $self->retcode, lc($self->curl->strerror($self->retcode))
        );

    }

    return $stat;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    my $protocols       = (CURLPROTO_FTP & CURLPROTO_FTPS);
    my $connect_timeout = $self->connect_timeout * 1000;

    $self->{'curl'} = WWW::Curl::Easy->new();

    # basic options

    $self->curl->setopt(CURLOPT_VERBOSE,           $self->xdebug);
    $self->curl->setopt(CURLOPT_PROTOCOLS,         $protocols);
    $self->curl->setopt(CURLOPT_NOPROGRESS,        1);
    $self->curl->setopt(CURLOPT_FAILONERROR,       $self->fail_on_error);
    $self->curl->setopt(CURLOPT_FORBID_REUSE,      !$self->keep_alive);
    $self->curl->setopt(CURLOPT_CONNECTTIMEOUT_MS, $connect_timeout);

    # setup authentication

    if ($self->username) {

        $self->curl->setopt(CURLOPT_USERNAME, $self->username);
        $self->curl->setopt(CURLOPT_PASSWORD, $self->password);

    }

    # set up the SSL stuff

    $self->curl->setopt(CURLOPT_SSL_VERIFYPEER, $self->ssl_verify_peer);
    $self->curl->setopt(CURLOPT_SSL_VERIFYHOST, $self->ssl_verify_host);

    if ($self->ssl_keypasswd) {

        $self->curl->setop(CURLOPT_KEYPASSWD, $self->ssl_keypasswd);

    }

    if ($self->ssl_cacert) {

        $self->curl->setopt(CURLOPT_CAINFO, $self->ssl_cacert);

    }

    if ($self->ssl_cert) {

        $self->curl->setopt(CURLOPT_SSLCERT, $self->ssl_cert);
        $self->curl->setopt(CURLOPT_SSLKEY,  $self->ssl_key);

    }

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Curl::FTP - A class to transfer files using FTP

=head1 SYNOPSIS

 use Badger::URL 'URL';
 use XAS::Lib::Curl::FTP;
 use Badger::Filesystem 'File';

 my $ftp = XAS::Lib::Curl::FTP->new(
     -username = 'kevin',
     -password = 'password',
 );

 my $url  = URL('ftp://examples.com/directory/file.txt');
 my $file = File('file.txt');

 if ($ftp->get($url, $file)) {

     printf("fetched %s in %s seconds, at a speed of %s bytes per second\n", 
          $ftp->transfer_time, $ftp->transfer_speed);

 }

=head1 DESCRIPTION

This module uses WWW::Curl to transfer files using FTP/FTPS. 

=head1 METHODS

=head2 new

This method initializes the module and takes the following parameters:

=over 4

=item B<-keep_alive>

A toggle to tell curl to forbid the reuse of sockets, defaults to true.

=item B<-connect_timeout>

The timeout for the initial connection, defaults to 300 seconds.

=item B<-password>

An optional password to use, implies a username. Wither the password is
actually used, depends on -auth_method.

=item B<-username>

An optional username to use, implies a password.

=item B<-ssl_cacert>

An optional CA cerificate to use.

=item B<-ssl_keypasswd>

An optional password for a signed cerificate.

=item B<-ssl_cert>

An optional certificate to use.

=item B<-ssl_key>

An optional key for a certificate to use.

=item B<-ssl_verify_host>

Wither to verify the host certifcate, defaults to true.

=item B<-ssl_verify_peer>

Wither to verify the peer certificate, defaults to true.

=back

=head2 list($url)

This method will return a list of files for the given url. The format of
the list is server dependent. 

=over 4

=item B<$url>

This is a Badger::URL object of the files url.

=back

=head2 info($url)

This method will return the size and DateTime object of the file residing at 
the url.

=over 4

=item B<$url>

This is a Badger::URL object of the files url.

=back

=head2 get($url, $file)

This method will get the file at url and place it a files destination. It
will return TRUE upon success, or throw an exception on failure.

=over 4

=item B<$url>

This is a Badger::URL object of the files url.

=item B<$file>

This ia a Badger::Filesystem::File object of the files destination.

=back

=head2 put($file, $url)

This method will put the file at the destination url. It will return TRUE upon 
success, or throw an exception on failure.

=over 4

=item B<$url>

This is a Badger::URL object of the files url.

=item B<$file>

This ia a Badger::Filesystem::File object of the files source.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::Curl::HTTP|XAS::Lib::Curl::HTTP>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2017 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
