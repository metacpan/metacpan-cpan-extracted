disbatch
========
a scalable distributed batch processing framework


Disbatch 4.2 is a scalable distributed batch processing framework using MongoDB.
It runs on one-to-many Disbatch Execution Nodes (DEN), where each DEN handles
hundreds to thousands of concurrent tasks for one or more plugins.
Disbatch 4.2 can be updated and restarted as needed to deploy changes without
interrupting currently running tasks.

Each DEN starts independent tasks using the specified plugin, and a separate
process provides the Disbatch Command Interface (DCI) for the JSON REST API and
web browser interface.

This is almost a complete rewrite of Disbatch 3, written by Matt Busigin.

For an in-depth description of the design, see
[Design](docs/Design.md).


#### Installing

* From CPAN (not yet published):

        cpanm Disbatch

* From Git:

        git clone https://github.com/mbusigin/disbatch.git
        cd disbatch
        dzil build
        cpanm disbatch-<VERSION>.tar.gz


#### Configuring Disbatch 4.2

See [Configuring](docs/Configuring.md)


#### Creating task plugins

See [Plugins](docs/Plugins.md)


#### Creating web extension plugins

See [WebExtensions](docs/WebExtensions.md)


#### Running Disbatch 4.2

See [Running](docs/Running.md)


#### Running QueueBalance

See [QueueBalance](docs/QueueBalance.md)


#### Changes from Disbatch 4.0 and Disbatch 3

See [Differences](docs/Differences.md)


#### Upgrading from Disbatch 4.0 and Disbatch 3

See [Upgrading](docs/Upgrading.md)


#### Configuring and Using Authentication with MongoDB

See [Authentication_MongoDB](docs/Authentication_MongoDB.md)


#### Configuring and Using SSL with MongoDB

See [SSL_MongoDB](docs/SSL_MongoDB.md)


#### Configuring and Using SSL with the Disbatch Command Interface

See [SSL_DCI](docs/SSL_DCI.md)


#### Authors

Ashley Willis (<awillis@synacor.com>)

Matt Busigin (<mbusigin@hovernetworks.com>)


#### Copyright and License

This software is Copyright (c) 2016, 2019 by Ashley Willis.

This is free software, licensed under:

> The Apache License, Version 2.0, January 2004

Some web browser code in `etc/disbatch/htdocs/` includes third-party libraries copyright others and licensed under their own terms.
See [THIRD-PARTY-LIBS](THIRD-PARTY-LIBS).
