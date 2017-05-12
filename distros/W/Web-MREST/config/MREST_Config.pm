# ************************************************************************* 
# Copyright (c) 2014-2015-2015, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 

# -------------------------------------------
# Web::MREST
# -------------------------------------------
#
# MREST_Config.pm
#
# WARNING: THIS FILE MAY CONTAIN PASSWORDS
# (restrictive permissions may be warranted)
# -------------------------------------------


# MREST_HOST
#    the hostname (vhost) where REST server will listen on a part
set( 'MREST_HOST', 'localhost' );

# MREST_PORT
#    the port where the REST server will listen
set( 'MREST_PORT', 5000 );

# MREST_LOG_FILE
#     full path of log file to log to (in the user's home directory)
#     If you don't want it in the user's home directory, specify an absolute
#     path.
set( 'MREST_LOG_FILE', "mrest.log" );

# MREST_LOG_FILE_RESET
#     should the logfile be deleted/wiped/unlinked/reset before each use
set( 'MREST_LOG_FILE_RESET', 1 );

# MREST_DOCUMENTATION_URI
#    used in the "help"/"default" resources
set( 'MREST_DOCUMENTATION_URI', 'https://metacpan.org/pod/Web::MREST' );

# MREST_REPORT_BUGS_TO
#    this should be an ordinary string like "bugs@dochazka.com" or
#    "http://bugs.dochazka.com"
set( 'MREST_REPORT_BUGS_TO', 'bug-App-MREST@rt.cpan.org' );

# MREST_MAX_LENGTH_URI
#    maximum length of a URI in bytes -- see Resource.pm->uri_too_long
set( 'MREST_MAX_LENGTH_URI', 1000 );

# MREST_MAX_LENGTH_REQUEST_ENTITY
#    maximum length of request entity in bytes -- see Resource.pm->malformed
set( 'MREST_MAX_LENGTH_REQUEST_ENTITY', 10000 );

# MREST_APPNAME
#    name of application (for logging) -- this can be set to any string, with
#    the proviso that it should not contain ':' characters
set( 'MREST_APPNAME', 'Web-MREST' );

# MFILE_APPLICATION_MODULE
#    the 'version' method of this module is called to get the version
#    number returned by the 'version' resource
set( 'MREST_APPLICATION_MODULE', 'Web::MREST' );

# MREST_DEBUG_MODE
#     determines whether or not debug- and trace-level messages are logged
set( 'MREST_DEBUG_MODE', 1 );

# MREST_SUPPORTED_HTTP_METHODS
#     list of supported HTTP methods returned by the 'known_methods' method
#     "HEAD" is omitted on purpose - see t/501-Not-Implemented.t
set( 'MREST_SUPPORTED_HTTP_METHODS', [ qw( GET PUT POST DELETE TRACE CONNECT OPTIONS ) ] );

# MREST_VALID_CONTENT_HEADERS
#     list of valid content headers as per RFC2616
set( 'MREST_VALID_CONTENT_HEADERS', [ qw(
    Encoding Language Length Location MD5 Range Type
) ] );

# MREST_SUPPORTED_CONTENT_TYPES
#     list of supported content types (major portions only!)
set( 'MREST_SUPPORTED_CONTENT_TYPES', [ 
    'application/json',
] );

# MREST_CACHE_ENABLED
#     set to 0 to include response headers telling clients not to cache
set( 'MREST_CACHE_ENABLED', 0 );

# MREST_CACHE_CONTROL_HEADER
#     value of 'Cache-Control' header used to disable caching
set( 'MREST_CACHE_CONTROL_HEADER', 'no-cache, no-store, must-revalidate, private' );


# -----------------------------------
# DO NOT EDIT ANYTHING BELOW THIS LINE
# -----------------------------------
use strict;
use warnings;

1;
