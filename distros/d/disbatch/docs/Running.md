### Running Disbatch 4

Copyright (c) 2016, 2019 by Ashley Willis.

* [Configure](Configuring.md) Disbatch before running

* Start, stop, restart

  * On each server you want Disbatch running:

            /etc/init.d/disbatchd [start|stop|restart]

  * On each server you want the Disbatch Command Interface running:

            /etc/init.d/disbatch-webd [start|stop|restart]

    This can run on the same servers as `disbatchd`, or on completely different
    ones.

* Web interface, by default listening on 127.0.0.1:8080

  * Create a new queue by clicking on `New Queue`, entering a `Name`, selecting
    a `Type` from the drop-down menu, and clicking `Create`.

  * Modify an existing queue by clicking on its `Type`, `Name`, or `Threads`.
    `Threads` is the number of concurrent tasks to run from this queue **per
    DEN**. You cannot delete a queue from the web interface.

  * To limit the total number of concurrent tasks to run per DEN, set `Max
    Threads` for that DEN in the `Disbatch Execution Nodes` table. This will
    take precedence over any queue `Threads` settings. To disable a DEN's `Max
    Threads` value, delete the value from the table. If you set it to `0`, no
    threads will run.

  * You can refresh the tables at any time by clicking on `Refresh`. They also
    refresh automatically every 60 seconds, and after any changes via the web
    interface.

* QueueBalance

  * See [QueueBalance](docs/QueueBalance.md) on how to use the tool for
    automatically maintaining a maximum number of threads across queues depending
    on the time of day and day of week.

* Monitoring

  * Disbatch now has a `GET /monitoring` endpoint as part of the web interface to
    check the status of Disbatch and QueueBalance. See `perldoc Disbatch::Web`
    for a full description.

* CLI

  * With `disbatch.pl`, you can list queues, create queues, modify max threads
    of queues, create a single task in a queue, create many tasks in a queue
    based off a filter from another collection, search for tasks in a queue, and
    list queue plugin types available.

  * For a full description, run `perldoc disbatch.pl`

  * If the Disbatch Command Interface is not running on `http://localhost:8080`,
    pass the URL with the `--url` option.
