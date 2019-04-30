### Upgrading from Disbatch 4.0 to Disbatch 4.2

Copyright (c) 2016, 2019 by Ashley Willis.

#### Configure

For new features to work, the config file must be updated and
`disbatch-create-users` must be ran again.

- For QueueBalance to work:
  - Add `auth.queuebalance` with a password to the config file
  - Set `balance.enabled` to `true` in the config file
  - Rerun `disbatch-create-users`

- For the new routes (`GET /tasks` and `GET /tasks/:id`) to work:
  - Rerun `disbatch-create-users`

- For the deprecated routes to work:
  - Add this `web_extensions` section to the config file and uncomment as
    necessary:

                "web_extensions": {
                    #"Disbatch::Web::Tasks": null,  # deprecated v4 routes: POST /tasks/search, POST /tasks/:queue, POST /tasks/:queue/:collection
                    #"Disbatch::Web::V3": null,     # deprecated v3 routes: *-json
                },

- Rerun `disbatch-create-users`:
  - See `perldoc disbatch-create-users` for more options. If you did the
    default, the following should work fine:

            disbatch-create-users --config /etc/disbatch/config.json --root_user root --drop_roles

- Restart `disbatchd` and `disbatch-webd`, and start `queuebalanced` if used.


### Upgrading from Disbatch 3 to Disbatch 4

#### Preliminary steps

- Rename the tasks and queues collections to `tasks` and `queues` if they have
  different names

- Set each queue's `threads` to how many maximum concurrent threads should be
  ran for that queue across all DENs. The queue field `maxthreads`, which
  applied per DEN, is no longer used.

- Run one of the following on each database, as the `constructor` field has been
  renamed to `plugin`:

        // for back-compat with Disbatch 3
        db.queues.distinct("constructor").forEach(function(c){
            db.queues.update({constructor: c}, {$set: {plugin: c}}, {multi: 1})
        })

        // or for no back-compat with Disbatch 3
        db.queues.update({}, {$rename: {constructor: "plugin"}})

- If using MongoDB authentication, make sure the `plugin` role has the proper
  permissions for any collections the plugin modifies.


#### Configure

See [Configuring](/docs/Configuring.md)

Consult `/etc/disbatch/disbatch.ini` for reference of current settings.


#### Modify your plugins:

- To support only Disbatch 4:
  - Remove these lines:

            use Synacor::Disbatch::Task;
            use Synacor::Disbatch::Engine;
            our @ISA=qw(Synacor::Disbatch::Task);

  - Modify `new()`:

    The plugin was formerly instantiated as `new($queue, $parameters)`, and is
    now instantiated as `new(workerthread => $workerthread, task => $doc)`.

    See [Example `new()`](example-new) below.
  - Remove any `$Synacor::Disbatch::Engine::EventBus` call (namely,
    `report_task_done`).

    **Any other `EventBus` usage will no longer work.**
  - Finally, the task must return this when finished:

            {status => $status, stdout => $stdout, stderr => $stderr};

- To support both Disbatch 3 and Disbatch 4:
  - Replace these lines:

            use Synacor::Disbatch::Task;
            use Synacor::Disbatch::Engine;
            our @ISA=qw(Synacor::Disbatch::Task);

  - with the following:

            warn "Synacor::Disbatch::Task not found\n"
                unless eval 'use base "Synacor::Disbatch::Task"; 1';
            warn "Synacor::Disbatch::Engine not found\n"
                unless eval 'use Synacor::Disbatch::Engine; 1';

  - or if you don't care for the warnings if they aren't installed:

            eval 'use base "Synacor::Disbatch::Task"';
            eval 'use Synacor::Disbatch::Engine';

  - Modify `new()`:

    The plugin was formerly instantiated as `new($queue, $parameters)`, and is
    now instantiated as `new(workerthread => $workerthread, task => $doc)`.

    See [Example `new()`](example-new) below.
  - Append to any `$Synacor::Disbatch::Engine::EventBus` call (namely,
    `report_task_done`):

            if defined $Synacor::Disbatch::Engine::EventBus;

    **Any other `EventBus` usage will no longer work.**
  - Finally, the task must return this when finished:

            {status => $status, stdout => $stdout, stderr => $stderr};

#### Example `new()`

Disbatch 3 was called via `new($queue, $parameters)`, with `$queue` containing
`{id => $queue_id}` and `$parameters` containing the task's parameters.

Disbatch 4 is called via `new(workerthread => $workerthread, task => $doc)`,
with `$workerthread` being a `Disbatch` object using the `plugin` MongoDB user
and role, and `$doc` being the task's document from MongoDB.

The below is from `lib/Disbatch/Plugin/Demo.pm`.

    sub new {
        my $class = shift;

        # deprecated Disbatch 3 format
        if (ref $_[0]) {
            my ($queue, $parameters) = @_;
            warn Dumper $parameters;
            my %self = map { $_ => $parameters->{$_} } keys %$parameters;	# modifying $parameters breaks something in Disbatch 3.
            $self{queue_id} = $queue->{id};
            return bless \%self, $class;
        }

        my $self = { @_ };
        $self->{task}{params} //= $self->{task}{parameters} if defined $self->{task}{parameters};	# for deprecated Disbatch 3 format
        warn Dumper $self->{task}{params};

        # back-compat, so as to not change Disbatch 3 plugins so much
        # stick all params in $self
        for my $param (keys %{$self->{task}{params}}) {
            next if $param eq 'workerthread' or $param eq 'task';
            $self->{$param} = $self->{task}{params}{$param};
        }
        $self->{queue_id} = $self->{task}{queue};
        $self->{id} = $self->{task}{_id};

        bless $self, $class;
    }
