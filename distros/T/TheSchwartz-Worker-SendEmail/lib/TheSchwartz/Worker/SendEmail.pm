=head1 NAME

TheSchwartz::Worker::SendEmail - sends email using SMTP

=head1 SYNOPSIS

  use TheSchwartz;
  use TheSchwartz::Worker::SendEmail;
  TheSchwartz::Worker::SendEmail->set_HELO("example.com");
  my $sclient = TheSchwartz->new(databases => \@Conf::YOUR_DBS);
  $sclient->can_do("TheSchwartz::Worker::SendEmail");
  $sclient->work; # main loop of program; goes forever, sending email

=head1 DESCRIPTION

This is a worker class for sending email (designed for B<lots> of
email) using L<TheSchwartz> job queue and a slightly-tweaked subclass
of L<Net::SMTP>.  See L<TheSchwartz> for more information.

=head1 JOB ARGUMENTS

When constructing a SendEmail job using L<TheSchwartz>'s insert_job
method, construct your L<TheSchwartz::Job> instance with its
'argument' of the following form:

   {
      # recipients:
      rcpts    => [ $email1, $email2, ... ],
      env_from => $envelope_from_address,
      data     => $headers_and_body_as_big_string,
   }

Note that "Bcc:" headers will be removed, and a "Message-ID" header
will be added if not present, but nothing else is magical.  This
module does no MIME, etc.  There are other modules for that.

=cut

package TheSchwartz::Worker::SendEmail;
use base 'TheSchwartz::Worker';
use Net::DNS qw(mx);
use Storable;

our $VERSION = '1.00';

my $resolver;
my $hello_domain;
my $keep_exit_status_for = 0;
my $on_5xx = sub {};

=head1 CLASS METHODS

=head2 set_resolver

   TheSchwartz::Worker::SendEmail->set_resolver($net_dns_resolver_obj)

Sets the DNS resolver object to use.  By default, just uses a new L<Net::DNS::Resolver>.

=cut

sub set_resolver {
    $resolver = $_[1];
}

sub resolver {
    return $resolver ||= Net::DNS::Resolver->new();
}

=head2 set_HELO

   TheSchwartz::Worker::SendEmail->set_HELO("example.com");

Sets the domain to announce in your HELO.

=cut

sub set_HELO {
    $hello_domain = $_[1];
}

=head2 set_on_5xx

    TheSchwartz::Worker::SendEmail->set_on_5xx(sub {
        my ($email, $thesch_job, $smtp_code_space_message) = @_;
    });

Set a subref to be run upon encountering a 5xx error.  Arguments to
your subref are the email address, L<TheSchwartz::Job> object, and a
scalar string of the form "SMTP_CODE SMTP_MESSAGE".  The return value
of your subref is ignored.

=cut

sub set_on_5xx {
    $on_5xx = $_[1];
}

sub set_keep_exit_status { $keep_exit_status_for = $_[1] }

sub work {
    my ($class, $job) = @_;
    my $args = $job->arg;
    my $client = $job->handle->client;
    my $rcpts    = $args->{rcpts};     # arrayref of recipients

    my %dom_rcpts;  # domain -> [ $rcpt, ... ]
    foreach my $to (@$rcpts) {
        my ($host) = $to =~ /\@(.+?)$/;
        next unless $host;
        $host = lc $host;

        $dom_rcpts{$host} ||= [];
        push @{$dom_rcpts{$host}}, $to;
    }

    # uh, whack.
    unless (%dom_rcpts) {
        # FIXME: log or something.  for artur.
        $job->completed;
        return;
    }

    # split into jobs per host.
    if (scalar keys %dom_rcpts > 1) {
        $0 = "send-email [splitting]";
        my @new_jobs;
        foreach my $dom (keys %dom_rcpts) {
            my $new_args = Storable::dclone($args);
            $new_args->{rcpts} = $dom_rcpts{$dom};
            my $new_job = TheSchwartz::Job->new(
                                                funcname => 'TheSchwartz::Worker::SendEmail',
                                                arg      => $new_args,
                                                coalesce => "$dom\@",
                                                );
            push @new_jobs, $new_job;
        }
        $job->replace_with(@new_jobs);
        return;
    }

    # all rcpts on same server, proceed...
    (my($host), $rcpts) = %dom_rcpts;   # (there's only one key)
    $0 = "send-email [$host]";

    my @mailhosts = mx(resolver(), $host);

    my @ex = map { $_->exchange } @mailhosts;

    # seen in wild:  no MX records, but port 25 of domain is an SMTP server.  think it's in SMTP spec too?
    @ex = ($host) unless @ex;

    my $smtp = Net::SMTP::BetterConnecting->new(
                                                \@ex,
                                                Hello          => $hello_domain,
                                                PeerPort       => 25,
                                                ConnectTimeout => 4,
                                                );
    die "Connection failed to domain '$host', MXes: [@ex]\n" unless $smtp;

    $smtp->timeout(300);
    # FIXME: need to detect timeouts to log to errors, so people with ridiculous timeouts can see that's why we're not delivering mail

    my $done = 0;
    while ($job && $class->_send_job_on_connection($smtp, $job) && ++$done < 50) {
        my $job1 = $job;
        $job = $client->find_job_with_coalescing_prefix(__PACKAGE__, "$host\@");

        my $handle = '<nothing>';
        if ($job) {
            $job->set_as_current;
            $handle = $job->handle->as_string;
            die "RSET failed" unless $smtp->reset;
        }

        $job1->debug("sent successfully.  trying another.  found: " . $handle);
    }

    $smtp->quit;
}

sub _send_job_on_connection {
    my ($class, $smtp, $job) = @_;

    my $args = $job->arg;
    my $hstr = $job->handle->as_string;

    if ($ENV{DEBUG}) {
        require Data::Dumper;
        warn "sending email on $smtp: " . Data::Dumper::Dumper($args);
    }

    my $env_from = $args->{env_from};  # Envelope From
    my $rcpts    = $args->{rcpts};     # arrayref of recipients
    my $body     = $args->{data};
    my $headers;

    my ($this_domain) = $env_from =~ /\@(.+)/;

    # remove bcc
    $body =~ s/^(.+?\r?\n\r?\n)//s;
    $headers = $1;
    $headers =~ s/^bcc:.+\r?\n//mig;

    # unless they specified a message ID, let's prepend our own:
    unless ($headers =~ m!^message-id:.+!mi) {
        $headers = "Message-ID: <sch-$hstr\@$this_domain>\r\n" . $headers;
    }

    my $details = sub {
        return eval {
            $smtp->code . " " . $smtp->message;
        }
    };

    my $not_ok = sub {
        my $cmd = shift;
        if ($smtp->status == 5) {
            $job->permanent_failure("Permanent failure during $cmd phase to [@$rcpts]: " . $details->());
            return 0;  # let's not re-use this connection anymore.
        }
        die "Error during $cmd phase to [@$rcpts]: " . $details->() . "\n";
    };

    return $not_ok->("MAIL")     unless $smtp->mail($env_from);

    my $got_an_okay = 0;
    my %perm_fail;
    foreach my $rcpt (@$rcpts) {
        if ($smtp->to($rcpt)) {
            $got_an_okay = 1;
            next;
        }
        if ($smtp->status == 5) {
            $perm_fail{$rcpt} = 1;
            $class->on_5xx_rcpt($job, $rcpt, $details->());
            next;
        }
        die "Error during TO phase to [@$rcpts]: " . $details->() . "\n";
    }

    unless ($got_an_okay) {
        $job->permanent_failure("Permanent failure TO [@$rcpts]: " . $details->() . "\n");
        return 0;
    }

    # have to add a fake "Received: " line in here, otherwise some
    # stupid over-strict MTAs like bellsouth.net reject it thinking
    # it's spam that was sent directly (it was).  Called
    # "NoHopsNoAuth".
    my $mailid = $hstr;
    $mailid =~ s/-/00/;  # not sure if hyphen is allowed in
    my $date = _rfc2822_date(time());
    my $rcvd = qq{Received: from localhost (theschwartz [127.0.0.1])
                      by $this_domain (TheSchwartzMTA) with ESMTP id $mailid;
                      $date
                  };
    $rcvd =~ s/\s+$//;
    $rcvd =~ s/\n\s+/\r\n\t/g;
    $rcvd .= "\r\n";

    return $not_ok->("DATA")     unless $smtp->data;
    return $not_ok->("DATASEND") unless $smtp->datasend($rcvd . $headers . $body);
    return $not_ok->("DATAEND")  unless $smtp->dataend;

    $job->completed;
    return 1;
}

sub on_5xx_rcpt {
    my ($class, $job, $email, $details) = @_;
    $on_5xx->($email, $job, $details);

}

sub keep_exit_status_for {
    return 0 unless $keep_exit_status_for;
    return $keep_exit_status_for->() if ref $keep_exit_status_for eq "CODE";
    return $keep_exit_status_for;
}

sub grab_for { 500 }
sub max_retries { 5 * 24 }  # 5 days * 24 hours
sub retry_delay {
    my ($class, $fails) = @_;
    return ((5*60, 5*60, 15*60, 30*60)[$fails] || 3600);
}

# TODO:
sub on_job_is_done_forever {
    my ($class, $job) = @_;
    # .... run subref to, say, put in LJ db that this email is undeliverable
}

sub _rfc2822_date {
    my $time = shift;
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday) =
        gmtime($time);
    my @days = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
    my @mon  = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    return sprintf("%s, %d %s %4d %02d:%02d:%02d +0000 (UTC)",
                   $days[$wday], $mday, $mon[$mon], $year+1900, $hour, $min, $sec);
}

package Net::SMTP::BetterConnecting;
use strict;
use base 'Net::SMTP';
use Net::Config;
use Net::Cmd;

# Net::SMTP's constructor could use improvement, so this is it:
#     -- retry hosts, even if they connect and say "4xx service too busy", etc.
#     -- let you specify different connect timeout vs. command timeout
sub new {
    my $self = shift;
    my $type = ref($self) || $self;
    my ($host, %arg);
    if (@_ % 2) {
        $host = shift;
        %arg  = @_;
    } else {
        %arg  = @_;
        $host = delete $arg{Host};
    }

    my $hosts = defined $host ? $host : $NetConfig{smtp_hosts};
    my $obj;
    my $timeout         = $arg{Timeout} || 120;
    my $connect_timeout = $arg{ConnectTimeout} || $timeout;

    my $h;
    foreach $h (@{ref($hosts) ? $hosts : [ $hosts ]}) {
        $obj = $type->IO::Socket::INET::new(PeerAddr => ($host = $h),
                                            PeerPort => $arg{Port} || 'smtp(25)',
                                            LocalAddr => $arg{LocalAddr},
                                            LocalPort => $arg{LocalPort},
                                            Proto    => 'tcp',
                                            Timeout  => $connect_timeout,
                                            )
            or next;

        $obj->timeout($timeout);  # restore the original timeout
        $obj->autoflush(1);
        $obj->debug(exists $arg{Debug} ? $arg{Debug} : undef);

        my $res = $obj->response();
        unless ($res == CMD_OK) {
            $obj->close();
            $obj = undef;
            next;
        }

        last if $obj;
    }

    return undef unless $obj;

    ${*$obj}{'net_smtp_exact_addr'} = $arg{ExactAddresses};
    ${*$obj}{'net_smtp_host'}       = $host;
    (${*$obj}{'net_smtp_banner'})   = $obj->message;
    (${*$obj}{'net_smtp_domain'})   = $obj->message =~ /\A\s*(\S+)/;

    unless ($obj->hello($arg{Hello} || "")) {
        $obj->close();
        return undef;
    }

    return $obj;
}

=head1 AUTHOR

Brad Fitzpatrick -- brad@danga.com

=head1 COPYRIGHT, LICENSE, and WARRANTY

Copyright 2006-2007, SixApart, Ltd.

License to use under the same terms as Perl itself.

This software comes with no warranty of any kind.

=head1 SEE ALSO

L<TheSchwartz>

=cut

1;
