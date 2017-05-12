package Vayne;

use strict;
use warnings;

use YAML::XS;
use File::Spec;
use Data::Printer;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

require Exporter;

our $VERSION         = '0.01';
our $NAMESPACE       = $ENV{VAYNE_SPACE} || 'vayne';
our $HOME            = $ENV{VAYNE_HOME}  || '~/vayne';

=encoding utf8

=head1 NAME

Vayne - Distribute task queue

=head1 SYNOPSIS

  use Vayne;
  use Vayne::Callback;
  use Vayne::Tracker;

  my @workload = <>; chomp @workload;
  my $tracker = Vayne::Tracker->new();
  my $step = Vayne->task('foo');
  my $taskid = $tracker->add_task(
       'region:region-first',
       {
           name   => 'foo',
           step   => $step,
           expire => 90,
       },
       @workload
  );
  my $call = Vayne::Callback->new();
  my $stat = $call->wait($taskid);

=head1 GETTING STARTED

  # First time only
  > vayne-init -d $HOME/vayne

  # Setup configurations in $HOME/vayne/conf (zookeeper mongodb redis)

  # Add our first region, then the region info will upload to zk server.
  > vayne-ctrl --set --region region-first --server redisserver:port --password redispasswd

  # Define our first task, $HOME/vayne/task/foo

    # check server ssh server
    - name: 'check ssh'                     #step's name
      worker: tcp                           #step's worker
      param:                                #step's parameters
        port: 22
        input: ''
        check: '^SSH-2.0-OpenSSH'

    - name: 'foo'
      worker: dump
      param:
        bar: baz

    - name: 'only suc'
      need:
        - 'check ssh': 1
      worker: dump
      param:
        - array
        - key1: value1
          key2: value2

    # tracke the job result
    - name: 'tracker'
      worker: track

  # Switch the server you run workers to our first region.
  > vayne-ctrl --switch --region region-first

  # Run workers.
  > $HOME/vayne/worker/tcp &
  > $HOME/vayne/worker/dump &
  > $HOME/vayne/worker/tracker &

  # Run task tracker.
  > vayne-tracker &

  # Submit our task by CLI.
  > echo '127.0.0.1'|vayne-task --add --name foo --expire 60 --strategy region:region-first
  # or
  > vayne-task --add --name foo --expire 60 --strategy region:region-first < server_list

  # Query our task through taskid by CLI.
  > vayne-task --taskid 9789F5E6-2644-11E6-A6F0-AF9AF8F9E07F --query

  # Or use Vayne lib in your program like SYNOPSIS.

=head1 DESCRIPTION

Vayne is a distribute task queue with many feature.

=head2 FEATURE

=over 3

=item Logical Region with Flexible Spawning Strategy

Has the concept of logical region.
You can spawn task into different region with strategy.
Spawning strategy can be easily write.

=item Custome Task Flow with Reusable Worker

Worker is a process can do some specific stuffs.
Step have a step's name, a worker's name and parameters.
You can define custome task flow by constructing any steps.

=item Simple Worker Interface with Good Performance

L<Vayne::Worker> is using L<Coro> which can provide excellent performance in network IO. 
Worker has a simple interface to write, also you can use Coro::* module to enhance worker performance.
Whole system is combined with Message Queue. 
You can get a better performance easily by increasing the worker counts while MQ is not the bottleneck.

=back

=head2 HOW IT WORKS

                                                                             +--------+
                                                                             |Worker A| x N
                                                                             +--------+
                                                       +------------+                        Workers may run on several servers
                                                       |            |        +--------+
                                                       |  Region A  |        |Worker B| x N
                                                       |            |        +--------+
                                                       +------------+
                                                                               .....
  +-----------+                                                              +----------+
  |           |                                        +------------+        |JobTracker| x N
  | Task Conf |                                        |            |        +----------+
  |           |                                        |  Region B  |
  | +-------+ |                                        |            |
  | | step1 | |    +-----------+                       +------------+                                                 +-----------+          +-----------+
  | +-------+ |    |           |        Spawn Jobs                                           Save Job Information     |           | +------> |           |
  |           | +  | workloads |    +---------------->                                       +--------------------->  |  Mongodb  |          |TaskTracker|
  | +-------+ |    |           |       with Strategy                                          to Center Mongodb       |           | <------+ |           |
  | | step2 | |    +-----------+                       +------------+                                                 +-----------+          +-----------+
  | +-------+ |                                        |            |
  |    ...    |                                        |  Region C  |          .....                                       ^
  | +-------+ |                                        |            |                                                      |
  | | stepN | |                                        +------------+                                                      |
  | +-------+ |                                                                                                            |
  |           |                                                                                                            |
  +-----------+                                        +------------+                                                      |
                                                       |            |                                                      |
                                                       |  Region D  |                                                      |
                |                                      |            |                                                      |
                |                                      +------------+                                                      |
                |                                                                                                          |
                |                                                                                                          |
                |                                                                                                          |
                |                                                                                                          |
                |                                Save Task Information to Center Mongodb                                   |
                +----------------------------------------------------------------------------------------------------------+
  

=head3 0. Task Conf & Step

The Task Conf is combined with several ordered steps.
Each step have a step's name, a worker's name and parameters.
Workload will be prosessed step by step.

=head3 1. Spawn Task

Vayne support CLI and API to spawn a task.
A task contain numbers of jobs.
Task info will write to I<task collection> in mongodb first.
Jobs will be hashed into saperated region by strategy.
Then enqueue jobs to their region's redis queue named by first step of the job, and write to I<job collection> in mongodb.

=head3 2. Queue & Region

Like L<Redis::JobQueue>, Vayne use I<redis> for job queuing and job info caching.
The data structure is nearly the same as L<Redis::JobQueue/"JobQueue data structure stored in Redis">.

Each B<region> has a I<queue(redis server)>. Both their infomation are saved on I<zookeeper server>.

Each I<real server> which you want to run workers should belong to a B<region>.

B<Worker> will register its names under real server's B<region> on I<zookeeper server> when it start.

Details see L<Vayne::Zk/"DATA STRUCTURE">.

=head3 2. Worker

When it start, worker register its names on I<zookeeper server>.
Then generate some L<Coro> threads below:

=over 4

=item Check the Registration

Go die when the registration changed.
Ex: Region info changed; Real Server switch to another region; Connection to zk failed.

I< * The worker will die very quickly when zookeeper server is not available. It may cause some problems. Should be careful. >

=item Job Consumer

BLPOP queues which worker registered, then put the job into L<Coro::Channel>

=item Worker

Get B<job> from L<Coro::Channel>, and do the stuff with it.
Tag the I<result> and I<status> on the B<job>.
Put the B<job> to update L<Coro::Channel>.

=item Update Job Info

Get B<Job> from  update L<Coro::Channel>.
Push the job to next queue according to the job's step.

=back

C<INT>, C<TERM>, C<HUP> signals will be catched.
Then graceful stop the worker.


=head3 4. JOB TRACKER

Job tracker is a special worker, it just send the job info dealed by previous workers to mongodb.
Usually 'tracker' should be the last step of a job.

=head3 5. TASK TRACKER

Script L<vayne-tracker>
Loop
bla..


=head2 BACKEND

Redis-3.2 L<http://redis.io/>

Zookeeper-3.3.6 L<http://zookeeper.apache.org/>

MongoDB-3.0.6 L<https://www.mongodb.com/>

=head2 DATA STRUCTURE

=head3 Zookeeper

L<Vayne::Zk/"DATA STRUCTURE">

=head3 Redis

Data Structure for job&queue is nearly the same as
L<Redis::JobQueue/"JobQueue data structure stored in Redis">

=head3 MongoDB

bla bla..


=head2 HOW TO WRITE A WORKER

bla bla..

=cut

my %STUB =
(
    conf => sub { eval{YAML::XS::LoadFile $_[0]} or LOGWARN $@;},
    task => sub { eval{YAML::XS::LoadFile $_[0]} or LOGWARN $@;},
    strategy => sub { eval{do $_[0]} or LOGWARN $@; },
);

#init logger
{
    my $conf = Vayne->conf('logger');
    $_->{level} = $Log::Log4perl::Level::PRIORITY{ $_->{level} } for @$conf;
    Log::Log4perl->easy_init(@$conf);
}

sub _path{File::Spec->join( $Vayne::HOME,  @_)}

sub AUTOLOAD
{
    return if our $AUTOLOAD =~ /::DESTROY$/;

    my $class = __PACKAGE__;
    my( $func ) = $AUTOLOAD =~ /^$class\:\:(.+)$/;
    return unless $func && $STUB{$func};

    my($foo, $name) = @_;
    LOGWARN "$name is not a file" and return unless $name = _path($func, $name) and -f $name;
    $STUB{$func}->($name);
}



1;
__END__

=head1 AUTHOR

SiYu Zhao E<lt>zuyis@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2016- SiYu Zhao

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Redis::JobQueue>

=cut
