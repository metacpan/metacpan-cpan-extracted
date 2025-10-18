
# NAME

WebDyne - PSGI application for handling web requests

# SYNOPSIS

`webdyne.psgi [--option] <document_root>`

`webdyne.psgi --port 8080 /var/www/html` 

# DESCRIPTION

`webdyne.psgi` is a PSGI application script that handles web requests using the WebDyne framework. It initializes the environment, creates a new PSGI request object, determines the appropriate handler, and processes the request to generate a response.

# OPTIONS

Command line options are handled by the Plack::Runner module and are the same as described in the [plackup(1)](man:plackup(1)) man page. Refer to that page for full options but some common options are:

**--host** Which host interface to bind to

**--port** Which port to bind to

**--server** Which server to use, e.g. Starman

**--reload** Reload if libraries or other files change

**-I** Same as perl -I for library include paths

**-M** Same as perl -M for loading modules before the script starts


# EXAMPLES

To run the script, use the following command for basic functionality and serving files from the /var/www/html directory. If no specific .psp requested the file 'index.psp' will attempt to be loaded (this can be changed - see below)

`webdyne.psgi /var/www/html`

Specify an alternative default document to serve if none specified

`DOCUMENT_DEFAULT=time.psp webdyne.psgi /var/www/html`

Run a single page app. Only this page will be allowed

`webdyne.psgi /var/www/html/time.psp`

Start with the Starman server

`DOCUMENT_DEFAULT=time.psp webdyne.psgi --no-default-middleware  --server Starman /home/aspeer/public_html`

# ENVIRONMENT VARIABLES

This script is a frontend to the WebDyne::Request::PSGI module. All environment variables and configuration files from that module are applicable when running this script.

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2025 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>