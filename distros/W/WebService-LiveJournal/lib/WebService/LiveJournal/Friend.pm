package WebService::LiveJournal::Friend;

use strict;
use warnings;
use WebService::LiveJournal::Thingie;
our @ISA = qw/ WebService::LiveJournal::Thingie /;

# ABSTRACT: LiveJournal friend class
our $VERSION = '0.08'; # VERSION


sub new
{
  my $ob = shift;
  my $class = ref($ob) || $ob;
  my $self = bless { }, $class;

  my %arg = @_;
  $self->{username} = $arg{username};  # req
  $self->{fullname} = $arg{fullname};  # req
  $self->{bgcolor} = $arg{bgcolor};  # req
  $self->{fgcolor} = $arg{fgcolor};  # req
  $self->{type} = $arg{type};    # opt
  $self->{groupmask} = $arg{groupmask};  # req

  return $self;
}


sub name { shift->username(@_) }
sub username { $_[0]->{username} }
sub fullname { $_[0]->{fullname} }
sub bgcolor { $_[0]->{bgcolor} }
sub fgcolor { $_[0]->{fgcolor} }
sub type { $_[0]->{type} }
sub groupmask { $_[0]->{groupmask} }
sub mask { $_[0]->{groupmask} }

sub as_string { '[friend ' . $_[0]->{username} . ']' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::LiveJournal::Friend - LiveJournal friend class

=head1 VERSION

version 0.08

=head1 SYNOPSIS

 use WebService::LiveJournal;
 my $client = WebService::LiveJournal->new(
   username => $user,
   password => $pass,
 );
 
 # get the list of your friends
 foreach my $friend (@{ $client->get_friend })
 {
   # $friend isa WS::LJ::Friend
   ...
 }
 
 # get the list of your stalkers, er... I mean people who have you as a friend:
 foreach my $friend (@{ $client->get_friend_of })
 {
   # $friend isa WS::LJ::Friend
   ...
 }

=head1 DESCRIPTION

This class represents a friend or user on the LiveJournal server.

=head1 ATTRIBUTES

=head2 username

The name of the user

=head2 fullname

The full name (First Last) of the user

=head2 bgcolor

The background color for the user

=head2 fgcolor

The foreground color for the user

=head2 type

The type of user

=head2 mask

The group mask of the user

=head1 SEE ALSO

L<WebService::LiveJournal>,

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
