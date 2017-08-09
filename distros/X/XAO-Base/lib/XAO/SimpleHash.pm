# Base of all hash-like objects.
#
package XAO::SimpleHash;
use strict;
use Carp;

###############################################################################

#
# METHODS
#

sub new ($;@);
sub fill ($@);

#
# Perl-style API
#

sub put ($$$);     # has URI support
sub get ($$);      # has URI support
sub getref ($$);   # has URI support
sub delete ($$);   # has URI support
sub defined ($$);  # has URI support
sub exists ($$);   # has URI support
sub keys ($);      # has URI support
sub values ($);    # has URI support
sub contains ($$);

#
# Java style API
#

sub isSet ($$);
sub containsKey ($);
sub containsValue ($$);
sub remove ($$);

###############################################################################
#
# Creating object instance and loading initial data.
#
sub new ($;@) { 
  my $proto=shift;
  my $this = bless {}, ref($proto) || $proto;
  $this->fill(@_) if @_;
  $this;
}

###############################################################################
#
# Filling with values. Values may be given in any of the following
# formats:
#  { key1 => value1,
#    key2 => value2
#  }
# or
#  key1 => value1,
#  key2 => value2
# or
#  [ key1 => value1 ],		(deprecated)
#  [ key2 => value2 ]
#
sub fill ($@)
{ 
  my $self = shift;
  return unless @_;
  my $args;

  #print "*** SimpleHash->fill: $self\n";

  #
  # We have hash reference?
  #
  if (@_ == 1 && ref($_[0]))
  { 
    $args = $_[0];
  }
  
  #
  # @_ = ['NAME', 'PHONE'], ['John Smith', '(626)555-1212']
  #
  elsif(ref($_[0]) eq 'ARRAY')
  { 
    my %a=map { ($_->[0], $_->[1]) } @_;
    $args=\%a;
  }

  #
  # @_ = 'NAME' => 'John Smith', 'PHONE' => '(626)555-1212'
  #
  elsif(int(@_) % 2 == 0)
  { 
    my %a=@_;
    $args=\%a;
  }
  #
  # Something we do not understand.. yet :)
  #
  else
  { 
    carp ref($self)."::fill - syntax error in argument passing";
    return undef;
  }

  #
  # Putting data in in pretty efficient but hard to read way :)
  #
  # @{self}{keys %{$args}} =CORE::values %{$args};

  foreach (CORE::keys %{$args}) { $self->{$_} = $args->{$_}; }
}
###############################################################################
#
# Checks does given key contains anything or not.
#
sub defined ($$)
{ 
  my ($self, $name) = @_;

  my @uri = $self->_uri_parser($name);

  return defined $self->{$uri[0]} unless $#uri > 0;

  my $value=$self;
  foreach my $key (@uri)
  {
    my $ref = ref($value);
    return undef unless ($ref eq 'HASH' || $ref eq ref($self))
                     && defined $value->{$key};
    $value = $value->{$key};
  }
  1;
}
###############################################################################
#
# The same as defined(), method name compatibility with Java hash.
#
sub isSet ($$)
{ 
  my $self=shift;
  $self->defined(@_);
}
###############################################################################
#
# Putting new value. Fill optimized for name-value pair.
#
sub put ($$$)
{ 
  my ($self, $name, $new_value) = @_;

  my @uri      = $self->_uri_parser($name);
  my $last_idx = $#uri;

  unless ($last_idx > 0)
  {
    $self->{$uri[0]} = $new_value;
    return $new_value;
  }

  my $i=0;
  my $value=$self;
  foreach my $key (@uri)
  {
    if ($i < $last_idx)
    {
      $value->{$key} = {} unless ref($value->{$key}) eq 'HASH';
      $value = $value->{$key};
    }
    else
    {
      $value->{$key} = $new_value;
      return $value->{$key};
    }
    $i++;
  }
}
###############################################################################
#
# Getting value by name
#
sub get ($$)
{ 
  my ($self, $name) = @_;
  my $ref = $self->getref($name);
  return ref($ref) ? $$ref : undef;
}
###############################################################################
#
# Returns reference to the value. Suitable for really big or complex
# values and to be used on left side of expression.
#
sub getref ($$)
{
  my ($self, $name) = @_;
  return undef unless $self->exists($name);

  my @uri = $self->_uri_parser($name);

  return \$self->{$uri[0]} unless $#uri > 0;

  my $value=$self;
  foreach my $key (@uri)
  {
    my $ref = ref($value);
    if ($ref eq 'HASH' || $ref eq ref($self))
    {
      $value = $value->{$key};
    }
    else
    {
      return undef;
    }
  }
  \$value;
}
###############################################################################
#
# Checks whether we contain given key or not.
#
sub exists ($$) { 
    my ($self, $name) = @_;

    my $value=$self;
    foreach my $key ($self->_uri_parser($name)) {
        my $r=ref($value);
        return undef unless ($r eq 'HASH' || $r eq ref($self)) &&
                            CORE::exists $value->{$key};
        $value=$value->{$key};
    }

    1;
}

###############################################################################
#
# The same as exists(), method name compatibility with Java hash.
#
sub containsKey ($)
{ 
  my $self=shift;
  $self->exists(@_);
}
###############################################################################
#
# List of elements in the 'hash'.
#
sub values ($)
{ 
  my ($self, $key) = @_;

  return CORE::values %{$self} unless defined($key);

  my @uri      = $self->_uri_parser($key);
  my $last_idx = $#uri;

  return CORE::values %{$self} unless $uri[0] =~ /\S+/;

  my $i=0;
  my $value=$self;
  foreach my $key (@uri)
  {
    my $ref = ref($value);
    if ($ref eq 'HASH' || $ref eq ref($self))
    {
      $value = $value->{$key};
    }
    else
    {
      return undef;
    }
    if ($i == $last_idx)
    {
      return ref($value) eq 'HASH' ? CORE::values %{$value} : undef;
    }
    $i++;
  }
}
###############################################################################
#
# The same as values(), method name compatibility with Java hash.
#
sub elements ($)
{ 
  my $self=shift;
  $self->values;
}
###############################################################################
#
# Keys in the 'hash'. In the same order as 'elements'.
#
sub keys ($)
{
  my ($self, $key) = @_;

  return CORE::keys %{$self} unless defined($key);

  my @uri      = $self->_uri_parser($key);
  my $last_idx = $#uri;

  return CORE::keys %{$self} unless $uri[0] =~ /\S+/;

  my $i=0;
  my $value=$self;
  foreach my $key (@uri)
  {
    my $ref = ref($value);
    if ($ref eq 'HASH' || $ref eq ref($self))
    {
      $value = $value->{$key};
    }
    else
    {
      return undef;
    }
    if ($i == $last_idx)
    {
      return ref($value) eq 'HASH' ? CORE::keys %{$value} : undef;
    }
    $i++;
  }
}

###############################################################################
#
# Deleting given key from the 'hash'.
#
sub delete ($$) { 
    my ($self, $key) = @_;

    my @uri      = $self->_uri_parser($key);
    my $last_idx = $#uri;

    return delete $self->{$uri[0]} unless $last_idx > 0;

    my $i=0;
    my $value=$self;
    foreach my $key (@uri) {
        if ($i < $last_idx) {
            return undef unless ref($value->{$key}) eq 'HASH';
            $value = $value->{$key};
        }
        else {
            return (ref($value) eq 'HASH' && CORE::exists $value->{$key})
                ? CORE::delete $value->{$key} : undef;
        }
        $i++;
    }

    '';
}

###############################################################################
#
# The same as delete(), method name compatibility with Java hash.
#
sub remove ($$)
{ 
  my $self=shift;
  $self->delete(@_);
}
###############################################################################
#
# Checks if our 'hash' contains specific value and return key or undef.
# Case is insignificant.
#
sub contains ($$)
{ 
  my ($self, $value) = @_;
  while(my ($key, $tvalue) = each %{$self})
  {
    return $key if uc($tvalue) eq uc($value);
  }
  undef;
}
###############################################################################
#
# The same as contains, method name compatibility with Java hash.
#
sub containsValue ($$)
{ 
  my $self=shift;
  $self->contains(@_);
}
###############################################################################
sub _uri_parser {
    my ($self, $uri) = @_;
    die "No URI passed" unless defined($uri);
    $uri =~ s/^\/+//; # get rid of leading  slashes
    $uri =~ s/\/+$//; # get rid of trailing slashes
    split(/\/+/, $uri);
}

###############################################################################

#XXX This should really be in POD! (AM)
#
# =item embeddable_methods ()
#
# Returns a list of methods to be embedded into Configuration. Only used
# by XAO::DO::Config object. Currently the list of embeddable methods
# include all methods of Perl API.
#
# =cut

sub embeddable_methods () {
    qw(put get getref delete defined exists keys values contains);
}

###############################################################################
#
# That's it
#
use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: SimpleHash.pm,v 2.1 2005/01/13 22:34:34 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";
1;
__END__

=head1 NAME

XAO::SimpleHash - Simple 2D hash manipulations

=head1 SYNOPSIS

  use XAO::SimpleHash;

  my $h=new XAO::SimpleHash a => 11, b => 12, c => 13;

  $h->put(d => 14);

  $h->fill(\%config);

  my @keys=$h->keys;

=head1 DESCRIPTION

Base object from which various hash-like containers are derived.
 
Methods are (alphabetical order, PERL API):

=over

=item *

sub contains ($$)
       
Returns key of the element, containing given text. Case is
insignificant in comparision.
   
If no value found 'undef' is returned.

=item *

sub defined ($$)
       
Boolean method to check if element with given key defined or not.
Exactly the same as 'defined ($hash->get($key))'.

=item *

sub delete ($$)
       
Deletes given key from the hash.

=item *

sub exists ($$)
       
Checks if given key exists in the hash or not (regardless of value,
which can be undef).

=item *

sub fill ($@)
       
Allows to fill hash with multiple values. Supports variety of argument
formats:
   
   $hash->fill(key1 => value1, key2 => value2, ...);
   
   $hash->fill({ key1 => value1, key2 => value2, ... });
   
   $hash->fill([ key1 => value1 ], [ key2 => value2 ], ...);

=item *

sub get ($$)
       
Returns element by given key. Usually called as:
   
$hash->get(key);

Support also available for URI:

$hash->put(/path/to/value);

Note that leading and trailing slashes are optional in URI.

=item *

sub getref ($$)
       
Return reference to the element by given key or 'undef' if such
element does not exist.

=item *

sub keys ($)
       
Returns array of keys.

=item *

sub new ($;@)
       
Creates new hash and pre-fills it with given values. Values are in the
same format as in fill().

=item *

sub put ($$$)
       
Puts single key-value pair into hash. Usually called as:
   
$hash->put(key => value);

Support also available for URI:

$hash->put(/path/to/value => value);

Note that leading and trailing slashes are optional in URI.

=item *

sub values ($)
       
Returns array of values in the same order as $hash->keys returns keys
(on non-modified hash).

=head1 JAVA STYLE API

In addition to normal Perl style API outlined above XAO::SimpleHash
allows developer to use Java style API. Here is the mapping between Perl
API and Java API:

  isSet          --  defined
  containsKey    --  exists
  elements       --  values
  remove         --  delete
  containsValue  --  contains

=head1 EXPORTS

Nothing.

=head1 AUTHORS

Copyright (c) 1997-2001 XAO Inc.

Authors are Marcos Alves <alves@xao.com>, Bil Drury <bild@xao.com>,
Andrew Maltsev <am@xao.com>.
