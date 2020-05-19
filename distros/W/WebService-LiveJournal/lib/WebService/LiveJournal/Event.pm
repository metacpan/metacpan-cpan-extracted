package WebService::LiveJournal::Event;

use strict;
use warnings;
use RPC::XML;
use WebService::LiveJournal::Thingie;
our @ISA = qw/ WebService::LiveJournal::Thingie /;

# ABSTRACT: (Deprecated) LiveJournal event class
our $VERSION = '0.09'; # VERSION


# crib sheet based on stuff i read in the doco may be
# complete rubbish.
#
# itemid (req)    # (int)
# event (req)    # (string) set to empty to delete
# lineendings (req)  # (string) "unix"
# subject (req)    # (string)
# security (opt)  # (string) public|private|usemask (defaults to public)
# allowmask (opt)  # (int)
# year (req)    # (4-digit int)
# mon (req)    # (1- or 2-digit month int)
# day (req)    # (1- or 2-digit day int)
# hour (req)    # (1- or 2-digit hour int 0..23)
# min (req)    # (1- or 2-digit day int 0..60)
# props (req)    # (struct)
# usejournal (opt)  # (string)
# 

sub new
{
  my $ob = shift;
  my $class = ref($ob) || $ob;
  my $self = bless {}, $class;
  my %arg = @_;
  
  $self->{props} = $arg{props} || {};
  $self->{itemid} = $arg{itemid} if defined $arg{itemid};
  $self->{subject} = $arg{subject} || '';
  $self->{url} = $arg{url} if defined $arg{url};
  $self->{anum} = $arg{anum} if defined $arg{anum};
  $self->{event} = $arg{event} || ' ';
  $self->eventtime($arg{eventtime}) if defined $arg{eventtime};
  $self->{security} = $arg{security} || 'public';
  $self->{allowmask} = $arg{allowmask} if defined $arg{allowmask};
  $self->{usejournal} = $arg{usejournal} if defined $arg{usejournal};
  $self->{client} = $arg{client};
  $self->{props}->{picture_keyword} = $arg{picture} if defined $arg{picture};

  $self->{year} = $arg{year} if defined $arg{year}; 
  $self->{month} = $arg{month} if defined $arg{month}; 
  $self->{day} = $arg{day} if defined $arg{day}; 
  $self->{hour} = $arg{hour} if defined $arg{hour}; 
  $self->{min} = $arg{min} if defined $arg{min}; 

  return $self;
}


sub subject
{
  my $self = shift;
  my $value = shift;
  $self->{subject} = $value if defined $value;
  $self->{subject};
}


sub event
{
  my $self = shift;
  my $value = shift;
  $self->{event} = $value if defined $value;
  $self->{event};
}


sub year
{
  my $self = shift;
  my $value = shift;
  $self->{year} = $value if defined $value;
  $self->{year};
}


sub month
{
  my $self = shift;
  my $value = shift;
  $self->{month} = $value if defined $value;
  $self->{month};
}


sub day
{
  my $self = shift;
  my $value = shift;
  $self->{day} = $value if defined $value;
  $self->{day};
}


sub hour
{
  my $self = shift;
  my $value = shift;
  $self->{hour} = $value if defined $value;
  $self->{hour};
}


sub min
{
  my $self = shift;
  my $value = shift;
  $self->{min} = $value if defined $value;
  $self->{min};
}


sub security
{
  my $self = shift;
  my $value = shift;
  if(defined $value)
  {
    if($value eq 'friends')
    {
      $self->{security} = 'usemask';
      $self->{allowmask} = 1;
    }
    else
    {
      $self->{security} = $value;
    }
  }
  $self->{security};
}


sub allowmask
{
  my $self = shift;
  my $value = shift;
  $self->{allowmask} = $value if defined $value;
  $self->{allowmask};
}


sub picture
{
  my $self = shift;
  my $value = shift;
  if(defined $value)
  {
    $self->{props}->{picture_keyword} = $value;
  }
  $self->{props}->{picture_keyword};
}


sub itemid { $_[0]->{itemid} }
sub url { $_[0]->{url} }
sub anum { $_[0]->{anum} }
sub usejournal { $_[0]->{usejournal} }


sub props { $_[0]->{props} }


sub update
{
  my $self = shift;
  if(defined $self->itemid)
  {
    return $self->editevent;
  }
  else
  {
    return $self->postevent;
  }
}


sub save { shift->update(@_) }


sub delete
{
  my($self) = @_;
  $self->event('');
  return $self->update;
}


sub getprop { $_[0]->{props}->{$_[1]} }
sub setprop { $_[0]->{props}->{$_[1]} = $_[2] }
sub get_prop { $_[0]->{props}->{$_[1]} }
sub set_prop { $_[0]->{props}->{$_[1]} = $_[2] }

sub _prep
{
  my $self = shift;
  my @list;
  push @list,
    event => new RPC::XML::string($self->event),
    subject => new RPC::XML::string($self->subject),
    security => new RPC::XML::string($self->security),
    lineendings => do { no warnings; $WebService::LiveJournal::Client::lineendings_unix },

    year  => new RPC::XML::int($self->year),
    mon  => new RPC::XML::int($self->month),
    day  => new RPC::XML::int($self->day),
    hour  => new RPC::XML::int($self->hour),
    min  => new RPC::XML::int($self->min),    
  ;
  push @list, allowmask => new RPC::XML::int($self->allowmask) if $self->security eq 'usemask';
  push @list, usejournal => new RPC::XML::string($self->usejournal) if defined $self->usejournal;
  
  my @props;
  foreach my $key (keys %{ $self->{props} })
  {
    push @props, $key => new RPC::XML::string($self->{props}->{$key});
  }
  push @list, props => new RPC::XML::struct(@props);
  
  @list;
}

sub _prep_flat
{
  my $self = shift;
  my @list;
  push @list,
    event => $self->event,
    subject => $self->subject,
    security => $self->security,
    lineendings => 'unix',
    year => $self->year,
    mon => $self->month,
    day => $self->day,
    hour => $self->hour,
    min => $self->min,
  ;
  push @list, allowmask => $self->allowmask if $self->security eq 'usemask';
  push @list, usejournal => $self->usejournal if defined $self->usejournal;
  foreach my $key (keys %{ $self->{props} })
  {
    push @list, "prop_$key" => $self->{props}->{$key};
  }
  
  @list;
}

sub editevent
{
  my $self = shift;
  my $client = $self->client;

  if(1)
  {
    my @list = _prep_flat($self, @_);
    push @list, itemid => $self->itemid;
    my $response = $client->send_flat_request('editevent', @list);
    if(defined $response)
    { return 1 }
    else
    { return }
  }
  else
  {
    my @list = _prep($self, @_);
    push @list, itemid => new RPC::XML::int($self->itemid);

    my $response = $client->send_request('editevent', @list);
    if(defined $response)
    { return 1 }
    else
    { return }
  }
}

sub _fill_in_default_time
{
  my($self) = @_;
  return if defined $self->{year}
  &&        defined $self->{month}
  &&        defined $self->{day}
  &&        defined $self->{hour}
  &&        defined $self->{min};
  my ($sec,$min,$hour,$mday,$month,$year,$wday,$yday,$isdst) = localtime(time);
  $self->{year}  //= $year+1900;
  $self->{month} //= $month+1;
  $self->{day}   //= $mday;
  $self->{hour}  //= $hour;
  $self->{min}   //= $min;
  return;
}

sub postevent
{
  my $self = shift;
  my $client = $self->client;
  
  $self->_fill_in_default_time;
  
  my $h;
  if(1)
  {
    my @list = _prep_flat($self, @_);
    $h = $client->send_flat_request('postevent', @list);
    return unless defined $h;
  }
  else
  {
    my @list = _prep($self, @_);
    my $response = $client->send_request('postevent', @list);
    return unless defined $response;
    $h = $response->value;
  }

  $self->{itemid} = $h->{itemid};
  $self->{url} = $h->{url};
  $self->{anum} = $h->{anum};
  return 1;
}

sub as_string
{
  my $self = shift;
  my $subject = $self->subject;
  $subject = 'untitled' if !defined $subject || $subject eq '';
  "[event $subject]";
}


sub get_tags
{
  my $self = shift;
  if(defined $self->{props}->{taglist})
  {
    return split /, /, $self->{props}->{taglist};
  }
  else
  {
    return ();
  }
}

# legacy
sub gettags { shift->get_tags(@_) }


sub set_tags
{
  my $self = shift;
  my $tags = join ', ', @_;
  $self->{props}->{taglist} = $tags;
  $self;
}

sub settags { shift->set_tags(@_) }


sub htmlid
{
  my $self = shift;
  my $url = $self->url;
  if($url =~ m!/(\d+)\.html$!)
  {
    return $1;
  }
  else
  {
    return;
  }
}

sub name { itemid(@_) }


sub set_access
{
  my($self, $type, @groups) = @_;

  if($type =~ /^(?:public|private)$/)
  {
    $self->security($type);
  }
  elsif($type eq 'groups')
  {
    my $mask = 0;
    foreach my $group (@_)
    {
      $mask |= $group->mask;
    }
    $self->security('usemask');
    $self->allowmask($mask);
  }
  elsif($type eq 'friends')
  {
    $self->security('usemask');
    $self->allowmask(1);
  }
  return ($type, @groups);
}


sub get_access
{
  my($self) = @_;
  
  my $security = $self->security;
  return $security if $security =~ /^(?:public|private)$/;
  my $allowmask = $self->allowmask;
  return 'friends' if $allowmask == 1;
  my $groups = $self->client->getfriendgroups;
  my @list;
  foreach my $group (@{ $groups })
  {
    my $mask = $group->mask;
    no warnings;
    push @list, $group if $mask & $allowmask == $mask;
  }
  return ('grops', @list);
}

# legacy
sub access
{
  my $self = shift;
  my $type = shift;
  defined $type ? $self->set_access(@_) : $self->get_access;
}

sub eventtime
{
  my $self = shift;
  my $value = shift;
  if(defined $value)
  {
    if($value =~ m/^(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)$/)
    {
      $self->{year} = $1;
      $self->{month} = $2;
      $self->{day} = $3;
      $self->{hour} = $4;
      $self->{min} = $5;
    }
    elsif($value eq 'now')
    {
      my($sec,$min,$hour,$mday,$month,$year,$wday,$yday,$isdst) = localtime(time);
      $self->{year} = $year+1900;
      $self->{month} = $month+1;
      $self->{day} = $mday;
      $self->{hour} = $hour;
      $self->{min} = $min;
    }
  }
  no warnings;
  sprintf("%04d-%02d-%02d %02d:%02d:%02d", $self->year, $self->month, $self->day, $self->hour, $self->min);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::LiveJournal::Event - (Deprecated) LiveJournal event class

=head1 VERSION

version 0.09

=head1 SYNOPSIS

create an event

 use WebService::LiveJournal;
 my $client = WebService::LiveJournal::Client->new(
   username => $user,
   password => $password,
 );
 
 # $event is an instance of WS::LJ::Event
 my $event = $client->create_event;
 $event->subject("this is a subject");
 $event->event("this is the event content");
 # doesn't show up on the LiveJournal server
 # until you use the update method.
 $event->update;
 
 # save the itemid for later use
 $itemid = $event->itemid;

update an existing event

 use WebService::LiveJournal;
 my $client = WebService::LiveJournal::Client->new(
   username => $user,
   password => $password,
 );
 
 my $event = $client->get_event( $itemid );
 $event->subject('new subject');
 $event->update;

=head1 DESCRIPTION

B<NOTE>: This distribution is deprecated.  It uses the outmoded XML-RPC protocol.
LiveJournal has also been compromised.  I recommend using DreamWidth instead
(L<https://www.dreamwidth.org/>) which is in keeping with the original philosophy
LiveJournal regarding advertising.

This class represents an "event" on the LiveJournal server.

=head1 ATTRIBUTES

=head2 subject

Required.

The subject for the event.

=head2 event

Required.

The content of the event.

=head2 year

Year

=head2 month

Month

=head2 day

Day

=head2 hour

Hour

=head2 min

Minute

=head2 security

One of

=over 4

=item public

=item private

=item friends

=item usemask

=back

=head2 allowmask

Relevant when security is usemask. A 32-bit unsigned integer 
representing which of the user's groups of friends are allowed 
to view this post. Turn bit 0 on to allow any defined friend to
read it. Otherwise, turn bit 1-30 on for every friend group that 
should be allowed to read it. Bit 31 is reserved.

=head2 picture

The picture tag to use for this entry.  Each icon picture
may have one or more tags, you can select it by using any
one of those tags for this attribute.

=head2 itemid

Read only.

The LiveJournal item id

=head2 url

Read only.

URL for the LiveJournal event.

=head2 anum

Read only.

The authentication number generated for this entry
Probably best ignored.

=head2 usejournal

If editing a shared journal entry, include this key and the username
you wish to edit the entry in. By default, you edit the entry as if
it were in user "user"'s journal, as specified above.

=head2 props

Property hash

=head1 METHODS

=head2 $event-E<gt>update

Create a new (if it isn't on the LiveJournal server yet) or update
the existing event on the LiveJournal server.

Returns true on success.

This method signals an error depending on the interface
selected by throwing an exception or returning undef.

=head2 $event-E<gt>save

An alias for update.

=head2 $event-E<gt>delete

Remove the event on the LiveJournal server.

This method signals an error depending on the interface
selected by throwing an exception or returning undef.

=head2 $event-E<gt>get_prop( $key )

Get the property with the given key

=head2 $event-E<gt>set_prop( $key => $value )

Set the property with the given key and value

=head2 $event-E<gt>get_tags

Returns the tags for the event as a list.

=head2 $event-E<gt>set_tags( @new_tags )

Set the tags for the event.

=head2 $event-E<gt>set_access([ 'public' | 'private' | 'friends' ])

=head2 $event-E<gt>set_access('group', @group_list)

Set the access for the event.  The first argument is the type:

=over 4

=item public

Entry will be readable by anyone

=item private

Entry will be readable only by the journal owner

=item friends

Entry will be readable only by the journal owner's friends

=item group

Entry will be readable only by the members of the given groups.

=back

=head2 get_access

Returns the access information for the entry.  It will always return the type
as defined above in the C<set_access> method.  In addition for the C<group>
type the list of groups will also be returned:

 my($type, @groups) = $event-E<gt>get_access

=head1 SEE ALSO

L<WebService::LiveJournal>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
