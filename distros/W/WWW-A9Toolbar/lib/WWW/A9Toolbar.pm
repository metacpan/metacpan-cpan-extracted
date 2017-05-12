#!/usr/bin/perl -w

package WWW::A9Toolbar;

use strict;
# use Data::Dumper;
# use Data::Dump::Streamer 'Dumper';
use WWW::Mechanize;
use WWW::Mechanize::FormFiller;
use URI;
use URI::URL;
use URI::QueryParam;
use Net::DNS;
use XML::Simple;
use List::MoreUtils 'apply';

our $VERSION = '0.01';

sub new
{
    my ($class, $args) = @_;

    $args = check_new_options($args);
    my $self = bless($args, $class);

    $self->{toolbarapiurl} = 'http://client.a9.com/api/toolbarapi/toolbar';
    $self->{jspurl}        = 'http://a9.com/-/search/updBm.jsp';
    $self->{lastbookmarkfetch} = 0;
    $self->connect() if($self->{connect});

    return $self;
}

sub check_new_options
{
    my ($args) = @_;

    # check for email, password and connect
    return $args;
}

sub connect
{
    my ($self) = @_;

    if(!$self->{email} || !$self->{password})
    {
        warn "No email or password specified!";
        return;
    }

    if($self->{agent})
    {
        warn "Already connected!";
        return;
    }

    my $agent = WWW::Mechanize->new( autocheck => 1 );
    $self->{agent} = $agent;

    my $formfiller = WWW::Mechanize::FormFiller->new();
    $agent->env_proxy();
    my $cookies = HTTP::Cookies->new();
    $agent->cookie_jar($cookies);

    $agent->get('http://a9.com/-/sign-in/a9SignIn.jsp?ss=1');
    $agent->form(1) if $agent->forms and scalar @{$agent->forms};
    $formfiller->add_filler( 'email' => Fixed => $self->{email} );
    $formfiller->add_filler( 'password' => Fixed => $self->{password} );
    $formfiller->fill_form($agent->current_form);
    $agent->submit();
    $self->{cookies} = $cookies;
    $self->scan_cookies();

## What happens on error?

    return 1;
}

sub customer_id
{
    my ($self) = @_;

    return $self->{'customer-id'} if($self->{'customer-id'});

    if(!$self->{cookies})
    {
        warn "No cookies found, not connected?";
        return undef;
    }
    
    $self->scan_cookies();

    return $self->{'customer-id'} if($self->{'customer-id'});

    return;
}

sub scan_cookies
{
    my ($self) = @_;

    return unless($self->{cookies});

    my ($id, $prefs, $name, $perm);

    my $scansub = sub {
        my ($version, $key, $val, $path, $domain, $port, $path_spec, $secure, $expires, $discard, $hash) = @_;
        if($domain eq 'a9.com')
        {
            $prefs = $val if($key eq 'a9Prefs');
            $id    = $val if($key eq 'a9id');
            $name  = $val if($key eq 'a9name');
            $perm  = $val if($key eq 'a9Perm');
        }
    };

    $self->{cookies}->scan( $scansub );

    $self->{'customer-id'} = $id;
    $self->{prefs}         = $prefs;
    $self->{name}          = $name;
    $self->{perm}          = $perm;
}

sub get_userdata
{
    my ($self) = @_;

    return $self->{userdata} if($self->{userdata});
    
    my $uri = URI->new($self->{toolbarapiurl}, 'http');
    my $method = 'basicuserdataunique';
    $uri->query_param('method'      => $method);
    $uri->query_param('customer-id' => $self->customer_id());
#    print $uri->as_string(), "\n";
    $self->{agent}->get($uri->as_string());
    
#    print $self->{agent}->content(), "\n";
    my $xmlobj = XMLin($self->{agent}->content());

    my $columns = $xmlobj->{columns};
    my $newcolumns;
    while($columns =~ s/\{id:"([^"]+)", name:"([^"]+)"\}//)
    {
        push @$newcolumns, {id => $1, name => $2};
    }
    $xmlobj->{columns} = $newcolumns;

    $self->{userdata} = $xmlobj;
    return $xmlobj;
}

sub get_bookmarks
{
    my ($self, $args) = @_;
    $args->{since} = $self->{lastbookmarkfetch} || 0 
        if(!defined $args->{since});
    if($args->{since} < $self->{lastbookmarkfetch})
    {
        return $self->{bookmarks};
    }
    $args->{since} *= 1000 if($args->{since} < 9999999999);

    my $uri = URI->new($self->{toolbarapiurl}, 'http');
    my $method = 'GetBookmarksChangedSinceTime';
    $uri->query_param('method'      => $method);
    $uri->query_param('customer-id' => $self->customer_id());
    $uri->query_param('bmtimestamp' => $args->{since});
    $uri->query_param('useAPI'      => 2);
    $uri->query_param('timestamp'   => $args->{since});
    $uri->query_param('clientid'    => 2);
    $uri->query_param('passback'    => 1);

    $self->{agent}->get($uri->as_string());

    my $xmlobj = XMLin($self->{agent}->content(), ForceArray => ['BookmarkEntry']);
    $self->{lastbookmarkfetch} = $xmlobj->{'a9'}{'getbookmarkschangedsincetime'}{'LastReturnedTimestamp'};

    foreach my $bm (@{$xmlobj->{'a9'}{'getbookmarkschangedsincetime'}{'BookmarkEntry'}})
    {
        $self->{bookmarks}{$bm->{guid}} = $bm;
    }

    my $prev;
    foreach my $b (values %{$self->{bookmarks}})
    {
#        $b = $bm->{guid};
        $b->{previous} = $prev;
        $prev->{next} = $b;
        $prev = $b;
    }
    $prev->{next} = undef;

#    print Dumper($self->{bookmarks});

    $self->{bookmarks} ||= {};

    return values %{$self->{bookmarks}};
#    print Dumper($self->{bookmarks});
}

sub find_bookmarks
{
    my ($self, $args) = @_;

    if(!$args->{title} && !$args->{url})
    {
        warn "Can't find bookmark without url or title";
        return;
    }
    $args->{title} ||= qr//;
    $args->{url}   ||= qr//;

    $self->get_bookmarks() if(!$self->{bookmarks});

    my @bookmarks = map {$_->{guid} } $self->{bookmarks};
    @bookmarks = grep { ( $_->{title} =~ /$args->{title}/ ||
                          ($_->{url} && $_->{url} =~ /$args->{url}/)) &&
                          $_->{deleted} eq 'false' } 
                             @bookmarks;

    @bookmarks = apply { delete $_->{next}; delete $_->{previous} } @bookmarks;

    return @bookmarks;

}

sub add_bookmark
{
    my ($self, $args) = @_;
#    print Dumper($args);
    my ($title, $url, $type, $parent, $before) 
        = @{$args}{qw/title url type parent before/};
    
    if(!$self->{bookmarks})
    {
        warn "Call get_bookmarks before trying to add any bookmarks.";
        return undef;
    }

    if($type ne 'folder' && $type ne 'url')
    {
        warn "Wrong type $type passed to get_bookmarks, use 'url' or 'folder'";
        return undef;
    }

    $parent ||= {guid => 0};

    my @sorted = sort {$a->{ordinal} <=> $b->{ordinal}} 
             values(%{$self->{bookmarks}});

    my $after = $before->{previous} if($before);
    if(!$before)
    {
        $before = $sorted[0];
        $after->{ordinal} = 0;
    }

    my $ordinal = $before->{ordinal} - 
        ($before->{ordinal} - $after->{ordinal})/2;

    my $method = 'AddBookmark';
    my $uri = URI->new($self->{toolbarapiurl}, 'http');
    $uri->query_param('method'      => $method);
    $uri->query_param('customer-id' => $self->customer_id());
    $uri->query_param('passback'    => 1);

    my %vars = ('clientid' => 2,
                'parentguid'  => $parent->{guid} || 0,
                'ordinal'     => $ordinal,
                'bmtype'      => $type,
                'title'       => $title,
                'url'         => $url || '',
                'useAPI'      => 2);

    $self->{agent}->post($uri->as_string(), \%vars);

#    print Dumper($self->{agent}->content);
    my $xmlresponse = XMLin($self->{agent}->content);

#    print Dumper($xmlresponse);
    if($xmlresponse->{status}{code} == 200)
    {
        # woo it worked
        $self->get_bookmarks({since => $self->{lastbookmarkfetch}});
        return $xmlresponse->{a9}{addbookmark};
    }

    warn "Failed to create bookmark n add_bookmark, " . 
        $xmlresponse->{status}{code} .
        ' ' . $xmlresponse->{status}{text};
    return undef;
}

sub delete_bookmark
{
    my ($self, $args) = @_;

    if(ref($args) ne 'ARRAY')
    {
        $args = [ $args ];
    }

    foreach my $bk (@$args)
    {
        if(!$bk->{guid})
        {
            warn "Bookmark without GUID, skipping";
            return undef;
        }
        my $method = 'deletebookmark';
        my $uri = URI->new($self->{jspurl}, 'http');
        $uri->query_param('method', $method);
        $uri->query_param('clientid', 1);
        $uri->query_param('guid', $bk->{guid});
#        print "Running", $uri->as_string(), "\n";
        $self->{agent}->get($uri->as_string());
        my $xmlresult = XMLin($self->{agent}->content);
#        print Dumper($xmlresult);
        if($xmlresult->{status} ne 'success')
        {
            warn "Failed to delete " . $bk->{title};
            last;
        }
    }

    $self->get_bookmarks({since => $self->{lastbookmarkfetch}});
    return 1;
}

sub get_diary_entries
{
    my ($self, $args) = @_;

    my $method = 'AllDiary';
    my $uri = URI->new($self->{toolbarapiurl}, 'http');
    $uri->query_param('method', $method);
    
    $self->{agent}->get($uri->as_string());
    my $xmlresponse = XMLin($self->{agent}->content);

    print Dumper($xmlresponse);

## POST!
## wants a url?
}

sub add_diary_entry
{
    my ($self, $args) = @_;
    
    if(!$args->{url} || !$args->{text} || !$args->{title})
    {
        warn "add_diary_entry needs a url and a text argument";
        return;
    }

    my $diaryuri = URI->new($args->{url})->canonical();
    my $domain = $diaryuri->host();
    my $res = new Net::DNS::Resolver;
    $res->tcp_timeout(10);
    my $resolved;
    do 
    {
        $domain =~ s/(.+?)\.//;
        $resolved = $res->query($domain, 'SOA');
    } until($resolved && ($resolved->answer)[0]->name eq $domain);

    my $method = 'AddDiaryEntry';
    my $uri = URI->new($self->{toolbarapiurl}, 'http');
    $uri->query_param('method', $method);
    $uri->query_param('customer-id', $self->customer_id());
    $uri->query_param('passback', 1);

    my %qvars = ('url' => $args->{url},
                 'domain' => $domain,
                 'shortannot' => $args->{text},
                 'clientid'   => 2,
                 'pagetitle'  => $args->{title},
                 'longannot'  => $args->{text},
                 'toolbarVer' => '1.3.1.154',
                 'debug'      => 'true',
                 );

    $self->{agent}->post($uri->as_string(), \%qvars);

    my $xmlresponse = XMLin($self->{agent}->content);

    return 1 if($xmlresponse->{status}{code} == 200);

    warn "Can't create diary entry: " . $xmlresponse->{status}{text};
    return undef;
}

sub remove_diary_entry
{
    my ($self, $args) = @_;

    if(!$args->{url})
    {
        warn "remove_diary_entry: URL argument missing";
        return;
    }

    my $method = 'removeEntry';
    my $uri = URI->new('http://diary.a9.com/-/diary/', 'http');
    $uri->query_param('method', $method);
    $uri->query_param('url', $args->{url});
    $self->{agent}->get($uri->as_string);

}


1;


__END__

=head1 NAME

WWW::A9Toolbar - A class to allow perl to access the a9.com toolbar.

=head1 VERSION

This documentation refers to version 0.01.

=head1 SYNOPSIS

 use WWW::A9Toolbar;
 my $a9 = WWW::A9Toolbar->new( { email => 'my@email.address',
                                 password => 'mya9password',
                                 connect  => 1 } );
 my @bookmarks = $a9->find_bookmarks({ title => qr/searchtext/ });
 
 my $newbookmark = $a9->add_bookmark({ title => 'My Bookmark',
                                       url   => 'http://mybookmark.com',
                                       type  => 'url' });

=head1 DESCRIPTION

The WWW::A9Toolbar class implements the functions provided by the a9.com toolbar and interface. The toolbar allows a9.com users to view their a9.com bookmarks, remove and edit them. It also allows annotating of URLs via the diary entry textfield.

So far this module supports the following methods:

=head1 METHODS

=head2 new (constructor)

 my $a9 = WWW::A9Toolbar->new( { email => 'my@email.address',
                                 password => 'mya9password',
                                 connect  => 1 } ); 

The new constructor creates and returns a WWW::A9Toolbar object, it should be passed the a9 login credentials as a hashref. Optionally, if connect => 1 is passed to the constructor, it will also connect to the service.

=head2 connect (method)

 $a9->connect();

Connect to the a9.com service, using the credentials supplied to the new constructor. Returns true on success.

=head2 customer_id (method)

 my $id = $a9->customer_id();

Returns the users current customer-id, which is unique for each connection to the a9.com service.

=head2 scan_cookies (method)

 $a9->scan_cookies();

Extracts the data from the cookies. Not much use at the moment.

=head2 get_userdata (method)

 my $userdata = $a9->get_userdata();

Fetches the user data for this account, returns a hashref containing the users nickname, the date they agreed to the terms of use, their uniquekey and a list of columns they have set in their a9.com preferences.

=head2 get_bookmarks (method)

 my @bookmarks = $a9->get_bookmarks({ since => time() - 3600 });

Returns all the bookmarks saved with a9.com. Optionally causes the module to refetch all bookmarks created since the given epoch time. The data returned is a list of hashrefs, each containing the fields: 

=over 

=item guid - A unique ID for the bookmark

=item parentguid - A unique ID for the bookmarks parent folder, 0 if it is at the top level.

=item ordinal - A real number used for sorting the bookmarks. (99999 for deleted items)

=item bmtype - The item type, "folder" or "url".

=item title - The title of the URL or Folder.

=item url - The url of a url type bookmark, empty for a folder.

=item shortannotation - A note added to the bookmark, via the diary functions.

=item timestamp - The time that this bookmark was created, in miliseconds.

=item deleted - "true" for deleted items, "false" otherwise.

=head2 find_bookmarks (method)

 my @bookmarks = $a9->find_bookmarks({ title => qr/mytitle/,
                                       url   => qr/myurl/ });

A function to filter the bookmarks, looking for items that match the given regular expressions. At least one of title or url must be supplied.

=head2 add_bookmark (method)

 my $newbookmark = $a9->add_bookmark({ title => 'My Title',
                                       url   => 'http://foo.com',
                                       type  => 'url',
                                       parent => $parentitem,
                                       before => $beforeitem });

Create a new bookmark on a9.com. The completed bookmark will be returned, with the fields all filled in, as per the get_bookmarks() method. The type can be set to either "folder" or "url". The parent item should be a previousl fetched bookmark folder object. The before item should be a previously fetched bookmark object that this new bookmark will be placed before (i.e. it will get a lower ordinal, a9.com sorts it's display in ascending ordinal order).

=head2 delete_bookmark (method)

 $a9->delete_bookmark([$bookmark,$bookmark2]);

Sets the passed in list of bookmarks (arrayref), as deleted. Returns 1 on success, warns which items it could not delete on failure. The items passed in should be previously fetched bookmark objects.

=head2 get_diary_entries (method)

## Not implemented yet.

=head2 add_diary_entry (method)

 $a9->add_diary_entry({url  => 'http://foo.com',
                       text => 'This is the foo.com website',
                       title => 'Foo Com' });

Annotate a url using the given text. The url does not have to be a bookmarked url. The annotation will be returned in the 'shortannotation' field of the bookmark when fetched with get_bookmarks().

=head2 remove_diary_entry (method)

 $a9->remove_diary_entry({ url => 'http://foo.com' });

Remove a previously created annotation. The result of this is a redirect (302) if it succeeds, and thus is hard to check.

=head1 DEPENDENCIES

Modules used, version dependencies, core yes/no

L<WWW::Mechanize>

L<WWW::Mechanize::FormFiller>

L<URI>

L<URI::URL>

L<URI::QueryParam>

L<Net::DNS>

L<XML::Simple>

=head1 NOTES

Usage of this module implies an acceptance of the www.a9.com L<Terms Of Use|http://a9.com/-/company/toolbar-tou.jsp>.

=head1 TODO

Still missing are the search and search history functionality, fetching all diary entries, and fetching siteinfo data.

The hashrefs returned as bookmark "objects" could probably be more objectlike.

=head1 BUGS AND LIMITATIONS

None known currently, please email the author if you find
any

=head1 AUTHOR

Jess Robinson  C<< castaway@desert-island.m.isar.de >>

=head1 LICENCE AND COPYRIGHT
 
Copyright (c) 2005, Jess Robinson C<< castaway@desert-island.m.isar.de >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
  
=head1 DISCLAIMER OF WARRANTY
 
BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.
 
IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
