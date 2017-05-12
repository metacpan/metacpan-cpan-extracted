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
package Test::Reporter::Transport::HTTPGateway;
our $VERSION = '1.57';
# ABSTRACT: HTTP transport for Test::Reporter

use base 'Test::Reporter::Transport';

use LWP::UserAgent;

sub new {
  my ($class, $url, $key) = @_;

  die "invalid gateway URL: must be absolute http or https URL"
    unless $url =~ /\Ahttps?:/i;

  bless { gateway => $url, key => $key } => $class;
}

sub send {
  my ($self, $report) = @_;

  # construct the "via"
  my $report_class   = ref $report;
  my $report_version = $report->VERSION;
  my $via = "$report_class $report_version";
  $via .= ', via ' . $report->via if $report->via;
  my $perl_version = $report->perl_version->{_version};
  # post the report
  my $ua = LWP::UserAgent->new;
  $ua->timeout(60);
  $ua->env_proxy;

  my $form = {
    key     => $self->{key},
    via     => $via,
    perl_version => $perl_version,
    from    => $report->from,
    subject => $report->subject,
    report  => $report->report,
  };

  my $res = $ua->post($self->{gateway}, $form);

  return 1 if $res->is_success;

  die sprintf "HTTP error: %s: %s", $res->status_line, $res->content;
}

1;



=pod

=head1 NAME

Test::Reporter::Transport::HTTPGateway - HTTP transport for Test::Reporter

=head1 VERSION

version 1.57

=head1 SYNOPSIS

    my $report = Test::Reporter->new(
        transport => 'HTTPGateway',
        transport_args => [ $url, $key ],
    );

=head1 DESCRIPTION

This module transmits a Test::Reporter report via HTTP to a
L<Test::Reporter::HTTPGateway> server (or something with an equivalent API).

=head1 USAGE

See L<Test::Reporter> and L<Test::Reporter::Transport> for general usage
information.

=head2 Transport Arguments

    $report->transport_args( $url, $key );

This transport class accepts two positional arguments.  The first is required
and specifies the URL for the HTTPGateway server.  The second argument
specifies an API key to transmit to the gatway.  It is optional for the
transport class, but may be required by particular gateway servers.

=head1 METHODS

These methods are only for internal use by Test::Reporter.

=head2 new

    my $sender = Test::Reporter::Transport::HTTPGateway->new( 
        @args 
    );

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


