package Combine::selurl;

use strict;

our $AUTOLOAD;

use URI;
#use URI::Escape;
#use URI::http;
#use URI::https;
#use URI::ftp;

use Carp;

use Combine::Config;

1; # package return thang

##########################################################
sub AUTOLOAD
{
  my $whatever = $AUTOLOAD;
  $whatever =~ s/^Combine::selurl\:\://;

  return if $whatever eq 'DESTROY';

  my($self) = shift;

  my $uri = $self->{'URI'};
  return $uri->$whatever(@_);
}


sub new
{
  my($class, $uristr, $scheme, %opt) = @_;

  my $self = {};

  if($opt{'sloppy'})
  {
    # If the original input has no scheme (like 'www.dtu.dk/some/path'
    # or even just 'www.dtu.dk'), and does not start with //, we'll
    # prepend http:// in the assumption the first thing is a hostname.

    if( $uristr !~ /^\w+:/ )
    {
      if($uristr =~ m|^//|)
      {
        $uristr = 'http:' . $uristr;
      } else {
        $uristr = 'http://' . $uristr;
      }
    }
  }

  # Whether sloppy is set or not, we will provide URI->new with a
  # default method to avoid a crash on host() overloading
  $scheme = 'http' unless $scheme;


  $self->{'URI'} = new URI($uristr, $scheme);
  # quickly catch if we can handle this scheme at all; otherwise
  # URI will cause trouble when we try to use host()

  return undef unless $self->{'URI'}->scheme() =~ /^http$|^https$|^ftp$/;

  $self->{'orguri'} = $uristr;

  bless $self, $class;
  return undef unless $self->{'URI'}->host();
  return undef unless $self->_init();

  return $self;
}


# We need new_abs to fulfill the pledge of inheritance from URI.
sub new_abs
{
  my($class, $uristr, $base, %opt) = @_;

  # Does NOT accept sloppy option!

  my $self = {};
#  $self->{'URI'} = new_abs URI($uristr, $base);
  $self->{'URI'} = URI->new_abs($uristr, $base);
  $self->{'orguri'} = $uristr;

  bless $self, $class;
  $self->_init();
  return $self;
}


sub _init
{
  # common instance initialiser for new*
  my $self = shift;
  my $uri = $self->{'URI'};

  # Set some elements we're probably going to use anyway

  my $h = $uri->host();
  $self->{'orghost'}       = $h;  # without default port
  $self->{'orgport'}       = $uri->port();  # even default port
  # TODO: may want to use host:port as id
  $self->{'preferredhost'} = $Combine::Config::serverbyalias{$h} || $h;
  $self->{'normalised'}    = '';
  $self->{'dirtycgi'}      = 0;  # Flag if cgi normalisation detected duplication
  $self->{'invalidreason'} = '';

  $self->{'normlevel'} = {'prefhost'     => 1,
                          'canonical'    => 1,
                          'cgidup'       => 2, # 1=keys, 2=key+val
                          'cgisessid'    => 1,
                          'fragment'     => 1,
			  'colapsedots'  => 1
                         };

  $self->{'validlevel'} = {'checkallow'   => 1,
                           'checkexclude' => 1,
                           'checklength'  => 1,
                           'checkcgidup'  => 0  # needn't be set if cgidup norm is set
                          };
  return 1;
}


sub normlevel
{
  # Get/set normalisation options
  my($self, %newnorm) = @_;
  # TODO: check option validity

  my %oldnorm = %{$self->{'normlevel'}};

  if(%newnorm)
  {
    # I assume Perl assigns values left-to-right... otherwise... <shrug>
    my %tmp = (%oldnorm, %newnorm);
    $self->{'normlevel'} = \%tmp;
    $self->{'normalised'} = '';  # clean cache
    $self->{'dirtycgi'} = 0;
    # do not reset invalidreason
  }

  return (%oldnorm);
}


sub validlevel
{
  # Get/set validation barriers
  my($self, %newlevel) = @_;
  # TODO: check option validity

  my %oldlevel = %{$self->{'validlevel'}};

  if(%newlevel)
  {
    # I assume Perl assigns values left-to-right... otherwise... <shrug>
    my %tmp = (%oldlevel, %newlevel);
    $self->{'validlevel'} = \%tmp;
    $self->{'normalised'} = '';  # clean cache
    $self->{'dirtycgi'} = 0;
    $self->{'invalidreason'} = '';
  }

  return (%oldlevel);
}


sub validate
{
  my $self = shift;

  #Check if global init done
#  if (!defined($selurl_init_done)) {
#      if(!selurl_init())
#      {
#	  die("Could not initialise selurl global config data");
#      }
#      $selurl_init_done=1;
#  }

  #####
  # 1: normalise. Always.
  my $norm = $self->normalise();

  my %validlevel = %{$self->{'validlevel'}};


  #####
  # 2 test length
  if($validlevel{'checklength'} and length($norm) > Combine::Config::Get('maxUrlLength') )
  {
    $self->{'invalidreason'} = 'length: ' . length($norm) . ' > ' . Combine::Config::Get('maxUrlLength');
    return 0;
  }


  #####
  # 3 test allow

  # TODO: do we need a host:port comparison for host entries?

  if($validlevel{'checkallow'})
  {
    my $allow = 0;
    foreach my $rule (@Combine::Config::allow)
    {
      my($hostind, $patt, $orgpatt) = @{$rule};
      if($hostind eq 'H' and $self->{'preferredhost'} =~ $patt)
      {
        $allow = 1;
        last;
      } elsif($hostind ne 'H' and $norm =~ $patt) {
        $allow = 1;
        last;
      }
    }
    if(!$allow)
    {
      $self->{'invalidreason'} = "allow: nomatch";
      return 0;
    }
  }


  #####
  # 4 test exclude
  if($validlevel{'checkexclude'})
  {
    my $exclude = 0;
    my $havocpatt;
    foreach my $rule (@Combine::Config::exclude)
    {
      my($hostind, $patt, $orgpatt) = @{$rule};
      if($hostind eq 'H' and $self->{'preferredhost'} =~ $patt)
      {
        $exclude = 1;
        $havocpatt = $orgpatt;
        last;
      } elsif($hostind ne 'H' and $norm =~ $patt) {
        $exclude = 1;
        $havocpatt = $orgpatt;
        last;
      }
    }
    if($exclude)
    {
      $self->{'invalidreason'} = "exclude: $havocpatt";
      return 0;
    }

  }

  #####
  # 5 test CGI repetition sanity
  if($validlevel{'checkcgidup'})
  {
    # Hmmm.... TODO: how to combine this with norm:cgidup settings?
  }

  return 1;
}


sub normalise
{
  my($self, %opt) = @_;

  # If cached, no action unless force option is set
  return $self->{'normalised'} if $self->{'normalised'} && !$opt{'force'};

  my %level = %{$self->{'normlevel'}};
  my $newuri = $self->{'URI'};

  # 1: goodbye fragment. Buglet: if you set a '' fragment, URI appends # to 
  # all URIs.
  $newuri->fragment(undef) if $level{'fragment'};

  # 2: Set preferred server.
  $newuri->host($self->{'preferredhost'}) if $level{'prefhost'};

  # TODO: first canonical

  # 3: perform URI->canonical: remove default port dep. on method,
  # lowercase host, unnecessary % escape removal
  #
  # We want to do this before CGI normalisation, because there
  # is a slight chance that canonical() changes the CGI string.
  # This implies we need to reconstruct a new URI from the 
  # canonical string.

  if($level{'canonical'})
  {
    $self->{'URI'} = $self->{'URI'}->canonical();
    $newuri = $self->{'URI'};
  }

  # clean CGI repetition (groovy)
  my $q = $newuri->query();
  my $newq;
  # TODO: add sessid to cleanquery based on cgisessid option
  if($q and $level{'cgidup'} == 1)
  {
    $newq = cleanquery($q, 'unique' => 'keys', 'cleansessions' => $level{'cgisessid'});
    $newuri->query($newq);
  } elsif($q and $level{'cgidup'} == 2) {
    $newq = cleanquery($q, 'unique' => 'kvpairs', 'cleansessions' => $level{'cgisessid'});
    $newuri->query($newq);
  }

  $self->{'dirtycgi'} = 1 if $newq and $newq ne $q;

  if($level{'colapsedots'})
  {
      #remove a '.' if last in host
      my $host = $newuri->host;
      if ( $host =~ s|\.$|| ) { $newuri->host($host); }
      #remove '%20' (space) if in host
      if ( $host =~ s|\s+||g ) { $newuri->host($host); }
      #collapsing ./, ../ in the path 
      #   You can also have the abs() method ignore excess ".."  segments in the
      #   relative URI by setting $URI::ABS_REMOTE_LEADING_DOTS to a TRUE value.
      my $path = $newuri->path;
      while ( $path =~ s%[^/]+/\.\./?|/\./|//|/\.$|/\.\.$%/% ) { }
      $newuri->path($path);
  }

  #more expensive normalization like adding trailing '/' if validated by database entries

  # We'll only keep the string, not the normalised URI object
  $self->{'normalised'} = $newuri->as_string();
  return $self->{'normalised'};
}

sub cleanquery
{
  # Class method.
  # check and clean a query string from repetitive keys or key/value
  # pairs. Maintain the order in which elements are specified.

  my($query, %opt) = @_;

  # which criterion to use for determining repetition: 'keys' or 
  # 'kvpairs' (default)
  my $unique = $opt{'unique'} || 'kvpairs';

  # Which keys are session ids and must be omitted entirely.
  # Very experimental. Might go to configuration.
  # Case sensitive!
  
  my %sessid;
  if($opt{'cleansessions'} == 1)
  {
      my $c = Combine::Config::Get('url');
#      %sessid = %{${%{$c}}{'sessionids'}}; #Problems with Ubuntu 9.10
       %sessid = %{$c->{'sessionids'}};
  }

#OLD
#  if($opt{'sessionid'})
#  {
#    foreach my $s (split(',', $opt{'sessionid'}))
#    {
#      $sessid{$s} = 1;
#    }
#  }
#/OLD

  my $cleaned= '';
  my @kvpairs = split('\&', $query);
  my(@keys, @values, %seen);
  foreach my $item (@kvpairs)
  {
    my($k, undef, $v) = $item =~ /(\w+)(=(.*))?/;
    next if defined($sessid{$k});
    if($unique eq 'kvpairs')
    {
      $cleaned .= '&' . $item unless $seen{$item};
      $seen{$item}++;
    } else { # 'keys'
      $cleaned .= '&' . $item unless $seen{$k};
      $seen{$k}++;
    }
  }

  return substr($cleaned,1);
}


=pod

=head1 NAME

selurl - Normalise and validate URIs for harvesting

=head1 INTRODUCTION

Selurl selects and normalises URIs on basis of both general practice
(hostname lowercasing, portnumber substsitution etc.) and
Combine-specific handling (aplpying config_allow, config_exclude,
config_serveralias and other relevant config settings).

The Config settings catered for currently are:

maxUrlLength - the maximum length of an unnormalised URL
allow - Perl regular to identify allowed URLs
exclude - Perl regular expressions to exclude URLs from harvesting
serveralias - Aliases of server names
sessionids - List sessionid markers to be removed

A selurl object can hold a single URL and has methods to obtain its
subparts as defined in URI.pm, plus some methods to normalise and
validate it in Combine context.


=head1 BUGS

Currently, the only schemes supported are http, https and ftp. Others
may or may not work correctly. For one thing, we assume the scheme has
an internet hostname/port.

clone() will only return a copy of the real URI object, not a new
selurl.

URI URI-escapes the strings fed into it by new() once. Existing
percent signs in the input are left untouched, which implicates that:

(a) there is no risk of double-encoding; and

(b) if the original contained an inadvertent sequence that could
be interpreted as an escape sequence, uri_unescape will not
render the original input (e.g. url_with_%66_in_it goes whoop)
If you know that the original has not yet been escaped and wish to
safeguard potential percent signs, you'll have to escape them (and
only them) once before you offer it to new().

A problem with URI is, that its object is not a hash we can
piggyback our data on, so I had to resort to AUTOLOAD to emulate
inheritance. I find this ugly, but well, this *is* Perl, so what'd
you expect?

=cut

