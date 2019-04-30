### Design of Disbatch 4

Copyright (c) 2016, 2019 by Ashley Willis.

This documents the Disbatch Execution Node (DEN) protocol and schema. All DENs
using the same MongoDB database must follow this, as well as the Disbatch Task
Runners (DTR) used by the DENs and any Disbatch Command Interfaces (DCI) using
the database.

#### Overview

The core components of Disbatch 4 are one or more DENs, the DTRs, one or more
DCIs, and MongoDB which is used as the data store and for all message passing.

The DEN ensures the database is set up correctly and runs the appropriate number
of tasks for each queue.

The DTR is called by the DEN when it claims a task. The DTR is responsible for
loading the plugin and running the task, as well as updating the task document
when the task completes.

The DCI provides a JSON REST API for the DENs, as well as a web browser
interface to the API. An additional CLI tool interacts with this API.


Each DEN monitors one or more queues, which may be restricted to a subset of
DENs, restricted from a subset of DENs, or available to all DENs.

Each queue uses a specific Disbatch plugin for its tasks. If the plugin listed
for a queue is not available, the queue is ignored. The queue sets the limit of
tasks to run across all DENs for that queue with the `threads` field.

A DEN may also limit the number of tasks to run on that DEN with the
`maxthreads` field in its `nodes` collection's document.

Each task links to a single queue.

On startup, each DEN:

* Reads the config file to get MongoDB settings and possibly other settings

* Ensures the collections have the proper indexes

* Optionally validates that all plugins listed in defined queues have a proper
  name and can be used

At a set interval (1 second), each DEN:

* Updates or inserts a document for itself in the `nodes` collection

* Cleans up any orphaned tasks

* Processes each queue, starting tasks as needed

* Optionally revalidates that all plugins listed in defined queues have a proper
  name and can be used if needed

#### Orphaned Tasks

Before a DEN starts processing tasks, it must clean up any orphaned tasks that
were not put into a completed state by setting their status to `-6`. It can also
check for this periodically. A recommendation is checking for tasks with a
status of `-1` and an `mtime` of older than 5 minutes.


##### Task Lifecycle

Each task is initialised with its `node` as `null` (unclaimed) and `status` as
`-2` (queued).

DENs claim tasks from queues using `findOneAndUpdate(filter, update, options)`,
(which returns the task object), by putting them into a claimed state (setting
`status` to `-1` and `node` to the hostname of the DEN) until the per-DEN
`maxthreads` and per-queue `theads` thresholds are reached. The DEN then
notifies the DTR of the task, and the DTR puts the task into a running state
(setting `status` to `0`). When the plugin has finished, it reports back the
status, stdout, and stderr of the task to the DTR. The DTR then updates the
task's document in MongoDB with these values as well as the `mtime`.

###### `findOneAndUpdate(filter, update, options)`

* filter

        { node: null, status: -2, queue: queue._id }

  Where `queue._id` is an `ObjectId` of the desired queue

* update

        { $set: {node: this.node, status: -1, mtime: ISODate()} }

    Where `this.node` is the hostname

* options (example to get the oldest queued task)

        { sort: { _id: 1 } }

See your MongoDB driver's documentation on its implemenation of
`findOneAndUpdate()`. If it is not available, you can use `findAndModify()`.

This ensures that there will be no race conditions amongst DENs, even in a
sharded or replicated MongoDB cluster.


#### Database Collections

##### Nodes

DEN documents are in the `nodes` collection.

###### Specification

The following elements must be included when registering a DEN:

* `node`: hostname (unique)

* `timestamp`: [ISODate](https://docs.mongodb.org/manual/core/shell-types/)

Each node document can also contain:

* `maxthreads`: a non-negative integer or null. If set to an integer, this
  entire DEN is limited to running that number of concurrent tasks across all
  queues.

MongoDB will create an `ObjectId` for the node's `_id`.

###### Example

    {
        "_id" : ObjectId("56fc05087aa3a33942e42a6a"),
        "node" : "mig01.example.com",
        "timestamp" : ISODate("2016-04-26T19:26:33.649Z"),
        "maxthreads": 5,
    }


##### Queues

Queue documents are in the `queues` collection.

###### Specification

The following elements must be included when creating a queue:

* `name`: a string to identify this queue (unique)

* `plugin`: the name of the plugin this queue uses (example:
  `"Disbatch::Plugin::Demo"`)

The following elements may be included when creating a queue:

* `threads`: a non-negative integer for the maximum number of threads across all
  DENs for this queue, or null

* `sort`: a string on how to sort the query results when looking for the next
  task to run. Valid options are `fifo`, `lifo`, or `default`. The sort is on
  the tasks' `_id` values. If not used, the default order of the query returned
  by MongoDB will be used.

MongoDB will create an `ObjectId` for the queue's `_id`.

###### Example

    {
        "_id" : ObjectId("571f8951b75bf335634ec271"),
        "plugin" : "Disbatch::Plugin::Demo",
        "name" : "demo",
        "threads" : 0,
        "sort" : "fifo"
    }


##### Tasks

Task documents are in the `tasks` collection.

###### Specification

The following elements must be included when creating a task:

* `queue`: an `ObjectId` of the queue's `_id`

* `ctime`: an `ISODate` of the creation time

* `mtime`: an `ISODate` of the modification time

* `node`: the DEN this task is running or ran on, or `null` if queued

* `status`: an integer for the task status code

* `params`: an object describing the unique qualities of this task (user,
  commands, etc)

The following elements should be created by the DEN when the task finishes, and
should be set to `null` when created:

* `stdout`: task output as a string or the GridFS file's `ObjectId`, or null

* `stderr`: task errors as a string or the GridFS file's `ObjectId`, or null

MongoDB will create an `ObjectId` for the task's `_id`.

###### Example

    {
        "_id" : ObjectId("571fac85ee63413233049fbd"),
        "params" : {
            "migration" : "oneoff",
            "user1" : "ashley@example.com",
            "user2" : "ashley@example.com",
            "commands" : "*",
        },
        "ctime" : ISODate("2016-04-26T17:59:33Z"),
        "status" : 1,
        "mtime" : ISODate("2016-04-26T18:37:40Z"),
        "queue" : ObjectId("54a700074b485f0b00000000"),
        "node" : "mig01.example.com",
        "stderr" : ObjectId("571fbac9d8590b78fe4830b4"),
        "stdout" : ObjectId("571fbac9d8590b78fe4830b2")
    }


#### Task Status Codes

These are the standard status codes in Disbatch 4:

* `-6`: Orphaned

  A task that was being worked on, but there was a disruption that was unrecoverable

* `-2`: Queued

  A task that has yet to be processed

* `-1`: Claimed

  A task claimed by a DEN but has yet to start (within ms). The `node` must also
  be set to the DEN's hostname for tasks with a claimed status.

* `0`: Running

  A task that is being worked on

* `1`: Succeeded

  A task that completed successfully

* `2`: Failed

  A task that completed, but part failed due to an error

Formerly defined status codes that may be used for other needs:

* `-5`: Cancelled

* `-4`: Blocked

* `-3`: Terminated

You may use additional integer values for status codes. As a postive integer
indicates that a task has finished, your plugin must return a positive integer
for the status. Any unused negative value may be set when a task is queued to
prevent the DEN from claiming it.

#### GridFS for Task stdout and stderr

Task `stdout` and `stderr` can be stored in the task as strings or by using
MongoDB's [GridFS](https://docs.mongodb.com/manual/core/gridfs/) specification.

As a document cannot be more than 16MB, GridFS will be needed to store `stdout`
and `stderr` if they can cause the task document to exceed this size.

Disbatch uses the collections `tasks.files` and `tasks.chunks` instead of the
default `fs.files` and `fs.chunks`, and the chunks are stored to ensure `data`
is of type `String` and not `BinData`. Each file contains `metadata: { task_id:
task._id }`, and the filenames are `stdout` or `stderr`.


#### Config file

On startup, the DEN, DCI, and DTR read a JSON format configuration file.

##### Mandatory settings are:

* `mongohost`

  A MongoDB URI, such as `"mongodb://mongodb01.example.com:27017"`.

* `database`

  The MongoDB database to use.

##### Optional MongoDB settings are:

* `attributes`

  A hash of connection attributes for
  [MongoDB::MongoClient](https://metacpan.org/pod/MongoDB::MongoClient).
  For SSL, it will contain the key `ssl` with a value of `1` if using a public
  certificate, a value of `{"SSL_ca_file": PATH_TO_CERTIFICATE_AUTHORITY }` if
  using an internally-signed certificate, or a value of `{"SSL_verify_mode": 0}`
  if using a self-signed certificate.

* `auth`

  A hash of usernames and passwords for MongoDB authentication. It must contain
  keys of `disbatchd`, `disbatch_web`, `task_runner`, and `plugin`, with the
  values their respective passwords.

##### Additional settings that may be specified are:

* `plugins`

   An array of default allowed plugin names for queues, such as
  `"Disbatch::Plugin::Demo"`. Default is `[]`.

* `monitoring`

  Set to `true` for `GET /monitoring` to check if Disbatch node(s) are running
  and optionally QueueBalance.

* `balance`

  A hash of settings for QueueBalance. Keys are `enabled`, `log`, `verbose`,
  and `pretend`.  All values are booleans.

* `web_extensions`

  A hash of package names and options for adding new routes to the DCI.

* `task_runner`

  Path to the DTR. Future support will allow task runners for plugins in
  languages other than Perl. Default is `"/usr/bin/task_runner"`.

* `gfs`

  Set this to `false` to store `stdout` and `stderr` in the task document
  instead of using GridFS. Set this to `true` to always use GridFS. Set this to
  `"auto"` to only store `stdout` and `stderr` in GridFS if needed due to size.
  Default is `"auto"`.

* `web_root`

  The path to the html, js, and other web documents for the web interface.
  Default is `"/etc/disbatch/htdocs/"`.

* `views_dir`

  The path to the template files for the web interface.
  Default is `"/etc/disbatch/views/"`.

* `log4perl`

  A hash of [Log::Log4perl](https://metacpan.org/pod/Log::Log4perl) settings.
  The default `level` is `DEBUG`, and the default log file is
  `/var/log/disbatchd.log`. The full default is below:

        "log4perl": {
            "level": "DEBUG",
            "appenders": {
                "filelog": {
                    "type": "Log::Log4perl::Appender::File",
                    "layout": "[%p] %d %F{1} %L %C %c> %m %n",
                    "args": { "filename": "/var/log/disbatchd.log" },
                },
                "screenlog": {
                    "type": "Log::Log4perl::Appender::ScreenColoredLevels",
                    "layout": "[%p] %d %F{1} %L %C %c> %m %n",
                    "args": { },
                }
            }
        },

* `activequeues` and `ignorequeues`

   An array of queue _id string values. Default is `[]`.

   Each DEN can be configured to only monitor specific queues, or to monitor all
   but specific queues. If both are set, only `activequeues` is used.
