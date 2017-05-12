package TheSchwartz::Moosified::Worker;

use strict;

sub grab_job {
    my $class = shift;
    my($client) = @_;
    return $client->find_job_for_workers([ $class ]);
}

sub keep_exit_status_for { 0 }
sub max_retries { 0 }
sub retry_delay { 0 }
sub grab_for { 60 * 60 }   ## 1 hour

sub work_safely {
    my ($class, $job) = @_;
    my $client = $job->handle->client;
    my $res;

    $job->debug("Working on $class ...");
    $job->set_as_current;
    $client->start_scoreboard;

    eval {
        $res = $class->work($job);
    };

    my $cjob = $client->current_job;
    if ($@) {
        $job->debug("Eval failure: $@");
        $cjob->failed($@);
    }
    unless ($cjob->did_something) {
        $cjob->failed('Job did not explicitly complete, fail, or get replaced');
    }

    $client->end_scoreboard;

    # FIXME: this return value is kinda useless/undefined.  should we even return anything?  any callers? -brad
    return $res;
}

1;
__END__

=head1 NAME

TheSchwartz::Moosified::Worker - superclass for defining task behavior

=head1 SYNOPSIS

    package MyWorker;
    
    use base 'TheSchwartz::Moosified::Worker';

    sub work {
        my $class = shift;
        my $job = shift;

        print "Workin' hard or hardly workin'? Hyuk!!\n";

        $job->completed();
    }

=head1 DESCRIPTION

TheSchwartz::Moosified::Worker is just a copy of L<TheSchwartz::Worker> to avoid an install of L<TheSchwartz>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
