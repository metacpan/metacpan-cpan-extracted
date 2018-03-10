# oxd-Perl Demo Site

This is a demo site for oxd-perl written using perl to demonstrate how to use oxd-perl to perform authorization with an OpenID Provider and fetch information.

## Deployment

### Prerequisites

1. **Client Server**

    - Perl 5
	- Apache 2.4.4 +
	- oxd-server running in the background. [Install oxd server](https://gluu.org/docs/oxd/install/)

2. **OpenID Provider**

     - An OpenID provider like Gluu Server. [Install Gluu Server](https://gluu.org/docs/ce/3.1.2/)

3. **Modules**

     - CGI::Session module
     - Net::SSLeay module
     - IO::Socket::SSL module


### Testing OpenID Connect with the demo site

#### Linux

- Install Perl on ubuntu:
```bash
$ sudo apt-get install perl
$ sudo apt-get install libapache2-mod-perl2 
```
- Create a virtual host of oxd-perl `oxd-perl.conf` 
under `/etc/apache2/sites-available/`  file and add these lines:

```bash
$ cd /etc/apache2/sites-available
$ vim oxd-perl-example.conf
```
- Add the following lines to the virtual host file:

```
<IfModule mod_ssl.c>
    <VirtualHost _default_:443>

        DocumentRoot /var/www/html/oxd-perl/example/
        ServerName www.client.example.com
        ServerAlias client.example.com

        <Directory /var/www/html/oxd-perl/example/>
                        AllowOverride All
        </Directory>

        ErrorLog /var/www/html/oxd-perl/example/logs/error.log
        CustomLog /var/www/html/oxd-perl/example/logs/access.log combined

        AddType application/x-httpd-php .php
           <Files 'xmlrpc.php'>
                   Order Allow,Deny
                   deny from all
           </Files>

        SSLEngine on
        SSLCertificateFile  /etc/certs/demosite.crt
        SSLCertificateKeyFile /etc/certs/demosite.key

                <FilesMatch "\.(cgi|shtml|phtml|php)$">
                        SSLOptions +StdEnvVars
                </FilesMatch>

                # processes .cgi and .pl as CGI scripts

                ScriptAlias /cgi-bin/ /var/www/html/oxd-perl/
                <Directory "/var/www/html/oxd-perl">
                        Options +ExecCGI
                        SSLOptions +StdEnvVars
                        AddHandler cgi-script .cgi .pl
                </Directory>

                BrowserMatch "MSIE [2-6]" \
            nokeepalive ssl-unclean-shutdown \
            downgrade-1.0 force-response-1.0
                BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown

        </VirtualHost>
</IfModule>
```

- Enable `oxd-perl-example.conf` virtual host by running:

```bash
$ sudo a2ensite oxd-perl-example.conf 
```

- Add domain name in the virtual host file:

```bash
$ sudo nano /etc/hosts
```

- In virtual host file add:
```
127.0.0.1 www.client.example.com
127.0.0.1  client.example.com
```

- Reload the Apache Server:

```bash
$ sudo service apache2 restart
```
Set up and run the demo application. Navigate to perl app root:

```bash
Copy example folder from oxdPerl directory and placed on root folder

cd /var/www/html/oxd-perl/example
```

#### Windows

- The client hostname should be a valid `hostname` (FQDN), not a localhost or an IP Address. You can configure the hostname by adding the following entry in  `C:\Windows\System32\drivers\etc\hosts` file:

    `127.0.0.1  client.example.com`
    
- Enable SSL by	adding the following lines to the virtual host file of Apache in the 
location `C:/apache/conf/extra/httpd-vhosts.conf`:

```
<VirtualHost *>
    ServerName client.example.com
    ServerAlias client.example.com
    DocumentRoot "<apache web root directory>"
</VirtualHost>

<VirtualHost *:443>
    DocumentRoot "<apache web root directory>"
    ServerName client.example.com
    SSLEngine on
    SSLCertificateFile "<Path to ssl certificate file>"
    SSLCertificateKeyFile "<Path to ssl certificate key file>"
    <Directory "<apache web root directory>">
        AllowOverride All
        Order allow,deny
        Allow from all
    </Directory>
</VirtualHost>
```

- Configure Apache to treat the project directory as a script directory. In the following location, `C:\Program Files\Apache Group\Apache\conf\httpd.conf`, set the path to `httpd.conf` 

```
ScriptAlias /cgi-bin/ "<path to CGI files>"
```

- To run CGI scripts and .pl extension anywhere in the domain, add the following line to `httpd.conf` file:

```
AddHandler cgi-script .cgi .pl
```

- In the `Directory` section of `httpd.conf` file, add the folowing CGI path:

```
<Directory "<path to CGI files>">
    AllowOverride All
    Options None
    Require all granted
</Directory>
```

- The first line of perl script contains `#!/usr/bin/perl`, replace it with the path of perl.exe `#!C:/program files/perl/bin/perl.exe` 

- Restart the Apache server.

- Copy oxdperl module from lib directory to the lib directory of the Perl installation (\perl\lib).

- With the oxd-server and Apache Server running, navigate to the URL's below to run Sample Client Application. To register a client in the oxd-server use the Setup client URL. Upon successful registration of the client application, oxd ID will be displayed in the UI. Next, navigate to the Login URL for authentication.

    - Setup Client URL: https://client.example.com:8090/cgi-bin/settings.cgi
    - Login URL: https://client.example.com:8090/cgi-bin/index.cgi
    - UMA URL: https://client.example.com:8090/cgi-bin/uma.cgi

- The input values used during Setup Client are stored in the configuration file (oxd-settings.json).