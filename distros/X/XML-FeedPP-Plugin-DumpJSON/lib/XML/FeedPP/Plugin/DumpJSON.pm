=head1 NAME

XML::FeedPP::Plugin::DumpJSON - FeedPP Plugin for generating JSON

=head1 SYNOPSIS

    use XML::FeedPP;
    my $feed = XML::FeedPP->new( 'index.rss' );
    $feed->limit_item( 10 );
    $feed->call( DumpJSON => 'index-rss.json' );

=head1 DESCRIPTION

This plugin generates a JSON data representation.

=head1 FILE OR STRING

If a JSON filename is C<undef> or C<''>, this module returns a JSON 
string instead of generating a JSON file.

    $feed->call( DumpJSON => 'feed.json' );     # generates a JSON file
    my $json = $feed->call( 'DumpJSON' );       # returns a JSON string

=head1 OPTIONS

This plugin allows some optoinal arguments following:

    my %opt = (
        slim             => 1,
        slim_element_add => [ 'media:thumbnail@url' ],
        slim_element     => [ 'link', 'title', 'pubDate' ],
    );
    my $json = $feed->call( DumpJSON => %opt );

=head2 slim

This plugin converts the whole feed into JSON format by default.
All elements and attribuets are included in a JSON generated.
If this boolean is true, some limited elements are only included.

=head2 slim_element_add

An array reference for element/attribute names
which is given by set()/get() method's format.
These elements/attributes are also appended for slim JSON.

=head2 slim_element

An array reference for element/attribute names.
The default list of limited elements is replaced by this value.

=head1 MODULE DEPENDENCIES

L<XML::FeedPP>, L<XML::TreePP> and L<JSON::Syck>

=head1 SEE ALSO

JSON, JavaScript Object Notation:
L<http://www.json.org/>

=head1 AUTHOR

Yusuke Kawasaki, http://www.kawa.net/

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2008 Yusuke Kawasaki. All rights reserved.
This program is free software; you can redistribute it 
and/or modify it under the same terms as Perl itself.

=cut
# ----------------------------------------------------------------
package XML::FeedPP::Plugin::DumpJSON;
use strict;
use vars qw( @ISA );
@ISA = qw( XML::FeedPP::Plugin );
use Carp;
use Symbol;
require 5.008;
use JSON::Syck;
# use JSON::PP;
# use JSON::XS;

use vars qw( $VERSION );
$VERSION = "0.33";

*XML::FeedPP::to_json = \&to_json;

my $SLIM_ELEM = [qw( 
    link title pubDate dc:date modified issued dc:subject category 
    image/url media:content@url media:thumbnail@url
)];
my $DEFAULT_OPTS = {
    slim_element    =>  undef,
    slim_element_add => undef,
    utf8_flag       =>  undef,
    use_json_syck   =>  1,
    use_json_pp     =>  undef,
};

sub run {
    my $class = shift;
    my $feed = shift;
    &to_json( $feed, @_ );
}

sub to_json {
    my $data = shift;
    my $file = shift if scalar @_ % 2;   # odd arguments
    my $opts = { %$DEFAULT_OPTS, @_ };
    $file = $opts->{file} if exists $opts->{file};

    # cut some elements out
    if ( $opts->{slim} || $opts->{slim_element} || $opts->{slim_element_add} ) {
        $data = &slim_feed( $data, $opts->{slim_element}, $opts->{slim_element_add} );
    }

    # perl object to json
    my $json = &dump_json( $data, $opts );

    # json to file
    if ( $file ) {
        &write_file( $file, $json, $opts );
    }
    $json;
}

sub write_file {
    my $file = shift;
    my $fh   = Symbol::gensym();
    open( $fh, ">$file" ) or Carp::croak "$! - $file";
    print $fh @_;
    close($fh);
}

sub dump_json {
    my $data = shift;
    my $opts = shift;

    my $usesyck = $opts->{use_json_syck};
    my $usepp   = $opts->{use_json_pp};
    $usesyck = 1 unless $usepp;
    $usepp   = 1 unless $usesyck;

    if ( $usesyck && defined $JSON::Syck::VERSION ) {
        return &dump_json_syck($data,$opts);
    }
    if ( $usepp && defined $JSON::VERSION ) {
        return &dump_json_pm($data,$opts);
    }
    if ( $usesyck ) {
        local $@;
        eval { require JSON::Syck; };
        return &dump_json_syck($data,$opts) unless $@;
    }
    if ( $usepp ) {
        local $@;
        eval { require JSON; };
        return &dump_json_pm($data,$opts) unless $@;
    }
    if ( $usepp ) {
        Carp::croak "JSON::PP or JSON::Syck is required";
    }
    else {
        Carp::croak "JSON::Syck is required";
    }
}

sub dump_json_syck {
    my $data = shift;
    my $opts = shift;
    # warn "[JSON::Syck $JSON::Syck::VERSION]\n";
    local $JSON::Syck::ImplicitUnicode = $opts->{utf8_flag} if exists $opts->{utf8_flag};
#   local $JSON::Syck::SingleQuote = 0;
    JSON::Syck::Dump($data);
}

sub dump_json_pm {
    my $data = shift;
    my $opts = shift;

    my $ver = ( $JSON::VERSION =~ /^([\d\.]+)/ )[0];
    Carp::croak "JSON::PP is not correctly loaded." unless $ver;
    return &dump_json_pp1($data,$opts) if ( $ver < 1.99 );
    return &dump_json_pp2($data,$opts);
}

sub dump_json_pp2 {
    my $data = shift;
    my $opts = shift;
    if ( ! defined $JSON::PP::VERSION ) {
        local $@;
        eval { require JSON::PP; };
        Carp::croak "JSON::PP is required" if $@;
    }
    # warn "[JSON::PP $JSON::PP::VERSION]\n";
    my $json = JSON::PP->new();
    my $utf8 = $opts->{utf8_flag} if exists $opts->{utf8_flag};
    my $bool = $utf8 ? 0 : 1;
    $json->utf8($bool);
    $json->allow_blessed(1);
    $json->as_nonblessed(1);
    $json->encode($data);
}

sub dump_json_pp1 {
    my $data = shift;
    my $opts = shift;
    # warn "[JSON $JSON::VERSION]\n";
    my $json = JSON->new();
    my $utf8 = $opts->{utf8_flag} if exists $opts->{utf8_flag};
    local $JSON::UTF8 = $utf8 ? 0 : 1;
    $json->convblessed(1);
    $json->objToJson($data)
}

sub slim_feed {
    my $feed = shift;
    my $list = shift || $SLIM_ELEM;
    my $add  = shift;
    my $slim = {};
    my $root = ( keys %$feed )[0];
    if ( ref $add ) {
        $list = [ @$list, @$add ];
    }
    my $channel = {};
    foreach my $key ( @$list ) {
        my $val = ( $key eq "link" ) ? $feed->link() : $feed->get($key);
        $channel->{$key} = $val if defined $val;
    }
    my $entries = [];
    foreach my $item ( $feed->get_item() ) {
        my $hash = {};
        foreach my $key ( @$list ) {
            my $val = ( $key eq "link" ) ? $item->link() : $item->get($key);
            $hash->{$key} = $val if defined $val;
        }
        push( @$entries, $hash );
    }
    my $data;
    if ( $root eq 'rss' ) {
        $channel->{item} = $entries;
        $data = { rss => { channel => $channel }};
    }
    elsif ( $root eq 'rdf:RDF' ) {
        $data = { 'rdf:RDF' => { channel => $channel, item => $entries }};
    }
    elsif ( $root eq 'feed' ) {
        $channel->{entry} = $entries;
        $data = { feed => $channel };
    }
    else {
        Carp::croak "Invalid feed type: $root";
    }
    $data;
}

# ----------------------------------------------------------------
1;
# ----------------------------------------------------------------
