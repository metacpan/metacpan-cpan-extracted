package WebService::BuzzurlAPI;

=pod

=head1 NAME

WebService::BuzzurlAPI - Buzzurl WebService API

=head1 VERSION

0.02

=head1 SYNOPSIS

  use WebService::BuzzurlAPI;
  use strict;

  my $buzz = WebService::BuzzurlAPI->new(email => "your email", password => "your password");
  # readers api
  my $res = $buzz->readers( userid => "your userid" );
  if($res->is_success){
      my $json = $res->json;
      # do something
  }else{
      die $res->errstr;
  }

=head1 DESCRIPTION

Buzzurl is social bookmark service.

For more information on Buzzurl, visit the Buzzurl website. http://buzzurl.jp/.

API Reference. http://labs.ecnavi.jp/developer/buzzurl/api/

=cut

use strict;
use warnings;
use base qw(Class::Accessor);
use Carp;
use LWP::UserAgent;
use Readonly;
use UNIVERSAL::require;
use URI;
use WebService::BuzzurlAPI::Response;


__PACKAGE__->mk_accessors(qw(email password));
__PACKAGE__->mk_ro_accessors(qw(ua));

our $VERSION = 0.02;

Readonly my $API_URL_FORMAT => "http://api.buzzurl.jp/api/%s/v1/json";
Readonly my %ALIAS_PACKAGE  => (
                readers          => "Readers",
                favorites        => "Favorites",
                url_info         => "UrlInfo",
# counter redirect image api not supported
#               counter          => "Counter", 
                bookmark_count   => "BookmarkCount",
                user_articles    => "UserArticles",
                recent_articles  => "RecentArticles",
                keyword_articles => "KeywordArticles", 
                add              => "Add"
                );

sub import {

    no strict "refs";
    foreach my $method(keys %ALIAS_PACKAGE){

        *{$method} = sub {

                        my($self, %args) = @_;
                        my $pkg = sprintf "%s::Request::%s", __PACKAGE__, $ALIAS_PACKAGE{$method};
                        $pkg->require or croak($UNIVERSAL::require::ERROR);
                        my $req = $pkg->new( buzz => $self, uri => URI->new($API_URL_FORMAT) );
                        my $res = WebService::BuzzurlAPI::Response->new($req->request(%args));
                        $res->analysis_response;
                        return $res;
                    };
    }
}

=pod

=head1 METHOD

=head2 new

Create instance

Option:

  email    : your login email(require when add api)
  password : your login password(require when add api)

Example:

  my $buzz = WebService::BuzzurlAPI->new(email => "your email", password => "your password");

=cut

sub new {

    my($class, %args) = @_;
    my $ua = LWP::UserAgent->new;
    $ua->agent(sprintf "%s/%f", __PACKAGE__, $VERSION);
    return bless { 
        email    => $args{email},
        password => $args{password},
        ua       => $ua,
    }, $class || ref($class);
}

=pod

=head2 readers

Get readers userid

Options:

  userid  : userid(require)

Example:

  my $res = $buzz->readers( userid => "userid" );
  if($res->is_success){
    foreach my $userid(@{$res->json}){
        # do something...
    }
  }

=head2 favorites

Get favorites userid

Options:

  userid  : userid(require)

Example:

  my $res = $buzz->favorites( userid => "userid" );
  if($res->is_success){  
    foreach my $userid(@{$res->json}){
        # do something...
    }
  }

=head2 url_info

Get url info

Options:

  url    : url(require)

Example:

  my $res = $buzz->url_info( url => "http://your.wanted.domain/" );
  if($res->is_success){
     my $urlinfo = shift @{$res->json};
     my $url = $urlinfo->{url};
     my $title = $urlinfo->{title};
     my $user_num = $urlinfo->{user_num};
     foreach my $ref(@{$userinfo->{posts}}){
        my $keywords = $ref->{keywords};
        my $comment = $ref->{comment};
        my $date = $ref->{date};
        my $user_name = $ref->{user_name};
     }
     # do something...
  }

=head2 bookmark_count

Get bookmark count

Options:

  url   : url(require max:30)

Example:

  my $res = $buzz->bookmark_count( url => "http://your.wanted.domain" );
  # multiple
  # my $res = $buzz->bookmark_count( url => [ "http://your.wanted.domain", "http://your.wanted.domain2" ] );
  if($res->is_success){  
    foreach my $ref(@{$res->json}){
        my $url = $ref->{url};
        my $title = $ref->{title};
        my $users = $ref->{users};
        # do something...
    }
  }

=head2 user_articles

Get user articles

Options:

  userid  : userid(require)

Example:

  my $res = $buzz->user_articles( userid => "userid" );
  if($res->is_success){  
    foreach my $ref(@{$res->json}){
        my $url = $ref->{url};
        my $title = $ref->{title};
        my $comment = $ref->{comment};
        my $keywords = $ref->{keywords};
        # do something...
    }
  }

=head2 recent_articles

Get recent articles

Options:

  num       : get number(default:5)
  of        : page number(default:0)
  threshold : bookmark count threshold(default:0)

Example:

  my $res = $buzz->recent_articles( num => 0, of => 1, threshold => 3 );
  if($res->is_success){  
    foreach my $ref(@{$res->json}){
        my $url = $ref->{url};
        my $title = $ref->{title};
        my $user_num = $ref->{user_num};
        my $user_id = $ref->{user_id};
        my $register_date = $ref->{register_date};
        # do something...
    }
  }

=head2 keyword_articles

Get keyword articles

Options:

  userid  : userid(require)
  keyword : keyword string(require)

Example:

  my $res = $buzz->keyword_articles( userid => "userid", keyword => "keyword string" );
  if($res->is_success){  
    foreach my $ref(@{$res->json}){
        my $url = $ref->{url};
        my $title = $ref->{title};
        my $user_num = $ref->{user_num};
        my $user_id = $ref->{user_id};
        my $register_date = $ref->{register_date};
        # do something...
    }
  }

=head2 add

Add my bookmark(https + basic auth access)

Options:

  url     : bookmark url(require)
  title   : bookmark title
  comment : bookmark comment
  keyword : bookmark keyword(max:8)

Example:

  my $res = $buzz->add(
             url     => "http://your.register.domain/",
             title   => "my bookmark title",
             comment => "my bookmark comment",
             keyword => "my keyword",
             # multiple keyword
             keyword => [ "my keyword", "my keyword2" ],
            );
  if($res->is_success){
    print $res->json->{status} . "\n";
  }else{
    die $res->errstr;
  }

=head1 ACCESSOR METHOD

=head2 email

Get/Set login email

Example:

  $buzz->email("your email");
  my $email = $buzz->email;

=head2 password

Get/Set login password

Example:

  $buzz->password("your password");
  my $password = $buzz->password;

=head2 ua

Get LWP::UserAgent instance(Readonly)

Example:

  # LWP::UserAgent::timeout
  $buzz->ua->timeout(30);
  # LWP::UserAgent::env_proxy
  $buzz->ua->env_proxy;

=cut

1;

__END__

=head1 SEE ALSO

L<Class::Accessor> L<LWP::UserAgent> L<Readonly> L<UNIVERSAL::require> L<URI>

=head1 AUTHOR

Akira Horimoto

=head1 COPYRIGHT

Copyright (C) 2007 Akira Horimoto

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

