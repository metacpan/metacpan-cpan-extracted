{

=head1 NAME

WebService::weblogUpdates - methods supported by the UserLand weblogUpdates framework.

=head1 SUMMARY

 use WebService::weblogUpdates;

 my $weblogs = WebService::weblogUpdates->new(transport=>"SOAP",debug=>0);
 $weblogs->ping("Perlblog","http://www.nospum.net/perlblog");

 # Since the 'rssUpdate' method has only been 
 # documented for the XML-RPC transport, we switch
 # the internal widget.

 $weblogs->Transport("XMLRPC");
 $weblogs->rssUpdate("Aaronland","http://www.aaronland.net/weblog/rss");

=head1 DESCRIPTION

This package implements methods supported by the UserLand weblogUpdates framework, 
for the weblogs.com website.

=head1 ON NAMING THINGS

This package was originally named to reflect the class that the original I<ping>
method lives in, weblogUpdates.

Since then, other methods have been added that live in different classes or don't
have any parent class at all. I have no idea why, especially since the equivalent
serTalk methods live in a 'weblogUpdates' class themselves. [1]

So it goes.

=cut

use strict;
package WebService::weblogUpdates;

$WebService::weblogUpdates::VERSION = '0.35';

use Carp;

use constant HOST    => "http://rpc.weblogs.com";
use constant RSSHOST => "http://rssrpc.weblogs.com";

use constant PATH  => "/RPC2";
use constant CLASS => "weblogUpdates";

use constant PING      => "ping";
use constant RSSUPDATE => "rssUpdate";

=head1 PACKAGE METHODS

=head2 $pkg = __PACKAGE__->new(%args)

Valid arguments are

=over 4

=item *

B<transport>

String. Valid transports are SOAP and XMLRPC and REST. I<required>

=item *

B<debug>

Boolean. Enable transport-specific debugging.

=back

=cut

sub new {
    my $pkg = shift;
    
    my $self = {};
    bless $self;

    $self->init(@_) || return undef;
    return $self;
}

sub init {
    my $self = shift;
    my $args = { @_ };

    if (! $args->{'transport'}) {
	carp "You must specify a transport.";
	return 0;
    }

    $self->Transport($args->{'transport'},debug=>$args->{'debug'}) 
	|| return 0;

    return 1;
}

=head1 OBJECT METHODS

=head2 $pkg->ping(\%args)

Ping the Userland servers and tell them your weblog has been updated.

Valid arguments are a hash reference whose keys are :

=over 4

=item *

B<name> 

String. The name of your weblog. I<required>

=item *

B<url> 

String. The URI of your weblog. I<required>

=item *

B<changesurl>

String.

This key may be specified if 

=over 4

=item *

The object's transport is REST and the site in question "need two urls, one that we can verify changes for, and the other to be included in changes.xml."

=item *

You are passing a I<category> key with your ping. In fact, it's required if you're doing that.

=back

=item *

B<category>

String.

Categories are not supported if the object's transport is REST.

=back

Returns true or false. This means that, unlike the Userland server itself, a successful ping returns 1 and a failed ping returns 0.

=cut

sub ping {
    my $self = shift;
    my $args = shift;

    delete $self->{'_message'};

    #

    if ((! $args->{name}) || (! $args->{url})) {
	carp "You must specify both a weblog name and url";
	return 0;
    }

    my $meth = undef;
    my @args = ();

    if ($self->{'__ima'} eq "Frontier::Client") {

      $meth = join(".",CLASS,PING);
      @args = (
	       $self->_client()->string($args->{name}),
	       $self->_client()->string($args->{url}),
	      );
      
      #
      
      if (($args->{changesurl}) && ($args->{category})) {
	push (@args,
	      $self->_client()->string($args->{changesurl}),
	      $self->_client()->string($args->{category}));
      }
    }
    
    elsif ($self->{'__ima'} eq "XMLRPC::Lite") {
	$meth = join(".",CLASS,PING);
	@args = (
		 SOAP::Data->type(string=>$args->{name}),
		 SOAP::Data->type(string=>$args->{url}),
		 );

	if (($args->{changesurl}) && ($args->{category})) {
	  push (@args,
		SOAP::Data->type(string=>$args->{changesurl}),
		SOAP::Data->name(string=>$args->{category}));
	}

   }

    elsif ($self->{'__ima'} eq "SOAP::Lite") {
	$meth = PING;
	@args = (
		 SOAP::Data->name(weblogname=>$args->{name}),
		 SOAP::Data->name(weblogurl=>$args->{url}),
		 );

	if (($args->{changesurl}) && ($args->{category})) {
	  push (@args,
		SOAP::Data->name(changesurl=>$args->{changesurl}),
		SOAP::Data->name(categoryname=>$args->{category}));
	}

    }

    elsif ($self->{'__ima'} eq "LWP::Simple") {
      $meth = PING;
      @args = ($args);
    }

    if (! $meth) {
	carp "Unable to determine transport and method.";
	return 0;
    }

    my $res = $self->_do($meth,@args)
	|| &{ carp "Returned undef. Not good."; return 0; };

    $self->{'_message'} = $res->{message};
    (! $res->{'flerror'}) ? return 1 : return 0;
}

=head2 $pkg->rssUpdate(\%args)

Ping the Userland servers and tell them your RSS feed has been updated.

Valid arguments are a hash reference whose keys are :

=over 4

=item *

B<name> 

String. The name of your weblog. I<required>

=item *

B<url> 

String. The URI of your weblog. I<required>

=back

This method is B<not> supported for the SOAP transport, although 
it will be as soon as it is documented by UserLand.

This method is B<not> supported for the REST transport.

=cut

sub rssUpdate {
  my $self = shift;
  my $args = shift;

  delete $self->{'_message'};

  #
  
  if ((! $args->{name}) || (! $args->{url})) {
    carp "You must specify both a weblog name and url";
    return 0;
  }
  
  my $meth = undef;
  my @args = ();
  
  if ($self->{'__ima'} eq "Frontier::Client") {

    # grrrrr....
    $self->_client()->{'url'} = RSSHOST.PATH;
    $self->_client()->{'rq'}->url(RSSHOST.PATH);

    $meth = join(".",RSSUPDATE);
    @args = (
	     $self->_client()->string($args->{name}),
	     $self->_client()->string($args->{url}),
	    );
  }
  
  elsif ($self->{'__ima'} eq "XMLRPC::Lite") {

    $self->_client()->proxy(RSSHOST.PATH);
    $meth = join(".",RSSUPDATE);
    @args = (
	     SOAP::Data->type(string=>$args->{name}),
	     SOAP::Data->type(string=>$args->{url}),
	    );
  }
  
  elsif ($self->{'__ima'} eq "SOAP::Lite") {
    carp "This method will be supported as soon as it is documented by UserLand.\n";
    return 0;
    #      $meth = RSSUPDATE;
    #      @args = (
    #	       SOAP::Data->name(weblogname=>$args->{name}),
    #	       SOAP::Data->name(weblogurl=>$args->{url}),
    #	      );
  }
  
  elsif ($self->{'__ima'} eq "LWP::Simple") {
    carp "This method is not supported for the REST transport.\n";
    return 0;
  }
  
  if (! $meth) {
    carp "Unable to determine transport and method.";
    return 0;
  }
  
  my $res = $self->_do($meth,@args)
    || &{ carp "Returned undef. Not good."; return 0; };
  
  $self->{'_message'} = $res->{message};
  (! $res->{'flerror'}) ? return 1 : return 0;
}

=head2 $pkg->LastMessage()

Return the response message that was sent with your last method call.

=cut

sub LastMessage {
  my $self = shift;
  (exists($self->{'_message'})) ? return $self->{'_message'} : return undef;
}

=head2 $pkg->Transport($transport,%args)

Set the transport for use with the package. Valid transports are SOAP, XMLRPC and REST. This field is required.

Valid arguments are 

=over 4

=item *

B<debug>

Boolean. Enable transport-specific debugging.

=back

=cut

sub Transport {
  my $self      = shift;
  my $transport = shift;
  my $args      = { @_ };
  
  if (defined $transport) {
    
    if (! $transport =~ /^(xmlrpc|soap|rest)$/i) {
      delete $self->{"_transport"};
      return undef;
    }
    
    $self->{"_transport"} = lc $transport;
    
    if (! $self->_client(debug=>$args->{'debug'})) {
      delete $self->{"_transport"};
      return undef;
    }
  }
  
  return $self->{"_transport"};
}

=head1 DEPRECATED METHODS

=head2 $pkg->ping_message()

B<DEPRECATED> Please use $pkg->LastMessage() instead.

=cut

sub ping_message {
  my $self = shift;
  return $self->LastMessage();
}

# Private methods

sub _do {
    my $self = shift;
    my $meth = shift;
    my @args = @_;

    if ($self->{'__ima'} eq "Frontier::Client") {
      my $res = undef;

      eval { $res = $self->_client()->call($meth,@args); };

      if ($@) {
	carp $@;
	return 0;
      }
      
      # Hack.
      if ($res->{'flerror'}) {
	$res->{'flerror'} = $res->{'flerror'}->value();
      }

      return $res;
    }

    # We don't bother wrapping this in an eval block
    # since we've already set a fault method for the 
    # SOAP::Lite object.

    elsif ($self->{'__ima'} =~ /^(SOAP|XMLRPC)::Lite$/){
	return $self->_client()->call($meth,@args)->result();
    }

    elsif ($self->{'__ima'} eq "LWP::Simple") {
      return $self->_client()->call($meth,@args);
    }

    else {
      return {flerror=>1,message=>"unknown transport"};
    }
}

sub _client {
    my $self   = shift;
    my $client = "_".$self->Transport();
    return $self->$client(@_);
}

sub _xmlrpc {
  my $self = shift;
  my $args = { @_ };
  
  if (! $self->{"_xmlrpc"}) {
    
    if (&_require("Frontier::Client")) {
      $self->{"_xmlrpc"} = Frontier::Client->new(url=>HOST.PATH,debug=>$args->{'debug'})
	|| &{ carp $!; return 0; };
    }
    
    elsif (&_require("XMLRPC::Lite")) {
      my $xmlrpc = XMLRPC::Lite->new()
	|| &{ carp $!; return 0; };

      &_setup_soaplite($xmlrpc,$args);

      #

      $xmlrpc->proxy(HOST.PATH);
      $self->{"_xmlrpc"} = $xmlrpc; 
    }
    
    else {
      return 0;
    }

    $self->{'__ima'} = ref($self->{"_xmlrpc"});
  }

  return $self->{"_xmlrpc"};
}

sub _soap {
  my $self = shift;
  my $args = { @_ };
  
  if (! $self->{"_soap"}) {
    
    my $class = "SOAP::Lite";
    &_require($class) || return 0;
    
    if ($SOAP::Lite::VERSION < 0.55) {
      carp 
	"SOAP::Lite version is $SOAP::Lite::VERSION\n".
	  "Please upgrade to version 0.55 or higher.\n";
    }
    
    carp 
      my $soap = $class->new() ||
	&{ carp $!; return 0; };
    
    &_setup_soaplite($soap,$args);
    
    #
    
    $soap->proxy(join("/",HOST,CLASS));
    
    $soap->on_action(
		     sub{ 
		       "\"/".CLASS."\"" 
		     }
		    );
    
    $self->{"_soap"} = $soap;
    $self->{'__ima'} = ref($self->{"_soap"});
  }
  
  return $self->{"_soap"};
}

sub _setup_soaplite {
  my $lite = shift;
  my $args = shift;

  # What if it doesn't work?
  $lite->on_fault(
		  sub{ 
		    my ($lite,$res) = @_; 
		    carp (ref $res) ? $res->faultstring : $lite->transport->status(); 
		    return 0; 
		  }
		 );
  
  # Who's on first?
  if ($args->{'debug'}) {
    $lite->on_debug(sub { print @_; });
  }
}

sub _rest {
  my $self = shift;
  my $class = "LWP::Simple";
  &_require($class) || return 0;

  $self->{'__ima'} = $class;
  return "REST";
}

sub _require {
    my $class = shift;
    
    eval "require $class" ||
	&{ carp $@; return 0; };
    
    return 1;
}

sub DESTROY {
    return 1;
}

package REST;
use constant PINGSITEFORM        => "http://newhome.weblogs.com/pingSiteForm";
use constant PINGSITEFORMTWOURLS => "http://newhome.weblogs.com/pingSiteFormTwoUrls";

my $html_parser = undef;

sub call {
  my $pkg  = shift;
  my $meth = shift;
  my $args = shift;

  my $ping = undef;

  if ($args->{changesurl}) {
    $ping = PINGSITEFORMTWOURLS."?name=$args->{name}&url=$args->{url}&changesUrl=$args->{changesurl}";
  }

  else {
    $ping = PINGSITEFORM."?name=$args->{name}&url=$args->{url}";
  }

  #

  my $html = LWP::Simple::get($ping);

  if (! $html) {
    return {flerror=>1,message=>"Failed to ping: ".LWP::Simple::getprint($ping)};
  }

  #

  eval "require HTML::Parser";

  if ($@) {
    return {flerror=>0,message=>"Failed to parse HTML, $@"};
  }

  #

  if (! $html_parser) {
    $html_parser = HTML::Parser->new(
				     start_h       => [\&start_element, "self,tagname, attr"],
				     text_h        => [\&characters,    "self,text"],
				    );
    $html_parser->unbroken_text(1);
  }

  $html_parser->parse($html);

  return {flerror=>0,message=>$html_parser->{__message}};
}

#

sub start_element {
  my $parser = shift;
  my $tag  = shift;

  if ($tag eq "html") {
    $parser->{'__ok'}      = 0;
    $parser->{'__message'} = undef;
  }
}

sub characters {
  my $parser = shift;
  my $chars = shift;

  return if (! $chars);

  $chars =~ s/^\s+//;
  $chars =~ s/\s+$//;
  return if (! $chars);

  # Ugh.

  if ($chars eq "Enter the name and URL of a weblog that has been updated.") {
    $parser->{'__ok'} = 1;
    return;
  }

  # Double ugh.

  if ($chars =~ /^Name:/) {
    $parser->{'__ok'} = 0;
  }

  if ($parser->{'__ok'}) {
    $chars =~ s/&nbsp;/ /gm;
    $parser->{__message} .= " $chars";
  }

  return 1;
}

=head1 VERSION

0.35

=head1 DATE

October 31, 2002

=head1 SEE ALSO

http://www.weblogs.com

http://www.xmlrpc.com/weblogsComForRss

http://www.xmlrpc.com/discuss/msgReader$2014?mode=day

=head1 FOOTNOTES

[1] http://www.xmlrpc.com/weblogsComForRss#changes103002ByDw

=head1 REQUIREMENTS

These packages are required in order to support the following transports :

=head2 XMLRPC

One of the following :

=over 4

=item *

B<Frontier::Client>

Default

=item *

B<XMLRPC::Lite> 

(part of SOAP::Lite)

=back

=head2 SOAP

=over 4

=item *

B<SOAP::Lite>

=back

=head2 REST

=over 4

=item *

B<LWP::Simple>

=item *

B<HTML::Parser>

This is optional, but required if you want this package to try and return a short and sweet message instead of raw HTML.

=back

=head1 LICENSE

Copyright (c) 2001-2002, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

return 1;

}
