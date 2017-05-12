package WWW::Simpy;

use 5.006001;
use strict;
use warnings;
use XML::Parser;
use LWP::UserAgent;
use URI;
use HTTP::Request::Common;
use Data::Dumper;


use constant API_NETLOC => "www.simpy.com:80";
use constant API_REALM => "/simpy/api/rest";
use constant API_BASE => "http://" . API_NETLOC . API_REALM . "/";

use constant PUBLIC => 1;
use constant PRIVATE => 0;

use constant SUCCESS => 0;
use constant PARAMETER_MISSING => 100;
use constant NONEXISTENT_ENTITY => 200;
use constant TRANSIENT_ERROR => 300;
use constant STORAGE_ERROR => 301;
use constant QUOTA_REACHED => 500;

# must be all on one line, or MakeMaker will get confused
our $VERSION = do { my @r = (q$Revision: 1.15 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
$VERSION = eval $VERSION;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Simpy ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( 
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( PUBLIC PRIVATE
			SUCCESS
			PARAMETER_MISSING
			NONEXISTENT_ENTITY
			TRANSIENT_ERROR
			STORAGE_ERROR
			QUOTA_REACHED
);


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

WWW::Simpy - Perl interface to Simpy social bookmarking service

=head1 SYNOPSIS

  use Simpy;

  my $sim = new Simpy;

  my $cred = { user => "demo", pass => "demo" };

  my $opts = { limit => 10 }; 
  my $tags = $sim->GetTags($cred, $opts) || die $sim->status;

  foreach my $k (keys %{$tags}) {
    print "tag $k has a count of " . $tags->{$k} . "\n";
  }

  my $opts = { limit => 10, q = "search" };
  my $links = $sim->GetTags($cred, $opts) || die $sim->status;

  foreach my $k (keys %{$links}) {
    print "url $k was added " . $links->{$k}->{addDate} . "\n";
  }

  my $opts = { fromTag => 'rose', toTag => 'another name' };
  $sim->RenameTag($cred, $opts) || die $sim->status;

  print $sim->message . "\n";
  
=head1 DESCRIPTION

This module provides a Perl interface to the Simpy social bookmarking
service.  See http://www.simpy.com/simpy/service/api/rest/

THIS IS AN ALPHA RELEASE.  This module should not be relied on for any
purpose, beyond serving as an indication that a reliable version will be
forthcoming at some point the future.

This module is being developed as part of the "mesh pooling" component 
ofthe Transpartisan Meshworks project ( http://www.transpartisanmeshworks.org ).
The mesh pool will integrate social bookmarking and collaborative 
content development in a single application.

=head2 EXPORT

=head3 accessorType

The accessorType property of a link may be PUBLIC or PRIVATE.

=head3 code

The Simpy status code may be any of the following constants.

   # SUCCESS			- Success
   # PARAMETER_MISSING		- Required parameter missing
   # NONEXISTENT_ENTITY		- Non-existent entity
   # TRANSIENT_ERROR		- Transient data retrieval error
   # STORAGE_ERROR		- Entity storage error
   # QUOTA_REACHED		- Storage quota exceeded
		
=cut

=head1 METHODS

=head2 Constructor Method

Simpy object constructor method.

  my $s = new Simpy;

=cut

sub new {
  my ($class, $user) = @_;

  # set up
  my $self = {
    _ua => LWP::UserAgent->new,
    _status => undef,
    _pa => new XML::Parser(Style => 'Objects'),
    _message => undef,
    _code => undef
  };

  # configure our web user agent
  my $ua = $self->{_ua};
  $ua->agent("WWW::Simpy $VERSION ($agent)");
  push @{ $ua->requests_redirectable }, 'POST';
  $self->{_ua} = $ua;

  # okay, we can go now
  bless $self, $class;
  return $self;
}

#
# internal utility functions - not public methods
#

# REST call by POST -- to avoid 414 Errors for long URIs
sub do_rest_post {
   my ($self, $do, $cred, $qry) = @_;

   # set up our REST query
   my $uri = URI->new_abs($do, API_BASE);

   # talk to the REST server
   my $ua = $self->{"_ua"};
   $ua->credentials(API_NETLOC, API_REALM, $cred->{'user'}, $cred->{'pass'});
   my $resp = $ua->post($uri, $qry);
   $ua->credentials(API_NETLOC, API_REALM, undef, undef);
   $self->{_status} = $resp->status_line;

   if ($resp->status_line !~ /^200/) {
     $self->{_status} .= "\n" . $resp->content;
   }

   # return document, or undef if not successful  
   return $resp->content if ($resp->is_success);
}

# REST-standard GET request
sub do_rest {
   my ($self, $do, $cred, $qry) = @_;

   # set up our REST query
   my $uri = URI->new_abs($do, API_BASE);
   $uri->query_form($qry);
   my $req = HTTP::Request->new(GET => $uri);
   $req->authorization_basic($cred->{'user'}, $cred->{'pass'});

   # talk to the REST server
   my $ua = $self->{"_ua"};
   my $resp = $ua->request($req);
   $self->{_status} = $resp->status_line;

   # return document, or undef if not successful   
   return $resp->content if ($resp->is_success);
}     


# Read the XML returned, and return an object
sub read_response {
  my ($self, $xml) = @_;

  # parse the xml to get 
  my $p = $self->{_pa};
  my $anon;
  eval { $anon = $p->parse($xml); };    # trap errors
  $self->{_status} = $@;

  # get Kids of the first xml object therein (there should only be one)
  my $obj = @{$anon}[0];
  my @kids = @{$obj->{Kids}};

  # set message if one was returned
  my $code = undef;
  my $msg = undef;
  foreach my $k (@kids) {
    next if ((ref $k) =~ /::Characters$/);
    my $ref = ref $k;
    $ref =~ s/.*::([^\:]*)$/$1/;
    $code = $k->{'Kids'}->[0]->{'Text'} if $ref eq 'code';
    $msg  = $k->{'Kids'}->[0]->{'Text'} if $ref eq 'message';
  }    
  $self->{_message} = $msg;
  $self->{_code} = $code;
  $self->{_status} = "$code: $msg";

  # return those kids as an array
  return @kids unless ($code);
}

=head2 Accessor Methods

Return status information from API method calls.

=head3 status

Return the HTTP status of the last call to the Simpy REST server, or 
syntax errors from the XML::Parser module, if any, or error from Simpy 
REST API, if any.

=cut

sub status {
  my ($self) = @_;
  return $self->{_status};
}

=head3 message

Return the message string, if any, returned by the last Simpy REST method.

=cut 

sub message {
  my ($self) = @_;
  return $self->{_message};
}

=head3 code

Return the Simpy error code, if any, returned by the last Simpy REST 
method.

=cut

sub code {
  my ($self) = @_;
  return $self->{_code};
}

=head2 REST API Methods

See http://www.simpy.com/simpy/service/api/rest/ for more information 
about required and optional parameters for these methods.

=head3 GetTags

Returns a hash reference of tag/count pairs.

   my $tags = $s->GetTags($cred, $opts);
   print "The tag 'dolphin' has a count of " . $tags->{dolphin};

=cut

sub GetTags {
  my ($self, $cred, $opts) = @_;

  my $xml = do_rest($self, "GetTags.do", $cred, $opts);
  return unless $xml;

  my @kids = read_response($self, $xml);  
  my %tags;
  foreach my $k (@kids) {
    my $name = $k->{name};
    next unless (defined $name);
    my $count = $k->{count};
    $tags{$name} = $count;
  }

  return \%tags;
}

=head3 RemoveTag

Removes a tag via the Simpy API.  Returns a true result if successful.  

=cut

sub RemoveTag {
  my ($self, $cred, $opts) = @_;

  my $xml = do_rest($self, "RemoveTag.do", $cred, $opts);
  return unless $xml;

  return read_response($self, $xml);
}

=head3 RenameTag

Renames a tag via the Simpy API.  Returns a true result if successful.  

=cut

sub RenameTag {
  my ($self, $cred, $opts) = @_;

  my $xml = do_rest($self, "RenameTag.do", $cred, $opts);
  return unless $xml;

  return read_response($self, $xml);
}


=head3 RenameTag

Merges two tags via the Simpy API.  Returns a true result if successful.  

=cut

sub MergeTags {
  my ($self, $cred, $opts) = @_;

  my $xml = do_rest($self, "MergeTags.do", $cred, $opts);
  return unless $xml;

  return read_response($self, $xml);
}


=head3 SplitTag

Splits a tag via the Simpy API.  Returns a true result if successful.  

=cut

sub SplitTag {
  my ($self, $cred, $opts) = @_;

  my $xml = do_rest($self, "SplitTag.do", $cred, $opts);
  return unless $xml;

  return read_response($self, $xml);
}


=head3 GetLinks

Returns an hash reference of links, keyed by url.  Each link is in turn 
a hash reference of link properties, keyed by property name.  The 
value of the 'tags' property keys is an array reference of tags.  All 
other properties tag a scalar value.  

The exported constants PUBLIC and PRIVATE can be used to check the value 
of the accessType property.

=cut

sub GetLinks {
  my ($self, $cred, $opts) = @_;

  my $xml = do_rest($self, "GetLinks.do", $cred, $opts);
  return unless $xml;

  my @kids = read_response($self, $xml);  

  my %links;
  foreach my $k (@kids) {
    next if ((ref $k) =~ /::Characters$/);

    my %hash;
    $hash{'accessType'} = { $k->{accessType} eq "public" } ? PUBLIC : PRIVATE;
    my @prop = @{$k->{Kids}};

    foreach my $p (@prop) {
      next if ((ref $p) =~ /::Characters$/);
      my $ref = ref $p;
      $ref =~ s/.*::([^\:]*)$/$1/;
      my $obj = $p->{Kids};

      if ($ref eq 'tags') {
        my @tags;
        foreach $t (@{$obj}) {
          next if ((ref $t) =~ /::Characters$/);
          push @tags, $t->{Kids}->[0]->{'Text'};          
        }
        $hash{$ref} = \@tags;
      } elsif (defined $obj->[0]) {
        $hash{$ref} = $obj->[0]->{'Text'};
      }
    }

    my $url = $hash{'url'};
    $links{$url} = \%hash;
  }

  return \%links;   
}

=head3 SaveLink

Saves a link via the Simpy API.  Returns a true result if successful.  

=cut

sub SaveLink {
  my ($self, $cred, $opts) = @_;

  my $xml = do_rest_post($self, "SaveLink.do", $cred, $opts);
  return unless $xml;

  return read_response($self, $xml);
}


=head1 CAVEATS

This is an early alpha release.  Not all methods of the API are 
implemented, nor have the sub-modules defining data types for those API 
methods been developed.

=head1 SEE ALSO

http://simpytools.sourceforge.net

http://www.transpartisanmeshworks.org

=head1 AUTHOR

Beads Land, beads@beadsland.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Beads Land

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl you may have available.

=cut

1;

