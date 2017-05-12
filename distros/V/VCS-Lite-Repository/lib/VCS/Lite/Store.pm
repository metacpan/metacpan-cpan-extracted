package VCS::Lite::Store;

use strict;
use warnings;

our $VERSION = '0.12';

#----------------------------------------------------------------------------

use Carp;
use File::Spec::Functions qw(:ALL);
use Time::Piece;

our $hidden_repos_dir = '.VCSLite';
$hidden_repos_dir = '_VCSLITE' if $^O =~ /vms/i;

#----------------------------------------------------------------------------

sub new {
    my ($pkg, %par) = @_;
    bless \%par,$pkg;
}

sub retrieve {
    my ($self, $path) = @_;

    my $store_file = $self->store_path($path);
    return unless -e $store_file;
    my $obj = $self->load($store_file) or die "Failed to retrieve $path";
    $obj->{store} = $self;
    $obj;
}

sub retrieve_or_create {
    my ($self, $proto) = @_;

    my $path = $proto->path;

    $self->retrieve($path) || $self->create($proto);
}

sub create {
    my ($self, $proto) = @_;

    my $path = $proto->path;

    my ($store_dir, $store_file) = $self->store_path($path);

    if (!-d $store_dir) {
        mkdir $store_dir or croak "Failed to make repository dir $store_dir";
    }

    my $creator = $self->can('user') ? $self->user : $proto->user or croak "Username not specified";

    @{$proto}{qw/store creator created/} = ($self,$creator,localtime->datetime);
    my $class = ref $proto;
    $proto->_mumble("Creating $class $path");
    $proto->save($store_file);
    $proto;
}

sub store_path {
    my ($self,$path,$ext) = @_;

    my ($vol,$dir,$fil) = splitpath(rel2abs($path));
    if ($fil && -d $path) {      # Because of the way splitpath works on Unix
        $dir = catdir($dir,$fil);
        $fil = '';
    }

    if (ref $self) {
        my ($hvol,$hdir) = splitpath($self->{home});
        croak "Wrong volume in attempt to access store for $path"
            if $hvol ne $vol;
        my @dir = splitdir($dir);
        for (splitdir($hdir)) {
            my $dd = shift @dir;
            croak "Outside directory tree: $path" if $dd ne $_;
        }
        ($vol,my $rdir) = splitpath($self->{root});
        $dir = catdir($rdir,@dir);
    } else {
        $dir = catdir($dir,$hidden_repos_dir);
    }

    ($dir, catpath($vol, $dir, $self->repos_name($fil,$ext)));
}

1;

__END__

#----------------------------------------------------------------------------

=head1 NAME

VCS::Lite::Store - Base class for repository persistence stores

=head1 SYNOPSIS

  package mystore;
  use base qw/VCS::Lite::Store/;
  ...

  my $newstore = mystore->new( user => 'fred', password => 'bloggs'...);
  my $rep = VCS::Lite::Repository->new( path => 'src/myfile.c',
                                        store => $newstore );

=head1 DESCRIPTION

The L<VCS::Lite::Repository> version control system offers a choice of
back end storage mechanisms. It is architected such that new back end
stores can be written, that will plug in with the existing classes.
The store is used as an object persistence mechanism for
L<VCS::Lite::Repository> and L<VCS::Lite::Element> objects. The store
can also potentially act as a proxy, giving access to repositories that
live on another machine, or even in another type of version control system.

The store object is passed to the element and repository constructors
VCS::Lite::Repository->new and VCS::Lite::Element->new as the optional
parameter I<store>. Note that this parameter can take a class name
instead, see L<In Situ Stores> below.

=head1 METHODS

=head2 new

The constructor takes a varying list of option value pairs. The exact list
depends on which store class used. These may, for example, include a DBI
connect string, username and password. Here are the ones inplemented in
the base class for use by the YAML and Storable classes:

=over 4

=item *
home

This is the absolute path for the top level directory of the files being
version controlled.

=item *
root

This is for stores like L<VCS::Lite::Store::Storable> and
L<VCS::Lite::Store::YAML>, which persist the elements and repositories
into flat files. This is the top level directory of the store.

=item *
user

All updating operations performed on this store take place on behalf of this
username.

=back

=head2 retrieve

  $store->retrieve( $path);

This is the call which is made by the L<VCS::Lite::Element> and
L<VCS::Lite::Repository> constructors, to retrieve an existing object
from the store. return if the object does not exist.

=head2 create

  $store->create( $proto);

This call writes an object to the store. If this object already exists,
it is overwritten. $proto is a prototype object, with a path and a few
other members populated, already blessed into the right class. The call
returns a persisted, fully populated object.

=head2 retrieve_or_create

  $store->retrieve_or_create( $proto);

Perform a retrieve based on the path attribute of the prototype, or create
a persisted object if it does not already exist in the store.

=head2 save

  $store->save($obj);

Apply updates to persist the object. This method is virtual, i.e. the
subclass is expected to provide the save method.

=head2 load

  $store->load($obj);

Load an object from a persistance store. This method is virtual, i.e. the
subclass is expected to provide the load method.

=head2 store_path

This method is internal to flat file stores. It is used to convert between
the path of a file or directory being version controlled, and the path for
the corresponding store. store_path returns a list of two scalars, which
are a directory and a file. There is an optional parameter of the file type
used by VCS::Lite::Element::Binary; this is passed over to repos_name.

=head2 repos_name

Passed an element name or the empty string, this is a virtual method that
turns this into the filename used to persist the element or repository.

There is also an optional file type parameter, which overrides the default
one for the type of store.

=head1 In Situ Stores

As an alternative to an B<object> as a store, L<VCS::Lite::Repository> and
L<VCS::Lite::Element> can be passed a class name. These use a more limited
type of store that lives in situ inside the directory tree of the files being
versioned. The class name can be shortened by missing off the VCS::Lite::Store::
from the front.

The store lives under 'hidden' directories called .VCSLite or in the case of
VMS _VCSLITE (dots are not permitted in the directory name syntax).

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please send an email to barbie@cpan.org or submit a bug to the
RT system (see link below). However, it would help greatly if you are able to
pinpoint problems or even supply a patch.

http://rt.cpan.org/Public/Dist/Display.html?Name=VCS-Lite-Repository

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

  Original Author: Ivor Williams (RIP)          2002-2009
  Current Maintainer: Barbie <barbie@cpan.org>  2014-2015

=head1 COPYRIGHT

  Copyright (c) Ivor Williams, 2002-2009
  Copyright (c) Barbie,        2014-2015

=head1 LICENCE

This distribution is free software; you can redistribute it and/or
modify it under the Artistic Licence v2.

=cut
