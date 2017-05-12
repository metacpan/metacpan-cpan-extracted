#
# Web::DataService::Plugin::Dancer.pm
# 
# This plugin provides Web::DataService with the ability to use Dancer.pm as
# its "foundation framework".  Web::DataService uses the foundation framework
# to parse HTTP requests, to marshall and send back HTTP responses, and to
# provide configuration information for the data service.
# 
# Other plugins will eventually be developed to fill this same role using
# Mojolicious and other frameworks.
# 
# Author: Michael McClennen <mmcclenn@cpan.org>


use strict;

package Web::DataService::Plugin::Dancer;

use Carp qw( carp croak );


sub initialize_plugin {
    
    Dancer::set(warnings => 0);
    #Dancer::set(app_handles_errors => 1);
}


# The following methods are called with the parameters specified: $ds is a
# reference to a data service instance, $request is a reference to the request
# instance defined by Web::DataService.  If a request object was defined by
# the foundation framework, it will be available as $request->{outer}.  The
# data service instance is also available as $request->{ds}.

# ============================================================================

# read_config ( ds, name, param )
# 
# This method returns configuration information from the application
# configuration file used by the foundation framework.  If $param is given,
# then return the value of that configuration parameter (if any).  This value
# is looked up first under the configuration group $name (if given), and if not
# found is then looked up directly.
# 
# If $param is not given, then return the configuration group $name if that
# was given, or else a hash of the entire set of configuration parameters.

sub read_config {
    
    my ($class, $ds) = @_;
    
    my $config_hash = Dancer::config;
    $ds->{_config} = $config_hash;
}


# store_request ( outer, inner )
# 
# Add to the specified "outer" request object a link to our "inner" request
# object.

sub store_inner {
    
    my ($plugin, $outer, $inner) = @_;
    
    Dancer::var('wds_request', $inner);
}


# retrieve_request ( outer )
# 
# Return the "inner" link from the specified request object.

sub retrieve_inner {

    my ($plugin, $outer) = @_;
    
    return Dancer::var('wds_request');
}


# store_outer ( outer )
# 
# Store the current 'outer' request object for later use.  This is a no-op for
# Dancer, since the current 'outer' request object is always available.

sub store_outer {

}


# retrieve_outer ( )
# 
# Return the 'outer' request object for the request being currently handled.

sub retrieve_outer {
    
    return Dancer::request;
}


# get_connection ( )
# 
# This method returns a database connection.  If you wish to use it, make sure
# that you "use Dancer::Plugin::Database" in your main program.

sub get_connection {
    
    return Dancer::Plugin::Database::database();
}


# get_base_url ( )
# 
# Return the base URL for the data service.

sub get_base_url {
    
    return Dancer::request->base;
}


# get_request_url ( request )
# 
# Return the full URL that generated the current request

sub get_request_url {
    
    return Dancer::request->uri;
}


# get_request_path ( request )
# 
# Return the request path

sub get_request_path {

    return Dancer::request->path;
}


# get_params ( request )
# 
# Return the parameters for the current request.

sub get_params {
    
    my ($plugin, $request, @rest) = @_;
    
    my $params = Dancer::params(@rest);
    delete $params->{splat};
    return $params;
}


# get_param ( param )
# 
# Return the specified raw parameter value for the current request.

sub get_param {
    
    my ($plugin, $request, $param) = @_;
    
    return Dancer::params->{$param};
}


# set_cors_header ( request, arg )
# 
# Set the CORS access control header according to the argument.

sub set_cors_header {

    my ($plugin, $request, $arg) = @_;
    
    if ( defined $arg && $arg eq '*' )
    {
	Dancer::header "Access-Control-Allow-Origin" => "*";
    }
}


# set_content_type ( outer, type )
# 
# Set the response content type.

sub set_content_type {
    
    my ($plugin, $request, $type) = @_;
    
    Dancer::content_type $type;
}


# set_header ( outer, header, value )
# 
# Set an arbitrary header in the response.

sub set_header {
    
    my ($plugin, $request, $header, $value) = @_;
    
    Dancer::header $header => $value;
}


# set_status ( outer, status )
# 
# Set the response status code.

sub set_status {
    
    my ($class, $request, $code) = @_;
    
    Dancer::status $code;
}


# set_body ( outer, body )
# 
# Set the response body.

sub set_body {
    
    my ($class, $request, $body) = @_;
    
    Dancer::SharedData->response->content($body);
}

	
# file_path ( @components )
# 
# Concatenate the specified file paths together, in a file-system-independent
# manner. 

sub file_path {

    shift;
    return Dancer::path(@_);
}


# file_readable ( filename )
# 
# Return true if the specified file exists and is readable, false otherwise.

sub file_readable {
    
    my $file_name = Dancer::path(Dancer::setting('public'), $_[1]);
    return -r $file_name;
}


# file_exists ( filename )
# 
# Return true if the specified file exists, false otherwise.

sub file_exists {

    my $file_name = Dancer::path(Dancer::setting('public'), $_[1]);
    return -e $file_name;
}


# send_file ( outer, filename )
# 
# Send as the response the contents of the specified file.  For Dancer, the path
# is always evaluated relative to the 'public' directory.

sub send_file {
    
    return Dancer::send_file($_[2]);
}


1;
