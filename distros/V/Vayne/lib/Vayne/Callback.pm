package Vayne::Callback;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::late;

use AnyEvent;
use AnyEvent::Redis;
use Coro;

use Log::Log4perl qw(:easy);
use Data::Printer;

use Vayne;
use Vayne::Task;
use Vayne::Tracker;
use constant CHANNEL => 'TASK_STAT';
use constant INTERVAL => 5;

our $CHANNEL = CHANNEL. ":". $Vayne::NAMESPACE;


has redis => (is => 'rw', isa => 'AnyEvent::Redis');
sub wait
{
    my($this, $taskid, $timeout, $cv, $tracker) = splice @_, 0, 3;

    $timeout = time + $timeout if defined $timeout;
    $tracker = Vayne::Tracker->new();

    $cv = $this->redis->subscribe($CHANNEL, sub {
        my ($id, $channel) = @_;
        $cv->send( $tracker->query_task($id) ) if $id eq $taskid;
    });

    my $w_timer = AnyEvent->timer(after => 0, interval => INTERVAL, cb => sub {
        my $stat = $tracker->query_task($taskid);
        unless($stat)
        {
            $cv->send('task not found!');
        }elsif(
            defined $timeout 
            && time > $timeout
        ){
            $cv->send('timeout! Task still running!');
        }elsif(
            grep{$stat->{status} eq $_}
            (Vayne::Task::STATUS_TIMEOUT, Vayne::Task::STATUS_CANCEL, Vayne::Task::STATUS_COMPLETE)
        ){
            $cv->send($stat);
        }

    });
    $cv->recv;
}


sub BUILD
{
    my ($self, $cv) = shift;

    my $conf = Vayne->conf('redis')->{callback};
    LOGDIE "connect string error" unless my @str = $conf->{server} =~ /^(.+?)\:(\d+)$/;

    my $redis = AnyEvent::Redis->new(
        host => $str[0],
        port => $str[1],
        encoding => 'utf8',
        on_error => sub { warn @_ },
        on_cleanup => sub { warn "Connection closed: @_" },
    );
    $cv = $redis->auth($conf->{password}) and $cv->recv eq 'OK' or warn 'redis auth failed' if $conf->{password};

    $self->redis($redis);
}
1;
