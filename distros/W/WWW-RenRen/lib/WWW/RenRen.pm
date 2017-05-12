package WWW::RenRen;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Cookies;
use HTML::TagParser;
use Encode;
use JSON;
use utf8;

our $VERSION = 0.35;

BEGIN {
    binmode (STDOUT, ':encoding(utf8)');
}

our %capcha_mapping = (
    'lockaccount' => 'KILLSELF_'
);

sub new
{
    my ($class, %cnf) = @_;

    ####
    my %defaults = (
        'agent' => 'Mozilla/5.0 (X11; Linux x86_64)',


    );
    $defaults{$_} = $cnf{$_} for (keys %cnf);

    ####
    my $ua = LWP::UserAgent->new (%defaults);
    $ua->timeout(3);
    $ua->cookie_jar (HTTP::Cookies->new);
    ####

    my $self = bless {
        'ua' => $ua,
        'userid' => undef,
        'rtk' => undef,
        'requestToken' => undef,
    }, $class;

    return $self;
}

sub get
{
    my ($self, $url) = @_;
    my $resp = $self->{ua}->get ($url);
    $self->{ua}->{cookie_jar}->extract_cookies ($resp);
    $resp->decoded_content;
}

sub post
{
    my ($self, $url, $formRef) = @_;

    my $resp = $self->{ua}->post ($url, $formRef);
    $self->{ua}->{cookie_jar}->extract_cookies ($resp);
    $resp->decoded_content;
}

sub login
{
    my ($self, $usr, $pw) = @_;
    my $loginURL = "http://www.renren.com/ajaxLogin/login";

    my %form = (
        'email' => $usr,
        'password' => $pw
    );

    my $loginHTML = $self->post ($loginURL, \%form);
    my $json = from_json( $loginHTML );
    if ( $json->{'code'} eq 'true' )
    {
        # find rtk & requestToken
        for (split /\n/ , $self->get($json->{'homeUrl'}))
        {
            if ($_ =~ /get_check:'([-0-9]+)',get_check_x:'([a-zA-Z0-9]+)'/)
            {
                $self->{requestToken} = $1;
                $self->{rtk} = $2;
            }
            elsif ( $_ =~ /'id':'([0-9]+)',/ )
            { 
                $self->{userid} = $1;
                last;
            }
        }

        return 1;
    }
    else
    {
        print 'Unable to login: ', $json->{'failDescription'};
    }

    return 0;
}

sub shareLink
{
    my ($self, $link, $url, $title, $comment) = @_;

    my $requestURL = 'http://shell.renren.com/' . $self->{userid} . '/share?1';
    my %form = (
        'link'         => $link,
        'url'          => $url,
        'hostid'       => $self->{userid},
        'channel'      => 'renren',
        'meta'         => '""',
        'thumbUrl'     => '',
        'summary'      => '',
        'type'         => 6,
        'comment'      => decode ('utf8', $comment),
        'requestToken' => $self->{requestToken},
        'rtk'          => $self->{rtk}
    );

    print $self->post ($requestURL, \%form);
}

sub geticode
{
    my ($self, $reason, $file) = @_;
    my $capchaURL = 'https://safe.renren.com/icode.renren.com/getcode.do?t=' . $reason . '&rnd=123';
    open my $fh, '>', $file or die $@;
    print $fh $self->get ($capchaURL);
    close $fh;
};

sub lockaccount
{
    my ($self, $passwd, $pcode) = @_;
    my %form = (
        'requestToken', $self->{rtk},
        'password', $passwd,
        'checkcode', $pcode
    );
    my $url_lockacct = 'https://safe.renren.com/account/del/verify/';

    print $self->post ( $url_lockacct, \%form );
};

sub relieve
{
    my ($self, $email, $pw) = @_;

    my %form = (
        'email' => $email,
        'password' => $pw,
        'dominName' => 'renren.com',
        'changeSubmit' => '解锁帐号'	
    );

    my $relieveURLPre = 'http://safe.renren.com/relive.do';
    my $url_relieve= 'http://safe.renren.com/account/relive/verify/';

    $self->get ($relieveURLPre);
    $self->post ( $url_relieve, \%form );
}

sub postNewEntry
{
    my ($self, $title, $content, $pass, $cate) = @_;
    my $newEntryPostURL = "http://blog.renren.com/NewEntry.do";

    my %form = (
        title => $title,
        body => $content,
        categoryid => defined $cate ? $cate : 0,
        blogControl => 99,
        passwordProtedted => 0,
        editBlogControl => 99,
        postFormid => -674374642,
        newLetterId => 0,
        blog_pic_id => undef,
        pic_path => undef,
        id => undef,
        relative_optype => "saveDraft",
        isVip => undef,
        jf_vim_em => 'true',
        blackListChang => 'false',
        passWord => $pass,
        requestToken => $self->{requestToken},
        _rtk => $self->{rtk},
    );

    for (split /\n/, $self->get ($newEntryPostURL))
    {
        $form{id} = $1 if $_ =~ /id="id" value="([0-9]+)"/;
    }

    print $self->post ($newEntryPostURL, \%form);
#	my $json = from_json( $self->post ($newEntryPostURL, \%form) , { utf8  => 1 } );
#	($json->{code} eq 0) ? 1 : 0;
}

sub postUpdatePhoto
{
    my ($self, $albumID) = @_;

    my %form = (
        id => $albumID,
        title => "AUTORM",
        editUploadedPhotos => "false",
#		x => 99,
#		y => 32,
# Another Vulnerability in renren.com:
#		requestToken => $self->{requestToken},
#		_rtk => $self->{rtk},
    );

    my $photoEditURL = 'http://photo.renren.com/editphotolist.do?id=' . $albumID;
    print "Edit url: ", $photoEditURL;
    $self->post ($photoEditURL, \%form);
}

sub uploadNewPhoto
{
    my ($self, $albumID, $photoref) = @_;

    my $photoPlainURL = "http://upload.renren.com/uploadservice.fcgi?pagetype=addPhotoPlain";

    my $i = 1;

    my @photos = (
        id => $albumID
    );

    for (@$photoref)
    {
        push @photos, "photo" . $i => [ $_ ];
        last if ++ $i > 5;
    }

    my $request = POST $photoPlainURL, 
    Content_Type => 'multipart/form-data', 
    Content => \@photos;

    my $resp = $self->{ua}->request ($request);
    if ( $resp->is_success && $resp->decoded_content =~ qq#<script># )
    {
        $self->postUpdatePhoto ($albumID);

        return 1;
    }
    return 0;
}

sub getAlbums
{
    my ($self) = @_;
    my $photourl = 'http://photo.renren.com/photo/' 
        . $self->{userid} 
        . '?__view=async-html';

    my $hrefReg = 'http://photo.renren.com/photo/[0-9]+/album-([0-9]+)';
    my %mapping = ();

    my $parser = HTML::TagParser->new ($self->get ($photourl));
    for my $e ($parser->getElementsByClassName ('album-title'))
    {
        next if $e->tagName ne "a";
        next if $e->attributes->{href} !~ /$hrefReg/;
        $mapping{$1} = $e->innerText;
    }

    return \%mapping;
}

sub deleteAlbum
{
    my ($self, $id, $capcha) = @_;
    my $deleteAlbumURL = 'http://photo.renren.com/photo/' . $self->{userid} . '/album-' . $id . '/delete';
    my %form = ( "photoInfoCode" => $capcha );

    my $json = from_json( $self->post ($deleteAlbumURL, \%form), { utf8  => 1 } );
    if ( $json->{'code'} eq 0 )
    {
        return 1;
    }
    return 0;
}

sub createAlbum
{
    my ($self, $title, $pass) = @_;

    my $albumURL = "http://photo.renren.com/ajaxcreatealbum.do";
    my %form = (
        'title', $title,
        'control', 99,
        'password', $pass,
        'passwordProtected', defined ($pass) ? 'true' : 'false'
    );

    my $json = from_json( $self->post ($albumURL, \%form), { utf8  => 1 } );
    return defined ($json->{'albumid'}) ? $json->{'albumid'} : "";
}

sub addThisFriend
{
    my ($self, $uid) = @_;

    my $requestFriendURL = "http://friend.renren.com/ajax_request_friend.do?from=sg_others_profile";
    my %form = (
        'id'  =>  $uid,
        'why' => '',
        'codeFlag'  =>  '0',
        'code'  =>  '',
        'requestToken'  =>  $self->{requestToken},
        '_rtk'  =>  $self->{rtk}
    );

    my $json = from_json( $self->post ($requestFriendURL, \%form), { utf8  => 1 } );
    if ( defined ($json->{'code'}) )
    {
        if ($json->{'code'} != 0)
        {
            print "Denied: ", $json->{'message'}, "\n";
        }
        return $json->{'code'};
    }

    return 0;
}

sub getCommonFriendsList
{
    my ($self) = @_;
    my $rcdURL = "http://rcd.renren.com/cwf_nget_home";
    my %sent = ();

    for (split />/ , $self->get($rcdURL) )
    {
        if ( $_ =~ /class="username" data-id="([0-9]+)"/ )
        {
            my $uid = $1;
            unless( defined ($sent{$uid}) )
            {
                $sent{$1}++;
            }
        }
    }

    return keys %sent;
}

sub getMyShares
{
    my ($self, $userid) = @_;
    # Another vulnerability of renren.com ;-(
    my $sharesURL = 'http://share.renren.com/share/' . $self->{userid} . '?__view=async-html';

    my @results = ();

    for (split /</, $self->get ($sharesURL))
    {
        push @results, $1 if /id="share_([0-9]+)"/;
    }

    return \@results;
}

sub getMyDoings
{
    my ($self) = @_;

    my $doingsURL = 'http://status.renren.com/status?__view=async-html';
    my %mapping = ();

    my $parser = HTML::TagParser->new ($self->get ($doingsURL));
    for my $e ($parser->getElementsByTagName ('li'))
    {
        next if ! defined $e->attributes->{id};
        if ($e->attributes->{id} =~ /status-([0-9]+)/)
        {
            my ($doing_id, $doing_content) = ($1, undef);

            # Find content!
            my $child = $e->firstChild();
            while (defined $child)
            {
                if ($child->tagName eq "h3")
                {
                    # BUGGY, hah?
                    ($doing_content = $child->innerText) =~ s/^[^:]+//;
                    last;
                }

                $child = $child->nextSibling;
            }

            $mapping{$doing_id} = $doing_content;
        }
    }

    return \%mapping;
}

sub postNewStatus
{
    my ($self, $text) = @_;
    my $postStatusURL = 'http://shell.renren.com/' . $self->{userid} . '/status';

    my %form = (
        'requestToken', $self->{requestToken},
        '_rtk', $self->{rtk},
        'hostid', $self->{userid},
        'content', decode ('utf8', $text),
        'channel', 'renren'
    );

    my $json = from_json( $self->post ($postStatusURL, \%form), { utf8  => 1 } );
    if ( $json->{'code'} eq 0 )
    {
        # succeed
        return 1;
    }
    return 0;
}

sub getFriendIDList
{
    my ($self) = @_;
    my $friendListURL = 'http://friend.renren.com/myfriendlistx.do';

    my @list = ();
    for (split /\r\n/, $self->get ($friendListURL))
    {
        if (/var friends=(.*);/)
        {
            my $json = from_json($1, { utf8 => 1 } );
            foreach (@$json)
            {
                push @list, $_->{'id'};
            }
        }
    }

    return @list;
}

sub accessHomePage
{
    my ($self, $rrid) = @_;
    $self->get ( 'http://www.renren.com/' . $rrid . '/profile?ref=opensearch_normal' );
}

sub delMyShare
{
    my ($self, $sid) = @_;
    my $delShareURL = 'http://share.renren.com/share/EditShare.do';

    my %form = (
        'action', 'del',
        'sid', $sid,
        'type', $self->{userid},
        'requestToken', $self->{requestToken},
        '_rtk', $self->{rtk},
    );

    if ( $self->post ($delShareURL, \%form) =~ /0/ )
    {
        return 1;
    }
    return 0;
}

sub delMyDoing
{
    my ($self, $id) = @_;

    my $deleteDoingURL = "http://status.renren.com/doing/deleteDoing.do";
    my %form = (
        'requestToken', $self->{requestToken},
        '_rtk', $self->{rtk},
        'id', $id
    );

    return 1 if ( $self->post ($deleteDoingURL, \%form) =~ /succ/ );
    return 0;
}

1;

__END__

=head1 NAME

 WWW::RenRen - renren.com funcality helper module

=head1 AUTHOR

 Aaron Lewis <the.warl0ck.1989@gmail.com> Copyright 2012
 Release under GPLv3 License

=head1 DESCRIPTION 

 Simulate browser to complete all kinds of request of renren.com, 
 popular social website in China

 Note from author:
 Everything is transmitted as clear text, also note the new password
 encryption algorithm is not implemented yet. Don't rap my door for it.

=head1 SYNOPSIS

 use WWW::RenRen;

 my $rr = WWW::RenRen->new; 
 die unless $rr->login ('XX@yy.com', 'your_password'); # or use user id

=head2 new

 Create a new object and return,

 my $rr = WWW::RenRen->new;

=head2 login

 Login could be done with either your email address or associated jabber ID, 
 nothing could be done before login.

 die unless $rr->login ('XX@yy.com', 'password');

 Note that the capcha handler is not implemented yet

=head2 postNewStatus

 Post a new status, 

 $rr->postNewStatus ('message_will_be_decoded_with_utf8');

=head2 getAlbums

 Get a hash reference of albums,

 ID -> Album name

 my $albums = $rr->getAlbums;
 print join ("\n", keys %$albums);

=head2 deleteAlbum 

 Delete an album, an album ID and a capcha code is required:

 $rr->deleteAlbum ('albumid', 'capcha');

=head2 createAlbum

 Create a new album, with password protection:

 $rr->createAlbum ('album_name', 'password');

 Or open to public:

 $rr->createAlbum ('album_name');

 On success, a newly assigned album id is returned.

=head2 getMyDoings

 Retrieve a hash reference of doings

 ID -> Content

 my %doings = %{ $rr->getMyDoings };

=head2 delMyDoing

 Delete a posted status, 

 $rr->delMyDoing ('doing_id')

=head2 getMyShares

 Get an array of share IDs,

 my @shareds = @{ $rr->getMyShares; }

=head2 delMyShare

 Delete a shared item, 

 $rr->delMyShare ('shareid')

=head2 addThisFriend

 Add a friend to your list, only number value is accepted,

 $rr->addThisFriend ('user_id');

=head2 uploadNewPhoto

 Upload photos (at most 5) to an existing album,

 $rr->uploadNewPhoto ('album_id', ['/path/to/1.png', '/path/to/2.png']);

=head2 postNewEntry

 Post a new blog entry, feature under testing

 $rr->postNewEntry ('title', 'content', 'password_optional', 'category_id_optional');

=head2 getFriendIDList

 Retrieve list of friend ids

 my @list = $rr->getFriendIDList();

=head2 accessHomePage

 Access home page of any user, use 'opensearch' by default:

 $rr->accessHomePage ('123456');

=head2 shareLink

 Share a link and post a status,

 $rr->shareLink ($link, $url, $title, $comment)

=head2 relieve

 Unlock your renren.com account,

 $rr->relieve ('your renren.com account', 'password');

=head2 lockaccount

 Lock your renren.com account,

 $rr->lockaccount('password', 'capcha code');

=head2 geticode

 Retrieve capcha code, dump to a file,
 $rr->geticode ('reason', '/tmp/icode.jpeg');
