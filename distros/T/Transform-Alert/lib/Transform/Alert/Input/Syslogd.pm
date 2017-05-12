package Transform::Alert::Input::Syslogd;

our $VERSION = '1.00'; # VERSION
# ABSTRACT: Transform alerts from an internal Syslog daemon

use sanity;
use Moo;
use MooX::Types::MooseLike::Base qw(InstanceOf);

use Net::Syslogd 0.04;

with 'Transform::Alert::Input';

has _conn => (
   is        => 'rw',
   isa       => InstanceOf['Net::Syslogd'],
   lazy      => 1,
   default   => sub {
      Net::Syslogd->new( %{shift->connopts} ) || die "Syslogd New failed: ".Net::Syslogd->error;
   },
   predicate => 1,
);

sub open   { shift->_conn     }
sub opened { shift->_has_conn }

sub get {
   my $self    = shift;
   my $syslogd = $self->_conn;

   my $msg = $syslogd->get_message(Timeout => 0);

   unless (defined $msg) {
      $self->log->error('Error grabbing Syslogd message: '.$syslogd->error);
      return;
   }
   if ($msg eq '0') {
      $self->log->warn('No syslog message in queue during get()');
      return \(''), {};
   }

   # rejoin message parts
   my $txt = $msg->remoteaddr.':'.$msg->remoteport.' - '.$msg->datagram;
   $msg->process_message;
   return (\$txt, {
      remoteaddr => $msg->remoteaddr,
      remoteport => $msg->remoteport,

      priority => $msg->priority,
      facility => $msg->facility,
      severity => $msg->severity,
      time     => $msg->time(),
      hostname => $msg->hostname,
      message  => $msg->message,
   });
}

sub eof {
   my $self = shift;
   my $port = $self->_conn->server;

   # check if a message is waiting
   my $rin = '';
   vec($rin, fileno($port), 1) = 1;
   return not select($rin, undef, undef, 0);
}

sub close { 1 }

42;

__END__

=pod

=encoding utf-8

=head1 NAME

Transform::Alert::Input::Syslogd - Transform alerts from an internal Syslog daemon

=head1 SYNOPSIS

    # In your configuration
    <Input test>
       Type      Syslogd
       Interval  5  # you should set this to be very short
 
       # See Net::Syslogd->new
       <ConnOpts>
          LocalAddr  192.168.1.1
          LocalPort  514  # default
          # Timeout - don't bother
       </ConnOpts>
       # <Template> tags...
    </Input>

=head1 DESCRIPTION

This input type will spawn a syslog listener and process each message through the input template engine.  If it finds a match, the results of
the match are sent to one or more outputs, depending on the group configuration.

See L<Net::Syslogd> for a list of the ConnOpts section parameters.  The C<<< Timeout >>> parameter is basically ignored, since C<<< get_message >>> calls
will use a timeout of 0 (ie: instant).  This is so that the main daemon doesn't bother waiting for messages during each heartbeat.  As such,
the C<<< Interval >>> setting should be set very low.  (But, not zero; that would be unwise...)

=head1 OUTPUTS

=head2 Text

    $addr:$port - $datagram

=head2 Preparsed Hash

    {
       remoteaddr => $str,
       remoteport => $int,
 
       priority => $int,
       facility => $str,  # text version
       severity => $str,  # text version
       time     => $str,
       hostname => $str,
       message  => $str,
    }

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/Transform-Alert/wiki>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Transform::Alert/>.

=head1 AUTHOR

Brendan Byrd <BBYRD@CPAN.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
