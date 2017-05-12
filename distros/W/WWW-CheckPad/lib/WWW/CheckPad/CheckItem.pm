package WWW::CheckPad::CheckItem;

use strict;
use warnings;
use Carp;
use Class::Accessor;
use WWW::CheckPad::Base;
use WWW::CheckPad::TodoParser;
use base qw(Class::Accessor
            WWW::CheckPad::Base
        );

__PACKAGE__->mk_accessors(qw(
                             id
                             title
                             is_finished
                             finished_time
                             checklist
                         ));

# DO NOT USE THIS.
sub _new {
    my ($class, %value_of) = @_;
    my $self = bless {}, $class;

    $self->id($value_of{id});
    $self->title($value_of{title});

    return $self;
}


## Creates insntance without inserting to the server.
sub _entity {
    my ($class, %value_of) = @_;
    my $self = bless {}, $class;

    $self->id($value_of{id});
    $self->title($value_of{title});
    $self->is_finished($value_of{is_finished});
    $self->finished_time($value_of{finished_time});
    $self->checklist($value_of{checklist});

    return $self;
}



##############################################################################
## Instance Method
##############################################################################

sub update {
    my $self = shift;
    
    croak("User haven't logged in") unless $self->connection->has_logged_in;

    $self->connection->_clear_cookie_of('sys_msg');
    my $response = $self->connection->_request({
        path => '/',
        encoding => 'utf8',
        form => {
            mode => 'ms',
            act => 'edit',
            id => $self->id,
            ttl => $self->title
        }
    });

    ## Error handling.
    if ($response->content =~ /DB *Error/) {
        croak "There were error during updating CheckItem(id=".$self->id.").";
    }

    return 1;
}


sub delete {
    my $self = shift;

    croak("User haven't logged in") unless $self->connection->has_logged_in;

    my $action = $self->is_finished() ? 'del_done' : 'del_notyet';
    
    $self->connection->_clear_cookie_of('sys_msg');
    my $response = $self->connection->_request({
        path => '/',
        form => {
            mode => 'ms',
            act => $action,
            id => $self->id(),
        }
    });

    ## Error handling.
    if ($response->content =~ /DB *Error/) {
        croak "There were error during updating CheckItem(id=".$self->id.").";
    }

    $self->checklist->_remove_checkitem_from_cache($self);

    return 1;
}


sub finish {
    my $self = shift;

    croak("User haven't logged in") unless $self->connection->has_logged_in();
    croak("Cannot finish the item which are already finished.") if $self->is_finished();

    my $response = $self->connection->_request({
        path => '/',
        form => {
            mode => 'ms',
            act => 'finish',
            id => $self->id(),
        }
    });
    
    $self->connection->_clear_cookie_of('sys_msg');

    ## Error handling.
    if ($response->content =~ /DB *Error/) {
        croak "There were error during updating CheckItem(id=".$self->id.").";
    }
    $self->is_finished(1);

    return 1;
}


sub unfinish {
    my $self = shift;

    croak("User haven't logged in") unless $self->connection->has_logged_in();
    croak("Cannot unfinish the item which are not yet finished.") unless $self->is_finished();

    my $response = $self->connection->_request({
        path => '/',
        form => {
            mode => 'ms',
            act => 'unfinish',
            id => $self->id(),
        }
    });
    
    $self->connection->_clear_cookie_of('sys_msg');

    ## Error handling.
    if ($response->content =~ /DB *Error/) {
        croak "There were error during updating CheckItem(id=".$self->id.").";
    }
    $self->is_finished(0);
    
    return 1;
}


##############################################################################
## Class Method
##############################################################################
sub retrieve_all_of {
    my ($class) = shift;

    croak "User haven't logged in" unless $class->connection->has_logged_in;

    my $checklist_id = ((ref $_[0]) eq 'WWW::CheckPad::CheckList')?
        $_[0]->id:
        $_[0];

    my $response = $class->connection->_request({
        path => '/',
        form => {
            mode => 'pjt',
            act => 'detail',
            id => $checklist_id
        }
    });
    my $parser = WWW::CheckPad::TodoParser->new();
    my @checkitem_infos = @{$parser->convert_to_item($response->content)};
    my @checkitems = ();


    foreach my $checkitem_info (@checkitem_infos) {
        my $checkitem = WWW::CheckPad::CheckItem->_entity(
            id       => $checkitem_info->{id},
            title    => $checkitem_info->{title},
            is_finished => $checkitem_info->{is_finished},
            finished_time => $checkitem_info->{finished_time},
        );
        push @checkitems, $checkitem;
    }
    return @checkitems;
}


sub _insert {
    my ($class, $checklist, $checkitem_title) = @_;

    croak("User haven't logged in") unless $class->connection->has_logged_in();

    my $response = $class->connection->_request({
        path => 'index.php',
        encoding => 'euc-jp',
        form => {
            mode => 'ms',
            act => 'add',
            ajax => 1,
            pjt_id => $checklist->id,
            ttl => $checkitem_title
        }
    });

    my $new_checkitem_id;
    if ($response->content =~ /<div id="new_id_value".*>([0-9]+)<\/div>/) {
        $new_checkitem_id = $1;
    }
    else {
        croak "There were error while inserting new CheckItem " .
            "(HTML of check*pad might changed).";
    }

    my $checkitem = WWW::CheckPad::CheckItem->_entity(
        id          => $new_checkitem_id,
        title       => $checkitem_title,
        is_finished => 0,
        checklist   => $checklist,
    );

    return $checkitem;
}


sub dumper {
    my ($self, $table, $indent) = @_;

    foreach my $key (keys %{$table}) {
        my $value = $table->{$key};
        if (ref $value eq 'HASH' or (ref $value) =~ /HTTP/) {
            $self->dumper($value, $indent + 4);
        }
        else {
            printf "%s%s = %s(%s)\n", ' ' x $indent, $key, $value, ref $value;
        }
    }
}



##############################################################################
1;
__END__

=head1 NAME

WWW::CheckPad::CheckItem - A class to control check item of check*pad.

=head1 SYNOPSIS

See the WWW::CheckPad

=head1 DESCRIPTION

This class will control the check item.

=head2 Class Method

=item retrieve_all_of

  my @checkitems = WWW::CheckPad::CheckItem->retrieve_all_of($chechlist_id);

C<retrieve_all_of> will return all of check item that is related to 
C<$checklist_id>. You don't need to use this directry usually. You 
better use $checklist->checkitems() instead.

=head2 Instance Method

=item update

  $checkitem->update();

Will update the information which C<$checkitem> has. The only information you
can update is C<title>, so you will use update like this:

  $checkitem->title('update title'); ## update the title
  $checkitem->update();

=item delete

  $checkitem->delete();

Just simply delete the check item.

=item finish

  $checkitem->finish();

Change the status of todo to "Finished".

=item unfinish

  $checkitem->unfinish();

Change the status of todo to "Unfinished".

=head1 SEE ALSO

WWW::CheckPad

WWW::CheckPad::CheckList


=head1 AUTHOR

Ken Takeshige, E<lt>ken.takeshige@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Ken Takeshige

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut


