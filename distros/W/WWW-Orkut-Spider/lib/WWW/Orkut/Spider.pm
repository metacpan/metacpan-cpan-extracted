package WWW::Orkut::Spider;

use 5.008002;
use strict;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use WWW::Orkut::Spider ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
    new
    login
    logout
    name
    users
    get_myfriends
    get_hisfriends
    get_friendsfriends
    get_xml_friendslist
    get_xml_communities
    get_xml_profile
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';


# Preloaded methods go here.
use WWW::Mechanize;
use HTML::Entities;
use HTML::Entities qw(encode_entities_numeric);
use Carp;
=head1 NAME

WWW::Orkut::Spider - Perl extension for spidering the orkut community

=head1 SYNOPSIS

        use WWW::Orkut::Spider;
        my $orkut = WWW::Orkut::Spider->new;
        $orkut->login($user,$pass);
        $orkut->get_hisfriends($uid);
        print $orkut->get_xml_profile($uid);


=head1 DESCRIPTION

        WWW::Orkut::Spider uses WWW:Mechanize to scrape orkut.com.
        Output is a simple xml format containing friends, communities and profiles for a given Orkut UID.

        - Access to orkut.com via WWW::Mechanize
        - Collects UIDs
        - Fetches Profiles/Communities/Friends for a given UID
        - Output via simple xml format

=head2  new (proxy)

        You can specify a Proxy Server here
        i.e: http://www.proxy.de:8080/
         or: undef

=cut
sub new {
        my $class = shift;
        my $self = {};
        $self->{proxy} = shift;
        $self->{useragent} = 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.5) Gecko/20031107 Galeon/1.3.11a (Debian package 1.3.11a-2)';

        return bless $self,$class;
}

=head2 login (user,pass)
        
        login orkut as user with pass
        return undef if unseccessful

=cut
sub login {
        my $self=shift;
        $self->{user}=shift;
        $self->{pass}=shift;

        $self->{agent} = WWW::Mechanize->new( autocheck => 1, 
                                              agent => $self->{useragent}, 
                                            );
        $self->{agent}->proxy( 'http', $self->{proxy} );
        
        # get main page
        $self->{agent}->get ('http://www.orkut.com/');
        unless ($self->{agent}->success) {
                croak "Can't even get the main page: ", $self->{agent}->response->status_line;
                return;
        }
                
        # submit login form
        $self->{agent}->submit_form( fields      => { u => $self->{user}, p => $self->{pass}, });
        sleep 1;

        # goto home page
        unless ( $self->{agent}->get("/Home.aspx") ) {
                croak "cannot get users home page";
                return;
        }
        return 1;
}

=head2 logout
        
        logout of orkut

=cut
sub logout {
        my $self=shift;
        $self->{agent}->follow('Logout'); 
}

=head2 name (uid)
        
        return name of given known uid

=cut
sub name {
        my $self = shift;
        my $uid = shift;
        return $self->{users}{$uid};
}

=head2 users
        
        return array with all known uids

=cut
sub users {
        my $self=shift;
        return keys %{$self->{users}};
}

=head2 xml (tag,value)
        
        return a simple
        <tag>value</tag>

=cut
sub xml {
        my $tag = shift;
        my $val = encode_entities_numeric(shift);
        return "\t<$tag>$val</$tag>\n";
}

=head2  get_myfriends

        only after login
        follow the link to friendslist
        and get friends uids
        return 1 if success

=cut
sub get_myfriends {
        my $self=shift;

        unless ( $self->{agent}->follow_link( url_regex => qr/FriendsList/ ) ) {
                croak "cannot follow link to FriendsList";
                return;
        }
        my $users = $self->follow_friends();
        foreach (keys %{$users}) {
                $self->{users}{$_} = $users->{$_};
        }
        return 1;
}

=head2  get_hisfriends (uid)

        parse uid friends page for more uids

=cut
sub get_hisfriends {
        my $self=shift;
        my $uid = shift;

        unless ( $self->{agent}->get("/FriendsList.aspx?uid=".$uid ) ) {
                croak "cannot get FriendsList.aspx?uid=$uid";
                return;
        }
        my $users = $self->follow_friends();
        foreach (keys %{$users}) {
                $self->{users}{$_} = $users->{$_};
        }
        return 1;
}

=head2 follow_friends

        follow through all friends pages
        called after GET of first friend page

=cut
sub follow_friends {
        my $self = shift;

        # get first page users
        my $users = $self->parse_friends();

        # get avaible pages
        my @links = $self->{agent}->find_all_links(url_regex=> qr/FriendsList.*uid/);
        my @pages;
        foreach my $l (@links) {
                my $uid = $l->[0];
                if ( $uid =~ m/\d+&pno=(\d+)$/ ) {
                        push @pages,$uid unless $1 eq '1';
                }
        }

        # pages
        foreach my $p (@pages) {
                unless ($self->{agent}->get('/'.$p)) {
                        croak "cannot get $p";
                }
                my $users_page = $self->parse_friends();
                %{$users} = (%{$users},%{$users_page});
        }

        return $users;
}

=head2  parse_friends

        parse html page for friends uids
        helper for follow friends
        used after GET FriendList

=cut
sub parse_friends {
        my $self = shift;
        my %users;
        my @links = $self->{agent}->find_all_links(url_regex=> qr/FriendsList.*uid/);
        foreach my $l (@links) {
                next if $l->[1] =~ m/IMG/;
                next if $l->[0] =~ m/\d+&pno=\d+/;
                my $uid= $l->[0];
                $uid =~ s/.*uid=(\d*).*/$1/;
                $users{$uid}=encode_entities_numeric($l->[1]);
        }

        return \%users;
}

=head2  get_friendsfriends (n)

        iterate n times over found uids to find more friends
        more than n=1 seems insane, unlikely to work
        don't let your script crash in this function, WWW::Mechanize may decide to die if orkut.com gets one of its server failures
        FIXME: logout/login all 50 requests may help

=cut
sub get_friendsfriends {
        my $self=shift;
        my $n = shift;
        my %friends;
        my %lookup;

        for (my $i=0;$i<$n;$i++) {
                %friends = undef;
                %friends = %{$self->{users}};
                foreach my $u (keys %friends) {
                        next if $lookup{$u};
                        $lookup{$u}+=1;
                        unless ( $self->{agent}->get("/FriendsList.aspx?uid=".$u) ) {
                            croak "cannot get FriendList of $u.";
                        }
                        my $users = $self->follow_friends();
                        foreach (keys %{$users}) {
                            $self->{users}{$_} = $users->{$_};
                        }
                }
        }
}

=head2  get_xml_profile (uid)

        return profile of uid as simple xml

=cut
sub get_xml_profile {
        my $self = shift;
        my $uid = shift;
        my $xml;

        # get his profile 
        $self->{agent}->get("/Profile.aspx?uid=".$uid);
        foreach ('relationship_status', 'birthday', 'age', 'here_for', 'children', 'ethnicity', 'political_view', 'humor', 'sexual_orientation', 'fashion', 'smoking','drinking','living', 'passions', 'sports', 'activities', 'books', 'music', 'tv_shows', 'movies', 'cuisines', 'email', 'country', 'IM', 'home_phone', 'address_line_1', 'address_line_2', 'webpage') {
                my $tag = $_;
                $tag =~ s/_/ /g;
                if ( $self->{agent}->content() =~ m!>$tag:</td><td>(.*?)</td>!x) { $xml .= xml($tag,$1); }
        }

        # get his karma 
        if ( $self->{agent}->content() =~ m!lblKarma">.*?img/i_t(\d).*img/i_c(\d).*img/i_h(\d).*<b>(\d+)</b>!) { 
                $xml .= xml('trust',$1);
                $xml .= xml('cool',$2);
                $xml .= xml('hot',$3);
                $xml .= xml('fans',$4);
        }
        return $xml;
}

=head2  get_xml_communities (uid)

        return communities of uid as simple xml

=cut
sub get_xml_communities {
        my $self = shift;
        my $uid = shift;
        my $xml;

        # get his communities
        $self->{agent}->get("/ProfileC.aspx?uid=".$uid);
        my @comm = $self->{agent}->find_all_links(url_regex=> qr/Community.aspx?/);
        my @fcomms;
        foreach my $c (@comm) {
                push @fcomms, encode_entities_numeric($c->[1]);
        }
        $xml .= xml('communities',join ',',@fcomms);
        return $xml;
}

=head2  get_xml_friendslist (uid)

        return friendslist of uid as simple xml

=cut
sub get_xml_friendslist {
        my $self = shift;
        my $uid = shift;
        my $xml;

        # similiar to 'get his friends'
        # get first page
        unless ($self->{agent}->get("/FriendsList.aspx?uid=".$uid)) {
                croak "cannot get FriendsList.aspx?uid=$uid";
        }

        my @fuids;
        my $users = $self->follow_friends();
        foreach (keys %{$users}) {
                push @fuids, $_;
        }

        $xml .= xml('friends',join ',',@fuids);
        return $xml;
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 SEE ALSO

        Net::Orkut ( using LWP directly )

=head1 AUTHOR

        mm-pause@manno.name

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by mm-pause@manno.name

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
# vim: ts=8 sw=8
