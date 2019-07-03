package WorkerManager::Client::TheSchwartz;
use strict;
use warnings;

use DBI;
use TheSchwartz::Simple;
use Module::Load ();
use Carp;

sub new {
    my ($class, $args) = @_;
    # Old version had typo...
    my $dsn = $args->{dsn} || $args->{dns} || croak 'not specified dsn for worker manager';
    my $user = $args->{user} || 'nobody';
    my $pass = $args->{pass} || 'nobody';
    my $opts = $args->{opts} || {};

    my $client;
    if ($ENV{DISABLE_WORKER}) {
        Module::Load::load('TheSchwartz');
        Module::Load::load('TheSchwartz::Job');
    } else {
        my $dbh = DBI->connect($dsn, $user, $pass, {RaiseError => 1, %$opts});
        $client = TheSchwartz::Simple->new([$dbh]);
    }
    bless { client => $client }, $class;
}

sub insert {
    my $self = shift;
    my $funcname = shift;
    my $arg = shift;
    my $options = shift;

    my $job = $ENV{DISABLE_WORKER} ? TheSchwartz::Job->new : TheSchwartz::Simple::Job->new;
    $job->funcname($funcname);
    $job->arg($arg);
    $job->run_after($options->{run_after} || time);
    $job->grabbed_until($options->{grabbed_until} || 0);
    $job->uniqkey($options->{uniqkey} || undef);
    $job->priority($options->{priority} || undef) if($job->can('priority'));

    if ($ENV{DISABLE_WORKER}) {
        eval {
            Module::Load::load($funcname);
            $funcname->work($job);
            warn $@ if $@;
            return !$@;
        }
    } else {
        return $self->{client}->insert($job)
    }
}

1;
