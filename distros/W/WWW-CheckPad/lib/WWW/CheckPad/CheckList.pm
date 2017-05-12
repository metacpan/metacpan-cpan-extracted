package WWW::CheckPad::CheckList;

use strict;
use warnings;
use Carp;
use Class::Accessor;
use WWW::CheckPad::CheckItem;
use WWW::CheckPad::Base;
use WWW::CheckPad::ListParser;
use base qw(Class::Accessor
            WWW::CheckPad::Base
        );


__PACKAGE__->mk_accessors(qw(
                             id
                             title
                         ));

sub _entity {
    my ($class, %value_of) = @_;
    my $self = bless {}, $class;

    $self->id($value_of{id});
    $self->title($value_of{title});

    if (not $value_of{ lazy_loading } and $value_of{ id }) {
        $self->_load_checkitems();
    }
    return $self;
}

##############################################################################
## Instance Method
##############################################################################
sub update {
    my $self = shift;

    $self->connection->_clear_cookie_of('sys_msg');
    my $content = $self->connection->_request({
        path => '/',
        form => {
            mode => 'pjt',
            act => 'edit',
            id => $self->id,
            ttl => $self->title,
        }
    });
    my $sys_msg = $self->connection->_get_cookie_of('sys_msg');
    croak "There was error while inserting new CheckList: " . $sys_msg if ($sys_msg);
    
    return $self;
}


sub delete {
    my $self = shift;

    $self->connection->_clear_cookie_of('sys_msg');
    my $response = $self->connection->_request({
        path => '/',
        form => {
            mode => 'pjt',
            act => 'del',
            id => $self->id,
        }
    });

    my $sys_msg = $self->connection->_get_cookie_of('sys_msg');

    croak "There was error while inserting new CheckList."if (not $sys_msg);

    $self->id(0);
    $self->title(q{});
}


sub add_checkitem {
    my ($self, $checkitem_title) = @_;

    my $current_checkitems = $self->checkitems();

    ## Insert the item to check*pad.
    my $checkitem = WWW::CheckPad::CheckItem->_insert(
        $self,
        $checkitem_title
    );

    ## push into the cached items.
    push @{$current_checkitems}, $checkitem;

    return $checkitem;
}


sub checkitems {
    my ($self) = @_;

    unless ($self->{_cp_loaded_checkitems}) {
        $self->_load_checkitems();
    }
    return $self->{_cp_loaded_checkitems} ?
        (wantarray) ? @{$self->{_cp_checkitems}} : $self->{_cp_checkitems} :
            undef;
}


sub _remove_checkitem_from_cache {
    my ($self, $checkitem_to_be_removed) = @_;
    my $checkitems = $self->checkitems;
    ## TODO: Doesn't look like good way to remove the value from array.

 SEARCH:
    foreach my $n (0..$#{$checkitems}) {
        my $checkitem = $checkitems->[$n];
        if ($checkitem->id == $checkitem_to_be_removed->id) {
            splice @{$checkitems}, $n, 1;
            last SEARCH;
        }
    }
}

##############################################################################
## Class Method
##############################################################################
sub retrieve_all {
    my ($class) = @_;

    croak "Have to login before calling retrieve_all()."
        unless ($class->connection and $class->connection->has_logged_in);

    my $response = $class->connection->_request({
        path => '',
        form => {
            mode => 'pjt',
            act => 'sort'
        }
    });

    # parse the contents with ListParser.
    my $parser = WWW::CheckPad::ListParser->new();
    my @check_list_infos = @{$parser->convert_to_item($response->content)};
    my @check_lists;
    foreach my $check_list_info (@check_list_infos) {
        my $check_list = WWW::CheckPad::CheckList->_entity(
            id => $check_list_info->{id},
            title => $check_list_info->{title}
        );
        push @check_lists, $check_list;
    }

    return @check_lists;
}


sub retrieve {
    my ($class, $id) = @_;

    croak "Have to call retrieve with ID of ChechList." unless $id;

    # Currently, we don't have no way to get only one CheckList.
    # So, just get all and filter afterword.
    foreach my $check_list ($class->retrieve_all()) {
        return $check_list if $check_list->id == $id
    }
    return undef;
}


sub insert {
    my $class = shift;
    my $checklist = undef;

    ## TODO: Reduce if-elsif-else ...
    if (ref $_[0] eq 'HASH') {
        $checklist = WWW::CheckPad::CheckList->_entity(title => $_[0]->{title});
    }
    elsif (not defined ref $_[0]) {
        $checklist = WWW::CheckPad::CheckList->_entity(title => $_[0]);
    }
    else {
        $checklist = $_[0];
    }

    $class->connection->_clear_cookie_of('sys_msg');
    my $response = $class->connection->_request({
        path => 'index.php',
        form => {
            mode => 'pjt',
            act => 'add',
            ajax => 1,
            ttl => $checklist->title,
        }
    });
    $checklist->title($class->connection->_jconvert($checklist->title, 'euc-jp'));
    
    my $sys_msg = $class->connection->_get_cookie_of('sys_msg');
    croak "There was error while inserting new CheckList." if (not $sys_msg);

    if ($response->header('location') =~ /id=([0-9]+)&/) {
        $checklist->id($1);
    }
    else {
        croak "There were error while inserting new CheckList.";
    }

    return $checklist;
}




sub _load_checkitems {
    my ($self) = @_;

    croak "Have to set id before loading checkitems from server." unless ($self->id);

    ## TODO: Should check return value or cache exception to handle error.
    my @checkitems = WWW::CheckPad::CheckItem->retrieve_all_of($self->id);
    $self->{_cp_checkitems} = \@checkitems;
    $self->{_cp_loaded_checkitems} = 1;

    return $self->{_cp_loaed_checkitems};
}


##############################################################################
1;
__END__

=head1 NAME

WWW::CheckPad::CheckList - A class to control checklist of check*pad.

=head1 SYNOPSIS

See the WWW::CheckPad

=head1 DESCRIPTION

WWW::CheckPad::CheckList will manage the check list of check*pad.
You can create/read/update/delete the checklist from this class.
And also you can create/read the checkitem (See also WWW::CheckPad::CheckItem).


=head2 Class Method

=item retrieve_all

  my @checklists = WWW::CheckPad::CheckList->retrieve_all();

C<retrieve_all> will return all of checklist that current user have.

=item retrieve

  my $checklist = WWW::CheckPad::CheckList->retrieve($checklist_id);

C<retrieve> will return the checklist object which id is $checklist_id.
Of course this checklist have to be current users's checklist. If it 
couldn't find the checklist from your checklist, it will return undef.

=item insert

  my $checklist = WWW::CheckPad::CheckList->insert({title => 'title of list'});

Create new check list and return it.

=head2 Instance Method

=item update

  $checklist->update();

Will update the information which C<$checklist> has. The only information you
can update is C<title>, so you will use update like this:

  $checklist->title('update title'); ## update the title
  $checklist->update();

=item delete

  $checklist->delete();

Just simply delete the check list.

=item add_checkitem

  my $checkitem = $checklist->add_checkitem('new todo item');

Will add new check item to this check list.

=item checkitems

  my @checkitems = $checklist->checkitems();

Will return all of check items which this check list has.

=head1 SEE ALSO

WWW::CheckPad

WWW::CheckPad::CheckItem

=head1 AUTHOR

Ken Takeshige, E<lt>ken.takeshige@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Ken Takeshige

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

