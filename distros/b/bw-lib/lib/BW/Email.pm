# BW::Email.pm
# Email support for BW::*
# 
# by Bill Weinman - http://bw.org/
# Copyright (c) 1995-2010 The BearHeart Group, LLC
#
# See POD for History

package BW::Email;
use strict;
use warnings;

use base qw( BW::Base );
use BW::Constants;
use IO::Socket::INET;

our $VERSION = "1.0.3";

sub _init
{
    my $self = shift;
    $self->SUPER::_init(@_);

    $self->helo( $ENV{HTTP_HOST} || $ENV{SERVER_NAME} || "mail" ) unless $self->helo;

    $self->smtp_port(25) unless $self->smtp_port;
    $self->{received_from} = $ENV{REMOTE_ADDR} || '';
    $self->{received_from} .= ' (' . $ENV{REMOTE_HOST} . ')' if $ENV{REMOTE_HOST};
    $self->{received_with} = "$ENV{SERVER_PROTOCOL} ($ENV{GATEWAY_INTERFACE}/$ENV{REQUEST_METHOD})" if $ENV{SERVER_PROTOCOL};
    $self->{received_okay} = TRUE if $self->{received_from};
    $self->{smtp_date}     = $self->smtpdate;
    $self->{extra_headers} = {};

    $self->{smtp_rc} = [];

    return SUCCESS;
}

# _setter_getter entry points
sub smtp_host       { BW::Base::_setter_getter(@_); }
sub smtp_port       { BW::Base::_setter_getter(@_); }
sub timeout         { BW::Base::_setter_getter(@_); }
sub helo            { BW::Base::_setter_getter(@_); }
sub email_to        { BW::Base::_setter_getter(@_); }
sub email_to_name   { BW::Base::_setter_getter(@_); }
sub email_from      { BW::Base::_setter_getter(@_); }
sub email_from_name { BW::Base::_setter_getter(@_); }
sub email_body      { BW::Base::_setter_getter(@_); }
sub email_subject   { BW::Base::_setter_getter(@_); }

sub validate_email
{
    my $email = shift;

    if ( ref($email) ) {    # allow for object or direct
        $email = shift;
    }

    return FAILURE unless $email;

    # this should really do a DNS test too.
    if   ( $email =~ /^[^\x00-\x20()\<\>\[\]\@\,\;\:\\\/"]+\@[^\x00-\x20()\<\>\[\]\@\,\;\:\\\/"]+$/i ) { return SUCCESS; }
    else { return FAILURE }
}

# smtpdate
#   returns a formatted date string suitable for SMTP
#
sub smtpdate
{
    my $self   = shift;
    my $t      = shift || time;
    my @days   = qw( Sun Mon Tue Wed Thu Fri Sat );
    my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    my $i;
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
    my @gm = gmtime($t);
    my $hoffset = sprintf( "%+2.02d00", ( $i = ( $hour - $gm[2] ) ) > 12 ? ( $i - 24 ) : $i );
    return sprintf( "%s, %d %s %d %02d:%02d:%02d $hoffset", $days[$wday], $mday, $months[$mon], $year + 1900, $hour, $min, $sec );
}

sub header
{
    my $self = shift;

    if (@_) {
        my $header_name = shift;
        my $header_value = shift || '';
        $self->{extra_headers}->{$header_name} = $header_value;
    }
    return $self->{extra_headers};
}

sub headers { header(@_) }

sub from_line
{
    my $self = shift;
    $self->{from_line} = $self->email_from_name ? $self->email_from_name . " <" . $self->email_from . ">" : $self->email_from;
    return $self->{from_line};
}

sub date
{
    my $self = shift;
    return $self->{smtp_date};
}

sub to_line
{
    my $self = shift;
    $self->{to_line} = $self->email_to_name ? $self->email_to_name . " <" . $self->email_to . ">" : $self->email_to;
    return $self->{to_line};
}

sub return_path
{
    my $self = shift;
    my $rp   = shift;
    $self->{return_path} = $rp if $rp;
    return $self->{return_path} || $self->email_from || '';
}

sub message
{
    my $self = shift;
    my $s    = '';

    my $body = $self->email_body;

    # this ensures that there are no bare linefeeds anywhere in the message.
    # it seems a bit extreme, but it's the only way I could find that worked.
    if ($body) {
        my @body = split( /\x0a/, $body );    # split on LF
        grep { s/\x0d$// } @body;             # loose any extraneous CRs
        $body = join( CRLF, @body );          # put 'em all back as CRLF
    }

    return $self->_error("cannot build message without both FROM and TO") unless ( $self->email_from and $self->email_to );

    my $extra_headers = $self->headers;
    my @top_headers   = qw( Return-Path Errors-To );

    foreach my $h (@top_headers) {
        $s .= "${h}: " . $extra_headers->{$h} . CRLF if $extra_headers->{$h};
    }
    $s .= 'Received: ' . $self->received . CRLF if $self->{received_okay};

    foreach my $h ( keys %$extra_headers ) {
        next if grep { $h eq $_ } @top_headers;    # skip top headers
        $s .= $h . ": " . $extra_headers->{$h} . CRLF;
    }

    $s .= 'Date: ' . $self->date . CRLF;
    $s .= 'Subject: ' . $self->email_subject . CRLF if $self->email_subject;
    $s .= 'From: ' . $self->from_line . CRLF;
    $s .= 'To: ' . $self->to_line . CRLF;
    $s .= CRLF;
    $s .= $body . CRLF if $body;
    return $s;
}

sub received
{
    my $self = shift;
    my $s    = '';

    $s .= "from " . $self->{received_from} if $self->{received_from};
    $s .= CRLF . "  " if $s and $self->helo;
    $s .= "by " . $self->helo if $self->helo;
    $s .= CRLF . "  " if $s && $self->{received_with};
    $s .= "with " . $self->{received_with} if $self->{received_with};
    $s .= ";" . CRLF . "  " if $s;
    $s .= $self->{smtp_date};

    return $s;
}

sub rc_line
{
    my $self   = shift;
    my $line   = shift || '';
    my $socket = $self->{socket};

    $self->{smtp_result}      = 0;
    $self->{smtp_result_text} = '';
    $self->{smtp_result_line} = '';

    while ( $line =~ /\d{3}-(.*)/ ) {
        $self->{smtp_result_text} .= $1;
        $line = $socket->getline;
    }

    $line =~ s/[\x0d\x0a]+$//;
    push @{ $self->{smtp_rc} }, $line;

    my ( $lh, $rh ) = split( m/ /, $line, 2 );
    $self->{smtp_result}      .= $lh || 0;
    $self->{smtp_result_text} .= $rh || '';
    $self->{smtp_result_line} .= $line;

    return $self->{smtp_rc};
}

sub make_smtp_socket
{
    my $self = shift;

    return $self->_error("make_smtp_socket: missing smtp_host value") unless($self->smtp_host);

    my $s = new IO::Socket::INET(
        PeerAddr => $self->smtp_host,
        PeerPort => $self->smtp_port,
        Proto    => 'tcp',
        Timeout  => $self->timeout
    );

    return $self->_error("make_smtp_socket: $!") unless($s);

    # autoflush is already set in later versions of the IO library, but we do
    # it here anyway -- it's cheap insurance
    $s->autoflush(1);

    $self->{socket} = $s;
}

sub smtp_lineout
{
    my $self   = shift;
    my $line   = shift;
    my $socket = $self->{socket};
    $socket->print( $line . CRLF );
    $self->rc_line( $socket->getline );
}

sub smtp_transaction
{
    my $self   = shift;
    my $socket = $self->{socket};
    my $rc     = $self->{smtp_rc};

    $self->rc_line( scalar <$socket> );    # get the SMTP signon
    return $self->_error(qq{SMTP Connect: SMTP server said "$self->{smtp_result_line}", quitting.})
      unless $self->{smtp_result} == 220;

    # HELO
    $self->smtp_lineout("HELO " . $self->helo);
    return $self->_error(qq{SMTP HELO: SMTP server said "$self->{smtp_result_line}", quitting.})
      unless $self->{smtp_result} == 250;

    # MAIL FROM
    $self->smtp_lineout( "MAIL FROM:<" . $self->return_path . ">" );
    return $self->_error(qq{SMTP MAIL FROM: SMTP server said "$self->{smtp_result_line}", quitting.})
      unless ( $self->{smtp_result} >= 250 and $self->{smtp_result} < 260 );

    # RCPT TO
    $self->smtp_lineout("RCPT TO:<" . $self->email_to . ">");
    return $self->_error(qq{SMTP RCPT: SMTP server said "$self->{smtp_result_line}", quitting.})
      unless ( $self->{smtp_result} >= 250 and $self->{smtp_result} < 260 );

    # Send the DATA command
    $self->smtp_lineout('DATA');
    return $self->_error(qq{SMTP DATA: SMTP server said "$self->{smtp_result_line}", quitting.})
      unless $self->{smtp_result} == 354;

    # send the message itself
    $socket->print( $self->message . CRLF . '.' . CRLF );
    $self->rc_line( $socket->getline );
    return $self->_error(qq{SMTP DATA End: SMTP server said "$self->{smtp_result_line}", quitting.})
      unless $self->{smtp_result} == 250;

    # Done: send QUIT
    # no need to check the value of the return code.
    $self->smtp_lineout('QUIT');

    $socket->close;

    return $rc;
}

sub send
{
    my $self    = shift;
    my $message = $self->message;

    if ( $self->make_smtp_socket ) {
        $self->smtp_transaction;
    }
}

1;

__END__

=head1 NAME

BW::Email - Support for email messages

=head1 SYNOPSIS

  use BW::Email;
  my $errstr;

  my $email = BW::Email->new();
  error($errstr) if (($errstr = $db->error));

=head1 METHODS

=over 4

=item new

Crate a new bw::Email object. 

=item init

Initializations called by new().

=item version

Return the version string.

=item error

Return the latest error condition.

=item validate_email ( email )

Returns SUCCESS if email is a valid email address. Otherwise returns FAILURE.

=item smtpdate

Return a date formatted for SMTP.

=item header ( name, value )

Create a new header. 

=item headers

Alias for header().

=item email_from

Set and/or return the From: email address. 

=item email_from_name

Set and/or return the From: name. 

=item email_from_line

Return the From: header value. 

=item email_subject

Set and/or return the Subject. 

=item date

Returns the SMTP date. 

=item email_body

Set and/or return the body of the email message. 

=item email_to

Set and/or return the To: email address. 

=item email_to_name

Set and/or return the To: name. 

=item to_line

Return the value of the To: header. 

=item return_path

Set and/or return the return-path (envelope address). 

=item message

Return the fully-assembled email message. 

=item received

Assemble the Received: header. (Internal only).

=item rc_line

Used internally for the SMTP transaction. 

=item rc

Used internally for the SMTP transaction. 

=item make_smtp_socket

Used internally for the SMTP transaction. 

=item smtp_lineout

Used internally for the SMTP transaction. 

=item smtp_transaction

Used internally for the SMTP transaction. 

=item send

Send the message. 

=back

=head1 AUTHOR

Written by Bill Weinman E<lt>http://bw.org/E<gt>.

=head1 COPYRIGHT

Copyright (c) 1995-2010 The BearHeart Group, LLC

=head1 HISTORY

    2010-02-02 bw 1.0.3 -- first CPAN version - some cleanup and documenting
    2008-01-28 bw       -- normalized from bwEmail

=cut

