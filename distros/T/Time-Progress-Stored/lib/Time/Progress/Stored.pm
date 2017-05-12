package Time::Progress::Stored;
$Time::Progress::Stored::VERSION = '1.002';
use v5.10;
use Moo;
use true;
use autobox::Core;

=head1 NAME

Time::Progress::Stored - Report progress + store and retrieve the current status

=head1 DESCRIPTION

This module helps if you have a long running process which reports
progress, but you need to actually display the progress to the user in
a different process.

Typically this is a long running web request in the web server or in a
job queue worker, while the web browser periodically sends Ajax
requests to get updated on the current progress status to show using a
progress bar.

Time::Progress::Stored stores the progress report as the worker
performs its job, and retrieves it from elsewhere where the report is
needed.

The report is a hashref with the following details:

    | id                | "progress-1454518121172"   |
    | max               | 262                        |
    | current           | 2                          |
    | activity          | "Importing Users"          |
    | elapsed_seconds   | "1"                        |
    | elapsed_time      | " 0:01"                    |
    | finish_time       | "Wed Feb 3 16:50:54 2016"  |
    | percent           | 0.8                        |
    | percent_string    | " 0.8%"                    |
    | remaining_seconds | "130"                      |
    | remaining_time    | " 2:10"                    |
    | is_done           | 0                          |

=head1 SYNOPSIS

    ### In the worker process

    my $progess_id = ...; # Probably comes from the client
    my $max = @items * 2; # Let's say two passes over @items

    my $redis = Redis->new( ... );
    my $progress = Time::Progress::Stored->new({
        max         => $max,
        progress_id => $progress_id,
        storage     => Progress::Stored::Storage::Redis->new({ redis => $redis }),
    });

    # Do the work
    for my $item (@items) {
        # Do stuff
        $progress->advance("Doing the first thing");
    }
    for my $item (@items) {
        # Do other stuff
        $progress->advance("Doing other stuff with $item->{name}");
    }

    $progress->done();


    ### HTTP endpoint, e.g. a Mojo controller for /progress/:progress_id

    sub get {
        my $self = shift;
        my $progress_id = $self->param("progress_id");

        my $storage = Time::Progress::Stored::Storage::Redis->new({
            redis => $self->redis,
        });
        my $response_json = $storage->retrieve($progress_id)
            or return $self->render(status => 404, json => {});

        return $self->render(json => { progress => $response_json });
    }


=head2 Synopsis breakdown

=head3 Worker

As the long running piece of work comes in, start the progress
reporting.

Create the $progress object with a storage to store the progress
reports. Initialize it with the number of actions you want to perform.

For each time something is done, call $progress->advance(). This might
update the actual report.

By default only about 100 steps will be reported (each percent
progressed). You can increase this by specifying the attribute
"report_every", e.g. to report every single time something happens,
set it to 1 (this might slow things down though).

"advance" can optionally be called with an activity description
string, indicating what's happening right now. This can be large scale
steps, or include details about this specific action being performed.

At the end, call $progress->done, just to make sure the reporting
knows it has reached the end. This will set is_done: 1 in the report.


=head3 HTTP endpoint

The client should send requests to the endpoint periodically to get
the current progress report. The request contains the progress id, and
it's simply fetched and returned as a JSON payload.

See above for the contents of the payload.


=head3 Client making a request to a long running web request

This is for when the long running process is running as one web
request.

A web page would typically provide a progress id while making the
initial Ajax request to kick off the long running process.

The client then sends Ajax requests to the HTTP endpoint (using the
id) every second to get updates on the progress. It does this until
the long running progress has responded.

If you look at the report payload you'll see there is a variety of
information to provide user feedback, e.g. percent done, time left,
what's going on etc.


=head3 Client making a request to a asynchronous worker process

This is for when the long running process is running as a background
process, e.g. in a job queue.

A web page would typically kick off the long running process. Instead
of the client passing in a progress id, the $progress object defaults
to a unique id (or you can just make one up yourself), and the HTTP
endpoint can report $progress->progress_id back to the client in the
response.

The client then sends Ajax requests to the HTTP endpoint (using the
id) every second to get updates on the progress. It does this until
the progress report "is_done" is set to 1.


=head2 Storage backends

Time::Progress::Stored can use various backends to store the
status.

Current backends are Redis and Memory. Memory is mainly for testing
and not very useful for real life scenarios.

The backends are tiny and it would be simple to write another backend
for e.g. a file, or using one of the Cache or CHI modules. Patches
more than welcome.



=head2 Pitfalls

If you're testing with a single threaded test server like Morbo, the
web browser's Ajax requests won't be processed until the long running
process has finished, so you'll never see the progress until it's all
done.

=cut

use Types::Standard qw/ Int Bool Str /;
use List::AllUtils qw/ min /;
use Time::Progress;

use Time::Progress::Stored::Storage::Memory;


=head1 ATTRIBUTES

=head2 max

The number of times you're planning to call ->advance().

=cut

has max => (
    is       => "ro",
    isa      => Int,
    required => 1,
);

=head2 storage

A Storage object to store reports in.

Default: Time::Progress::Stored::Storage::Memory, but that's probably
only useful for testing.

=cut

has storage => (
    is  => "lazy",
    isa => sub { shift->isa("Time::Progress::Stored::Storage") },
);
sub _build_storage {
    my $self = shift;
    Time::Progress::Stored::Storage::Memory->new();
}

=head2 progress_id

The id to identify this progress report with. Either set by the
client, or defaulted to a unique URL-param safe value you can return
to the client.

=cut

has progress_id => ( is => "lazy" );
sub _build_progress_id { "progress-" . time() . "-" . int(rand(10_000)) }

=head2 report_every

Number of calls to ->advance() for every time a new progress report is
generated and stored.

Default: a value that results in a report for every percent of
progress.

=cut

has report_every => ( is => "lazy" );
sub _build_report_every {
    my $self = shift;
    int($self->max / 100) || 1;
}

=head2 current

The current iteration. You could in theory set this yourself, but it's
recommended to call ->advance().

=cut

has current => (
    is      => "rw",
    isa     => Int,
    lazy    => 1,
    builder => "_build_current",
);
sub _build_current { 0 }
sub inc_current {
    my $self = shift;
    $self->current( $self->current + 1 );
}

has is_done => (
    is      => "rw",
    isa     => Bool,
    lazy    => 1,
    builder => "_build_is_done",
);
sub _build_is_done { 0 }

=head2 current_activity

Same as ->current, but for the current activity.

=cut

has current_activity => (
    is      => "rw",
    isa     => Str,
    lazy    => 1,
    builder => "_build_current_activity",
);
sub _build_current_activity { "" }




has progress => ( is => "lazy" );
sub _build_progress {
    my $self = shift;
    Time::Progress->new( max => $self->max // 1 )
}



=head1 METHODS

=cut

sub BUILD {
    my $self = shift;
    # There should always be a report available to fetch
    $self->write_report();
}

=head2 advance($activity?)

Advance the progress one iteration. Optionally set the current
$activity.

=cut

sub advance {
    my $self = shift;
    my ($activity) = @_;
    defined($activity) and $self->current_activity( $activity );
    $self->inc_current;
    $self->current % $self->report_every or $self->write_report();
}

=head2 done()

Mark the progress as being completed, and set the is_done key in the
report.

=cut

sub done {
    my $self = shift;
    $self->current( $self->max );
    $self->is_done(1);
    $self->write_report();
}

sub write_report {
    my $self = shift;
    $self->storage->store( $self->progress_id, $self->report );
}

sub report {
    my $self = shift;

    # Avoid going beyond max, since that results in a "n/a"
    my $current = min($self->current, $self->max);

    state $progress_template = join("\t", qw/ %p %l %L %e %E %f /);
    my $report_string = $self->progress->report( $progress_template, $current );
    my (
        $percent_string, $elapsed_seconds, $elapsed_time,
        $remaining_seconds, $remaining_time, $finish_time,
    ) = split(/\t/, $report_string);
    my $percent = $self->percent_from_string($percent_string);

    return {
        id                => $self->progress_id,
        activity          => $self->current_activity,
        max               => $self->max,
        current           => $current,
        percent_string    => $percent_string,
        percent           => $percent,
        elapsed_seconds   => $elapsed_seconds,
        elapsed_time      => $elapsed_time,
        remaining_seconds => $remaining_seconds,
        remaining_time    => $remaining_time,
        finish_time       => $finish_time,
        is_done           => $self->is_done,
    };
}

sub percent_from_string {
    my $self = shift;
    my ($percent_string) = @_;
    $percent_string =~ /([\d.]+)/ or return 0;
    return $1 + 0;
}


=head1 DEVELOPMENT

=head2 Author

Johan Lindstrom, C<< <johanl [AT] cpan.org> >>


=head2 Contributors



=head2 Source code

L<https://github.com/jplindstrom/p5-Time-Progress-Stored>


=head2 Bug reports

Please report any bugs or feature requests on GitHub:

L<https://github.com/jplindstrom/p5-Time-Progress-Stored/issues>.


=head2 Caveats


=head1 COPYRIGHT & LICENSE

Copyright 2016- Broadbean Technologies, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=head1 ACKNOWLEDGEMENTS

Thanks to Broadbean for providing time to open source this during one
of the regular Hack-days.

This module uses the excellent L<Time::Progress> module, which you
should be using if you just need a progress bar in a command line
script.

=cut
