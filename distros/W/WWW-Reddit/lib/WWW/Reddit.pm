package WWW::Reddit;

our $VERSION = '0.10';

use 5.012004;
use Data::Dumper;

use common::sense;

use LWP::Simple;
use JSON;

use HTTP::Cookies;
use LWP::UserAgent;

my $base_url        = 'http://www.reddit.com/';
my $api_url         = $base_url . 'api/';
my $login_url       = $api_url . 'login';
my $submit_url      = $api_url . 'submit';
my $comment_url     = $api_url . 'comment';

my $api_type        = 'json';

sub new {
    my $obj_class       = shift;
    my $class = ref $obj_class || $obj_class;
        
    my ($user, $passwd, $subreddit) = @_;

    my $self = {
        base_url    => $base_url,
        api_url     => $api_url,
        
        login_url   => $login_url,
        submit_url  => $submit_url,

        api_type    => $api_type,

        user        => $user,
        passwd      => $passwd,

        subreddit   => $subreddit,

        ua          => new LWP::UserAgent,
        cookie_jar  => HTTP::Cookies->new,

        modhash     => '',
    };

    bless $self, $class;
    
    $self->create_methods;
    return $self;
}

#>-----------------------------------------------<#
#  Helper Methods
#>-----------------------------------------------<#

# create accessor/mutator methods for defined parameters
sub create_methods {
    my $self = shift;
    for my $datum (keys %{$self}) {
        no strict "refs";
        *$datum = sub {
            my $self = shift;
            $self->{$datum} = shift if @_;
            return $self->{$datum};
        };
    }
}

# Set cookie 
sub set_cookie {
    my $self        = shift;
    my $response    = shift;    

    $self->cookie_jar->extract_cookies ($response);
    $self->ua->cookie_jar ($self->cookie_jar);
    $self->parse_modhash ($response);
}

# Set modhash
sub parse_modhash {
    my $self        = shift;
    my $response    = shift;

    my $decoded = from_json ($response->content);
    $self->modhash ($decoded->{json}{data}{modhash});
}

# takes link, returns post ID
sub parse_link {
    my $self = shift;
    my $link = shift;

    my ($id) = $link =~ /comments\/(\w+)\//i;
    return $id;
}

#>---------------------------------------------------<#
#  Main Methods
#>---------------------------------------------------<#

# Login to reddit
sub login {
    my $self = shift;
    
    if (@_) {
        $self->user ($_[0]);
        $self->passwd ($_[1]);
    }
    my $response = $self->ua->post($self->login_url,
        {
            api_type    => $self->api_type,
            user        => $self->user,
            passwd      => $self->passwd,
        }
    );

    $self->set_cookie( $response);
#   print Dumper $response;
}

# Submit link to reddit
sub submit_link {
    my $self = shift;
    my ($title, $url, $subreddit) = @_;

    my $kind        = 'link';

    my $newpost     = $self->ua->post($self->submit_url,
        {
            uh      => $self->modhash,
            kind    => $kind,
            sr      => $subreddit || $self->subreddit,
            title   => $title,
            r       => $subreddit || $self->subreddit,
            url     => $url,
        }
    );

    my $json_content    = $newpost->content;
    my $decoded         = from_json $json_content;

    #returns link to new post if successful
    my $link = $decoded->{jquery}[18][3][0];
    my $id = $self->parse_link($link);

    return $id, $link;
}

sub submit_story {
    my $self = shift;
    my ($title, $text, $subreddit) = @_;

    my $kind        = 'self';

    my $newpost     = $self->ua->post($self->submit_url,
        {
            uh       => $self->modhash,
            kind     => $kind,
            sr       => $subreddit || $self->subreddit,
            r        => $subreddit || $self->subreddit,
            title    => $title,
            text     => $text,
        },
    );

    my $json_content    = $newpost->content;
    my $decoded         = from_json $json_content;

    #returns id and link to new post if successful
    my $link = $decoded->{jquery}[12][3][0];
    my $id = $self->parse_link($link);

    return $id, $link;
}

1;
__END__

=head1 NAME

WWW::Reddit - Perl extension for http://www.reddit.com, this module has been obsoleted and replaced by the Reddit module

=head1 SYNOPSIS

  use Reddit;
  
  # $username, $password, [$subreddit]
  $r = Reddit->new('Foo', 'Bar', 'Perl');

  # optionally, you may specify $username, $passwd and $subreddit here
  $r->login;

  # $title, $url, [$subreddit]
  # This overrides a subreddit set previously
  $r->submit_link( 'Test', 'http://example.com', 'NotPerl');

=head1 DESCRIPTION

Perl module for interacting with Reddit.

This module is still largely inprogress.

=head2 Requires

  common::sense
  LWP::Simple
  LWP::UserAgent
  JSON
  HTTP::Cookies

  For Testing:
  Data::Dumper

=head2 EXPORT

None.


=head1 SEE ALSO

https://github.com/reddit/reddit/wiki

=head1 AUTHOR

Jon A, E<lt>info[replacewithat]cyberspacelogistics[replacewithdot]comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by jon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
