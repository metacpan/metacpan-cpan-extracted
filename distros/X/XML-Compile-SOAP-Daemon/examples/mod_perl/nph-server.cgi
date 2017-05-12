#!/usr/bin/perl

#### See README

# XXX package MyServer;
# XXX 
# XXX use Exporter;
# XXX @ISA = qw(Exporter);
# XXX @EXPORT_OK = qw( $daemon );

use warnings;
use strict;
use CGI;

use lib "/usr/local/www/SOAP";
my $schemas = "/usr/local/www/SOAP";

# constants, change this if needed (also in the client script?)

use constant ERROR_NS   => 'http://namesservice.thomas_bayer.com/error';

# This could come from a database...
use MyExampleData  qw/$namedb/;

# This module defines my additional (non-WSDL) calls
use MyExampleCalls;

# All the other XML modules should be automatically included.
use XML::Compile::SOAP::Daemon::CGI;
use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::Util    qw/pack_type/;

# The client and server scripts can be translated easily, using the
# 'example' translation table name-space. trace/info/error come from
# the LogReport error dispatch infra-structure.

# Other useful modules
use Getopt::Long  qw/:config no_ignore_case bundling/;
use List::Util    qw/first/;

use Data::Dumper;          # Data::Dumper is your friend.
$Data::Dumper::Indent = 1;

# Forward declarations allow prototype checking
sub get_countries($$);
sub get_name_info($$);
sub get_names_in_country($$);
sub get_name_count($$);
sub create_get_name_count($);

##
#### MAIN
##

#
# start with this set to DEBUG, then change it later

my $mode = 'DEBUG';

#
# XML::Compile::* uses Log::Report.  The 'default' dispatcher for error
# messages is here changed from PERL (die/warn) into using syslog.
#

use Log::Report 'example';
dispatcher FILE => 'log', mode => $mode, to => '/tmp/soap';

#
# Create the daemon set-up
#

our $daemon = XML::Compile::SOAP::Daemon::CGI->new;
my $wsdl = XML::Compile::WSDL11->new("$schemas/namesservice.wsdl");
$wsdl->importDefinitions("$schemas/namesservice.xsd");

# The error namespace I use in this example is not defined in the
# wsdl neither the xsd, so have to add it explicitly.
$wsdl->prefixes(err => ERROR_NS);

# enforce the error name-space declaration to be available in all
# returned messages: at compile-time, it is not known that it may
# be used... but XML::Compile handles namespaces statically.
$wsdl->prefixFor(ERROR_NS);

# This will give you some understanding about what is defined.
#$wsdl->schemas->namespaces->printIndex;

# If you have a WSDL, then most of the infrastructure is auto-generated.
# The only thing you have to do, is provide call-back code references
# for each of the portNames in the WSDL.
my %callbacks =
  ( getCountries       => \&get_countries
  , getNamesInCountry  => \&get_names_in_country
  , getNameInfo        => \&get_name_info
  );

$daemon->operationsFromWSDL
  ( $wsdl
  , callbacks => \%callbacks
  );

# Add a handler which is not defined in a WSDL
create_get_name_count $daemon;

##########
########## NPH START
########## 

my $query = CGI->new;
$daemon->runCgiRequest( query => $query);;
exit 0;

##########
########## NPH END
##########
### 
###    nph-server2.cgi START
### 
###    #!/usr/bin/perl
###    use lib '/usr/local/www/SOAP';
###    use Log::Report   'example', syntax => 'SHORT';
###    use CGI;
###    use MyServer qw( $daemon );
###    my $mode = 'DEBUG';
###    dispatcher FILE => 'log', mode => $mode, to => "/tmp/soap";
###    my $query = CGI->new;
###    $daemon->runCgiRequest( query => $query );
###    exit 0;
### 
###    nph-server2.cgi END
### 
##
### Server-side implementations of the operations
##

#
# First example, no incoming data
#

sub get_countries($$)
{   my ($server, $in) = @_;

    # We do not have to look at the incoming data ($in) in this case,
    # because this message doesn't provide any.

    # The output structure needs all names of header and body message
    # parts, as defined in the WSDL.  This message only contains a
    # message part named 'parameters'.

    my %parameters; # 'getCountriesResponse' element, see *xsd
    my @countries = sort keys %$namedb;
    $parameters{country} = \@countries;
    # You can use XML::Compile::Schema::template(PERL) to figure-out what
    # the getCountryResponse element structure looks like.

    { parameters => \%parameters } 
}

#
# Second example, with decoding of incoming data
#

sub find_name($$)
{   my $name  = lc shift;
    my $names = shift || [];
    (first {lc($_) eq $name} @$names) ? 1 : undef;
}

sub get_name_info($$)
{   my ($server, $in) = @_;

    # debugging daemons is not easy, but you could do things like:
    #      (debug mode is enabled by Log::Report dispatchers with
    #       -vvv on the [server] command-line)
    trace join '', 'get_name_info', Dumper $in;

    # In the message description, the getNameInfo message has only
    # one part, named `parameters'.  Its structure is an optional
    # name string.
    my $name = $in->{parameters}{name} || '';

    # It is probably easier for your regression testing to put more
    # complex data processing in seperate files; not in the server
    # file.
    my ($males, $females, @countries) = (0, 0);
    foreach my $country (sort keys %$namedb)
    {   my $male   = find_name $name, $namedb->{$country}{  male};
        my $female = find_name $name, $namedb->{$country}{female};
        $male or $female or next;

        $males    = 1 if $male;
        $females  = 1 if $female;
        push @countries, $country;
    }

    my $gender
      = $males && $females ? 'either'
      : $males             ? 'male'
      : $females           ? 'female'
      :                      undef;

    # The output message is constructed, which has one body element, named
    # 'parameters'.  It's structure is one optional 'nameinfo' element
    my %country_list = (country => \@countries);
    my %nameinfo =
      ( name => $name, countries => \%country_list
      , gender => $gender, male => $males, female => $females
      );

    my %parameters = (nameinfo => \%nameinfo);
    { parameters => \%parameters };

    # if you are not afraid for references, you simply write
    # { parameters =>
    #    { nameinfo =>
    #      { name => $name, countries => {country => \@countries}
    #      , gender => $gender, male => $males, female => $females }}}
    # Perl looks like Lisp, sometimes ;-)
}

##
### The third example
##

sub get_names_in_country($$)
{   my ($server, $in) = @_;

    # this should look quite familiar now... a bit more compact!
    my $country = $in->{parameters}{country} || '';
    my $data    = $namedb->{$country};

    $data or return
     +{ Fault =>
         { faultcode   => pack_type(ERROR_NS, 'UnknownCountry')
         , faultstring => "No information about country '$country'"
         }

      # The next two are put in the header of HTTP responses. Can
      # also be used in valid responses. Defaults to RC_OK.
      , _RETURN_CODE => 404  # use HTTP codes
      , _RETURN_TEXT => 'Country not found'
      };
    
    my @names   = sort @{$data->{male} || []}, @{$data->{female} || []};
    { parameters => { name => \@names } };
}

#
# The last example shows how to add your own non-WSDL calls
# You have to visit each of the levels of the procedure yourself:
#  1 collect the schemas you need
#  2 specify the protocol details
#  3 defined the incoming and outgoing message explicitly.
#    (see the client.pl, which requires exactly the same info)
#  4 define how to recognize the message
#  5 add the procedure to the knowledge of the server
# Steps 1 and 2 can be shared of all procedures you add manually.

sub create_get_name_count($)
{   my $daemon = shift;

    ##### BEGIN only once per script
    # I want to base my own methods on the WSDL definitions
    $wsdl->importDefinitions(\@my_additional_schemas);
    my $soap11 = XML::Compile::SOAP11::Server->new(schemas => $wsdl);

    # You could also do
    # my $soap11 = XML::Compile::SOAP11::Server->new;
    # $soap11->importDefinitions($_) for @my_additional_schemas;
    ##### END only once per script

    ##### BEGIN usually in initiation phase of the daemon
    # For each of the messages you want to be able to handle, you need to
    # implement this block, run before the daemon starts.

    # The 'input' and 'output' roles are the reversed in the client.
    my $decode = $soap11->compileMessage(RECEIVER => @get_name_count_input);
    my $encode = $soap11->compileMessage(SENDER   => @get_name_count_output);
    ##### END in initiation phase of daemon

    # How do we know that this message is the one arriving?  The selector
    # CODE ref is called with the XML::LibXML::Document which has arrived
    # and must return true when it feels addressed.
    # The ::compileFilter() implementation is quite thorough, because it
    # needs to understand messages from the WSDL which look much alike.
    # You may implement something else.
    # So, either
    #   my $selector = $soap11->compileFilter(@get_name_count_input);
    # or
    my $selector = sub
      { my ($xml, $info) = @_;
        @{$info->{body}} && $info->{body}[0] =~ m/\}getNameCount$/;
      };

    # The handler is the client-side plug, default produces an error reply
    my $handler = $soap11->compileHandler
      ( name       => 'getNameCount'
      , selector   => $selector       # important!
      , decode     => $decode
      , encode     => $encode
      , callback   => \&get_name_count
      );

    $daemon->addHandler('getNameCount', $soap11, $handler);
}

sub get_name_count($$)
{   my ($server, $in) = @_;

    # Althought the message is not specified in a WSDL, the handler is
    # still the same.
    my $count   = 0;
    if(my $country = $in->{request}{country})
    {   my $data = $namedb->{$country} || {};
        $count = @{$data->{male} || []} + @{$data->{female} || []};
    }

    {answer => {count => $count}};
}

1;
