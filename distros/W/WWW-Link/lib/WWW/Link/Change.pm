package WWW::Link::Change;
$REVISION=q$Revision: 1.4 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );

=head1 NAME

WWW::Link::Change - convert messages for link changes 

=head1 SYNOPSIS

B<Not yet implemented>

=head1 DESCRIPTION

Many things can happen to resources at the other end of Links.  This
class provides a way for the owners of resources to send messages to
people who reference those resources.

=head1 POSSIBLE CHANGES

=over 4 

=item updated

the resource is essentially the same but has been updated in some
major unspecified way which a person referencing it might want to
examine.

=item deleted

the resource no longer exists and no replacement is known or
suggested.

=item outdated

The resource is now considered outdated and references to it should be
changed to something else.  This nothing about whether it has been
deleted as old resources are often kept for historical reasons.

=item split

A resourece has been split into parts which are logically separate.
Some references to that resource will want to go one new location and
some to another.

=cut

=head1 METHODS

=head2 new ($message) ($link, newstatus, options)

A WWW::Link::Change can be constructed from either a message from another
entity or from the information needed for that change.  

=head2 as_message

This outputs a string which can be sent and used to construct an
equivalent WWW::Link::Change in another place.  The message is designed so
that it could be used by other languages or even a human.  

=cut
