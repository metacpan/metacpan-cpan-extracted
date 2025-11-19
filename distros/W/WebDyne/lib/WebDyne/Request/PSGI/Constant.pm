#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2025 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#


#
#
package WebDyne::Request::PSGI::Constant;


#  Pragma
#
use strict qw(vars);
#use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT %Constant);
use vars qw($VERSION @ISA %Constant);
use warnings;


#  Version information
#
$VERSION='2.031';


#  Get module file name and path, derive name of file to store local constants
#
use Cwd qw(abs_path);
my $local_fn=abs_path(__FILE__) . '.local';


#  Hash of constants
#  <<<
%Constant=(

    
    #  Document Root, usually supplied as env var or command line option but
    #  can be set here.
    #
    DOCUMENT_ROOT	=> undef,
    
    
    #  Document default - will be served if exists in DOCUMENT_ROOT and no other
    #  file specified.
    #
    DOCUMENT_DEFAULT	=> 'app.psp',
    
    
    #  Middeware config, static module. Loaded by default for convenience if
    #  started via webdyne.psgi script directly (i.e. not invoked by plakup
    #  or starman). Activate in middleware section below if wanted with plackup
    #  or starman
    #
    #  Serve any static file except .psp
    #
    #WEBDYNE_PLACK_MIDDLEWARE_STATIC => qr{^(?!.*\.psp$).*\.\w+$},
    #
    #  Just common files
    #
    WEBDYNE_PLACK_MIDDLEWARE_STATIC => qr{\.(?:css|js|jpg|jpeg|png|gif|svg|ico|woff2?|ttf|eot|otf|webp|map|txt|inc|htm|html)$}i,
    
    
    #  All other middleware. Uncomment/modify as required
    #
    WEBDYNE_PLACK_MIDDLEWARE_AR => [
        
        #{ 'Debug' => 
        #    { panels => [ qw(Environment) ] } 
        #},
        
        #  If given as a sub code ref the $DOCUMENT_ROOT is first param 
        #
        #{ 'Static' => sub { 
        #    { path=>qr{^(?!.*\.psp$).*\.\w+$}, root=>shift() }
        #}}
        
    ],
    
    
    #  Dir Config
    #
    WEBDYNE_PSGI_DIR_CONFIG => undef,
    
    
    #  Warn on error ?
    #
    WEBDYNE_PSGI_WARN_ON_ERROR => undef,


);
# >>>


sub import {
    
    goto &WebDyne::Constant::import;
    
}


#  Export constants to namespace, place in export tags
#
require WebDyne::Constant;
@ISA=qw(WebDyne::Constant);


#  All done
#
1;
#===================================================================================================
