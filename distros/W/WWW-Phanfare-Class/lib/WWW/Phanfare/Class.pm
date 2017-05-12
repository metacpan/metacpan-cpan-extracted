package WWW::Phanfare::Class;
use Moose;
use MooseX::Method::Signatures;
use WWW::Phanfare::Class::CacheAPI;
use WWW::Phanfare::API;
use WWW::Phanfare::Class::Account;

has 'api_key'       => ( is=>'ro', isa=>'Str', required=>1 );
has 'private_key'   => ( is=>'ro', isa=>'Str', required=>1 );
has 'email_address' => ( is=>'ro', isa=>'Str' );
has 'password'      => ( is=>'ro', isa=>'Str' );
sub _childclass { 'WWW::Phanfare::Class::Account' }

# Initialize account
has 'account' => (
  is         => 'ro',
  isa        => 'WWW::Phanfare::Class::Account',
  lazy_build => 1,
);
sub _build_account {
  my $self = shift;

  my $api = $self->api;

  # Login to create session
  my $session;
  if ( $self->email_address and $self->password ) {
    $session = $api->Authenticate(
      email_address => $self->email_address,
      password      => $self->password,
    );
  } else {
    $session = $api->AuthenticateGuest();
  }

  warn sprintf "*** Error: Could not login: %s\n", $session->{code_value}
    unless $session->{stat} eq 'ok';

  # Create account object with session data
  #my $account = WWW::Phanfare::Class::Account->new(
  my $type = $self->_childclass;
  my $account = $type->new(
    uid => $session->{session}{uid},
    gid => $session->{session}{public_group_id},
    parent => $self,
    name => '',
    id => 0,
  );
  $account->setattributes( $session->{session} );
  return $account;
} 

# Initialize API  
has api => (
  isa        => 'WWW::Phanfare::API',
  is         => 'rw',
  lazy_build => 1,
);
sub _build_api {
  my $self = shift;

  # Create an API Agent
  WWW::Phanfare::Class::CacheAPI->new(
    api_key     => $self->api_key,
    private_key => $self->private_key,
  );
}


# Get a subnode, by name of name.id
#
method get ( Str $name ) {
  $self->account->list;
}

sub AUTOLOAD {
  my $self = shift @_;
  our $AUTOLOAD;

  my $name = $AUTOLOAD;
  $name =~ s/.*:://;

  return $self->get($name);
}


=head1 NAME

WWW::Phanfare::Class - Object interface to Phanfare library

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use WWW::Phanfare::Class;

    $class = WWW::Phanfare::Class->new(
      api_key       => 'secret',
      private_key   => 'secret',
      email_address => 's@c.et',
      password      => 'secret',
    );

    # Site Name
    my($sitename) = $class->account->names;

    # Site Object
    my $site = $class->account->$sitename;

    # Album Names
    my @albums = $site->names;

    # Photo filenames in Album's Main Section
    my @filenames = $site->"Family Vacation"->"Main Section"->Full->names;

    # Upload Image and set Caption
    my $folder = $site->"Family Vacation"->"Main Section"->Full;
    my $image = $folder->add( 'filename.jpg', slurp 'filename.jpg', '2009-09-15T00:00:00' );
    $image->attribute( Caption => 'Family on Vacation' );


=head1 DESCRIPTION

WWW::Phanfare::Class creates an object tree for Phanfare site. Each 
Phanfare object can be referred to by name or by object reference.


=head1 BEFORE GETTING STARTED

Users of this module must possess own Phanfare account and API key.


=head1 TREE HIERARKI

Class is the top object and it has one Account to access data using
Phanfare API.

The tree hierarki is as follows:

=over

    An Account has a nuber of Sites.
    A Site has a number of Years.
    A Year has a number of Albums.
    An Album has a number of Sections.
    A Section has a number of Renditions.
    A Rendition has a number of Images.

=back


=head1 NAME CLASH

In Phanfare it's possible for multiple objects to have same name. For example
multi albums can have same name. In such cases WWW::Phanfare::Class will
append the id on the names that are not uniq. Example:

    Kids Photos
    Family Vacation.12345678
    Family Vacation.12345789


=head1 METHODS

Each object implements the following methods.

=head2 parent

    $object->parent();

The parent object.

=head2 names

    my @childrennames = $object->names;

The names of child objects. For example for an Album it will return the
names of all sections.

=head2 list

    my @children_objects = $object->list;

All child objects.

=head2 get($name)

    my $child = $object->get($name);
    my $child = $object->$name;

Access child object by name. Append ID when there is a name clash.

If no ID is appended on name clash, then a random matching object is
returned.

=head2 add($name, $value?, $date?)

    # Create Branch Node
    $object->add($name);

    # Create Leaf Node
    $object->add($name, $value);

    # Create Image with Date
    $object->add($name, $value, $date);

Create a new child object. When creating a Branch, such as for example an
Album, no value must be set.

For Images, a value can be provided, which is the raw image data.
Date may be optionally provided as well.

=head2 remove($name)

    $object->remove($name);

Remove a child object by name. For certain objects it 
removes all child objects recursive. For example when removing an Album,
it will also remove all Sections and Images belonging to Album.

Removing a Year is not possible as long as there are Albums in the Year.
The Year will be automatically remove when all Albums in the Year have
been removed.

Site and Account cannot be removed.


=head1 ATTRIBUTES

Account. Album, Section and Image objects have attributes.

For classes with attributes, the follow addition attribute accessors are
available to the object.

=head2 attributes

    @attribute_names = $object->attributes;

List of names of attributes.

=head2 setattributes($hashreference)

    $object->setattributes({
        name1 => $value1,
        name2 => $value2,
        ...   => ...,
    });

Set values of multiple attributes.

=head2 attribute($name, $value?)

    $object->attribute( $name => $value );
    $value = $object->attribute( $name );

Read or write an attribute value.


=head1 VALUE

Image raw data is uploaded or downloaded with value accessor.
No other object have value.

=head2 value($data?)

    $image = slurp 'filename.jpg';
    $object->value( $image );
    $image = $object->value;

Get or set image data.

Images can only be upload in Full rendition. All other renditions are
for download only.

=head1 DATES

Dates follow same formats as on Phanfare. Example:

  2009-09-15T00:00:00


=head1 PERFORMANCE CONSIDERATIONS

WWW::Phanfare::API is used for communication with Phanfare Rest/XML API.
Results of queries are each cached for 30 seconds to limit network traffic
and to improve performance.


=head1 SEE ALSO

L<WWW::Phanfare::API>


=head1 AUTHOR

Soren Dossing, C<< <netcom at sauber.net> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-www-phanfare-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Phanfare-Class>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Phanfare::Class


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Phanfare-Class>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Phanfare-Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Phanfare-Class>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Phanfare-Class/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Soren Dossing.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
