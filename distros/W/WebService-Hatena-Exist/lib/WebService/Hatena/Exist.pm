package WebService::Hatena::Exist;

use strict;
use warnings;
use base qw( Class::ErrorHandler );
use URI::Fetch::SimpleCache;
use XML::Simple;
use Readonly;

Readonly our $HATENA_URL => q[http://d.hatena.ne.jp/exist?mode=xml&url=];

our $VERSION = '0.02';
our $TARGET_URL;

sub new {
    my($class,$self)=(shift,{@_});
    bless($self,$class);

    $self->target_url( $self->{'url'} ) if $self->{'url'};

    $self;
}

sub target_url {
    my $self = shift;
    if(@_) { $TARGET_URL = shift }
    return $TARGET_URL;
}

sub bookmark {
    shift->{'parse_ref'}->{'count'}->{'bookmark'}->{'content'};
}

sub antenna {
    shift->{'parse_ref'}->{'count'}->{'antenna'}->{'content'};
}

sub diary {
    shift->{'parse_ref'}->{'count'}->{'diary'}->{'content'};
}

sub parse_ref {
    shift->{'parse_ref'};
}

sub feed {
    shift->{'feed'};
}

sub get_feed {
    my $self = shift;

    my $get_url = $HATENA_URL.$self->target_url;

    my $res = URI::Fetch::SimpleCache->fetch(
        $get_url,
        Cache                 => $self->{'Cache'},
        Cache_root            => $self->{'Cache_root'},
        Cache_default_expires => $self->{'Cache_default_expires'},
        UserAgent             => $self->{'ua'},
    ) or return $self->error( URI::Fetch::SimpleCache->errstr );

    $self->{'feed'}      = $res->content;
    $self->{'parse_ref'} = $self->parse_feed;

    $self->{'feed'};
}

sub parse_feed {
    XMLin(shift->{'feed'});
}

1;
__END__

=head1 NAME

WebService::Hatena::Exist - Interface to the HATENA exist API

=head1 VERSION

This documentation refers to WebService::Hatena::Exist version 0.02

=head1 SYNOPSIS

    #! /usr/bin/perl -w
    
    use strict;
    use WebService::Hatena::Exist;
    use Data::Dumper;
    
    my $h = WebService::Hatena::Exist->new(
        url => 'http://www.hatena.ne.jp/',
    );
    
    if ( ! $h->get_feed ) {
        print $h->errstr;
        exit;
    }
    
    print $h->target_url , "\n";
    
    print "feed\n";
    print $h->feed,"\n";
    
    print "bookmark\n";
    print $h->bookmark,"\n";
    
    print "antenna\n";
    print $h->antenna,"\n";
    
    print "diary\n";
    print $h->diary,"\n";
    
    print Dumper($h->parse_ref);
    

=head1 DESCRIPTION

"WebService::Hatena::Exist" provides an interface to the HATENA exist API.
HATENA exist API is REST API.
To use HATENA exist API easily, this is made. 

=head1 METHOD

=head2 new
    
    my $h = WebService::Hatena::Exist->new(
        url   => 'http://www.hatena.ne.jp/',
        ua                    => $ua,  # LWP's object
        Cache                 => $ca,  # Cache::Cache's object
        Cache_root            => '',
        Cache_default_expires => '',
    );

Creates and returns new WebService::Hatena::Exist object.
If you have already had LWP::UserAgent's object,
LWP::UserAgent's object can be used by WebService::Hatena::Exist. 
If you have already had Cache::Cache's object,
Cache::Cache's object can be used by WebService::Hatena::Exist. 

=over 4

=back

=head3 OPTIONS

=over 4

url ,It's that wants to investigate. 
ua is LWP::UserAgent's object.
Cache is Cache::Cache's object.
Cache_root is Cache::Cache's local cache path.
Cache_default_expires is cache time.

=back

=head2 target_url

=over 4

    $h->target_url('http://search.cpan.org/');

You can change target url on this method.

=back

=head2 get_feed

=over 4

    $h->get_feed;

You can get Hatena exist feed on this method.
This method executes parse_feed method. 
And, bookmark, antenna, diary, parse_ref, and feed are set. 

=back

=head2 bookmark

=over 4

    $h->bookmark;

Count of Bookmark can be acquired. 

=back

=head2 antenna

=over 4

    $h->antenna;

Count of Antenna can be acquired. 

=back

=head2 diary

=over 4

    $h->diary;

Count of Diary can be acquired. 

=back

=head2 parse_ref

=over 4

    $h->parse_ref;

HASH Ref of Hatena Exist Feed can be acquired. 

=back

=head2 feed

=over 4

    $h->feed;

Feed of Hatena Exist can be acquired. 

=back

=head2 parse_feed

=over 4

This parse_feed method is called from get_feed method. 
This method use XML::Simple.

=back

=head1 DEPENDENCIES

L<strict>,L<warnings>,L<Class::ErrorHandler>,L<URI::Fetch::SimpleCache>,L<XML::Simple>,L<Readonly>

=head1 SEE ALSO

=over 4

=item * Hatena exist API

http://d.hatena.ne.jp/keyword/%a4%cf%a4%c6%a4%caexist%20API

=back

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to Atsushi Kobayashi (E<lt>nekokak@cpan.orgE<gt>)
Patches are welcome.

=head1 AUTHOR

Atsushi Kobayashi, E<lt>nekokak@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Atsushi Kobayashi (E<lt>nekokak@cpan.orgE<gt>). All rights reserved.

This library is free software; you can redistribute it and/or modify it
 under the same terms as Perl itself. See L<perlartistic>.

=cut
