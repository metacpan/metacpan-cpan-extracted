package Test::Reporter::Transport::Metabase::Fallback;

# $Id: Fallback.pm 54 2018-01-25 02:06:01Z stro $

use strict;
use warnings;
use parent 'Test::Reporter::Transport';

use Carp;
use Test::Reporter;
use Test::Reporter::Transport::File;
use Test::Reporter::Transport::Metabase;

our $MAX_FILES = 25;

BEGIN {
  $Test::Reporter::Transport::Metabase::Fallback::VERSION = '1.001';
}

my @metabase_required_args = ( 'uri', 'id_file' );
my @metabase_allowed_args  = ( 'client', @metabase_required_args );
my @file_allowed_args      = ( 'File' );
my @this_allowed_args      = ( 'max_files' );

sub new {
    my $class = shift;

    Carp::confess __PACKAGE__ . " requires transport args in key/value pairs\n" if @_ % 2;
    my %args = @_;

    foreach my $k ( @metabase_required_args ) {
        Carp::confess __PACKAGE__ . " requires $k argument\n" unless exists $args{$k};
    }

    foreach my $k ( keys %args ) {
        Carp::confess __PACKAGE__ . " unknown argument '$k'\n" unless grep { $k eq $_ } @metabase_allowed_args, @file_allowed_args, @this_allowed_args;
    }

    unless ($args{'File'}) {
        require CPAN::Reporter::Config;
        $args{'File'} = CPAN::Reporter::Config::_get_config_dir();
    }

    $args{'__file'} = Test::Reporter::Transport::File->new( $args{'File'} );

    $args{'__metabase'} = Test::Reporter::Transport::Metabase->new( map { $_ => $args{$_} } grep { $args{$_} } @metabase_allowed_args );

    $args{'max_files'} = $MAX_FILES unless $args{'max_files'};

    return bless \%args => $class;
}


sub send {
    my ($self, $report) = @_;

    my @errors;

    # Try Metabase
    if (my $rv_m = eval { $self->{'__metabase'}->send($report) } ) {
        # Metabase seems working, let's see if we have some files queued
        if (opendir(my $DIR => $self->{'File'})) {
            my @files = map { File::Spec->catfile($self->{'File'}, $_) } grep { /\.rpt/ } readdir $DIR;
            closedir $DIR;
            foreach my $file (splice(@files, 0, $self->{'max_files'})) {
                my $tr = Test::Reporter->new(
                    'transport' => 'Metabase',
                    'transport_args' => [
                        map { $_ => $self->{$_} } grep { $self->{$_} } @metabase_allowed_args
                    ],
                )->read( $file );
                print __PACKAGE__ . ': sending queued report ' . $file . "\n";
                if ($tr and $tr->send()) {
                    unlink $file;
                    sleep 1; # Don't try to hammer the Metabase
                } else {
                    print __PACKAGE__ . ': cannot submit the file to Metabase, stop queue processing.' . "\n";
                    # Cannot send file to Metabase. Let's stop.
                    last;
                }
            }
        }
    } else {
        push @errors, __PACKAGE__ . ' Metabase error: ' . $@,
                      __PACKAGE__ . ' Saving report in the queue.';

        # Try File
        my $rv_f;
        unless ($rv_f = eval { $self->{'__file'}->send($report) }) {
            push @errors, __PACKAGE__ . ' File error: ' . $@;
        }

        Carp::carp join("\n", @errors, '') if @errors;

        return $rv_f;
    }

    return 1;
}

1;

# ABSTRACT: Metabase transport for Test::Reporter with fallback to File transport

=head1 NAME

Test::Reporter::Transport::Metabase::Fallback

=head1 SYNOPSIS

    my $report = Test::Reporter->new(
        transport => 'Metabase::Fallback',
        transport_args => [
          uri     => 'http://metabase.example.com:3000/',
          id_file => '/home/jdoe/.metabase/metabase_id.json',
          File    => '/home/jdoe/.cpanreporter/reports',
        ],
    );

    # use space-separated in a CPAN::Reporter config.ini
    transport = Metabase::Fallback uri http://metabase.example.com:3000/ ... File /home/stro/reports max_files 42

=head1 DESCRIPTION

This module creates a fallback mechanism for Test::Reporter Metabase
instance, combining L<Test::Reporter::Transport::File> and
L<Test::Reporter::Transport::Metabase> functionality.

Whenever Metabase submission fails, the report file is saved locally.
When the next report is successfully submitted to Metabase, all queued
reports are submitted along with it.

"max_files" parameter specifies how many reports are sent from the queue
during the regular submission. Default value is 25. You may want to
increase it if you're running a smoker or decrease it if you don't want to
wait for too long during the casual CPAN shell usage. Keep in mind that
your queue is only processed when a report is being sent so if you're using
CPAN shell irregularly, a small number may keep some reports sitting in a
queue for a very long time.

=head1 ISSUES

If a saved report is corrupted (for example, has 0 byte length because your
disk is full), it will stay in your queue forever.

If a saved report is corrupted in a way that it cannot be accepted by
Metabase, you queue may stuck until you manually remove the offending file.

You probably couldn't use multiple CPAN shells at once unless you separate
.cpanreporter dir for each Perl.

=head1 SUGGESTIONS

Send your suggestions through RT, to stro@cpan.org, or post to
cpan-testers-discuss@perl.org mailing list.

=head1 AUTHOR

Serguei Trouchelle <stro@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2018 by Serguei Trouchelle

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

