package Wiki::Toolkit::Plugin;

use strict;

use vars qw( $VERSION );
$VERSION = '0.04';

=head1 NAME

Wiki::Toolkit::Plugin - A base class for Wiki::Toolkit plugins.

=head1 DESCRIPTION

Provides methods for accessing the backend store, search and formatter
objects of the L<Wiki::Toolkit> object that a plugin instance is
registered with.

=head1 SYNOPSIS

  package Wiki::Toolkit::Plugin::Foo;
  use base qw( Wiki::Toolkit::Plugin);

  # And then in your script:
  my $wiki = Wiki::Toolkit->new( ... );
  my $plugin = Wiki::Toolkit::Plugin::Foo->new;
  $wiki->register_plugin( plugin => $plugin );
  my $node = $plugin->datastore->retrieve_node( "Home" );

=head1 POSSIBLE METHODS

=over 4

=item B<pre_moderate>

  Called before moderation is performed.
  Allows changes to the parameters used in moderation.

  my %args = @_;
  my ($name_ref,$version_ref) = @args{ qw( node version ) };
  $$name_ref =~ s/\s/_/g;
  return 0;

=item B<post_moderate>

  Called after moderation has been performed.
  Allows additional actions to occur after node moderation.

  my %args = @_;
  my ($node,$node_id,$version) = 
     @args{ qw( node node_id version ) };
  &update_pending_list($node,$version);

=item B<pre_rename>

  Called before a rename is performed.
  Allows changes to the parameters used by rename.

  my %args = @_;
  my ($old_name_ref,$new_name_ref,$create_new_versions_ref) = 
     @args{ qw( old_name new_name create_new_versions ) };
  $$old_name_ref =~ s/\s/_/g;
  $$new_name_ref =~ s/\s/_/g;
  return 0;

=item B<post_rename>

  Called after a rename has been performed.
  Allows additional actions to occur after node renames.

  my %args = @_;
  my ($old_name,$new_name,$node_id) =
     @args{ qw( old_name new_name node_id ) };
  &recalculate_category_listings();

=item B<pre_retrieve>

  Called before a retrieve is performed.
  Allows changes to the parameters used by retrieve.

  my %args = @_;
  my ($name_ref,$version_ref) = @args{ qw( node version ) };
  return &check_retrive_allowed($$name_ref);

  TODO: Allow declining of the read.

=item B<pre_write>

  Called before a write is performed.
  Allows changes to the parameters used by the write;

  my %args = @_;
  my ($node_ref,$content_ref,$metadata_ref) = 
      @args{ qw( node content metadata ) };
  $$content_ref =~ s/\bpub\b/Pub/g;
  return 1;

=item B<post_write>

  Called after a write has been performed.
  Allows additional actions to occur after node writes.

  my %args = @_;
  my ($node,$node_id,$version,$content,$metadata) =
     @args{ qw( node node_id version content metadata ) };
  &log_node_write($node,gmtime);

=item B<post_delete>

  Called after a delete has been performed.
  Allows additional actions to occur after node deletions.

  my %args = @_;
  my ($node,$node_id,$version) = 
     @args{ qw( node node_id version ) };
  &log_node_delete($node,gmtime);

=back

=head1 DECLINING ACTIONS FROM PRE_ METHODS

  Note: This functionality is missing for pre_retrieve

  It is possible for the pre_ methods (eg C<pre_write>) to
  decline the action. This could be due to an authentication
  check done by the plugin, due to the content, or whatever else
  the plugin fancies. There are three possible return values from
  a pre_ plugin:

  C<-1> - Deny this action
  C<0> or C<undef> - I have no opinion
  C<1> - Allow this action

  If you have only zeros, the action will be allowed. If you have ones
  and zeros, it will also be allowed.

  If you have minus ones and zeros, it will be denied. If you have minus
  ones, ones and zeros, the sum will be used to decide. 

  For default deny, have one plugin return -1, and another only return 1 
  if the action is explicity allowed)

=head1 METHODS

=over 4

=item B<new>

  sub new {
      my $class = shift;
      my $self = bless {}, $class;
      $self->_init if $self->can("_init");
      return $self;
  }

Generic contructor, just returns a blessed object.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->_init if $self->can("_init");
    return $self;
}

=item B<wiki>

Returns the Wiki::Toolkit object, or C<undef> if the C<register_plugin>
method hasn't been called on a L<Wiki::Toolkit> object yet.

=cut

sub wiki {
    my $self = shift;
    $self->{_wiki} = $_[0] if $_[0];
    return $self->{_wiki};
}

=item B<datastore>

Returns the backend store object, or C<undef> if the C<register_plugin>
method hasn't been called on a L<Wiki::Toolkit> object yet.

=cut

sub datastore {
    my $self = shift;
    $self->{_datastore} = $_[0] if $_[0];
    return $self->{_datastore};
}

=item B<indexer>

Returns the backend search object, or C<undef> if the
C<register_plugin> method hasn't been called on a L<Wiki::Toolkit> object
yet, or if the wiki object had no search object defined.

=cut

sub indexer {
    my $self = shift;
    $self->{_indexer} = $_[0] if $_[0];
    return $self->{_indexer};
}

=item B<formatter>

Returns the backend formatter object, or C<undef> if the C<register_plugin>
method hasn't been called on a L<Wiki::Toolkit> object yet.

=cut

sub formatter {
    my $self = shift;
    $self->{_formatter} = $_[0] if $_[0];
    return $self->{_formatter};
}

=back

=head1 SEE ALSO

L<Wiki::Toolkit>

=head1 AUTHOR

Kake Pugh (kake@earth.li).

=head1 COPYRIGHT

     Copyright (C) 2003-4 Kake Pugh.  All Rights Reserved.
     Copyright (C) 2006 the Wiki::Toolkit team. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
