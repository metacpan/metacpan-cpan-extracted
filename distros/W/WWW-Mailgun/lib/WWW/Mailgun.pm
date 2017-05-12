package WWW::Mailgun;

use strict;
use warnings;

use JSON;
use MIME::Base64;
use match::smart;

require LWP::UserAgent;

BEGIN {
    our $VERSION = 0.54;
}

my @IGNORE_DOMAIN = qw/domains/;
my @GET_METHODS = qw/stats domains log mailboxes/;
my @POST_METHODS = qw//;
my @ALL_METHODS = (@GET_METHODS, @POST_METHODS);

my $ALIAS__OPTION = {
    attachments => 'attachment',
    tags        => 'o:tag',
};

my $OPTION__MAXIMUM = {
    "o:tag" => 3,
};

sub new {
    my ($class, $param) = @_;

    my $Key = $param->{key} // die "You must specify an API Key";
    my $Domain = $param->{domain} // die "You need to specify a domain (IE: samples.mailgun.org)";
    my $Url = $param->{url} // "https://api.mailgun.net/v2";
    my $From = $param->{from} // "";

    my $self = {
        ua  => LWP::UserAgent->new,
        url => $Url . '/',
        domain => $Domain,
        from => $From,
    };

    $self->{get} = sub {
        my ($self, $type, $data) = @_;
        return my $r = $self->{ua}->get(_get_route($self,[$type, $data]));
    };

    $self->{del} = sub {
        my ($self, $type, $data) = @_;
        return my $r = $self->{ua}->request(
            HTTP::Request->new( 'DELETE', _get_route( $self, [$type, $data] ) )
        );
    };

    $self->{post} = sub {
        my ($self, $type, $data) = @_;
        return my $r = $self->{ua}->post(_get_route($self,$type), Content_Type => 'multipart/form-data', Content => $data);
    };

    $self->{ua}->default_header('Authorization' => 'Basic ' . encode_base64('api:' . $Key));

    return bless $self, $class;
}

sub _handle_response {
    my ($response) = shift;

    my $rc = $response->code;

    return 1 if 200 <= $rc && $rc <= 299; # success

    my $json = from_json($response->decoded_content);
    if ($json->{message}) {
        die $response->status_line." ".$json->{message};
    }

    die "Bad Request - Often missing a required parameter" if $rc == 400;
    die "Unauthorized - No valid API key provided" if $rc == 401;
    die "Request Failed - Parameters were valid but request failed" if $rc == 402;
    die "Not Found - The requested item doesn’t exist" if $rc == 404;
    die "Server Errors - something is wrong on Mailgun’s end" if $rc >= 500;
}

sub send {
    my ($self, $msg)  = @_;

    $msg->{from} = $msg->{from} || $self->{from}
        or die "You must specify an email address to send from";
    $msg->{to} = $msg->{to}
        or die "You must specify an email address to send to";
    if (ref $msg->{to} eq 'ARRAY') {
        $msg->{to} = join(',',@{$msg->{to}});
    }

    $msg->{subject} = $msg->{subject} // "";
    $msg->{text} = $msg->{text} // "";

    my $content = _prepare_content($msg);

    my $r = $self->{post}->($self, 'messages', $content);

    _handle_response($r);

    return from_json($r->decoded_content);
}

=head2 _prepare_content($option__values) : \@content

Given a $option__values hashref, transform it to an arrayref suitable for
sending as multipart/form-data. The core logic here is that array references
are modified from:

    option => [ value1, value2, ... ]

to

    [ option => value1, option => value2, ... ]

=cut

sub _prepare_content {
    my ($option__values) = @_;

    my $content = [];
    my $option__count = {};

    while (my ($option, $values) = each %$option__values) {
        $option = $ALIAS__OPTION->{$option} || $option;
        $values = ref $values ? $values : [$values];

        for my $value (@$values) {
            $option__count->{$option}++;
            if ($OPTION__MAXIMUM->{$option} &&
                    $option__count->{$option} > $OPTION__MAXIMUM->{$option}) {
                warn "Reached max number of $option, skipping...";
                last;
            }
            $value = [ $value ] if $option eq 'attachment';
            push @$content, $option => $value;
        }
    }

    return $content;
}

sub _get_route {
    my ($self, $path) = @_;

    if (ref $path eq 'ARRAY'){
        my @clean = grep {defined} @$path;
        unshift @clean, $self->{domain}
            unless $clean[-1] |M| @IGNORE_DOMAIN;
        $path = join('/',@clean);
    } elsif (!($path |M| @IGNORE_DOMAIN)) {
        $path = $self->{domain} . '/' . $path
    }
    return $self->{url} . $path;
}

sub unsubscribes {
    my ($self, $method, $data) = @_;
    $method = $method // 'get';

    my $r = $self->{lc($method)}->($self,'unsubscribes',$data);
    _handle_response($r);
    return from_json($r->decoded_content);
}

sub complaints {
    my ($self, $method, $data) = @_;
    $method = $method // 'get';

    my $r = $self->{lc($method)}->($self,'complaints',$data);
    _handle_response($r);
    return from_json($r->decoded_content);
}

sub bounces {
    my ($self, $method, $data) = @_;
    $method = $method // 'get';

    my $r = $self->{lc($method)}->($self,'bounces',$data);
    _handle_response($r);
    return from_json($r->decoded_content);
}

sub logs {
    ## Legacy support.
    my $self = shift;
    return $self->log();
}

sub AUTOLOAD { ## Handle generic list of requests.
    our $AUTOLOAD;
    my $self = shift;
    my @ObjParts = split(/\:\:/, $AUTOLOAD);
    my $method = pop(@ObjParts);
    return if $method eq 'DESTROY'; ## Ignore DESTROY.
    unless ($method |M| @ALL_METHODS) {
        die("Not a valid method, \"$method\".");
    }
    my $mode = 'get';
    $mode = 'post' if $method |M| @POST_METHODS;
    my $r = $self->{$mode}->($self, $method, @_);
    _handle_response($r);
    return from_json($r->decoded_content);
}

=pod


=head1 NAME

WWW::Mailgun - Perl wrapper for Mailgun (L<http://mailgun.org>)

=head1 SYNOPSIS

    use WWW::Mailgun;

    my $mg = WWW::Mailgun->new({
        key => 'key-yOuRapiKeY',
        domain => 'YourDomain.mailgun.org',
        from => 'elb0w <elb0w@YourDomain.mailgun.org>' # Optionally set here, you can set it when you send
    });

    #sending examples below

    # Get stats http://documentation.mailgun.net/api-stats.html
    my $obj = $mg->stats;

    # Get logs http://documentation.mailgun.net/api-logs.html
    my $obj = $mg->logs;


=head1 DESCRIPTION

Mailgun is a email service which provides email over a http restful API.
These bindings goal is to create a perl interface which allows you to
easily leverage it.

=head1 USAGE

=head2 new({key => 'mailgun key', domain => 'your mailgun domain', from => 'optional from')

Creates your mailgun object

from => the only optional field, it can be set in the message.



=head2 send($data)

Send takes in a hash of settings
Takes all specificed here L<http://documentation.mailgun.net/api-sending.html>
'from' is optionally set here, otherwise you can set it in the constructor and it can be used for everything

=item Send a HTML message with optional array of attachments

    $mg->send({
          to => 'some_email@gmail.com',
          subject => 'hello',
          html => '<html><h3>hello</h3><strong>world</strong></html>',
          attachment => ['/Users/elb0w/GIT/Personal/Mailgun/test.pl']
    });

=item Send a text message

    $mg->send({
          to => 'some_email@gmail.com',
          subject => 'hello',
          text => 'Hello there'
    });

=item Send a MIME multipart message

    $mg->send({
          to      => 'some_email@gmail.com',
          subject => 'hello',
          text    => 'Hello there',
          html    => '<b>Hello there</b>'
    });


=head2 unsubscribes, bounces, spam

Helper methods all take a method argument (del, post, get)
L<http://documentation.mailgun.net/api_reference.html>
'post' optionally takes a hash of properties


=item Unsubscribes

    # View all unsubscribes L<http://documentation.mailgun.net/api-unsubscribes.html>
    my $all = $mg->unsubscribes;

    # Unsubscribe user from all
    $mg->unsubscribes('post',{address => 'user@website.com', tag => '*'});

    # Delete a user from unsubscriptions
    $mg->unsubscribes('del','user@website.com');

    # Get a user from unsubscriptions
    $mg->unsubscribes('get','user@website.com');



=item Complaints

    # View all spam complaints L<http://documentation.mailgun.net/api-complaints.html>
    my $all = $mg->complaints;

    # Add a spam complaint for a address
    $mg->complaints('post',{address => 'user@website.com'});

    # Remove a complaint
    $mg->complaints('del','user@website.com');

    # Get a complaint for a adress
    $mg->complaints('get','user@website.com');

=item Bounces

    # View the list of bounces L<http://documentation.mailgun.net/api-bounces.html>
    my $all = $mg->bounces;

    # Add a permanent bounce
    $mg->bounces('post',{
        address => 'user@website.com',
        code => 550, #This is default
        error => 'Error Description' #Empty by default
    });

    # Remove a bounce
    $mg->bounces('del','user@website.com');

    # Get a bounce for a specific address
    $mg->bounces('get','user@website.com');

=head1 TODO

=item Mailboxes

=item Campaigns

=item Mailing Lists

=item Routes

=head1 Author

George Tsafas <elb0w@elbowrage.com>

=head1 Support

elb0w on irc.freenode.net #perl
L<https://github.com/gtsafas/mailgun.perl>


=head1 Resources

L<http://documentation.mailgun.net/>


