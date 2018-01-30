# Copyrights 2003-2018 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution User-Identity.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package User::Identity::Item;
use vars '$VERSION';
$VERSION = '0.99';


use strict;
use warnings;

use Scalar::Util qw/weaken/;
use Carp;


sub new(@)
{   my $class = shift;
    return undef unless @_;       # no empty users.

    unshift @_, 'name' if @_ %2;  # odd-length list: starts with nick

    my %args = @_;
    my $self = (bless {}, $class)->init(\%args);

    if(my @missing = keys %args)
    {   local $" = '", "';
        warn "WARNING: Unknown ".(@missing==1? 'option' : 'options' )
           . " \"@missing\" for a $class\n";
    }

    $self;
}

sub init($)
{   my ($self, $args) = @_;

    unless(defined($self->{UII_name} = delete $args->{name}))
    {   croak "ERROR: Each item requires a name";
    }

    $self->{UII_description} = delete $args->{description};
    $self;
}

#-----------------------------------------


sub name(;$)
{   my $self = shift;
    @_ ? ($self->{UII_name} = shift) : $self->{UII_name};
}

#-----------------------------------------


sub description() {shift->{UII_description}}

#-----------------------------------------


our %collectors =
 ( emails      => 'User::Identity::Collection::Emails'
 , locations   => 'User::Identity::Collection::Locations'
 , systems     => 'User::Identity::Collection::Systems'
 , users       => 'User::Identity::Collection::Users'
 );  # *s is tried as well, so email, system, and location will work

sub addCollection(@)
{   my $self = shift;
    return unless @_;

    my $object;
    if(ref $_[0])
    {   $object = shift;
        croak "ERROR: $object is not a collection"
           unless $object->isa('User::Identity::Collection');
    }
    else
    {   unshift @_, 'type' if @_ % 2;
        my %args  = @_;
        my $type  = delete $args{type};

        croak "ERROR: Don't know what type of collection you want to add"
           unless $type;

        my $class = $collectors{$type} || $collectors{$type.'s'} || $type;
        eval "require $class";
        croak "ERROR: Cannot load collection module $type ($class); $@\n"
           if $@;

        $object = $class->new(%args);
        croak "ERROR: Creation of a collection via $class failed\n"
           unless defined $object;
    }

    $object->parent($self);
    $self->{UI_col}{$object->name} = $object;
}



sub removeCollection($)
{   my $self = shift;
    my $name = ref $_[0] ? $_[0]->name : $_[0];

       delete $self->{UI_col}{$name}
    || delete $self->{UI_col}{$name.'s'};
}



sub collection($;$)
{   my $self       = shift;
    my $collname   = shift;
    my $collection
      = $self->{UI_col}{$collname} || $self->{UI_col}{$collname.'s'} || return;

    wantarray ? $collection->roles : $collection;
}



sub add($$)
{   my ($self, $collname) = (shift, shift);
    my $collection
     = ref $collname && $collname->isa('User::Identity::Collection')
     ? $collname
     : ($self->collection($collname) || $self->addCollection($collname));

    unless($collection)
    {   carp "No collection $collname";
        return;
    }

    $collection->addRole(@_);
}


sub type { "item" }


sub parent(;$)
{   my $self = shift;
    return $self->{UII_parent} unless @_;

    $self->{UII_parent} = shift;
    weaken($self->{UII_parent});
    $self->{UII_parent};
}


sub user()
{   my $self   = shift;
    my $parent = $self->parent;
    defined $parent ? $parent->user : undef;
}

#-----------------------------------------


sub find($$)
{   my $all        = shift->{UI_col};
    my $collname   = shift;
    my $collection
     = ref $collname && $collname->isa('User::Identity::Collection') ? $collname
     : ($all->{$collname} || $all->{$collname.'s'});

    defined $collection ? $collection->find(shift) : ();
}

1;

