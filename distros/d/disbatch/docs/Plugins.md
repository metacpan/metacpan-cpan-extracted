### Writing Perl plugins for Disbatch 4

Copyright (c) 2016 by Ashley Willis.

For a simple example, see `lib/Disbatch/Plugin/Demo.pm`.

#### Requirements

* Two subroutines: `new` and `run`

  * `new({workerthread => $workerthread, task => $doc})`

    `$workerthread` is a `Disbatch` object using the `plugin` MongoDB user and
    role. This gives access to the Disbatch subroutines, such as `logger`,
    `mongo`, and the various collection helper subs (`nodes`, `queues`,
    `tasks`), with whatever MongoDB access permissions `plugin` has.

    `$doc` is the task's full document from MongoDB, where `$doc->{_id}` and
    `$doc->{queue}` are `MongoDB::OID` objects.

  * `run()`

    This must return a HASH, and the HASH should contain the keys `status`,
    `stdout`, and `stderr`.

    The value of `status` must be a positive integer, where `1` indicates
    success, and generally `2` to indicate failure.  If not, it will be set as
    `2`.

    The values of `stdout` and `stderr` should be simple scalars (strings or
    `undef`), and will be forced to be strings.

#### Task Params

Anything for a particular task can be here. For email migrations, we typically
have the following key names: `client`, `migration`, `user1`, `user2`, and
`commands`.

* `client` defines the client name that the user is part of, as some plugins
  work for multiple clients
* `migration` is a string to identify a group of migration tasks. You can also
  use queues alone for this purpose.
* `user1` and `user2` identify the source and destination email accounts. Rarely
  will they differ, outside of testing.
* `commands` is a string where each character signifies a step in the migration
  process, or `*` to signify all the standard steps needed. For each step,
  `commands` is checked against a regex. An array of commands with descriptive
  names could also be used.

The `params` object may also contain additional name/value pairs for special
options.

#### Recommendations

* `finish()`

  As shown in `lib/Disbatch/Plugin/Demo.pm`, there is a `finish` subroutine,
  which handles all the finalization of the task and returning the task's
  `status`, `stdout`, and `stderr`. The finalization is typically saving a
  report for this task in the `reports` collection. In the event of an error, a
  command's step will set the status to `2` to indicate failure, call
  `finish()`, and return the result. If the end of `run()` is reached, then
  `finish()` will be called (at the beginning of `run()`, the status is set to
  `1` to indicate success).

* Reports

  A report typically contains the important identifying params of the task
  (`migration`, `user1`, `user2`, and `commands`), as well as the task and queue
  ids, the start and end times of the task, the plugin version used, the status
  of the task, a count of any errors encounted, and a simple string identifying
  an error which caused a failure of a task.

  This is written to the `reports` collection, so the `plugin` MongoDB user and
  role needs to have the `insert` permission.

* Accessing and updating other MongoDB collections

  You may need to find, update, or insert documents in other collections. The
  `plugin` role by default can read all collections in the database it has
  access to. Add `insert`, `update`, and possibly `createIndex` permissions to
  the role as appropriate.

  Within the plugin, you can access these collections with the following:

        $self->{workerthread}->mongo->get_collection($name)
