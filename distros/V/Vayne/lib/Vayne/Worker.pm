package Vayne::Worker;
use Vayne;
use Vayne::Zk;
use Vayne::Queue;

use Clone qw(clone);
use Guard;
use Coro;
use AnyEvent;
use Coro::AnyEvent;
use Log::Log4perl qw(:easy);

use base Exporter;

@EXPORT = qw(register);                 # symbols to export on request

use constant POISON => 'POISON_PILL';   
use constant MAX_UP_JOB => 10;          #update job when up channel contain jobs >= 10

my %worker;
sub register
{
    my($queue, $sub, $concurrency) = @_;
    $concurrency ||= 1;
    $worker{$queue} = [$sub, $concurrency, Coro::Channel->new];
}

sub run
{
    my ($zk, @path) = Vayne::Zk->new;
    @path = $zk->register(keys %worker);

    my($up_channel, @w_thread, @c_thread, $KILL) = Coro::Channel->new(MAX_UP_JOB);
    my $k_sig = new Coro::Signal;


    $SIG{TERM} = $SIG{INT} = $SIG{HUP} = sub
    {
        local $SIG{TERM} = local $SIG{INT} = local $SIG{HUP} = 'IGNORE';
        INFO "signal receive, prepare to die!";
        $KILL = 1;
        $k_sig->send;
    };

    #thread: check zk connection
    async { while(1){ $zk->check; Coro::AnyEvent::idle_upto 10;}};

    #thread: update job info
    my $up_thread = async
    {
        my $q = Vayne::Queue->new($zk->queue);
        while(1)
        {
            my $job = $up_channel->get;
            last if $job eq POISON;

            $q->update_job($job);
        }
        TRACE "job updater quit";
    };

    for my $queue( keys %worker)
    {
        my $q = Vayne::Queue->new($zk->queue);
        my($sub, $concurrency, $channel) = @{ $worker{$queue} };
        my $sem = Coro::Semaphore->new($concurrency);
        
        #thread: job consumer
        push @c_thread, async
        {
            while(1)
            {
                last if $KILL;
                my($worker, $job) = $q->get_next_job($queue);
                next unless  $job;

                TRACE "try $queue down: ", $sem->count;
                $sem->down;
                TRACE "$queue down: ", $sem->count;

                $channel->put($job);
                
            }
            TRACE $queue," consumer quit";
        };

        #thread: worker
        for my $worker_num(1..$concurrency)
        {
            push @w_thread, async
            {
                while(1)
                {
                    my $job = $channel->get;

                    TRACE "job:", $job;
                    last if $job eq POISON;

                    #1.check step now is null => no need to do job
                    #2.check need => update status no need to do        TODO
                    #3.do step => log result
                    
                    my $step = $job->step_to_run;

                    if($step)
                    {
                        my $s_name = $step->{name}||$job->run;
                        my @subs = my($s_result, $s_status) = 
                            map{ my $method = $_; sub{ $job->$method($s_name, shift) } }qw(result status);
                        
                        if($job->chk_need($step))
                        {
                            eval { $sub->( $job->workload, $step, @subs, clone($job) ) };

                            if($@)
                            {
                                FATAL $@;
                                $s_result->('worker execute failed');
                                $s_status->(0);
                            }
                        }else{
                            $s_status->(0); 
                            INFO "[job] ", $job->key, " step ", $step->{name}, " no need to do";
                        }
                        TRACE "try put update channel";
                        $up_channel->put($job);
                        TRACE "put update channel";

                    }else{
                        TRACE "[job] ", $job->key, " run ", $job->run, " no more step";
                    }

                    $sem->up;
                    TRACE "$queue up ", $sem->count;
                }
                TRACE $queue.$worker_num, " quit";
            }
        }
    }

    #wait to die
    $k_sig->wait;

    $_->join for @c_thread;
    INFO "Consumer DOWN!";
    
    for(values %worker)
    {
        my($sub, $concurrency, $channel) = @$_;
        $channel->put(POISON) for 1..$concurrency;
    }

    $_->join for @w_thread; INFO "Worker DOWN!";

    $up_channel->put(POISON); $up_thread->join; INFO "Updater DOWN!";
}

1;
