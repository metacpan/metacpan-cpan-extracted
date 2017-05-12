package Vayne::Queue;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::late;

use AnyEvent;
use AnyEvent::Redis;
use Coro;

use Log::Log4perl qw(:easy);
use Sereal qw(encode_sereal decode_sereal);

use Vayne::Job;

use constant BLOCK_TIMEOUT => 5;

has redis => (is => 'rw', isa => 'AnyEvent::Redis');

sub get_queue { map{ $Vayne::NAMESPACE. ":queue:". $_ }@_ }

sub get_next_job
{
    my ($this, $rec, $uuid, $job) = shift;
    $this->redis->blpop( get_queue(@_), BLOCK_TIMEOUT, rouse_cb);
    return unless $rec = rouse_wait;
    $uuid = $rec->[1];
    $job = $this->load_job($uuid);
    $job ? ($rec->[0] => $job) : undef ;

}

sub load_job
{
    my($this, $uuid) = @_;

    my $job = Vayne::Job->new(uuid => $uuid);
    $this->redis->hgetall($job->key, rouse_cb);

    my ($rec, %hash) = rouse_wait;
    return unless ref $rec and %hash = @$rec;

    for(@Vayne::Job::META)
    {
        next unless $hash{$_};
        $hash{$_} = decode_sereal($hash{$_}) if $Vayne::Job::FREEZE{$_};
        $job->$_( $hash{$_} );
    }

    $job;
}


sub add_job
{
    my($this, $job) = @_;
    return unless $this->_update_job( $job, @Vayne::Job::META );
    $this->redis->expire($job->key, $job->expire || 1 * 60 * 60, rouse_cb);

    rouse_wait eq 1 ? 1 : 0;
}

sub update_job 
{
    my($this, $job, $step, $s_name) = splice @_, 0, 2;

    $step = $job->step_to_run;
    $s_name = $step->{name} || $job->run;
    $job->run($job->run + 1);

    $this->redis->exists($job->key, rouse_cb);

    if(rouse_wait eq 1)
    {

        INFO sprintf "[job] %s [step] %s [status] %s [update] %s", 
                $job->key, $s_name, $job->status->{$s_name},
                $this->_update_job( $job, @Vayne::Job::UPDATE ) ? "success" : "failed";
    }else{
        WARN "[job] ". $job->key. " not exists";
    }
}
sub _update_job
{
    my ($this, $job, @attrs) = @_;

    my($key, %values) = $job->key;

    for(@attrs)
    {
        my $v = $job->$_;
        next unless $v;
        $v = encode_sereal($v) if $Vayne::Job::FREEZE{$_};
        $values{ $_ } = $v;
    }

    $this->redis->hmset($key, %values, rouse_cb);
    return unless rouse_wait eq 'OK';

    if(my $queue = eval{$job->step->[ $job->run ]->{worker} })
    {
        $this->redis->rpush(get_queue($queue), $job->uuid, rouse_cb) ;
        return unless rouse_wait > 0;
    }else{
        $this->redis->del($job->key, rouse_cb);
        return unless rouse_wait eq 1;
    }
    1;
}

sub BUILD
{
    my ($self, $param, $cv) = @_;

    LOGDIE "connect string error" unless my @str = $param->{server} =~ /^(.+?)\:(\d+)$/;

    my $redis = AnyEvent::Redis->new(
        host => $str[0],
        port => $str[1],
        encoding => 'utf8',
        on_error => sub { warn "@_ ($param->{server})" },
        on_cleanup => sub { warn "Connection closed: @_" },
    );
    $cv = $redis->auth($param->{password}) and $cv->recv eq 'OK' or warn 'redis auth failed' if $param->{password};

    $self->redis($redis);
}


1;
