package WebService::DMM;
use strict;
use warnings;
use 5.008_001;

use Carp ();
use URI;
use POSIX qw/strftime/;
use Furl;
use Encode ();
use XML::LibXML;

use WebService::DMM::Item;
use WebService::DMM::Response;
use WebService::DMM::Person::Actor;
use WebService::DMM::Person::Author;
use WebService::DMM::Person::Director;
use WebService::DMM::Person::Fighter;
use WebService::DMM::Delivery;
use WebService::DMM::Label;
use WebService::DMM::Maker;
use WebService::DMM::Series;

use utf8;

our $VERSION = '0.11';

my $agent_name = __PACKAGE__ . "/$VERSION";
our $UserAgent = Furl->new(agent => $agent_name);

my $ROOT_NODE;
my @supported_api_versions = ('2.00', '1.00');

sub __ua {
    $UserAgent ||= Furl->new(agent => $agent_name);
    $UserAgent;
}

sub new {
    my ($class, %args) = @_;

    for my $param (qw/affiliate_id api_id/) {
        unless (exists $args{$param}) {
            Carp::croak("missing mandatory parameter '$param'");
        }
    }

    _validate_affiliate_id($args{affiliate_id});

    bless {
        %args,
    }, $class;
}

sub _validate_affiliate_id {
    my $account = shift;

    unless ($account =~ m{9[0-9]{2}$}) {
        Carp::croak("Postfix of affiliate_id is '900--999'");
    }

    return 1;
}

my %validate_table = (
    hits    => \&_validate_hits_param,
    offset  => \&_validate_offset_param,
    sort    => \&_validate_sort_param,
);

sub search {
    my ($self, %args) = @_;

    my %param;

    # mandatory parameters
    $param{affiliate_id} = $self->{affiliate_id};
    $param{api_id}       = $self->{api_id};
    $param{operation}    = $args{operation} || 'ItemList';
    $param{version}      = _validate_version_param($args{version});
    $param{timestamp}    = $args{timestamp} || _format_current_time();
    $param{site}         = _validate_site_param($args{site});

    # optional parameters
    for my $p (qw/hits offset sort/) {
        if ($args{$p}) {
            $param{$p} = $validate_table{$p}->($args{$p});
        }
    }

    if ($args{service}) {
        my ($service, $floor)
            = _validate_service_floor(@args{'site', 'service', 'floor'});

        $param{service} = $service;
        $param{floor}   = $floor if defined $floor;
    }

    if ($args{keyword}) {
        $param{keyword} = Encode::encode('euc-jp', $args{keyword});
    }

    _set_root_node_name($param{version});

    $self->_send_request(%param);
}

sub _set_root_node_name {
    my $version = shift;

    # API 1.00 mistake spelling 'response'
    $ROOT_NODE = $version eq '1.00' ? 'responce' : 'response';
}

sub _validate_version_param {
    my $version = shift;
    return '2.00' unless defined $version;

    unless (grep { $version eq $_ } @supported_api_versions) {
        Carp::croak("Invalid version '$version'");
    }

    return $version;
}

sub _validate_sort_param {
    my $sort = shift;
    my @sort_values = qw(rank +price -price date review);

    unless (grep {$sort eq $_} @sort_values) {
        Carp::croak("'sort' parameter should be (@sort_values)");
    }

    return $sort;
}

sub _validate_site_param {
    my $site = shift;

    unless (defined $site) {
        Carp::croak("'site' parameter is mandatory parameter");
    }

    unless ($site eq 'DMM.co.jp' || $site eq 'DMM.com') {
        Carp::croak("'site' parameter should be 'DMM.co.jp' or 'DMM.com'");
    }

    return $site;
}

sub _validate_hits_param {
    my $hits = shift;

    unless ($hits >= 1 && $hits <= 100) {
        Carp::croak("'hits' parameter should be 1 <= n <= 100");
    }

    return $hits;
}

sub _validate_offset_param {
    my $offset = shift;

    unless ($offset >= 1) {
        Carp::croak("'offset' parameter should be positive number(n >= 1)");
    }

    return $offset;
}

sub _format_current_time {
    strftime '%Y-%m-%d %T', localtime;
}

sub last_response {
    my $self = shift;
    $self->{_last_response};
}

sub _send_request {
    my ($self, %args)  = @_;

    my $uri = URI->new('http://affiliate-api.dmm.com/');
    $uri->query_form(%args);

    my $res = __ua()->get( $uri->as_string );
    unless ($res->is_success) {
        Carp::croak("Download failed: " . $uri->as_string);
    }

    $self->{_site} = $args{site}; # need for parsing actor information

    my $response = $self->_parse_response( \$res->content );
    $self->{_last_response} = $res;
    return $response;
}

sub _parse_response {
    my ($self, $content_ref) = @_;
    my $decoded = _decode_xml_utf8( $content_ref );

    my $dom = XML::LibXML->load_xml(string => $decoded);

    my $res = WebService::DMM::Response->new();
    my $message = _get_text_content(
        node => $dom, path => "/$ROOT_NODE/result/message"
    );
    if (defined $message) {
        my $cause = _get_text_content(
            node => $dom, path => "/$ROOT_NODE/result/errors/error/value"
        );
        $res->cause($cause);
        $res->is_success(0);
        return $res;
    }
    $res->is_success(1);

    for my $p (qw/result_count total_count first_position/) {
        my $text = _get_text_content(
            node => $dom, path => "/$ROOT_NODE/result/$p"
        );
        $res->$p($text);
    }

    $res->items( $self->_parse_items($dom) );
    return $res;
}

sub _parse_items {
    my ($self, $dom) = @_;

    my @items;
    for my $item_node ($dom->findnodes("/$ROOT_NODE/result/items/item")) {
        my %param;

        for my $p (qw/service_name floor_name category_name/) {
            $param{$p} = _get_text_content(node => $item_node, path => "$p");
        }

        for my $p (qw/content_id product_id URL affiliateURL title date/) {
            $param{$p} = $item_node->findvalue($p);
        }

        # for Smart Phone
        for my $p (qw/URLsp affiliateURLsp/) {
            $param{$p} = _get_text_content(node => $item_node, path => $p);
        }

        $param{image} = _image_urls($item_node);
        $param{sample_images} = _sample_images($item_node);

        ## item/prices/*
        for my $p (qw/price price_all list_price/) {
            $param{$p} = _get_text_content(node => $item_node, path => "prices/$p");
        }

        ## item/prices/deriveries/*
        $param{deliveries} = _delivery_info($item_node);

        ## item/iteminfo
        $param{keywords} = [
            map { $_->findvalue('name') } $item_node->findnodes('iteminfo/keyword')
        ];

        my ($actor_path, $node_num);
        if ($self->{_site} eq 'DMM.co.jp') {
            $actor_path = 'iteminfo/actress';
            $node_num   = 3; # actress node has another information
        } else {
            $actor_path = 'iteminfo/actor';
            $node_num   = 2;
        }
        $param{actors} = _personal_info('Actor', $item_node, $actor_path, $node_num);

        for my $p (qw/author director fighter/) {
            my $class = ucfirst $p;
            my $key   = $p . 's';
            $param{$key} = _personal_info($class, $item_node, "iteminfo/$p", 2);
        }

        for my $p (qw/series maker label/) {
            my $class = 'WebService::DMM::' . ucfirst $p;
            my @nodes = $item_node->findnodes("iteminfo/$p");
            next unless @nodes;

            $param{$p} = $class->new(
                id   => $nodes[0]->findvalue('id'),
                name => $nodes[0]->findvalue('name')
            );
        }

        for my $p (qw/jancode maker_product isbn stock/) {
            $param{$p} = _get_text_content(
                node => $item_node, path => "iteminfo/$p"
            );
        }

        push @items, WebService::DMM::Item->new(%param);
    }

    return \@items;
}

sub _get_text_content {
    my (%args) = @_;

    my @nodes = $args{node}->findnodes($args{path});
    return unless @nodes;

    return $nodes[0]->textContent;
}

sub _image_urls {
    my $item_node = shift;

    my %image_url;
    for my $p (qw/list small large/) {
        $image_url{$p} = $item_node->findvalue("imageURL/$p");
    }

    return \%image_url;
}

sub _sample_images {
    my $item_node = shift;

    my @image_nodes = $item_node->findnodes('sampleImageURL/sample_s/image');
    return [ map { $_->textContent } @image_nodes ];
}

sub _delivery_info {
    my $item_node = shift;

    my @deliveries;
    for my $node ($item_node->findnodes('iteminfo/prices/deliveries')) {
        push @deliveries, WebService::DMM::Delivery->new(
            type  => $node->findvalue('type'),
            price => $node->findvalue('price'),
        );
    }

    return scalar @deliveries != 0 ? \@deliveries : [];
}

sub _personal_info {
    my ($type, $node, $path, $node_num) = @_;

    my $class = 'WebService::DMM::Person::' . $type;

    my @persons;
    my @person_nodes = $node->findnodes($path);
    while (my ($name_node, $ruby_node) = splice @person_nodes, 0, $node_num) {
        my $name_str = $name_node->findvalue('name');
        my $id       = $name_node->findvalue('id');
        my $ruby_str = $ruby_node->findvalue('name');
        my $ruby_id  = $ruby_node->findvalue('id');

        unless ($ruby_id eq "${id}_ruby") {
            Carp::croak("Internal Error(ruby_id=$ruby_id, id=${id})");
        }

        my ($name, $name_aliases) = _separate_name($name_str);
        my ($ruby, $ruby_aliases) = _separate_name($ruby_str);

        my %param = ( id => $id, name => $name, ruby => $ruby );

        if (defined $name_aliases) {
            my @aliases;
            my $length = scalar @{$name_aliases};
            for my $i (0..($length - 1)) {
                my $ruby_alias = defined $ruby_aliases->[$i] ? $ruby_aliases->[$i] : '';
                push @aliases, {
                    name => $name_aliases->[$i],
                    ruby => $ruby_alias,
                },
            }

            $param{aliases} = \@aliases;
        } else {
            $param{aliases} = [];
        }

        push @persons, $class->new( %param );
    }

    my $retval = scalar @persons ? \@persons : [];
    return $retval;
}

sub _separate_name {
    my $name_str = shift;

    # Name paramter may have Zenkaku/Hankaku spaces and comma.
    if ($name_str =~ m{(.+?)[(（](.+?)[)）]}) {
        my ($name, $aliases_str) = ($1, $2);

        if ($aliases_str) {
            return ($name, [ split /[,、]/, $aliases_str ]);
        } else {
            return ($name, []);
        }
    } else {
        return ($name_str);
    }
}

# parsing XML encoded EUC-jp is difficult.
sub _decode_xml_utf8 {
    my $content_ref = shift;
    $$content_ref =~ s{encoding="euc-jp"}{encoding="utf-8"};

    return Encode::decode('euc-jp', $$content_ref);
}

sub items {
    my $self = shift;
    return @{$self->{items}};
}

my %service_floor = (
    'DMM.com' => {
        lod          => [qw/akb48 ske48/],
        digital      => [qw/bandai anime video idol cinema fight/],
        monthly      => [qw/toei animate shochikugeino idol cinepara dgc fleague/],
        digital_book => [qw/comic novel photo otherbooks/],
        pcsoft       => [qw/pcgame pcsoft/],
        mono         => [qw/dvd cd book game hobby kaden houseware gourmet/],
        rental       => [qw/rental_dvd ppr_dvd rental_cd ppr_cd comic/],
        nandemo      => [qw/fashion_ladies fashion_mems rental_iroiro/],
    },

    'DMM.co.jp' => {
        digital => [qw/videoa videoc nikkatsu anime photo/],
        monthly => [qw/shirouto nikkatsu paradisetv animech dream avstation
                       playgirl alice crystal hmp waap momotarobb moodyz
                       prestige jukujo sod mania s1 kmp mousouzoku/],
        ppm     => [qw/video videoc/],
        pcgame  => [qw/pcgame/],
        doujin  => [qw/doujin/],
        book    => [qw/book/],
        mono    => [qw/dvd goods anime pcgame book doujin/],
        rental  => [qw/rental_dvd ppr_dvd/],
    },
);

sub _validate_service_floor {
    my ($site, $service, $floor) = @_;

    unless (defined $floor) {
        return ($service, undef);
    }

    unless (exists $service_floor{$site}->{$service}) {
        my @keys = keys %service_floor;
        Carp::croak("Invalid service '$service': (@keys)");
    }

    my @floors = @{$service_floor{$site}->{$service}};
    unless (grep { $floor eq $_ } @floors) {
        Carp::croak("Invalid floor '$floor'(service $service): (@floors)");
    }

    return ($service, $floor);
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

WebService::DMM - DMM webservice module

=head1 SYNOPSIS

  use WebService::DMM;
  use Config::Pit;

  my $config = pit_get('dmm.co.jp', require => {
      affiliate_id => 'DMM affiliate ID',
      api_id       => 'DMM API ID',
  });

  my $dmm = WebService::DMM->new(
      affiliate_id => $config->{affiliate_id},
      api_id       => $config->{api_id},
  );

  my $response = $dmm->search( %params );
  die "Failed to request" unless $response->is_success;

  for my $item (@{$response->items}) {
      ....
  }

=head1 DESCRIPTION

WebService::DMM is DMM webservice module.
DMML<http://www.dmm.com> is Japanese shopping site.

=head1 INTERFACES

=head2 Class Methods

=head3 C<< WebService::DMM->new(%args) :WebService::DMM >>

Create and return a new WebService::DMM instance with I<%args>.

I<%args> must have following parameter:

=over

=item affiliate_id

Affiliate ID of DMM. Postfix of affliate_id should be 900-999.

=item api_id

API ID of DMM. Register your account in DMM and you can get API ID.

=back

=head2 Instance Method

=head3 $dmm->search(%param) : WebService::DMM::Response

I<%params> mandatory parameters are:

=over

=item operation :Str = "ItemList"

=item version :Str = "2.00"

Version should be '1.00' or '2.00'.

=item timestamp :Str = current time

Time format should be 'Year-Month-Day Hour:Minute:Second'
(strftime format is '%Y-%m-%d %T')

=item site :Str

Site, 'DMM.co.jp' or 'DMM.com'.

=back

I<%param> optional parameters are:

=over

=item hits :Int = 20

Number of items

=item offset :Int = 1

Offset of searched results

=item sort :Str = "rank"

Type of sort, 'rank', '+price', '-price', 'date', 'review'.

=item service :Str

See "SERVICE AND FLOOR" section

=item floor :Str

See "SERVICE AND FLOOR" section

=item keyword :Str

Search keyword. You can use DMM search keyword style.
Keyword should be string(not byte sequence).

=back

=head3 $dmm->last_response : Furl::Response

Return last response which is a Furl::Response instance.

=head1 SERVICE AND FLOOR

DMM.com services are:

=over

=item lod

akb48, ske48

=item digital

bandai, anime, video, idol, cinema, fight

=item monthly

toei, animate, shochikugeino, idol, cinepara, dgc, fleague

=item digital_book

comic, novel, photo, otherbooks

=item pcsoft

pcgame, pcsoft

=item mono

dvd, cd, book, game, hobby, kaden, houseware, gourmet

=item rental

rental_dvd, ppr_dvd, rental_cd, ppr_cd, comic

=item nandemo

fashion_ladies, fashion_mems, rental_iroiro

=back

DMM.co.jp services are:

=over

=item digital

videoa, videoc, nikkatsu, anime, photo

=item monthly

shirouto, nikkatsu, paradisetv, animech, dream, avstation, playgirl, alice,
crystal, hmp, waap, momotarobb, moodyz, prestige, jukujo, sod, mania, s1, kmp,
mousouzoku

=item ppm

video, videoc

=item pcgame

pcgame

=item doujin

doujin

=item book

book

=item mono

dvd, good, anime, pcgame, book, doujin

=item rental

rental_dvd, ppr_dvd

=back

=head1 CUSTOMIZE USER AGENT

You can specify your own instance of L<Furl> to set $WebService::DMM::UserAgent.

    $WebService::DMM::UserAgent = Furl->new( your_own_paramter );

=head1 EXAMPLES

There are many examples in the "eg/" directory in this distribution.

=head1 AUTHOR

Syohei YOSHIDA E<lt>syohex@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2013 - Syohei YOSHIDA

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Official Guide L<https://affiliate.dmm.com/api/guide/>

=cut
