### Differences in Disbatch 4 compared to Disbatch 3

#### Goals achieved with rewrite:
- No more memory leak in main process.
- No more locked up event bus via unix sockets (uses MongoDB to pass all data).
- Can stop/restart disbatchd process any time without affecting running tasks.
- Can update plugins at any time without restarting disbatchd.
- Independent web server.
- Better permission model for MongoDB.


#### Backwards compatibility concerns for existing deployments:
- Can replace v3 of Disbatch with v4 with minimal changes to the database, and
  few changes to the plugin.
- Can run both v3 and v4 against the same unauthenticated database.
- CANNOT pass Perl data structures (only JSON is allowed) to `queue search` nor
  `queue tasks`. That was a horrible idea.
- The `Backfill` feature has been removed - a web server thread handles this
  (creating 100k tasks at once only took 12 seconds on my 13" rMBP).
- The `Preemptive` setting has been removed.
- The `enclosure` command has been removed.
- The `reloadqueues` command has been removed.
- The API call `/scheduler-json` returns `queued`, `running`, and `completed`
  instead of `tasks_todo`, `tasks_doing`, `tasks_done`, and the UIs have been
  updated and reordered to match.
- The main process, the web server, the task runner, and the plugin all have
  their own permission models if using authentication instead of sharing one
  account.
- Queue names must now be unique.


#### Changes:
- To keep the code simple, as much as possible is by convention instead of
  config (collection names, DEN name, etc).
- As the DEN name is the hostname the DEN is running on, only one instance is
  allowed per server.
- No need to have a file in `etc/disbatch/disbatch.d/` to define a plugin.
- Only the `::Task` part of the plugin is needed. Its parent is unused.
- `bin/disbatchd` instead of `bin/disbatchd.pl`
- `etc/disbatch/config.json` instead of `etc/disbatch/disbatch.ini`
- The `disbatch-log4perl.conf` file is no longer used (automatically generated
  settings, can be overwritten in the config file)
- Task `stdout` and `stderr` are now written to (mostly-compatible) GridFS
  documents if needed due to size. This can be disabled in the config, or always
  enabled for all tasks.
- To define a queue via the Disbatch Command Interface, the type must already be
  used in another queue, or listed in `plugins` in the config.
- `ctime` and `mtime` are now `ISODate()` objects in MongoDB, and not unix
  timestamps.
- `parameters` has been renamed to `params` in task documents.
- `count_todo` and `count_total` have been removed from the queue documents.
  These are now counted on demand.
- `queues` has been removed from the node documents in the `nodes` collection.
- `maxthreads` (which applied per DEN) in queues has been replaced by `threads`
  (which applies across all DENs).


#### New:
- can limit a DEN to a maximum number of tasks to run (value goes in the
  `nodes` collection documents)
