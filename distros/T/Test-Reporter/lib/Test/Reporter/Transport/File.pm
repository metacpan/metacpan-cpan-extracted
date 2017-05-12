use strict;
BEGIN{ if (not $] < 5.006) { require warnings; warnings->import } }
package Test::Reporter::Transport::File;

our $VERSION = '1.62';

use base 'Test::Reporter::Transport';

sub new {
  my ($class, $dir) = @_;

  die "target directory '$dir' doesn't exist or can't be written to"
    unless -d $dir && -w $dir;

  return bless { dir => $dir } => $class;
}

sub send {
    my ($self, $report) = @_;
    $report->dir( $self->{dir} );
    return $report->write();
}

1;

# ABSTRACT: File transport for Test::Reporter

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Reporter::Transport::File - File transport for Test::Reporter

=head1 VERSION

version 1.62

=head1 SYNOPSIS

    my $report = Test::Reporter->new(
        transport => 'File',
        transport_args => [ $dir ],
    );

=head1 DESCRIPTION

This module saves a Test::Reporter report to the specified directory (using
the C<write> method from Test::Reporter.

This lets you save reports during offline operation.  The files may later be
uploaded using C<< Test::Reporter->read() >>.

    Test::Reporter->new->read( $file )->send();

=head1 USAGE

See L<Test::Reporter> and L<Test::Reporter::Transport> for general usage
information.

=head2 Transport Arguments

    $report->transport_args( $dir );

This transport class must have a writeable directory as its argument.

=head1 METHODS

These methods are only for internal use by Test::Reporter.

=head2 new

    my $sender = Test::Reporter::Transport::File->new( $dir ); 

The C<new> method is the object constructor.   

=head2 send

    $sender->send( $report );

The C<send> method transmits the report.  

=head1 AUTHORS

=over 4

=item *

Adam J. Foxson <afoxson@pobox.com>

=item *

David Golden <dagolden@cpan.org>

=item *

Kirrily "Skud" Robert <skud@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

Richard Soderberg <rsod@cpan.org>

=item *

Kurt Starsinic <Kurt.Starsinic@isinet.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Authors and Contributors.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
