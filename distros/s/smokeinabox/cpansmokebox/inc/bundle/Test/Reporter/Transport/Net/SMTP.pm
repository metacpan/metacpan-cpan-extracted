# 
# This file is part of Test-Reporter
# 
# This software is copyright (c) 2010 by Authors and Contributors.
# 
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# 
use strict;
BEGIN{ if (not $] < 5.006) { require warnings; warnings->import } }
package Test::Reporter::Transport::Net::SMTP;
our $VERSION = '1.57';
# ABSTRACT: SMTP transport for Test::Reporter

use base 'Test::Reporter::Transport';

sub new {
    my ($class, @args) = @_;
    bless { args => \@args } => $class;
}

sub _net_class {
    my ($self) = @_;
    my $class = ref $self ? ref $self : $self;
    my ($net_class) = ($class =~ /^Test::Reporter::Transport::(.+)\z/);
    return $net_class;
}

# Next two subs courtesy of Casey West, Ricardo SIGNES, and Email::Date
# Visit the Perl Email Project at: http://emailproject.perl.org/
sub _tz_diff {
    my ($self, $time) = @_;

    my $diff  =   Time::Local::timegm(localtime $time)
                - Time::Local::timegm(gmtime    $time);

    my $direc = $diff < 0 ? '-' : '+';
       $diff  = abs $diff;
    my $tz_hr = int( $diff / 3600 );
    my $tz_mi = int( $diff / 60 - $tz_hr * 60 );

    return ($direc, $tz_hr, $tz_mi);
}

sub _format_date {
    my ($self, $time) = @_;
    $time = time unless defined $time;

    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = (localtime $time);
    my $day   = (qw[Sun Mon Tue Wed Thu Fri Sat])[$wday];
    my $month = (qw[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec])[$mon];
    $year += 1900;

    my ($direc, $tz_hr, $tz_mi) = $self->_tz_diff($time);

    sprintf "%s, %d %s %d %02d:%02d:%02d %s%02d%02d",
      $day, $mday, $month, $year, $hour, $min, $sec, $direc, $tz_hr, $tz_mi;
}

# Taken with slight modifications from MIME::QuotedPrint::Perl 1.00 by Gisle Aas
sub _encode_qp_perl {
    my ($res,$eol) = @_;
    $eol = "\n" unless defined $eol;

    if (ord('A') == 193) { # on EBCDIC machines we need translation help
      require Encode;
    }

    my $RE_Z = "\\z";
    $RE_Z = "\$" if $] < 5.005;

    if ($] >= 5.006) {
        require bytes;
        if (bytes::length($res) > length($res) ||
            ($] >= 5.008 && $res =~ /[^\0-\xFF]/))
        {
            require Carp;
            Carp::croak("The Quoted-Printable encoding is only defined for bytes");
        }
    }

    # Do not mention ranges such as $res =~ s/([^ \t\n!-<>-~])/sprintf("=%02X", ord($1))/eg;
    # since that will not even compile on an EBCDIC machine (where ord('!') > ord('<')).
    if (ord('A') == 193) { # EBCDIC style machine
        if (ord('[') == 173) {
            $res =~ s/([^ \t\n!"#\$%&'()*+,\-.\/0-9:;<>?\@A-Z[\\\]^_`a-z{|}~])/sprintf("=%02X", ord(Encode::encode('iso-8859-1',Encode::decode('cp1047',$1))))/eg;  # rule #2,#3
            $res =~ s/([ \t]+)$/
              join('', map { sprintf("=%02X", ord(Encode::encode('iso-8859-1',Encode::decode('cp1047',$_)))) }
                           split('', $1)
              )/egm;                        # rule #3 (encode whitespace at eol)
        }
        elsif (ord('[') == 187) {
            $res =~ s/([^ \t\n!"#\$%&'()*+,\-.\/0-9:;<>?\@A-Z[\\\]^_`a-z{|}~])/sprintf("=%02X", ord(Encode::encode('iso-8859-1',Encode::decode('posix-bc',$1))))/eg;  # rule #2,#3
            $res =~ s/([ \t]+)$/
              join('', map { sprintf("=%02X", ord(Encode::encode('iso-8859-1',Encode::decode('posix-bc',$_)))) }
                           split('', $1)
              )/egm;                        # rule #3 (encode whitespace at eol)
        }
        elsif (ord('[') == 186) {
            $res =~ s/([^ \t\n!"#\$%&'()*+,\-.\/0-9:;<>?\@A-Z[\\\]^_`a-z{|}~])/sprintf("=%02X", ord(Encode::encode('iso-8859-1',Encode::decode('cp37',$1))))/eg;  # rule #2,#3
            $res =~ s/([ \t]+)$/
              join('', map { sprintf("=%02X", ord(Encode::encode('iso-8859-1',Encode::decode('cp37',$_)))) }
                           split('', $1)
              )/egm;                        # rule #3 (encode whitespace at eol)
        }
    }
    else { # ASCII style machine
        $res =~  s/([^ \t\n!"#\$%&'()*+,\-.\/0-9:;<>?\@A-Z[\\\]^_`a-z{|}~])/sprintf("=%02X", ord($1))/eg;  # rule #2,#3
        $res =~ s/\n/=0A/g unless length($eol);
        $res =~ s/([ \t]+)$/
          join('', map { sprintf("=%02X", ord($_)) }
                   split('', $1)
          )/egm;                        # rule #3 (encode whitespace at eol)
    }

    return $res unless length($eol);

    # rule #5 (lines must be shorter than 76 chars, but we are not allowed
    # to break =XX escapes.  This makes things complicated :-( )
    my $brokenlines = "";
    $brokenlines .= "$1=$eol"
        while $res =~ s/(.*?^[^\n]{73} (?:
                 [^=\n]{2} (?! [^=\n]{0,1} $) # 75 not followed by .?\n
                |[^=\n]    (?! [^=\n]{0,2} $) # 74 not followed by .?.?\n
                |          (?! [^=\n]{0,3} $) # 73 not followed by .?.?.?\n
            ))//xsm;
    $res =~ s/\n$RE_Z/$eol/o;

    "$brokenlines$res";
}

sub _encode_qp {
    my $text = shift;
    if ( $] >= 5.007003 ) {
        require MIME::QuotedPrint;
        return MIME::QuotedPrint::encode_qp($text);
    }
    else {
      return _encode_qp_perl($text);
    }
}

sub send {
    my ($self, $report, $recipients) = @_;
    $recipients ||= [];

    my $perl_version = $report->perl_version->{_version};
    my $helo          = $report->_maildomain(); # XXX: tight -- rjbs, 2008-04-06
    my $from          = $report->from();
    my $via           = $report->via();
    my @tmprecipients = ();
    my @bad           = ();
    my $smtp;

    my $mx;

    my $transport = $self->_net_class;

    # Sorry.  Tight coupling happened before I got here. -- rjbs, 2008-04-06
    for my $server (@{$report->{_mx}}) {
        eval {
            $smtp = $transport->new(
                $server,
                Hello   => $helo,
                Timeout => $report->timeout(),
                Debug   => $report->debug(),
                $report->transport_args(),
            );
        };

        if (defined $smtp) {
            $mx = $server;
            last;
        }
    }

    die "Unable to connect to any MX's: $@" unless $mx && $smtp;

    my $cc_str;
    if (@$recipients) {
        if ($mx =~ /(?:^|\.)(?:perl|cpan)\.org$/) {
            for my $recipient (sort @$recipients) {
                if ($recipient =~ /(?:@|\.)(?:perl|cpan)\.org$/) {
                    push @tmprecipients, $recipient;
                } else {
                    push @bad, $recipient;
                }
            }

            if (@bad) {
                warn __PACKAGE__, ": Will not attempt to cc the following recipients since perl.org MX's will not relay for them. Either use Test::Reporter::Transport::Mail::Send, use other MX's, or only cc address ending in cpan.org or perl.org: ${\(join ', ', @bad)}.\n";
            }

            $recipients = \@tmprecipients;
        }

        $cc_str = join ', ', @$recipients;
        chomp $cc_str;
        chomp $cc_str;
    }

    $via = ', via ' . $via if $via;

    my $envelope_sender = $from;
    $envelope_sender =~ s/\s\([^)]+\)$//; # email only; no name

    # wrap as quoted-printable if we have lines longer than 100 characters
    my $body = $report->report;
    my $needs_qp = $body =~ /^.{100}/m;
    $body = _encode_qp($body) if $needs_qp;
    my @body = split /\n/, $body;

    # Net::SMTP returns 1 or undef for pass/fail 
    # Net::SMTP::TLS croaks on fail but may not return 1 on pass
    # so this closure lets us die on an undef return only for Net::SMTP
    my $die = sub { die $smtp->message if ref $smtp eq 'Net::SMTP' };
    
    eval {
        $smtp->mail($envelope_sender) or $die->();
        $smtp->to($report->address) or $die->();
        if ( @$recipients ) { $smtp->cc(@$recipients) or $die->() };
        $smtp->data() or $die->();
        $smtp->datasend("Date: ", $self->_format_date, "\n") or $die->();
        $smtp->datasend("Subject: ", $report->subject, "\n") or $die->();
        $smtp->datasend("From: $from\n") or $die->();
        $smtp->datasend("To: ", $report->address, "\n") or $die->();
        if ( @$recipients ) { $smtp->datasend("Cc: $cc_str\n") or $die->() };
        $smtp->datasend("Message-ID: ", $report->message_id(), "\n") or $die->();
        $smtp->datasend("X-Reported-Via: Test::Reporter $Test::Reporter::VERSION$via\n") or $die->();
        $smtp->datasend("X-Test-Reporter-Perl: $perl_version\n") or $die->();
        if ( $needs_qp ) {
            $smtp->datasend("MIME-Version: 1.0\n");
            $smtp->datasend("Content-Type: text/plain; charset=utf-8\n");
            $smtp->datasend("Content-Transfer-Encoding: quoted-printable\n");
        }
        $smtp->datasend("\n") or $die->();
        for my $b ( @body ) {
          $smtp->datasend("$b\n") or $die->();
        }
        $smtp->dataend() or $die->();
        $smtp->quit or $die->();
        1;
    } or die "$transport: $@";

    return 1;
}

1;



=pod

=head1 NAME

Test::Reporter::Transport::Net::SMTP - SMTP transport for Test::Reporter

=head1 VERSION

version 1.57

=head1 SYNOPSIS

    my $report = Test::Reporter->new(
        transport => 'Net::SMTP',
    );

=head1 DESCRIPTION

This module transmits a Test::Reporter report using Net::SMTP.

=head1 USAGE

See L<Test::Reporter> and L<Test::Reporter::Transport> for general usage
information.

=head2 Transport Arguments

    $report->transport_args( @args );

Any transport arguments are passed through to the Net::SMTP constructer.

=head1 METHODS

These methods are only for internal use by Test::Reporter.

=head2 new

    my $sender = Test::Reporter::Transport::Net::SMTP->new( @args );

The C<new> method is the object constructor.   

=head2 send

    $sender->send( $report );

The C<send> method transmits the report.  

=head1 AUTHORS

  Adam J. Foxson <afoxson@pobox.com>
  David Golden <dagolden@cpan.org>
  Kirrily "Skud" Robert <skud@cpan.org>
  Ricardo Signes <rjbs@cpan.org>
  Richard Soderberg <rsod@cpan.org>
  Kurt Starsinic <Kurt.Starsinic@isinet.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Authors and Contributors.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


