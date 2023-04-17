# Copyrights 2003-2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution User-Identity.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package User::Identity::Collection;
use vars '$VERSION';
$VERSION = '1.02';

use base 'User::Identity::Item';

use strict;
use warnings;

use User::Identity;
use Carp;

use List::Util    qw/first/;
use Hash::Ordered ();


use overload '""' => sub {
   my $self = shift;
   $self->name . ": " . join(", ", sort map {$_->name} $self->roles);
};


use overload '@{}' => sub { [ shift->roles ] };

#-----------------------------------------


sub type { "people" }


sub init($)
{   my ($self, $args) = @_;

    defined($self->SUPER::init($args)) or return;
    
    $self->{UIC_itype} = delete $args->{item_type} or die;
    tie %{$self->{UIC_roles}}, 'Hash::Ordered';
    my $roles = $args->{roles};
 
    my @roles
     = ! defined $roles      ? ()
     : ref $roles eq 'ARRAY' ? @$roles
     :                         $roles;
 
    $self->addRole($_) foreach @roles;
    $self;
}

#-----------------------------------------


sub roles() { values %{shift->{UIC_roles}} }


sub itemType { shift->{UIC_itype} }

#-----------------------------------------


sub addRole(@)
{   my $self = shift;
    my $maintains = $self->itemType;

    my $role;
    if(ref $_[0] && ref $_[0] ne 'ARRAY')
    {   $role = shift;
        croak "ERROR: Wrong type of role for ".ref($self)
            . ": requires a $maintains but got a ". ref($role)
           unless $role->isa($maintains);
    }
    else
    {   $role = $maintains->new(ref $_[0] ? @{$_[0]} :  @_);
        croak "ERROR: Cannot create a $maintains to add this to my collection."
            unless defined $role;
    }

    $role->parent($self);
    $self->{UIC_roles}{$role->name} = $role;
    $role;
}


sub removeRole($)
{   my ($self, $which) = @_;
    my $name = ref $which ? $which->name : $which;
    my $role = delete $self->{UIC_roles}{$name} or return ();
    $role->parent(undef);
    $role;
}


sub renameRole($$$)
{   my ($self, $which, $newname) = @_;
    my $name = ref $which ? $which->name : $which;

    if(exists $self->{UIC_roles}{$newname})
    {   $self->log(ERROR=>"Cannot rename $name into $newname: already exists");
        return ();
    }

    my $role = delete $self->{UIC_roles}{$name};
    unless(defined $role)
    {   $self->log(ERROR => "Cannot rename $name into $newname: doesn't exist");
        return ();
    }

    $role->name($newname);   # may imply change other attributes.
    $self->{UIC_roles}{$newname} = $role;
}


sub sorted() { sort {$a->name cmp $b->name} shift->roles}

#-----------------------------------------


sub find($)
{   my ($self, $select) = @_;

      !defined $select ? ($self->roles)[0]
    : !ref $select     ? $self->{UIC_roles}{$select}
    : wantarray        ? grep ({ $select->($_, $self) } $self->roles)
    :                    first { $select->($_, $self) } $self->roles;
}

1;

