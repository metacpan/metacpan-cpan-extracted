package WebService::Toggl;

use Module::Runtime qw(use_package_optimistically);

use Moo;
with 'WebService::Toggl::Role::Base';
use namespace::clean;

our $VERSION = "0.11";


has 'me' => (is =>'ro', lazy => 1, builder => 1);
sub _build_me { shift->_new_thing('::API::Me') }


sub workspace      { shift->_new_thing_by_id('::API::Workspace',     @_) }
sub client         { shift->_new_thing_by_id('::API::Client',        @_) }
sub project        { shift->_new_thing_by_id('::API::Project',       @_) }
sub project_user   { shift->_new_thing_by_id('::API::ProjectUser',   @_) }
sub tag            { shift->_new_thing_by_id('::API::Tag',           @_) }
sub task           { shift->_new_thing_by_id('::API::Task',          @_) }
sub time_entry     { shift->_new_thing_by_id('::API::TimeEntry',     @_) }
sub user           { shift->_new_thing_by_id('::API::User',          @_) }
sub workspace_user { shift->_new_thing_by_id('::API::WorkspaceUser', @_) }


sub details { shift->_new_thing('::Report::Details', @_) }
sub summary { shift->_new_thing('::Report::Summary', @_) }
sub weekly  { shift->_new_thing('::Report::Weekly',  @_) }


sub _new_thing {
    my ($self, $class, $args) = @_;
    return use_package_optimistically('WebService::Toggl' . $class)
        ->new({_request => $self->_request, %{$args || {}}});
}

sub _new_thing_by_id { shift->_new_thing(shift, {id => shift}) }

1;
__END__

=encoding utf-8

=head1 NAME

WebService::Toggl - Wrapper for the toggl.com task logging API

=head1 SYNOPSIS

    use WebService::Toggl;

    my $toggl = WebService::Toggl->new({api_key => $ENV{API_KEY}});
    my $me = $toggl->me();
    say "Me: " . $me->fullname . " <" . $me->email . ">:";

    say "My Workspaces:";
    for my $ws ($me->workspaces->all) {
        say "  " . $ws->name . " (" . $ws->id . ")";
        say "    Projects:";
        say "      " . $_->name . " (" . $_->id . ") " for ($ws->projects->all);
    }

=head1 DESCRIPTION

B<< NB: This is a new module, and the API is still under development.
While I'm pretty happy with the current interface, expect the
internals to be heavily refactored before v1.0.  This version
currently only supports read access to the API, but I plan to add
write access in the near future. >>

L<WebService::Toggl> is a perl interface to the
L<Toggl|http://www.toggl.com> API, as described at
L<https://github.com/toggl/toggl_api_docs>.  When a new
C<WebService::Toggl> object is created, it is associated with a
particulars user's credentials via their API token.  The API token can
be found at the bottom of your 'My Profile' on Toggl.  Any new objects
created by the C<WebService::Toggl> object will inherit its credentials.

=head2 Laziness

All C<Webservice::Toggl::API::> and C<WebService::Toggl::Report::>
objects are created lazily.  If you ask for a particular
C<::API::Workspace> object by id, no GET request against the Toggl API
will be issued until you request an attribute that has not yet been set. E.g.

 my $workspace = $toggl->workspace(1234);
 say $workspace->id;  # prints 1234, no GET yet issued
 say $workspace->name; # name is not yet set, will issue GET request

=head2 Raw data

Each C<API::> and C<Report::> object stores the raw response received
from Toggl in an attribute called C<raw>.  If you want to force the
object to fill itself in with data from the API, calling
C<< $object->raw() >> will do so.

=head2 Set objects

Each C<API::> class has a corresponding class that represents a set of
the objects.  These set objects store the raw response query and will
return a list of the objects it comprises via the C<< ->all() >>
method.

=head2 Additional queries

You can make other requests against the Toggle API via the
C<api_{get,post,put,delete}()> methods provided by
L<WebService::Toggl::Role::Base>.  For instance, if you had a
L<WebService::Toggl::API::Tag> object that you wanted to delete, you
could write:

 $tag->api_delete( $tag->my_url );


=head1 METHODS

=head2 API objects

=head3 me()

Returns the L<WebService::Toggl::API::Me> object representing the
authorized user.

=head3 workspace($id)

Returns the L<WebService::Toggl::API::Workspace> object with the given id.

=head3 workspace_user( $id )

Returns the L<WebService::Toggl::API::WorkspaceUser> object with the given id.

=head3 client( $id )

Returns the L<WebService::Toggl::API::Client> object with the given id.

=head3 project( $id )

Returns the L<WebService::Toggl::API::Project> object with the given id.

=head3 project_user( $id )

Returns the L<WebService::Toggl::API::ProjectUser> object with the given id.

=head3 tag( $id )

Returns the L<WebService::Toggl::API::Tag> object with the given id.

=head3 task( $id )

Returns the L<WebService::Toggl::API::Task> object with the given id.

=head3 time_entry( $id )

Returns the L<WebService::Toggl::API::TimeEntry> object with the given id.

=head3 user( $id )

Returns the L<WebService::Toggl::API::User> object with the given id.

=head2 Reports

=head3 details( $args )

Returns the L<WebService::Toggl::Report::Details> object with the
given arguments.

=head3 summary( $args )

Returns the L<WebService::Toggl::Report::Summary> object with the
given arguments.

=head3 weekly( $args )

Returns the L<WebService::Toggl::Report::Weekly> object with the given
arguments.

=head1 LICENSE

Copyright (C) Fitz Elliott.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Fitz Elliott E<lt>felliott@fiskur.orgE<gt>

=cut

