ZimbraManager
=============
Zimbra commandline administration with Perl and SOAP. 

This tool runs much faster than calling 'zmprov' from the command line.

Use Case
--------
If you like to manage user accounts in scripts you can call the 'zmprov'
command of Zimbra. Unfortunatly always a java environment will be started
which takes multiple seconds for a hugh amount (>10'000) of accounts.

This ZimbraManager is a Mojo Web Service which keeps a session for user
management open and allows to set run SOAP requests based on user REST
requests as input.

Usage
-----

# ZimbraManager::SOAP::Friendly;

    use ZimbraManager::SOAP::Friendly;

    my $authToken = 'VERY_LONG_TOKEN_LINE_FROM_SESSION';
    my $action = 'createAccount';
    my $args = {
        uid                => 'rplessl',
        defaultEmailDomain => 'oetiker.ch',
        givenName          => 'Roman',
        surName            => 'Plessl',
        country            => 'CH',
        displayName        => 'Roman Plessl',
        localeLang         => 'de',
        cosId              => 'ABCD-EFGH-1234',
    };
    my $namedParameters = {
        action    => $action,
        args      => $args,
        authToken => $authToken,
    };
    my ($ret, $err) = $self->soap->callFriendly($namedParameters);


Installation
------------
Build infrastructure to run the framework

    $ cd /opt
    $ git clone https://github.com/rplessl/ZimbraManager
    $ cd ZimbraManager
    $ ./setup/build-perl-modules.sh

Fetch WSDLs and XML Schemas

    $ ./bin/get-wsdl.sh zimbra.example.com

Usage
----- 

    $ ./bin/zimbra-manager.pl prefork

or 

    $ ./bin/zimbra-manager.pl daemon


Deployment
----------
### RHEL

An init.d and sysconfig configuration file is located in setup/rhel

    $ cp setup/rhel/rc.d/init.d/ZimbraManager   /etc/rc.d/init.d/
    $ chmod 755 /etc/rc.d/init.d/ZimbraManager
    $ cp setup/rhel/sysconfig/ZimbraManager     /etc/sysconfig/
    $ cp setup/rhel/logrotate.d/ZimbraManager   /etc/logrotate.d/

    $ chkconfig  --add ZimbraManager
    $ service ZimbraManager restart


LICENSE
--------
GPL 3 license (see LICENSE)

Contact info
------------
Roman Plessl <roman@plessl.info>

http://roman.plessl.info/
