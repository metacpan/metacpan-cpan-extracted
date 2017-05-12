package WWW::Topica;

use strict;
use Cwd;
use Carp qw(carp croak);
use Date::Parse;
use Email::Date;
use Email::Simple;
use Email::Simple::Creator;
use HTML::Entities;
use HTML::Scrubber;
use LWP::UserAgent;
use URI;

use vars qw($VERSION);

use WWW::Topica::Index;
use WWW::Topica::Mail;
use WWW::Topica::Reply;

$VERSION    = '0.6';
my $USER_AGENT = 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)';


=pod

=head1 NAME

WWW::Topica - read emails from a Topica mailing list

=head1 SYNOPSIS


    my $topica = WWW::Topica->new( list => 'mylist', login => 'mylogin', password => 'mypass' );
    
    while (my $mail = $topica->mail) {
        Email::LocalDelivery->deliver($mail, 'mylist.mbox');        
    }

=head1 DESCRIPTION

This module screen scrapes the Topica website and fetches back RFC822 text representations 
of all the mails posted to a given list. Where possible it fills in the from, to and date
fields. It should be noted that in some cases it's impossible to get both the sender name 
and their email address.

=head1 METHODS

=cut

=head2 new 

Takes three options, the list name, your login account and your password;

You can also pass in C<local> and C<debug>. C<debug> will print out
various debugging messages whereas C<local> will use local files for
testing. C<local> automatically sets C<debug> to C<1> unless debug is
explicitly set to C<0>.


Furthermore if you pass in a C<first> option the parsing will start from 
that offset. A C<last> lets you set an upper bound.

=cut

sub new {
    my $class = shift;
    my %opts  = @_;
    
    die "You must pass a list\n" unless defined $opts{list};
    #die "You must pass an email\n" unless defined $opts{email};
    #die "You must pass a password\n" unless defined $opts{password};


    $opts{_next} = $opts{first} || 0;
    $opts{debug} = $opts{local} if exists $opts{local} and not exists $opts{local};
    
    $opts{scrubber} = HTML::Scrubber->new( allow => [] );

    return bless \%opts, $class;

}

=head2 mail

Returns a mail at a time

Logs in automatically.

=cut


sub mail {
    my $self = shift; 

    # first time ever
    unless ($self->{_index}) 
    {
           $self->login;
        print STDERR "Beginning to collect mails\n" if $self->{debug};
    }

    # relog in after an hour
    # TODO: untested
    unless ($self->{local}) {
        my $time_diff  = time() - $self->{_logged_in};
        $self->login() if ($time_diff>60*60);
    }


    INDEX:
    # need to get new message ids
    unless (defined $self->{_message_ids} && @{$self->{_message_ids}}) 
    {
        # all over
        return undef unless defined $self->{_next};

        # the last one we want
        return undef if defined $self->{last} and $self->{_next} >= $self->{last};

        # end of first page
        # return undef if $self->{debug} && $self->{_index};

        $self->{_index} = WWW::Topica::Index->new($self->fetch_index($self->{_next}));
        
        return undef unless $self->{_index};

        $self->{_next} = $self->{_index}->next();  
        $self->{_prev} = $self->{_index}->prev();  
        @{$self->{_message_ids}} = $self->{_index}->message_ids;

    }

    GET: my $mess_id = shift @{$self->{_message_ids}};    
    goto INDEX unless defined $mess_id;    

    # the mail has some information and also provides a link to the reply if we're logged in...
    my $mail_html = $self->fetch_mail($mess_id);
    goto GET unless $mail_html; 
    my $mail  = WWW::Topica::Mail->new($mail_html, $mess_id);

    my $reply;

    # which has other information (like the un-htmled mail and the email address) ...            
    if ($mail->eto) {
        my $reply_html = $self->fetch_reply($mess_id,$mail->eto) if defined $mail->eto;
        goto GET unless $reply_html;
        $reply = WWW::Topica::Reply->new($reply_html, $mess_id, $mail->eto);
    }
               
    # now build the rfc822 mail string
    return $self->build_rfc822($mail, $reply);        

}

=head2 login

Logs in to Topica and stashes the cookie.

Called automatically by the first call to C<mail>.

Builds the loader automatically.

=cut

sub login {
    my $self = shift;

    $self->build_loader;

    my $anon =  !defined $self->{email} || !defined $self->{password};


    if ($anon) {
        $self->{email} = $self->{password} = 'anonymous';
    }



    print STDERR "Logging in using ".$self->{email}."/".$self->{password}."\n" if $self->{debug};

    return if $self->{local};

    if (!$anon) {
        (undef) = $self->fetch_page("http://lists.topica.com/");
        (undef) = $self->fetch_page("http://lists.topica.com/list.html");
        (undef) = $self->fetch_page("http://lists.topica.com/perl/login.pl?email=".$self->{email}."&password=".$self->{password});
    }

    



    # store when we logged in so that we can relog in again after an hour
    $self->{_logged_in} = time;        


}

=head2 fetch_index <offset>

Retrieve the html of the index page with the given offset.

=cut

sub fetch_index {
    my $self   = shift;
    my $offset = shift;
    my $list   = $self->{list};
    
    print STDERR "Fetching index $offset of list ${list}\n" if $self->{debug};

    my $url = "http://lists.topica.com/lists/${list}/read?sort=d&start=$offset";
    
    if ($self->{local}) {
        $url = "file://".cwd."/t/local_files/";
        if (0 == $offset) {
            $url .= "list_first.html";
        } elsif (100 == $offset) {
            $url .= "list_middle.html";
        } elsif (200 == $offset) {
            $url .= "list_last.html";
        } 
    
    } 
    
    return $self->fetch_page($url);

}


=head2 fetch_mail <id>

Retrieve the html of a the message page with the given id.

=cut

sub fetch_mail {
    my $self = shift;
    my $id   = shift;
    my $list = $self->{list};


    print STDERR "\tFetching mail $id\n" if $self->{debug};
    
    my $url = "http://lists.topica.com/lists/${list}/read/message.html?mid=$id";
    
    if ($self->{local}) {
        $url = "file://".cwd."/t/local_files/mail.html";    
    }
    
    return $self->fetch_page($url);
    
}


=head2 fetch_reply <id> <eto>

Retrieve the html of a the reply page with the given id and eto.

=cut

sub fetch_reply {
    my $self   = shift;
    my $id     = shift;
    my $eto    = shift;
    my $list   = $self->{list};

    print STDERR "\t\tFetching reply $id - $eto\n" if $self->{debug};


    my $url = "http://lists.topica.com/lists/${list}/read/post.html?mode=replytosender&mid=$id&eto=$eto";
    
    if ($self->{local}) {
        $url = "file://".cwd."/t/local_files/reply.html";    
    }
    
    return $self->fetch_page($url);


}


=head2 build_rfc822 <WWW::Topic::Mail> <WWW::Topica::Reply>

Given a C<WWW::Topic::Mail> object and a C<WWW::Topica::Reply> object
build up the text of an RFC822 compliant email.

=cut

sub build_rfc822 {
    my $self   = shift;
    my $mail   = shift;
    my $reply  = shift;

    my $list   = $self->{list};

    my $mid    = $mail->id;

    my $name   = decode_entities($mail->from);
    my $email  = "";
    if (defined $reply) {
        $email = decode_entities($reply->email);
    } else {
        $email = "${list}\@topica.com";
    }

    # we may have been confused and got name and email mixed up    
    if ($name =~ /@/ && $email !~ /@/) {
        my $tmp = $name;
        $name   = $email;
        $email  = $tmp;
    }

    # try and build a sane From: line
    my $from;
    if ($name ne $email && $email =~ /@/) {
        $from = "$name <$email>";
    } elsif ($email =~ /@/) {
        $from = "<$email>";
    } else {
        $from = "$name <${list}\@topica.com>";
    }
    
    # get the subject from somewhere - mail preferably because then it 
    # doesn't have the Re: which we don't know whether to strip out or not
    my $subject = $mail->subject;
       $subject = $reply->subject if defined $reply && $subject =~ /^\s*$/;

    # remove newlines
    $subject    =~  s/[\n\r]//gs;

    # strip out html 
    $subject    =~ s!<BR>\s+!!sg; # hack
    $subject    = $self->{scrubber}->scrub($subject);

    $subject = decode_entities($subject);

    # time 
    my $time    = str2time(decode_entities($mail->date)) || gmtime; 
    

    # message-id
    my $message_id = "${mid}\@lists.topica.com";


    # time to build the mail
    # we should probably use Email::Simple::Creator for this
    my $string = "";

    my $body   = "";
    if ($reply && defined $reply->body) {
        $body = $reply->body;
    }else { 
        $body = $self->{scrubber}->scrub($mail->body) || "";
    }

    $string .= "Date: ".format_date($time)."\n";
    $string .= "To: ${list}\@topica.com\n";
    $string .= "From: $from\n";
    $string .= "Message-ID: $message_id\n";
    $string .= "X-TopicaMailUrl: http://lists.topica.com/lists/${list}/read/message.html?mid=${mid}\n";
    if ($reply) {
        my $rid    = $reply->id;
        my $eto    = $reply->eto;
        $string .= "X-TopicaReplyUrl: http://lists.topica.com/lists/${list}/read/post.html?mode=replytosender&mid=${rid}&eto=${eto}\n";
    }
    $string .= "Subject: $subject\n";
    $string .= "\n$body\n\n";

    return $string;
}

=head2 build_loader

Set up the LWP::UserAgent object used to fetch pages.

=cut

sub build_loader { 
    my $self = shift;
    
    my $ua = new LWP::UserAgent( keep_alive => 1, timeout => 30, agent => $USER_AGENT, );


    # setting it in the 'new' seems not to work sometimes
    $ua->agent($USER_AGENT);
    # for some reason this makes stuff work
    $ua->max_redirect( 0 );
    # cookies!
    $ua->cookie_jar( {} );

    $self->{_ua} = $ua;
}

=head2 fetch_page <url>

Utility function for getting a page with various niceties.

=cut

sub fetch_page {
    my $self = shift;
    my $url  = shift;

    # print STDERR "\tfetching $url\n" if $self->{debug};

    # make a full set of headers
    my $h = new HTTP::Headers(
                'Host'            => "lists.topica.com",
                'User-Agent'      => $USER_AGENT,                                
                'Referer'         => $url,
                'Accept'          => 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,video/x-mng,image/png,image/jpeg,image/gif;q=0.2,*/*;q=0.1',
                'Accept-Language' => 'en-us,en;q=0.5',
                'Accept-Charset'  => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
                #'Accept-Encoding' => 'gzip,deflate',
                'Keep-Alive'      =>  '300',
                'Connection'      =>  'keep-alive',
                
    );
    
    $h->referer("$url");



    my $request  =  HTTP::Request->new ( 'GET', $url, $h );
    my $response;

    my $times = 0;

    # LWP should be able to do this but seemingly fails sometimes
    while ($times++<3) {
        $response =  $self->{_ua}->request($request);
        last if $response->is_success;
        if ($response->is_redirect) {
            $url = URI->new($response->header("Location"));
            $url = $url->abs("http://lists.topica.com");
            $h->referer("$url");
            $request  =  HTTP::Request->new ( 'GET', $url, $h );
        }
    }

    if (!$response->is_success && !$response->is_redirect)     {
        carp "Failed to retrieve $url";
        return undef;
    }

    return $response->content;

}

1;

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright (c) 2004, Simon Wistow

=cut



