### QueueBalance

Copyright (c) 2019 by Ashley Willis.

QueueBalance automatically maintains a maximum number of threads across queues
depending on the time of day and day of week.

A set of queues can have the same priority, and other queues can have other
priorities.

This is useful to maintain load across multiple queues, but have priority
queues for the occasional tasks which must be ran ASAP.  You can also have
different max threads depending on the time of day and day of week.

To enable, set `balance.enabled` to `true` in the config file.

Start it with the following, which will initialize the needed collection and
every 30 seconds make changes to threads per queue if needed.

    sudo etc/init.d/queuebalanced start

The web interface is at `/balance` (default: `http://localhost:8080/balance`).

It hopefully is self-explanatory. Any errors should appear in red.
The `test` button will show you the JSON to be submitted to make the change.

Example intervals to have 5 threads during weekdays, 10 during weeknights, and
15 during weekends:

    DOW    HH:MM    max
    Daily  07:00    5
    Daily  19:00    10
    Mon    07:00    5
    Fri    19:00    15

Which would be sent as the following:

    "max_tasks": {
      "* 07:00": "5",
      "* 19:00": "10",
      "1 07:00": "5",
      "5 19:00": "15"
    },

Note that a specific day at a set time will overwrite the Daily (`*`) value at
the same time, but otherwise will not.

You can also use `GET /balance` and `POST /balance` as API calls.

The running status of QueueBalance can be monitored via `GET /monitoring`.

