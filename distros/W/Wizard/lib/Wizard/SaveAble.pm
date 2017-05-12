# -*- perl -*-
#
#   Wizard - A Perl package for implementing system administration
#            applications in the style of Windows wizards.
#
#
#   This module is
#
#           Copyright (C) 1999     Jochen Wiedmann
#                                  Am Eisteich 9
#                                  72555 Metzingen
#                                  Germany
#
#                                  Email: joe@ispsoft.de
#                                  Phone: +49 7123 14887
#
#                          and     Amarendran R. Subramanian
#                                  Grundstr. 32
#                                  72810 Gomaringen
#                                  Germany
#
#                                  Email: amar@ispsoft.de
#                                  Phone: +49 7072 920696
#
#   All Rights Reserved.
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   $Id$
#

use strict;

use Symbol ();
use Data::Dumper ();
use IO::AtomicFile ();
use File::Basename ();
use File::Path ();

package Wizard::SaveAble;

$Wizard::SaveAble::VERSION = '0.01';


=pod

=head1 NAME

    Wizard::SaveAble - A package for automatically saved objects.


=head1 SYNOPSIS

    # Tell a SaveAble object that it's modified
    $obj->Modified(1);

    # Tell the SaveAble object to store itself back to disk
    $obj->Store();


=head1 DESCRIPTION

An object of the class Wizard::SaveAble is something that knows whether
it has to be saved or not. To that end it offers methods like I<Modified>
and I<Store>.


=head1 CLASS INTERFACE

All methods are throwing a Perl exception in case of errors.


=head2 Constructors

  # Create an empty SaveAble object and associate a file name to it.
  my $obj = Wizard::SaveAble->new('file' => $file);

  # Load a SaveAble object from a file.
  my $obj = Wizard::SaveAble->new($file);

  # Same thing, but creating an empty object if $file doesn't exist
  my $obj = Wizard::SaveAble->new('file' => $file, 'load' => 1);

(Class method) There are two possible constructors for the
I<Wizard::SaveAble> class: The first is creating an empty object, you
typically use a subclass of I<Wizard::SaveAble> here. The most important
attribute is the I<file> name where the object should later be stored.

The other constructor is loading an already existing object from a file.
The object is automatically blessed into the same class again, typically
a subclass of Wizard::SaveAble.

=cut

sub _load {
    my $proto = shift; my $file = shift;
    my $self = do $file;
    die "Failed to load Wizard::SaveAble object from $file: $@" if $@;
    die "Error while loading $file: Object returned is not an instance"
	. " of Wizard::SaveAble: " . (defined($self) ? $self : "undef")
	    unless UNIVERSAL::isa($self, "Wizard::SaveAble");
    $self->Modified(0);
    $self->File($file);
    $self;
}

sub new {
    my $proto = shift;
    return $proto->_load(shift) if @_ == 1;
    my $self = { @_ };
    my $file = delete $self->{'file'} if (exists($self->{'file'}));
    if (exists($self->{'load'})  and  delete $self->{'load'}) {
	return $proto->_load($file) if $file and -f $file;
    }
    bless($self, (ref($proto) || $proto));
    $self->Modified(1);
    $self->File($file);
    $self->CreateMe($file);
    $self;
}

sub CreateMe {
    my $self = shift;
    $self->{'_wizard_saveable_createme'} = shift if @_;
    $self->{'_wizard_saveable_createme'};
}

=pod

=head2 Setting and Querying an objects status

  # Tell an object that it's modified
  $obj->Modified(1);
  # Query whether an object is modified
  $modified = $obj->Modified()

(Instance methods) The I<Modified> method is used to determine whether an
object needs to be saved or not.

=cut

sub Modified {
    my $self = shift;
    if (@_) {
	if (shift) {
	    $self->{'_wizard_saveable_modified'} = 1;
	} else {
	    delete $self->{'_wizard_saveable_modified'};
	}
    }
    exists($self->{'_wizard_saveable_modified'});
}


=pod

=head2 Setting and Querying an objects file name

  # Set the objects associated file
  $obj->File($file);
  # Query the objects associated file
  $file = $obj->File();

(Instance methods) The I<Modified> method is used to determine whether an
object needs to be saved or not.

=cut

sub File {
    my $self = shift;
    $self->{'_wizard_saveable_file'} = shift if @_;
    $self->{'_wizard_saveable_file'};
}


=pod

=head2 Storing an object to disk

  $obj->Store();

(Instance Method) The object is stored back to disk into the file that
was fixed within the constructor.

=cut

sub Store {
    my $self = shift;

    # Create a copy of the object to work with it.
    my $copy = { %$self };
    bless($copy, ref($self));

    return unless delete $copy->{'_wizard_saveable_modified'};

    delete $copy->{'_wizard_saveable_createme'};
    my $file = delete $copy->{'_wizard_saveable_file'};
    my $dir = File::Basename::dirname($file);
    die "Failed to create directory $dir: $!"
	unless -d $dir  ||  File::Path::mkpath([$dir], 0, 0644);

    my $dump = Data::Dumper->new([$copy], ['obj']);
    $dump->Indent(1);
    my $fh = IO::AtomicFile->open($file, "w")
	or die "Failed to create file $file: $!";
    if (!$fh->print("my ", $dump->Dump())  ||  !$fh->close()) {
	my $msg = $!;
	$fh->delete();
	die "Failed to write file $file: $msg";
    }
    $self->Modified(0);
}


=pod

=head1 AUTHORS AND COPYRIGHT

This module is

  Copyright (C) 1999     Jochen Wiedmann
                         Am Eisteich 9
                         72555 Metzingen
                         Germany

                         Email: joe@ispsoft.de
                         Phone: +49 7123 14887

                 and     Amarendran R. Subramanian
                         Grundstr. 32
                         72810 Gomaringen
                         Germany

                         Email: amar@ispsoft.de
                         Phone: +49 7072 920696

All Rights Reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.


=head1 SEE ALSO

L<Wizard(3)>, L<Wizard::State(3)>

=cut

