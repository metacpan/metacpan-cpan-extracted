package Disbatch::QueueBalance;
$Disbatch::QueueBalance::VERSION = '4.103';
use 5.12.0;
use warnings FATAL => 'uninitialized';

use Data::Dumper;
use List::Util qw/max min sum/;
use Try::Tiny;

#$config = {
#    LCCLIENT => {
#        balance => {		# skipped if undefined
#            enabled => 1,	# skipped if false
#            log =>     1,	# log output if true
#            verbose => 1,	# verbose output if true
#            pretend => 1,	# don't do updates if true
#        },
#    }
#};
#
#$balance_default = { max_tasks => {}, queues => [] };	# created if no document in balance collection
#$balance = {
#    timestamp => time,		# current time
#    status    => $status,	# 'OK' or 'CRITICAL'
#    message   => $message,	# 'QueueBalance is running' or "QueueBalance $message" or "QueueBalance $error"
#    disabled  => $timestamp,	# a timestamp for when this is disabled until, or undef
#    queues    => [		# each entry is an ARRAY of one or more queue names
#        ...			# i believe these are in order of priority, and if multiple queues in an entry they have the same priority and threads are evenly split between them
#    ],
#    max_tasks => {
#        $key => $value,	# $key =~ /^(?<day>.+?)\s+(?<hour>.+?):(?<minute>.+?)$/
#				# $+{day} is '*' for 0..6, or 0 through 6?
#				# $value is... max number of threads?
#    },
#}

# logger levels: trace debug info warn (log_warn) error (error_warn error_die) fatal (logdie)
sub new {
    my ($class, $config_file) = @_;
    my $disbatch = Disbatch->new(class => 'Disbatch::QueueBalance', config_file => $config_file);
    $disbatch->load_config;
    my $logger = $disbatch->logger('balance');
    $logger->info('Starting Disbatch Queue Balance');

    my $self = { name => $disbatch->{config}{database}, disbatch => $disbatch, logger => $logger };
    if (!defined $disbatch->{config}{balance}) {		# { log => 1, verbose => 0, pretend => 0, enabled => 0 }
        $logger->logdie("QueueBalance for $self->{name} not configured");
        $self->{enabled} = 0;
    } else {
        $self = {
            enabled => $disbatch->{config}{balance}{enabled} // 0,
            # these are optional:
            log     => $disbatch->{config}{balance}{log} // 0,
            verbose => $disbatch->{config}{balance}{verbose} // 0,
            pretend => $disbatch->{config}{balance}{pretend} // 0,
        };
        if ($self->{enabled}) {
            $logger->info("QueueBalance for $self->{name} started");# if $self->{log};
        } else {
            $logger->logdie("QueueBalance for $self->{name} disabled");
        }
    }
    bless $self, $class;
}

# used by monitoring
sub status {
    my ($self, $status, $message) = @_;
    $self->{disbatch}->balance->update_one({}, {'$set' => { timestamp => time, status => $status, message => $message } });
}

sub update {
    my ($self) = @_;

    # 1. find total $max_tasks based on time of day
    my @balance = $self->{disbatch}->balance->find()->all;
    if (!@balance) {
        $self->{disbatch}->balance->insert_one({ max_tasks => {}, queues => [] });
        @balance = $self->{disbatch}->balance->find()->all;
    }
    try {
        die "exactly one entry allowed in balance collection, but found ", scalar @balance unless @balance == 1;
        die "balance collection does not contain key 'max_tasks'" unless defined $balance[0]{max_tasks};
        die "balance collection does not contain key 'queues'" unless defined $balance[0]{queues};
        die "balance collection value for 'queues is not an ARRAY'" unless ref $balance[0]{queues} eq 'ARRAY';
    } catch {
        my $message = $_;
        $self->status('CRITICAL', "QueueBalance: $message");
        die "$self->{name}: $message\n";
    };

    my $max_tasks = max_tasks($balance[0]{max_tasks});

    if (defined $balance[0]{disabled}) {
        if (time < $balance[0]{disabled}) {
            my $message = "disabled until " . localtime $balance[0]{disabled};
            $self->status('OK', "QueueBalance $message");
            $self->{logger}->info("$self->{name}: $message"); # if $self->{verbose};
            return;
        } else {
            $self->{disbatch}->balance->update_one({}, {'$set' => {disabled => undef} }) unless $self->{pretend};
            $self->{logger}->info("$self->{name}: no longer disabled");# if $self->{verbose};
        }
    }

    my @queues = map { [ map { $self->{disbatch}->queues->find_one({name => $_}) } @$_ ] } @{$balance[0]{queues}};

    for my $p (@queues) {
        for my $queue (@$p) {
            $queue->{queued} = $self->{disbatch}->tasks->count({status => {'$lte' => -2}, queue => $queue->{_id}});	# FIXME: maybe just status => -2
            $queue->{running} = $self->{disbatch}->tasks->count({status => {'$in' => [-1,0]}, queue => $queue->{_id}});	# was status => 0
        }
    }

    # 2. find $default_remove which is the sum of non-default queued's, limit $max_tasks
    #my $default_remove = min(sum( map { $_->{queued} } @queues[1..@queues-1] ), $max_tasks);
    my $default_remove = @queues > 1 ? min(sum( map { sum(map { $_->{queued} } @$_) } @queues[1..@queues-1] ), $max_tasks) : 0;

    # 3. set new $default_max which is $max_tasks - $default_remove
    #$queues[0]{max} = $max_tasks - $default_remove;
    $_->{max} = min(int(($max_tasks - $default_remove) / @{$queues[0]}), $_->{queued}) for @{$queues[0]};
    my $adjust = (grep { $_->{max} < $_->{queued} } @{$queues[0]} )[0];
    $adjust->{max} += ($max_tasks - $default_remove) - sum(map { $_->{max} } @{$queues[0]}) if defined $adjust;

    # 4. set new $oneoff_max which is $max_tasks - max($default_running, $default_max) limit $oneoff->{queued}
    # 5. set new $single_max which is $max_tasks - max($default_running, $default_max) - max($oneoff_running, $oneoff_max) limit $single->{queued}
    my $running_max_total = 0;
    for (my $i = 1; $i < @queues; $i++) {
        $running_max_total += sum( map { max($_->{running}, $_->{max}) } @{$queues[$i-1]} );
        $_->{max} = int(max(0, min($max_tasks - $running_max_total, $_->{queued})) / @{$queues[$i]}) for @{$queues[$i]};
        my $adjust = (grep { $_->{max} < $_->{queued} } @{$queues[$i]} )[0];
        $adjust->{max} += max(0, min($max_tasks - $running_max_total, sum(map {$_->{queued}} @{$queues[$i]}) )) - sum(map { $_->{max} } @{$queues[$i]}) if defined $adjust;
    }

    if ($self->{verbose} > 1) {
        say "$self->{name}: running_max_total = $running_max_total";
        say "$self->{name}: default_remove = $default_remove";
        say "$self->{name}: max_tasks = $max_tasks";
        say Dumper \@queues, $adjust;
    }

    #die Dumper @queues;

    # *. apply if needed
    say "pretend ($self->{name}):" if $self->{verbose} and $self->{pretend};
    for my $p (@queues) {
        for my $queue (@$p) {
            $queue->{maxthreads} //= 0;		# disbatch.pl queue creation doesn't create this field
            if ($queue->{maxthreads} != $queue->{max}) {
                say "$self->{name}: changing $queue->{name}: $queue->{maxthreads} => $queue->{max}" if $self->{verbose};
                $self->{logger}->info("$self->{name}: changing $queue->{name}: $queue->{maxthreads} => $queue->{max}") if $self->{log};
                $self->{disbatch}->queues->update_one({name => $queue->{name}}, {'$set' => {maxthreads => $queue->{max} } }) unless $self->{pretend};
            } else {
                say "$self->{name}: no change to $queue->{name}" if $self->{verbose};
            }
        }
    }
    say '---' if $self->{verbose};
    $self->status('OK', 'QueueBalance is running');
}

sub max_tasks {
    my ($max_threads_entries, $debug) = @_;
    die 'Nothing passed to max_tasks' unless defined $max_threads_entries;

    use warnings FATAL => 'uninitialized';

    my $max_threads_hash = {};
    for my $k (sort keys %$max_threads_entries) {
        my ($d, $t) = split /\s+/, $k;
        my ($h, $m) = split /:/, $t;
        if ($d eq '*') {
            $max_threads_hash->{$_}{$h}{$m} = $max_threads_entries->{$k} for 0..6;
        } else {
            $max_threads_hash->{$d}{$h}{$m} = $max_threads_entries->{$k};
        }
    }

    (undef, my $min, my $hour, undef, undef, undef, my $wday) = localtime;

    my @days = sort {$a <=> $b} keys %$max_threads_hash;
    my @eq = grep { $_ == $wday } @days;
    my @lt = grep { $_ < $wday } @days;
    my @gt = grep { $_ > $wday } @days;

    my $hour_hash = @eq ? $max_threads_hash->{$eq[0]} : @lt ? $max_threads_hash->{$lt[-1]} : $max_threads_hash->{$gt[-1]};

    my @hours = sort {$a <=> $b} keys %$hour_hash;
    @eq = grep { $_ == $hour } @hours;
    @lt = grep { $_ < $hour } @hours;
    @gt = grep { $_ > $hour } @hours;

    my $min_hash = @eq ? $hour_hash->{$eq[0]} : @lt ? $hour_hash->{$lt[-1]} : $hour_hash->{$gt[-1]};

    my @mins = sort {$a <=> $b} keys %$min_hash;
    @eq = grep { $_ == $min } @mins;
    @lt = grep { $_ < $min } @mins;
    @gt = grep { $_ > $min } @mins;

    my $max = @eq ? $min_hash->{$eq[0]} : @lt ? $min_hash->{$lt[-1]} : $min_hash->{$gt[-1]};

    if ($debug // 0) {
        say Dumper $max_threads_hash;
        say "$wday $hour $min";
        say 'hour => minute : ', Dumper $hour_hash;
        say 'minute => value : ', Dumper $min_hash;
        say $max;
    }

    return $max;    
}

__END__

=head1 NAME

Disbatch::QueueBalance

=head1 VERSION

version 4.103

=head1 SYNOPSIS

    use Disbatch::QueueBalance;

    my $qb = Disbatch::QueueBalance->new($config_file); # where $config_file is the same as for Disbatch
    $qb->update();

=head1 Subroutines

=over 2

=item new($config_file)

Parameters: path to Disbatch config file

Sets up QueueBalance. Dies if QueueBalance is not configured or not enabled.

=item status($status, $message)

Parameters: status string (should be C<OK>, C<WARNING>, or C<CRITICAL>), message for status

Returns C<update_one> result, but is ignored.

=item update

Parameters: none

Updates maxthreads for all queues, for all clients.

Returns nothing meaningful. Sets status to C<CRITICAL> and dies if the C<balance> collection is misconfigured.

=item max_tasks($max_threads_entries)

Parameters: C<HASH> where keys are of form C<D H:M> and values are integers.

Determines the max number of threads allowed for the current day and time.

Returns: integer for current max_threads allowed

  day of week  0-6 (0 is sunday), or * for all unless an explicit rule overrides it
  hour         0-23
  minute       0-59

=back

=head1 AUTHORS

Ashley Willis <awillis@synacor.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015, 2019 by Ashley Willis.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

==========================================

[ default oneoff single ] {
    begin
        maxthreads max ne {
            verbose { (changing ) print name print (: ) print maxthreads print ( => ) print max print (\n) print } if
            pretend not {
                mongo /collection get [ << /name name >> << /$set << /maxthreads max >> >> ] .update
            } if
        } {
            verbose { (no change to ) print name print (\n) print } if
        } ifelse
    end
} forall

CURRENT:
1. find total $max_tasks based on time of day
2. find $master_remove which is $oneoff->{queued} limit $max_tasks
3. set new $master_max which is $max_tasks - $master_remove
4. set new $oneoff_max which is $max_tasks - ( $master_running > $master_max ? $master_running : $master_max )

NEW:
1. find total $max_tasks based on time of day
2. find $master_remove which is ($oneoff->{queued} + $single->{queued}) limit $max_tasks
3. set new $master_max which is $max_tasks - $master_remove
4. set new $oneoff_max which is $max_tasks - max($master_running,$master_max) limit $oneoff->{queued}
5. set new $single_max which is $max_tasks - max($master_running,$master_max) - max($oneoff_running,$oneoff_max) limit $single->{queued}

1n. $max_tasks is always positive.
2n. $master_remove is never < 0 since queued values are verified to be >= 0.
3n. $master_max is never < 0 since $master_remove is limited by $max_tasks
4n. if $master_running > $max_tasks, problems for $oneoff_max -- should not let it be < 0
5n. if $master_running+$oneoff_running > $max_tasks, problems for $single_max -- should not let it be < 0

* hughes and oneoff are set to max 10|0, but processing 10|1, and running this does not change hughes max to 9

# in comes 4 oneoffs: (10 0 0)
1. 10
2.  4 = 4+0 lim 10
3.  6 = 10-4
4.  0 = 10-10
5.  0 = 10-10-0

# 2 in master finish, and 3 singles come in: (8 0 0)
1. 10
2.  7 = 4+3 lim 10
3.  3 = 10-7
4.  2 = 10-8
5.  0 = 10-8-2

# 2 more in master finish (6 2 0)
1. 10
2.  7 = 4+3 lim 10
3.  3 = 10-7
4.  4 = 10-6
5.  0 = 10-6-4

# 1 in oneoff finishes (6 3 0)
1. 10
2.  6 = 3+3 lim 10
3.  4 = 10-6
4.  3 = 10-6 lim 3
5.  1 = 10-6-3

# (6 3 1)
