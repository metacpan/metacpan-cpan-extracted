 package Yote::Server::ListContainer;

#
# Caveats. Be careful
#   * with gather
#   * when using js clearCache
#   * about asyn with  yote object methods
#   * about 'use Foo' for ListContainer list objects
#


use strict;
use warnings;
no warnings 'uninitialized';

use vars qw($VERSION);

$VERSION = '1.0';

use Yote::Server;
use base 'Yote::ServerObj';

# --vvv override -------
sub _allowedUpdates { qw(name notes) } #override returning a list of allowed updates

sub _lists { {} }  # override with list-name -> class

sub _gather {}  # override with extra stuff to send across

sub _init {
    my $self = shift;
    my $listhash = $self->_lists;
    for my $list (keys %$listhash) {
        $self->set( $list, [] );
    }
}

sub _calculate {}  #override

# --^^^ override -------

sub _valid_choice { return 1; }

sub _addEditAccess {
    my( $self, $acct ) = @_;
    my $acls = $self->get__acls({});
    $acls->{$acct} = 1;
    $self->set__has_acls( 0 < keys %$acls );
}
sub _removeEditAccess {
    my( $self, $acct ) = @_;
    my $acls = $self->get__acls({});
    delete $acls->{$acct};
    $self->set__has_acls( 0 < keys %$acls );
}

sub __allowedUpdates {
    my $self = shift;
    die "Cant update" if $self->get__has_acls && ! $self->get__acls->{$self->{SESSION}{acct} };
    $self->{__ALLOWED} //= { map { $_ => 1 } ($self->_allowedUpdates) };
}

sub update {
    my( $self, $updates ) = @_;
    my %allowed = %{$self->__allowedUpdates};
    for my $fld (keys %$updates) {
        die "Cant update '$fld' in ".ref($self) unless $allowed{$fld};
        my $val = $updates->{$fld};
        die "Cant update '$fld' to $val in " . ref($self) 
            unless $self->_valid_choice($fld,$val);
        $self->set( $fld, $val )
    }
    $self->_calculate( 'update', $updates );
} #update

sub add_entry {
    my( $self, $listName, $obj ) = @_;
    
    my $class = $self->_lists->{$listName};
    
    die "Unknown list '$listName' in ".ref($self) unless $class;
    die "Cannot add this choice to list $listName in ".ref($self) 
        unless $self->_valid_choice( $listName, $obj );

    my $list = $self->get( $listName, [] );
    $obj //= $self->{STORE}->newobj( {
        parent => $self,
        name   => $listName.' '.(1 + @$list),
                                        },$class  );
    $obj->get_parent( $self );

    push @$list, $obj;
    $obj->_calculate( 'added_to_list', $listName, $self );
    $self->_calculate( 'new_entry', $listName, $obj, scalar(@$list) );
    $obj, $obj->gather;
} #add_entry

sub gather {
    my $self = shift;
    my $seen = shift || {};
    return if $seen->{$self->{ID}}++;
    my $listhash = $self->_lists;
    my @res;
    for my $list (keys %$listhash) {
        my $l = $self->get( $list, [] );
        push @res, $l, (map { $_, $_->gather($seen) } grep { ref($_) } @$l);
    }
    @res, $self->_gather( $seen );
} #gather

sub remove_entry {  #TODO - paramertize this like add_entry does
    my( $self, $item, $from, $moreArgs ) = @_;
    die "Unknown list '$from' in ".ref($self) unless $self->_lists->{$from};
    my $list = $self->get($from);
    my $i = 0;
    my $removed;
    for( $i=0; $i<@$list; $i++ ) {
        if( $list->[$i] == $item ) {
            $removed = splice @$list, $i, 1;
            last;
        }
    }
    $self->_calculate( 'removed_entry', $from, $removed, $i );

} #remove_entry

# TODO - implement a copy?
1;

__END__
