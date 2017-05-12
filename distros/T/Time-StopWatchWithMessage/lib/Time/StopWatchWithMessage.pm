package Time::StopWatchWithMessage;
use strict;
use warnings;
use List::Util qw( sum max reduce );
use List::MoreUtils qw( first_index );
use Time::HiRes qw( gettimeofday tv_interval );

our $VERSION     = "0.06";
our $IS_REALTIME = 0;
our $LENGTH      = 3;

sub new { bless [ ], shift }

sub start {
    my $self    = shift;
    my $message = shift || __PACKAGE__ . ">>> Start watching.";

    $self->stop
        if $self->_does_stop_need;

    push @{ $self }, { time => [ gettimeofday ], message => $message };

    return $self;
}

sub stop {
    my $self = shift;
    my $time = [ gettimeofday ];

    my $previous = pop @{ $self };
    $previous->{time} = tv_interval( $previous->{time}, $time );

    push @{ $self }, $previous;

    if ( $IS_REALTIME ) {
        warn sprintf "%s - %.${LENGTH}f[s]\n", $previous->{message}, $previous->{time};
    }

    return $self;
}

sub _does_stop_need {
    my $self = shift;
    return @{ $self } && ref $self->[-1]{time} eq ref [ ];
}

sub collapse {
    my $self = shift;

    $self->stop
        if $self->_does_stop_need;

    my $watches_ref = reduce {
        my $i = first_index { $_->{message} eq $b->{message} } @{ $a };

        if ( $i >= 0 ) {
            $a->[ $i ]{time} += $b->{time};
            $a->[ $i ]{count}++;
        }
        else {
            push @{ $a }, $b;
        }

        $a;
    } ( [ ], @{ $self } );

    return bless $watches_ref, ref $self;
}

sub _output {
    my $self = shift;
    my $FH   = shift;

    $self->stop
        if $self->_does_stop_need;

    my $sum    = sum( map { $_->{time} } @{ $self } );
    my $max    = max( map { $_->{time} } @{ $self } );
    my %length = (
        time    => max( map { length int $_->{time} } @{ $self } ),
        message => max( map { length $_->{message} }  @{ $self } ),
    );

    OUTPUT_ALL_WATCHES:
    while ( defined( my $watch_ref = shift @{ $self } ) ) {
        my $output = sprintf(
            "%$length{message}s - %$length{time}.${LENGTH}f[s] / %$length{time}.${LENGTH}f[s] = %$length{time}.${LENGTH}f[%%]",
            $watch_ref->{message},
            $watch_ref->{time},
            $sum,
            $watch_ref->{time} / $sum * 100,
        );

        if ( $watch_ref->{count} ) {
            $output = join q{; }, $output, sprintf "%d times measured.", $watch_ref->{count} + 1;
        }

        print { $FH } $output, "\n";
    }

    return;
}

sub output {
    my $self = shift;
    my $FH   = shift || *STDERR;

    return $self->_output( $FH );
}

sub print { shift->_output( *STDOUT ) }

sub warn { shift->_output( *STDERR ) }

1;

__END__
=encoding utf8

=head1 NAME

Time::StopWatchWithMessage - Calculate a interval between Previous and Current with a message

=head1 SYNOPSIS

  use Time::StopWatchWithMessage;
  $Time::StopWatchWithMessage::IS_REALTIME = 0;
  $Time::StopWatchWithMessage::LENGTH      = 3;

  my $watch = Time::StopWatchWithMessage->new;

  $watch->start( "Initialize." );
  do_initialize( );
  $watch->stop;

  $watch->start( "Doing something." );
  do_something( );
  $watch->stop->start( "Finalize." );
  do_finalize( );
  $watch->stop->warn;

=head1 DESCRIPTION

You can use Time::StopWatch.  This module likes it.
This is used to record a message.

Note, this module hasn't care overhead of self executing.

=head2 EXPORT

None.

=head2 GLOBALS

=over

=item $Time::StopWatchWithMessage::IS_REALTIME

Reports message per stop.

=item $Time::StopWatchWithMessage::LENGTH

Specifies a length of after floating point of the report.

=back

=head2 METHODS

=over

=item start

Starts watching time.

=item stop

Stops watching time.

=item collapse

Collapses message which has same message.

This is useful when you call start, and stop in loop.

=item warn

Prints the result to STDERR.

=item print

Prints the result to STDOUT.

=item output

Prints the result to file handle.

=back

=head1 SEE ALSO

=over

=item Time::StopWatch

=item Devel::Profile

=back

=head1 AUTHOR

Kuniyoshi.Kouji, E<lt>kuniyoshi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Kuniyoshi.Kouji

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

