#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2003 Sergey Rusakov.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
#
#----------------------------------------------------------------------------


package ePortal::App::MsgForum;
    our $VERSION = '4.2';
	use base qw/ePortal::Application/;

	# use system modules
	use ePortal::Global;
	use ePortal::Utils;
	use ePortal::ThePersistent::Support;

	# use internal Application modules
	use ePortal::App::MsgForum::MsgForum;
	use ePortal::App::MsgForum::MsgItem;

    # other modules
    use Text::Wrap;

our @Smiles = (qw/ biggrin confused cool down eek frown gigi insane lamer
        laugh lol mad redface rolleyes rotate shuffle smile smirk spy tongue
        up weep wink /);
our @Smiles2 = (qw/ 2jump beer eyes idea jump love moderator pofig puke super
    /);


#Returns ThePersistent object with a list of available forums with
#additional information such as number of topics and date of last message

############################################################################
sub Forums  {   #11/06/02 9:54
############################################################################
    my $self = shift;

    my ($xacl_where, @xacl_binds) = ePortal::ThePersistent::ExtendedACL::xacl_where('MsgForum.xacl_read','MsgForum.uid');
    my $obj = new ePortal::ThePersistent::Support(
        DBISource => 'MsgForum',
        Attributes => {
            last_message => { dtype => 'DateTime'}
        },
        SQL => "select MsgForum.id, MsgForum.title, MsgForum.memo,
              count(If(MsgItem.prev_id is null or MsgItem.prev_id=0, 1, null)) as topics,
              count(distinct MsgItem.id) as messages,
              max(MsgItem.msgdate) as last_message
          from MsgForum
          left join MsgItem  on forum_id=MsgForum.id",
        GroupBy => "MsgForum.title, MsgForum.id",
        Where => $xacl_where,
        Bind => \@xacl_binds);
   return $obj;
}##Forums


#Returns ThePersistent object with topics of the forum

############################################################################
sub Topics  {   #11/27/02 9:39
############################################################################
    my $self = shift;
    my $forum_id = shift;

    my $obj = new ePortal::ThePersistent::Support(
        DBISource => 'MsgForum',
        Attributes => {
            last_message => { dtype => 'DateTime'}
        },
        SQL => "select MsgItem.id, MsgItem.title, MsgItem.msgdate,
                MsgItem.picture,
                If(MsgItem.fromuser is null, '$guestname',
                  If(epUser.fullname is null, MsgItem.fromuser, epUser.fullname)) as fullname,
                count(distinct mi.id) as replies,
                max(mi.msgdate) as last_message
            from MsgItem
            left join MsgItem mi on MsgItem.id = mi.prev_id
            left join epUser on MsgItem.fromuser = epUser.username",
        GroupBy => 'MsgItem.id',
        OrderBy => 'MsgItem.msgdate desc',
        Where => "(MsgItem.prev_id is null or MsgItem.prev_id=0)",
        );

    return $obj;
}##Topics


############################################################################
sub onDeleteUser    {   #11/19/02 2:14
############################################################################
    my $self = shift;
    my $username = shift;
    my $result = 0;

    my $dbh = $self->dbh;

    # Remove user's subscription to any forum
    $result = 0+ $dbh->do("DELETE FROM MsgSubscr WHERE username=?", undef, $username);

    return $result;
}##onDeleteUser



# ------------------------------------------------------------------------
# Attributes of MsgSubsc table
#
my %MsgSubsc_Attributes = (
    forum_id => { type => 'ID', dtype => 'Number' },
    username => { type => 'ID', dtype => 'Varchar' }
    );
############################################################################
sub Subscribe   {   #11/25/02 1:09
############################################################################
    my $self = shift;
    my $username = shift;   # user name to subscribe
    my @forums = @_;        # ID of forums for subcribing

    foreach (@forums) {
        $self->dbh->do("DELETE FROM MsgSubscr WHERE forum_id=? and username=?",
            undef, $_, $username);
        $self->dbh->do("INSERT INTO MsgSubscr (forum_id,username) VALUES(?,?)",
            undef, $_, $username);
    }
}##Subscribe

############################################################################
sub Unsubscribe {   #11/25/02 1:17
############################################################################
    my $self = shift;
    my $username = shift;
    my @forums = @_;

    foreach (@forums) {
        $self->dbh->do("DELETE FROM MsgSubscr WHERE forum_id=? and username=?",
            undef, $_, $username);
    }
}##Unsubscribe


#ThePersistent object with forums subscribed to given user

############################################################################
sub ForumsSubscribed    {   #11/25/02 1:50
############################################################################
    my $self = shift;
    my $username = shift || $ePortal->username;

    my $st = new ePortal::ThePersistent::Support(
        Attributes => \%MsgSubsc_Attributes,
        DBISource => 'MsgForum',
        SQL => "SELECT MsgSubscr.forum_id, MsgSubscr.username, MsgForum.title
                FROM MsgSubscr
                LEFT JOIN MsgForum on forum_id=MsgForum.id",
        Where => 'MsgSubscr.username=?',
        Bind => [$ePortal->username],
        OrderBy => 'MsgForum.title');

    return $st;
}##ForumsSubscribed


#ThePersistent object with users subscribed to given forum

############################################################################
sub ForumSubscribers    {   #11/25/02 1:50
############################################################################
    my $self = shift;
    my $forum_id = shift;

    my $st = new ePortal::ThePersistent::Support(
        Attributes => \%MsgSubsc_Attributes,
        DBISource => 'MsgForum',
        SQL => "SELECT MsgSubscr.forum_id, MsgSubscr.username,
                    MsgForum.title,
                    epUser.email, epUser.fullname
                FROM MsgSubscr
                LEFT JOIN epUser on MsgSubscr.username=epUser.username
                LEFT JOIN MsgForum on MsgSubscr.forum_id = MsgForum.id",
        Where => 'MsgSubscr.forum_id=?',
        Bind => [$forum_id]
        );

    return $st;
}##ForumSubscribers


1;
