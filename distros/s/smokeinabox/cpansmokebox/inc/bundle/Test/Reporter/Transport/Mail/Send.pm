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
package Test::Reporter::Transport::Mail::Send;
our $VERSION = '1.57';
# ABSTRACT: Mail::Send transport for Test::Reporter

use base 'Test::Reporter::Transport';

use Mail::Send;

sub new {
    my ($class, @args) = @_;
    bless { args => \@args } => $class;
}

sub send {
    my ($self, $report, $recipients) = @_;
    $recipients ||= [];

    my $perl_version = $report->perl_version->{_version};
    my $via = $report->via();
    my $msg = Mail::Send->new();

    my $cc_str;
    if (@$recipients) {
        $cc_str = join ', ', @$recipients;
        chomp $recipients;
        chomp $recipients;
    }

    $via = ', via ' . $via if $via;

    $msg->to($report->address());
    $msg->set('From', $report->from());
    $msg->subject($report->subject());
    $msg->add('X-Reported-Via', "Test::Reporter $Test::Reporter::VERSION$via");
    $msg->add('X-Test-Reporter-Perl', $perl_version);
    $msg->add('Cc', $cc_str) if $cc_str;

    my $fh = $msg->open( @{ $self->{args} } );

    print $fh $report->report();
    
    $fh->close();
}

1;



=pod

=head1 NAME

Test::Reporter::Transport::Mail::Send - Mail::Send transport for Test::Reporter

=head1 VERSION

version 1.57

=head1 SYNOPSIS

    my $report = Test::Reporter->new(
        transport => 'Mail::Send',
        transport_args => [ @mail_send_args ],
    );

=head1 DESCRIPTION

This module transmits a Test::Reporter report using Mail::Send.

=head1 USAGE

See L<Test::Reporter> and L<Test::Reporter::Transport> for general usage
information.

=head2 Transport Arguments

    $report->transport_args( @mail_send_args );

Any arguments supplied are passed to the Mail::Send constructor.

=head1 METHODS

These methods are only for internal use by Test::Reporter.

=head2 new

    my $sender = Test::Reporter::Transport::Mail::Send->new( 
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

