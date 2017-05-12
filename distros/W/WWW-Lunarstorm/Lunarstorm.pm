package Lunarstorm;

$VERSION  = '0.02';
$ABSTRACT = 'Lunarstorm (www.lunarstorm.se) interface';

use strict;
use LWP::UserAgent;
use HTTP::Cookies;
use HTML::TableExtract;
use URI::Escape;

my %Defaults = (
		Username	=> undef,
		Password	=> undef,
		UserID		=> undef,
		CookiePath	=> '.',
		AgentIdent	=> 'Mozilla/4.0 (compatible; MSIE 6.0; Windows 98)'
		);


# Constructor
sub new{
	my ($class, %args) = @_;
	my $self = {};
	bless $self, $class;

	foreach my $key (keys %Defaults){
		$self->{$key} = defined $args{$key} ? $args{$key} : $Defaults{$key};
	}
	$self->{Cookie} = HTTP::Cookies->new(file => "$self->{CookiePath}/cookies.txt", autosave => 1);

	return $self;
}

# Destructor
sub DESTROY{

}


# login()
sub login{
	my $self = shift;

	$self->{Cookie}->load();

	my $ua = LWP::UserAgent->new(keep_alive => 1, timeout => 300);
	$ua->agent($self->{AgentIdent});
	$ua->cookie_jar($self->{Cookie});

	my $req = HTTP::Request->new(POST => 'http://www.lunarstorm.se/log/log_login.asp');
	$req->content_type('application/x-www-form-urlencoded');
	$req->content("username=$self->{Username}&password=$self->{Password}&pejl_mood=0");
	$req->referer('http://www.lunarstorm.se/log/log_outside.asp');
	$req->header('Accept' => 'text/xml,application/xml,application/xhtml+xml,text/html,text/plain');
	$self->{Cookie}->add_cookie_header($req);

	my $res = $ua->request($req);

	if(not ($res->is_success || $res->code == 302)){
		return 0;
	}

	$self->{Cookie}->save();
	return 1;
}


# logout
sub logout{
	my $self = shift;

	my $ua = LWP::UserAgent->new(keep_alive => 1, timeout => 300);
	$ua->agent($self->{AgentIdent});
	$ua->cookie_jar($self->{Cookie});

	my $req = HTTP::Request->new(POST => 'http://www.lunarstorm.se/sys_exit.asp');
	$req->content_type('application/x-www-form-urlencoded');
	$req->referer('http://www.lunarstorm.se/log/log_outside.asp');
	$req->header('Accept' => 'text/xml,application/xml,application/xhtml+xml,text/html,text/plain');
	$self->{Cookie}->add_cookie_header($req);

	my $res = $ua->request($req);

	if(not ($res->is_success || $res->code == 302)){
		return 0;
	}

	return 1;
}


# visitors()
sub visitors{
	my $self = shift;
	my $te = new HTML::TableExtract(depth => 2, count => 0, keep_html => 1);

	my $ua = LWP::UserAgent->new(keep_alive => 1, timeout => 300);
	$ua->agent($self->{AgentIdent});
	$ua->cookie_jar($self->{Cookie});

	my $req = HTTP::Request->new(POST => "http://www.lunarstorm.se/usr/usr_presentationlog.asp?username=$self->{Username}");
	$req->content_type('application/x-www-form-urlencoded');
	$req->referer('http://www.lunarstorm.se/usr/usr_presentation.asp');
	$req->header('Accept' => 'text/xml,application/xml,application/xhtml+xml,text/html,text/plain');
	$self->{Cookie}->add_cookie_header($req);

	my $res = $ua->request($req);

	if(not ($res->is_success || $res->code == 302)){
		return;
	}

	$te->parse($res->as_string);
	my @items=();
	foreach my $ts ($te->table_states){
		foreach my $row ($ts->rows){
			my $item = @$row[1];
			my $userid="";
			my $nick="";
			my $sex="N";
			my $age=0;
			my $city="N/A";
			my $state="N/A";

			if($item=~/userid=(%7B.*%7D)/){
				$userid=uri_unescape($1);
			}

			if($item=~/([\w\d_]+)\W(F|P)(\d+)/i){
				$nick=$1;
				$sex=$2;
				$age=$3;
			}
			$nick=~s/^\s//;
			$nick=~s/\s$//;

			my %item;
			$item{NICK}	= $nick;
			$item{SEX}	= $sex;
			$item{AGE}	= $age;
			$item{CITY}	= $city;
			$item{STATE}	= $state;
			$item{USERID}	= $userid;
			push(@items, \%item);
		}
	}

	shift(@items);
	return @items;
}


# guestbook
sub guestbook{
	my ($self, $page, $userid) = @_;

	$userid	= $self->{UserID} if not defined $userid;
	$page	= 1 if not defined $page;

	my $te = new HTML::TableExtract(depth => 2, count => 0, keep_html => 1);

	my $ua = LWP::UserAgent->new(keep_alive => 1, timeout => 300);
	$ua->agent($self->{AgentIdent});
	$ua->cookie_jar($self->{Cookie});

	my $req = HTTP::Request->new(POST => "http://www.lunarstorm.se/usr/gst_guestbook.asp?userid=$userid&page=$page");
	$req->content_type('application/x-www-form-urlencoded');
	$req->referer('http://www.lunarstorm.se/usr/usr_presentation.asp');
	$req->header('Accept' => 'text/xml,application/xml,application/xhtml+xml,text/html,text/plain');
	$self->{Cookie}->add_cookie_header($req);

	my $res = $ua->request($req);

	if(not ($res->is_success || $res->code == 302)){
		return;
	}

	$te->parse($res->as_string);
	my @gb_items=();
	foreach my $ts ($te->table_states){
		foreach my $row ($ts->rows){
			my $gb_item = @$row[2];
			if(($gb_item=~/\(.*(obesvarat|oläst)\)/) || ($userid ne $self->{UserID})){
				my $userid_a;
				my $guestnr=0;
				my $nick="";
				my $sex="N";
				my $age=0;
				my $city="N/A";
				my $state="N/A";

				if($gb_item=~/userid=({[\dA-F-]*})/){
					$userid_a=$1;
				}
				if($gb_item=~/guestnr=(\d*)/){
					$guestnr=$1;
				}

				$gb_item=~s/<br>/\n/igs;
				$gb_item=~s/<(?:[^>'"]*|(['"]).*?\1)*>//gs;			

				my @tmp = split(/\n/, $gb_item);
				shift(@tmp);
				if($tmp[0]=~/([\w\d_]+)\W(F|P)(\d+) från (.+) i (.+) län/i){
					$nick=$1; $sex=$2; $age=$3;
					$city=$4; $state=$5;
				}
				$nick=~s/^\s//;
				$nick=~s/\s$//;
				shift(@tmp);
				$gb_item=join(' ', @tmp);
				$gb_item=~s/^\s+//g;
				$gb_item=~s/\s+$//g;

				my %item;
				$item{NICK}	= $nick;
				$item{SEX}	= $sex;
				$item{AGE}	= $age;
				$item{CITY}	= $city;
				$item{STATE}	= $state;
				$item{USERID}	= $userid_a;
				$item{GUESTNR}	= $guestnr;
				$item{TEXT}	= $gb_item;
				push(@gb_items, \%item);
			}
		}
	}

	return @gb_items;
}


# sign_guestbook
sub sign_guestbook{
	my ($self, $nick, $userid, $guestnr, $msg) = @_;

	if(not $userid=~/{.*}/){
		$userid = uri_unescape($userid);
	}

	$msg = uri_escape($msg);

	my $ua = LWP::UserAgent->new(keep_alive => 1, timeout => 300);
	$ua->agent($self->{AgentIdent});
	$ua->cookie_jar($self->{Cookie});

	my $req = HTTP::Request->new(POST => 'http://www.lunarstorm.se/usr/gst_store.asp');
	$req->content_type('application/x-www-form-urlencoded');
	$req->content("guestnr=$guestnr&userid=$userid&username=$nick&source=popup&msgbody=$msg");
	$req->referer("http://www.lunarstorm.se/usr/gst_compose.asp?guestnr=$guestnr&userid=$userid&username=$nick");
	$req->header('Accept' => 'text/xml,application/xml,application/xhtml+xml,text/html,text/plain');
	$self->{Cookie}->add_cookie_header($req);

	my $res = $ua->request($req);

	if(not ($res->is_success || $res->code == 302)){
		return 0;
	}

	return 1;
}


# relations
sub relations{
	my ($self, $userid) = @_;

	if(not $userid=~/{.*}/){
		$userid = uri_unescape($userid);
	}

	my $te = new HTML::TableExtract(depth => 2, count => 1, keep_html => 1);

	my $ua = LWP::UserAgent->new(keep_alive => 1, timeout => 300);
	$ua->agent($self->{AgentIdent});
	$ua->cookie_jar($self->{Cookie});

	my $req = HTTP::Request->new(POST => "http://www.lunarstorm.se/usr/fri_friends.asp?userid=$userid");
	$req->content_type('application/x-www-form-urlencoded');
	$req->referer('http://www.lunarstorm.se/usr/usr_presentation.asp');
	$req->header('Accept' => 'text/xml,application/xml,application/xhtml+xml,text/html,text/plain');
	$self->{Cookie}->add_cookie_header($req);

	my $res = $ua->request($req);

	if(not ($res->is_success || $res->code == 302)){
		return;
	}

	$te->parse($res->as_string);
	my @friends=();
	foreach my $ts ($te->table_states){
		foreach my $row ($ts->rows){
			my $friend = @$row[2];
			my $userid;
			if($friend=~/userid=({[\dA-F-]*})/i){
				$userid=$1;
			}

			$friend=~s/<(?:[^>'"]*|(['"]).*?\1)*>//gs;			

			if($friend=~/([\w\d_]+)\W(F|P)(\d+)/i){
				my $nick=$1;
				my $sex="N";
				my $age=0;
				my $city="N/A";
				my $state="N/A";
				$nick=~s/^\s//;
				$nick=~s/\s$//;

				my %item;
				$item{NICK}	= $nick;
				$item{SEX}	= $sex;
				$item{AGE}	= $age;
				$item{CITY}	= $city;
				$item{STATE}	= $state;
				$item{USERID}	= $userid;
				push(@friends, \%item);
			}
		}
	}

	return @friends;
}


# scribbles
sub scribbles{
	my $self = shift;

	my $te = new HTML::TableExtract(depth => 2, count => 0, keep_html => 1);

	my $ua = LWP::UserAgent->new(keep_alive => 1, timeout => 300);
	$ua->agent($self->{AgentIdent});
	$ua->cookie_jar($self->{Cookie});

	my $req = HTTP::Request->new(POST => "http://www.lunarstorm.se/bbs/bbs_main.asp");
	$req->content_type('application/x-www-form-urlencoded');
	$req->referer('http://www.lunarstorm.se/usr/usr_presentation.asp');
	$req->header('Accept' => 'text/xml,application/xml,application/xhtml+xml,text/html,text/plain');
	$self->{Cookie}->add_cookie_header($req);

	my $res = $ua->request($req);

	if(not ($res->is_success || $res->code == 302)){
		return;
	}

	$te->parse($res->as_string);

	my @scribbles=();
	foreach my $ts ($te->table_states){
		foreach my $row ($ts->rows){
			my $scribble = @$row[2];
			my $userid="";
			my $nick="";
			my $sex="N";
			my $age=0;
			my $city="N/A";
			my $state="N/A";

			if($scribble=~/userid=({[\dA-F-]*})/){
				$userid=$1;
			}

			$scribble=~s/<br>/\n/igs;
			$scribble=~s/<(?:[^>'"]*|(['"]).*?\1)*>//gs;			

			if($scribble=~/([\w\d_]+)\W(F|P)(\d+) från (.+) i (.+) län/i){
				$nick=$1; $sex=$2; $age=$3;
				$city=$4; $state=$5;
			}
			$nick=~s/^\s//;
			$nick=~s/\s$//;

			my @tmp = split(/\n/, $scribble);
			shift(@tmp);
			$scribble=join(' ', @tmp);
			$scribble=~s/^\s+//g;
			$scribble=~s/\s+$//g;

			my %item;
			$item{NICK}	= $nick;
			$item{SEX}	= $sex;
			$item{AGE}	= $age;
			$item{CITY}	= $city;
			$item{STATE}	= $state;
			$item{USERID}	= $userid;
			$item{TEXT}	= $scribble;
			push(@scribbles, \%item);
		}
	}

	return @scribbles;
}


# scribble
sub scribble{
	my ($self, $scribble) = @_;

	$scribble = uri_escape($scribble);

	my $ua = LWP::UserAgent->new(keep_alive => 1, timeout => 300);
	$ua->agent($self->{AgentIdent});
	$ua->cookie_jar($self->{Cookie});

	my $req = HTTP::Request->new(POST => 'http://www.lunarstorm.se/bbs/bbs_db.asp?status=insert');
	$req->content_type('application/x-www-form-urlencoded');
	$req->content("body=$scribble");
	$req->referer("http://www.lunarstorm.se/bbs/bbs_main.asp");
	$req->header('Accept' => 'text/xml,application/xml,application/xhtml+xml,text/html,text/plain');
	$self->{Cookie}->add_cookie_header($req);

	my $res = $ua->request($req);

	if(not ($res->is_success || $res->code == 302)){
		return 0;
	}

	return 1;
}


# relations_status
sub relations_status{
	my $self = shift;

	my $te = new HTML::TableExtract(depth => 2, count => 0, keep_html => 1);

	my $ua = LWP::UserAgent->new(keep_alive => 1, timeout => 300);
	$ua->agent($self->{AgentIdent});
	$ua->cookie_jar($self->{Cookie});

	my $req = HTTP::Request->new(GET => 'http://www.lunarstorm.se/usr/fri_status.asp');
	$req->content_type('application/x-www-form-urlencoded');
	$req->referer('http://www.lunarstorm.se/usr/usr_presentation.asp');
	$req->header('Accept' => 'text/xml,application/xml,application/xhtml+xml,text/html,text/plain');
	$self->{Cookie}->add_cookie_header($req);

	my $res = $ua->request($req);

	if(not ($res->is_success || $res->code == 302)){
		return 0;
	}

	
	$te->parse($res->as_string);

	my @relations=();
	foreach my $ts ($te->table_states){
		foreach my $row ($ts->rows){
			my $relation = @$row[0];
			my $userid="";
			my $nick="";
			my $sex="N";
			my $age=0;
			my $city="N/A";
			my $state="N/A";
			my $type="";

			$relation=uri_unescape($relation);

			if($relation=~/UserID=({[\dA-F-]*})/){
				$userid=$1;
			}

			$relation=~s/<(?:[^>'"]*|(['"]).*?\1)*>//gs;

			if($relation=~/([\w\d_]+)\W(F|P)(\d+)/i){
				$nick=$1;
				$sex=$2;
				$age=$3;
			}
			$nick=~s/^\s//;
			$nick=~s/\s$//;

			if($relation=~/skapa relationen.(.+).med/){
				$type=$1;
			}elsif($relation=~/hellre skapa relationen.(.+)\./){
				$type=$1;
			}elsif($relation=~/avslutat/){
				$type="CLOSED";
			}

			my %item;
			$item{NICK}	= $nick;
			$item{SEX}	= $sex;
			$item{AGE}	= $age;
			$item{CITY}	= $city;
			$item{STATE}	= $state;
			$item{USERID}	= $userid;
			$item{TYPE}	= $type;
			if($nick){
				push(@relations, \%item);
			}
		}
	}

	return @relations;
}


# accept_relation
sub accept_relation{
	my ($self, $relation) = @_;

	my $ua = LWP::UserAgent->new(keep_alive => 1, timeout => 300);
	$ua->agent($self->{AgentIdent});
	$ua->cookie_jar($self->{Cookie});

	my $req;
	if($relation->{TYPE} ne "CLOSED"){
		$req=HTTP::Request->new(POST => "http://www.lunarstorm.se/usr/fri_registration.asp?UserID=$relation->{USERID}&Action=ac&Part=3");
	}else{
		$req=HTTP::Request->new(POST => "http://www.lunarstorm.se/usr/fri_datamaster.asp?DMUserID=$relation->{USERID}&orgin=/usr/fri_status.asp&qs=&status=verify");
	}
	$req->content_type('application/x-www-form-urlencoded');
	if($relation->{TYPE} ne "CLOSED"){
		$req->content("Stuff=1&Diary=1&Category=&Relation=");
	}
	$req->referer("http://www.lunarstorm.se/usr/fri_registration.asp");
	$req->header('Accept' => 'text/xml,application/xml,application/xhtml+xml,text/html,text/plain');
	$self->{Cookie}->add_cookie_header($req);

	my $res = $ua->request($req);

	if(not ($res->is_success || $res->code == 302)){
		return 0;
	}

	if($relation->{TYPE} ne "CLOSED"){
		$req=HTTP::Request->new(POST => "http://www.lunarstorm.se/usr/fri_registration.asp?UserID=$relation->{USERID}&Action=ac&Part=4");
		$req->content("COMMENT=&Category=&Relation=&Stuff=1&Diary=1");
		$res = $ua->request($req);
		if(not ($res->is_success || $res->code == 302)){
			return 0;
		}
	}

	return 1;
}

1;

__END__

=head1 NAME

WWW::Lunarstorm - Perl module for interacting with the Swedish community Lunarstorm

=head1 SYNOPSIS

	use strict;
	use WWW::Lunarstorm;

	my $lunar = new Lunarstorm(Username => 'myusername', Password => 'mypassword',
				UserID => '{DEADBEAF-BABE-DEAD-BABE-DEADBEAFBABE}',
				CookiePath => '/directory/to/place/cookiefile/in');

	$lunar->login() or die "Unable to login";
	$lunar->logout() or die "Unable to logout";

=head1 DESCRIPTION

This module provides functions for interacting with the Swedish
community Lunarstorm (www.lunarstorm.se).

=head1 METHODS

=over

=head2 Constructor

=item new()

Return a new Lunarstorm object. Valid attributes are:

=over

=item Username

Your Lunarstorm username

=item Password

Your Lunarstorm password

=item UserID

Your Lunarstorm userid. This is a id use by lunarstorm internaly. Every 
user got an id in the form of {DEADBEAF-BABE-DEAD-BABE-DEADBEAFBABE}. 
This is needed to locate your personal guestbook etc.

I'll most likely remove this from the constructor in future
versions.

=back

=back

=item login()

Logs in to the community. May be integrated in constructor in future 
versions. Returns 1 on success and 0 on failure.

=item logout()

Logs out from the cumminty. May be integrated in the destructor in f
uture versions. Returns 1 on success and 0 on failure.

=item visitors()

Retrives a list of people who have visited you personal page.

=over

Returns a hash containing:

=over

=item NICK

=item SEX

=item AGE

=item CITY

=item STATE

=item USERID

=back

USERID is the lunarstorm id.

=back

=item guestbook()

Takes two arguments. Page number and userid. Page number is the page 
number which you wish to retrive guestbook entries from.  Page number 
1 represents the latest page in the guestbook.  Userid is the 
lunarstorm id of the person whos guestbook you wish to read from. If 
left out, your own guestbook is read.

=over

Returns a hash containing:

=over

=item NICK

=item SEX

=item AGE

=item CITY

=item STATE

=item USERID

=item GUESTNR

=item TEXT

=back

TEXT is the body of the message.

=back

=item sign_guestbook()

Takes four arguments. Username, userid, guestbookitem id and the text 
you wish to sign the guestbook with. Username is the username of the 
user whos guestbook you are to sign. Userid is the users lunarstorm 
id. Guestbookitem id is a id given to every guestbook item. It is 
used to identify which item you replied to, so that it can be marked 
as answered.  Returns 1 on success and 0 on failure.

=item relations()

Takes one optional argument, userid. Userid is the lunarstorm id of the 
person whos list of relations you wish to retrive. If left out, your 
own list of relations is retrived.

=over

Returns a hash containing:

=over

=item NICK

=item SEX

=item AGE

=item CITY

=item STATE

=item USERID

=back

USERID is the lunarstorm id.

=back


=item scribbles()

Takes zero arguments. Retrives all items in the scribble board.

=over

Returns a hash containing:

=over

=item NICK

=item SEX

=item AGE

=item CITY

=item STATE

=item USERID

=item TEXT

=back

TEXT is the body of the scribble.

=back


=item scribble()

Takes one argument, the text you wish to write on the board.
Returns 1 on success and 0 on failure.

=item relations_status()

Takes zero arguments. Retrievs a list of newly created, or ended 
relations. These are accapted with accept_relation().

=over

Returns a hash containing:

=over

=item NICK

=item SEX

=item AGE

=item CITY

=item STATE

=item USERID

=item TYPE

=back

If TYPE is "CLOSED", the relation is a closed one. Else TYPE contains a 
string containing the relation type.

=back

=item accept_relation()

Takes one argument, a hash containing at least two variables: USERID and 
TYPE. It is recommened to just pass the hash returned by 
relations_status(). For example:

	my @relations = $lunar->relations_status();

	foreach my $relation (@relations){
		$lunar->accept_relation($relation);
	}

Returns 1 on success and 0 on failure.

=head1 REQUIERS

LWP::UserAgent, HTTP::Cookies, HTML::TableExtract, URI::Escape

=head1 AUTHOR

Martin Stenberg E<lt>F<bumby@evilninja.org>E<gt>

=head1 COPYRIGHT

Copyright (c) 2004 Martin Stenberg
All rights reserved. This program is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.


=head1 SEE ALSO

www.lolisa.org, AI::MegaHal.

=cut
