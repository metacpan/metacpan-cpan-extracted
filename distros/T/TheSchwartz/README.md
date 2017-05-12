TheSchwartz
=============

**TheSchwartz** is a reliable job queue system. Your application can put jobs into the system, and your worker processes can pull jobs from the queue atomically to perform. Failed jobs can be left in the queue to retry later.

**Abilities** specify what jobs a worker process can perform. Abilities are the names of *TheSchwartz::Worker* subclasses, as in the synopsis: the *MyWorker* class name is used to specify that the worker script can perform the job. When using the *TheSchwartz* client's *work* functions, the class-ability duality is used to automatically dispatch to the proper class to do the actual work.

TheSchwartz clients will also prefer to do jobs for unused abilities before reusing a particular ability, to avoid exhausting the supply of one kind of job while jobs of other types stack up.

Some jobs with high set-up times can be performed more efficiently if a group of related jobs are performed together. TheSchwartz offers a facility to **coalesce** jobs into groups, which a properly constructed worker can find and perform at once. For example, if your worker were delivering email, you might store the domain name from the recipient's address as the coalescing value. The worker that grabs that job could then batch deliver all the mail for that domain once it connects to that domain's mail server.

INSTALLATION
------------

Just follow the usual procedure:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

If you want to install a private copy of this module-suite in your home directory, then you should try to produce the initial Makefile with something like this command:

    perl Build.PL PREFIX=~/perl

See perldoc perlmodinstall for more information on installing modules.

SUPPORT
-------

Just follow the usual procedure:

    perl Build.PL
    ./Build

Questions, bug reports, useful code bits, and suggestions for this module should just be sent to JFEARN@cpan.org or open a ticket in the [CPAN RT](https://rt.cpan.org//Dist/Display.html?Queue=TheSchwartz)

AVAILABILITY
-------
The latest version of this module is available from the Comprehensive Perl Archive Network (CPAN).  Visit (http://www.perl.com/CPAN/) to find a CPAN site near you.

The source is available on github (https://github.com/jfearn/TheSchwartz), patches should be sent as pull requests against this repository.

