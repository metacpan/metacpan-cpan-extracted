package WebService::Rakuten;

our $VERSION = '0.05';

use 5.008008;
use strict;
use warnings;
{
    use Carp;
    use LWP::UserAgent;
    use JSON qw( from_json );
    use Unicode::Japanese;
}

my (
    $USER_AGENT_ALIAS, $OUTPUT_TYPE_REGEX, $DEFAULT_OUTPUT_TYPE,
    $MT_STR,           %RESPONSE_TYPE_FOR,
);
{
    use Readonly;

    Readonly $USER_AGENT_ALIAS    => __PACKAGE__ . "/$VERSION";
    Readonly $OUTPUT_TYPE_REGEX   => qr{\A (?: xml|perl|json ) \z}xms;
    Readonly $DEFAULT_OUTPUT_TYPE => 'perl';
    Readonly $MT_STR              => "";

    Readonly %RESPONSE_TYPE_FOR => (
        json => 'json',
        perl => 'json',
        xml  => 'rest',
    );
}

sub new {
    my $class = shift @_;

    my %params = _hashify(@_);

    croak "couldn't make sense of the parameters\n"
      if !keys %params;

    croak "developer_id is required\n"
      if !defined $params{developer_id} || !$params{developer_id};

    $params{affiliate_id} ||= $MT_STR;

    $params{output_type} ||= $DEFAULT_OUTPUT_TYPE;

    if ( $params{output_type} !~ $OUTPUT_TYPE_REGEX ) {

        carp "unrecognized output type requested ",
          "defaulting to $DEFAULT_OUTPUT_TYPE\n";

        $params{output_type} = $DEFAULT_OUTPUT_TYPE;
    }

    my $self = bless {
        output_type  => delete $params{output_type},
        developer_id => delete $params{developer_id},
        affiliate_id => delete $params{affiliate_id},
        ua           => LWP::UserAgent->new(),
    }, $class;

    $self->{ua}->default_header( 'User-Agent', $USER_AGENT_ALIAS );

    for my $unexpected ( keys %params ) {
        carp "unrecognized parameter: $unexpected\n";
    }

    return $self;
}

## Service Methods ##

sub simplehotelsearch {
    my $self = shift @_;

    my %params = _hashify(@_);

    my $api_url = $self->_build_url(
        developerId      => $self->{developer_id},
        affiliateId      => $self->{affiliate_id},
        operation        => 'SimpleHotelSearch',
        version          => '2008-11-13',
        url              => 'http://api.rakuten.co.jp/rws/2.0/',
        callBack         => $params{callBack},
        largeClassCode   => $params{largeClassCode},
        middleClassCode  => $params{middleClassCode},
        smallClassCode   => $params{smallClassCode},
        detailClassCode  => $params{detailClassCode},
        hotelNo          => $params{hotelNo},
        latitude         => $params{latitude},
        longitude        => $params{longitude},
        searchRadius     => $params{searchRadius},
        squeezeCondition => $params{squeezeCondition},
        carrier          => $params{carrier},
        hits             => $params{hits},
        datumType        => $params{datumType},
    );

    return $self->_get_results($api_url);
}

sub booksgamesearch {
    my $self = shift @_;

    my %params = _hashify(@_);

    my $api_url = $self->_build_url(
        developerId    => $self->{developer_id},
        affiliateId    => $self->{affiliate_id},
        operation      => 'BooksGameSearch',
        version        => '2009-04-15',
        url            => 'http://api.rakuten.co.jp/rws/2.0/',
        callBack       => $params{callBack},
        title          => $params{title},
        hardware       => $params{hardware},
        makerCode      => $params{makerCode},
        label          => $params{label},
        jan            => $params{jan},
        booksGenreId   => $params{booksGenreId},
        hits           => $params{hits},
        page           => $params{page},
        availability   => $params{availability},
        outOfStockFlag => $params{outOfStockFlag},
        sort           => $params{sort},
        carrier        => $params{carrier},
    );

    return $self->_get_results($api_url);
}

sub hoteldetailsearch {
    my $self = shift @_;

    my %params = _hashify(@_);

    croak "hoteldetailsearch: missing required parameter: hotelNo"
      if !defined $params{hotelNo};

    my $api_url = $self->_build_url(
        developerId => $self->{developer_id},
        affiliateId => $self->{affiliate_id},
        operation   => 'HotelDetailSearch',
        version     => '2009-03-26',
        url         => 'http://api.rakuten.co.jp/rws/2.0/',
        callBack    => $params{callBack},
        hotelNo     => $params{hotelNo},
        carrier     => $params{carrier},
        datumType   => $params{datumType},
    );

    return $self->_get_results($api_url);
}

sub gethotelchainlist {
    my $self = shift @_;

    my %params = _hashify(@_);

    my $api_url = $self->_build_url(
        developerId => $self->{developer_id},
        affiliateId => $self->{affiliate_id},
        operation   => 'GetHotelChainList',
        version     => '2009-05-12',
        url         => 'http://api.rakuten.co.jp/rws/2.0/',
        callBack    => $params{callBack},
    );

    return $self->_get_results($api_url);
}

sub bookssoftwaresearch {
    my $self = shift @_;

    my %params = _hashify(@_);

    my $api_url = $self->_build_url(
        developerId    => $self->{developer_id},
        affiliateId    => $self->{affiliate_id},
        operation      => 'BooksSoftwareSearch',
        version        => '2009-04-15',
        url            => 'http://api.rakuten.co.jp/rws/2.0/',
        callBack       => $params{callBack},
        title          => $params{title},
        os             => $params{os},
        makerCode      => $params{makerCode},
        label          => $params{label},
        jan            => $params{jan},
        booksGenreId   => $params{booksGenreId},
        hits           => $params{hits},
        page           => $params{page},
        availability   => $params{availability},
        outOfStockFlag => $params{outOfStockFlag},
        sort           => $params{sort},
        carrier        => $params{carrier},
    );

    return $self->_get_results($api_url);
}

sub bookscdsearch {
    my $self = shift @_;

    my %params = _hashify(@_);

    my $api_url = $self->_build_url(
        developerId    => $self->{developer_id},
        affiliateId    => $self->{affiliate_id},
        operation      => 'BooksCDSearch',
        version        => '2009-04-15',
        url            => 'http://api.rakuten.co.jp/rws/2.0/',
        callBack       => $params{callBack},
        title          => $params{title},
        artistName     => $params{artistName},
        label          => $params{label},
        jan            => $params{jan},
        booksGenreId   => $params{booksGenreId},
        hits           => $params{hits},
        page           => $params{page},
        availability   => $params{availability},
        outOfStockFlag => $params{outOfStockFlag},
        sort           => $params{sort},
        carrier        => $params{carrier},
    );

    return $self->_get_results($api_url);
}

sub vacanthotelsearch {
    my $self = shift @_;

    my %params = _hashify(@_);

    my @required = qw( checkinDate checkoutDate );
    for my $param (@required) {
        croak "vacanthotelsearch: missing required parameter: $param"
          if !defined $params{$param};
    }

    my $api_url = $self->_build_url(
        developerId        => $self->{developer_id},
        affiliateId        => $self->{affiliate_id},
        operation          => 'VacantHotelSearch',
        version            => '2009-06-25',
        url                => 'http://api.rakuten.co.jp/rws/2.0/',
        callBack           => $params{callBack},
        largeClassCode     => $params{largeClassCode},
        middleClassCode    => $params{middleClassCode},
        smallClassCode     => $params{smallClassCode},
        detailClassCode    => $params{detailClassCode},
        hotelNo            => $params{hotelNo},
        checkinDate        => $params{checkinDate},
        checkoutDate       => $params{checkoutDate},
        adultNum           => $params{adultNum},
        upClassNum         => $params{upClassNum},
        lowClassNum        => $params{lowClassNum},
        infantWithMBNum    => $params{infantWithMBNum},
        infantWithMNum     => $params{infantWithMNum},
        infantWithBNum     => $params{infantWithBNum},
        infantWithoutMBNum => $params{infantWithoutMBNum},
        roomNum            => $params{roomNum},
        maxCharge          => $params{maxCharge},
        minCharge          => $params{minCharge},
        latitude           => $params{latitude},
        longitude          => $params{longitude},
        searchRadius       => $params{searchRadius},
        squeezeCondition   => $params{squeezeCondition},
        carrier            => $params{carrier},
        datumType          => $params{datumType},
    );

    return $self->_get_results($api_url);
}

sub booksmagazinesearch {
    my $self = shift @_;

    my %params = _hashify(@_);

    my $api_url = $self->_build_url(
        developerId    => $self->{developer_id},
        affiliateId    => $self->{affiliate_id},
        operation      => 'BooksMagazineSearch',
        version        => '2009-04-15',
        url            => 'http://api.rakuten.co.jp/rws/2.0/',
        callBack       => $params{callBack},
        title          => $params{title},
        publisherName  => $params{publisherName},
        jan            => $params{jan},
        booksGenreId   => $params{booksGenreId},
        hits           => $params{hits},
        page           => $params{page},
        availability   => $params{availability},
        outOfStockFlag => $params{outOfStockFlag},
        sort           => $params{sort},
        carrier        => $params{carrier},
    );

    return $self->_get_results($api_url);
}

sub itemcodesearch {
    my $self = shift @_;

    my %params = _hashify(@_);

    croak "itemcodesearch: missing required parameter: itemCode"
      if !defined $params{itemCode};

    my $api_url = $self->_build_url(
        developerId => $self->{developer_id},
        operation   => 'ItemCodeSearch',
        version     => '2007-04-11',
        url         => 'http://api.rakuten.co.jp/rws/2.0/',
        itemCode    => $params{itemCode},
    );

    return $self->_get_results($api_url);
}

sub bookstotalsearch {
    my $self = shift @_;

    my %params = _hashify(@_);

    my $api_url = $self->_build_url(
        developerId    => $self->{developer_id},
        affiliateId    => $self->{affiliate_id},
        operation      => 'BooksTotalSearch',
        version        => '2009-04-15',
        url            => 'http://api.rakuten.co.jp/rws/2.0/',
        callBack       => $params{callBack},
        keyword        => $params{keyword},
        booksGenreId   => $params{booksGenreId},
        hits           => $params{hits},
        page           => $params{page},
        availability   => $params{availability},
        outOfStockFlag => $params{outOfStockFlag},
        sort           => $params{sort},
        field          => $params{field},
        carrier        => $params{carrier},
        orFlag         => $params{orFlag},
        NGKeyword      => $params{NGKeyword},
    );

    return $self->_get_results($api_url);
}

sub booksforeignbooksearch {
    my $self = shift @_;

    my %params = _hashify(@_);

    my $api_url = $self->_build_url(
        developerId    => $self->{developer_id},
        affiliateId    => $self->{affiliate_id},
        operation      => 'BooksForeignBookSearch',
        version        => '2009-04-15',
        url            => 'http://api.rakuten.co.jp/rws/2.0/',
        callBack       => $params{callBack},
        title          => $params{title},
        author         => $params{author},
        publisherName  => $params{publisherName},
        isbn           => $params{isbn},
        booksGenreId   => $params{booksGenreId},
        hits           => $params{hits},
        page           => $params{page},
        availability   => $params{availability},
        outOfStockFlag => $params{outOfStockFlag},
        sort           => $params{sort},
        carrier        => $params{carrier},
    );

    return $self->_get_results($api_url);
}

sub genresearch {
    my $self = shift @_;

    my %params = _hashify(@_);

    croak "genresearch: missing required parameter: genreId"
      if !defined $params{genreId};

    my $api_url = $self->_build_url(
        developerId => $self->{developer_id},
        operation   => 'GenreSearch',
        version     => '2007-04-11',
        url         => 'http://api.rakuten.co.jp/rws/2.0/',
        genreId     => $params{genreId},
    );

    return $self->_get_results($api_url);
}

sub auctionitemsearch {
    my $self = shift @_;

    my %params = _hashify(@_);

    my $api_url = $self->_build_url(
        developerId => $self->{developer_id},
        affiliateId => $self->{affiliate_id},
        operation   => 'AuctionItemSearch',
        version     => '2009-05-20',
        url         => 'http://api.rakuten.co.jp/rws/2.0/',
        callBack    => $params{callBack},
        keyword     => $params{keyword},
        genreId     => $params{genreId},
        hits        => $params{hits},
        page        => $params{page},
        minPrice    => $params{minPrice},
        maxPrice    => $params{maxPrice},
        sort        => $params{sort},
        blowFlag    => $params{blowFlag},
        itemType    => $params{itemType},
        newFlag     => $params{newFlag},
        field       => $params{field},
        carrier     => $params{carrier},
        imageFlag   => $params{imageFlag},
        orFlag      => $params{orFlag},
        NGKeyword   => $params{NGKeyword},
    );

    return $self->_get_results($api_url);
}

sub dynamicad {
    my $self = shift @_;

    my %params = _hashify(@_);

    my $api_url = $self->_build_url(
        developerId => $self->{developer_id},
        affiliateId => $self->{affiliate_id},
        url         => 'http://dynamic.rakuten.co.jp/rcm/1.0/i/',
        url         => $params{url},
        carrier     => $params{carrier},
        callBack    => $params{callBack},
    );

    return $self->_get_results($api_url);
}

sub cdsearch {
    my $self = shift @_;

    my %params = _hashify(@_);

    my $api_url = $self->_build_url(
        developerId          => $self->{developer_id},
        affiliateId          => $self->{affiliate_id},
        operation            => 'CDSearch',
        version              => '2007-10-25',
        url                  => 'http://api.rakuten.co.jp/rws/1.11/',
        callBack             => $params{callBack},
        keyword              => $params{keyword},
        genreId              => $params{genreId},
        hits                 => $params{hits},
        page                 => $params{page},
        sort                 => $params{sort},
        minPrice             => $params{minPrice},
        maxPrice             => $params{maxPrice},
        availability         => $params{availability},
        field                => $params{field},
        carrier              => $params{carrier},
        imageFlag            => $params{imageFlag},
        orFlag               => $params{orFlag},
        NGKeyword            => $params{NGKeyword},
        genreInformationFlag => $params{genreInformationFlag},
    );

    return $self->_get_results($api_url);
}

sub booksearch {
    my $self = shift @_;

    my %params = _hashify(@_);

    my $api_url = $self->_build_url(
        developerId          => $self->{developer_id},
        affiliateId          => $self->{affiliate_id},
        operation            => 'BookSearch',
        version              => '2007-10-25',
        url                  => 'http://api.rakuten.co.jp/rws/1.11/',
        callBack             => $params{callBack},
        keyword              => $params{keyword},
        genreId              => $params{genreId},
        hits                 => $params{hits},
        page                 => $params{page},
        sort                 => $params{sort},
        minPrice             => $params{minPrice},
        maxPrice             => $params{maxPrice},
        availability         => $params{availability},
        field                => $params{field},
        carrier              => $params{carrier},
        imageFlag            => $params{imageFlag},
        orFlag               => $params{orFlag},
        NGKeyword            => $params{NGKeyword},
        genreInformationFlag => $params{genreInformationFlag},
    );

    return $self->_get_results($api_url);
}

sub getareaclass {
    my $self = shift @_;

    my %params = _hashify(@_);

    my $api_url = $self->_build_url(
        developerId => $self->{developer_id},
        affiliateId => $self->{affiliate_id},
        operation   => 'GetAreaClass',
        version     => '2009-03-26',
        url         => 'http://api.rakuten.co.jp/rws/2.0/',
        callBack    => $params{callBack},
    );

    return $self->_get_results($api_url);
}

sub hotelranking {
    my $self = shift @_;

    my %params = _hashify(@_);

    croak "hotelranking: missing required parameter: genre"
      if !defined $params{genre};

    my $api_url = $self->_build_url(
        developerId => $self->{developer_id},
        affiliateId => $self->{affiliate_id},
        operation   => 'HotelRanking',
        version     => '2009-06-25',
        url         => 'http://api.rakuten.co.jp/rws/2.0/',
        callBack    => $params{callBack},
        genre       => $params{genre},
        carrier     => $params{carrier},
    );

    return $self->_get_results($api_url);
}

sub catalogsearch {
    my $self = shift @_;

    my %params = _hashify(@_);

    my $api_url = $self->_build_url(
        developerId          => $self->{developer_id},
        affiliateId          => $self->{affiliate_id},
        operation            => 'CatalogSearch',
        version              => '2009-04-15',
        url                  => 'http://api.rakuten.co.jp/rws/2.0/',
        callBack             => $params{callBack},
        keyword              => $params{keyword},
        genreId              => $params{genreId},
        hits                 => $params{hits},
        page                 => $params{page},
        sort                 => $params{sort},
        field                => $params{field},
        imageFlag            => $params{imageFlag},
        releaseRange         => $params{releaseRange},
        orFlag               => $params{orFlag},
        NGKeyword            => $params{NGKeyword},
        genreInformationFlag => $params{genreInformationFlag},
    );

    return $self->_get_results($api_url);
}

sub booksdvdsearch {
    my $self = shift @_;

    my %params = _hashify(@_);

    my $api_url = $self->_build_url(
        developerId    => $self->{developer_id},
        affiliateId    => $self->{affiliate_id},
        operation      => 'BooksDVDSearch',
        version        => '2009-04-15',
        url            => 'http://api.rakuten.co.jp/rws/2.0/',
        callBack       => $params{callBack},
        title          => $params{title},
        artistName     => $params{artistName},
        label          => $params{label},
        jan            => $params{jan},
        booksGenreId   => $params{booksGenreId},
        hits           => $params{hits},
        page           => $params{page},
        availability   => $params{availability},
        outOfStockFlag => $params{outOfStockFlag},
        sort           => $params{sort},
        carrier        => $params{carrier},
    );

    return $self->_get_results($api_url);
}

sub keywordhotelsearch {
    my $self = shift @_;

    my %params = _hashify(@_);

    croak "keywordhotelsearch: missing required parameter: keyword"
      if !defined $params{keyword};

    my $api_url = $self->_build_url(
        developerId     => $self->{developer_id},
        affiliateId     => $self->{affiliate_id},
        operation       => 'KeywordHotelSearch',
        version         => '2009-04-23',
        url             => 'http://api.rakuten.co.jp/rws/2.0/',
        callBack        => $params{callBack},
        carrier         => $params{carrier},
        page            => $params{page},
        hits            => $params{hits},
        sumDisplayFlag  => $params{sumDisplayFlag},
        keyword         => $params{keyword},
        middleClassCode => $params{middleClassCode},
    );

    return $self->_get_results($api_url);
}

sub itemranking {
    my $self = shift @_;

    my %params = _hashify(@_);

    my $api_url = $self->_build_url(
        developerId => $self->{developer_id},
        affiliateId => $self->{affiliate_id},
        operation   => 'ItemRanking',
        version     => '2009-04-15',
        url         => 'http://api.rakuten.co.jp/rws/2.0/',
        callBack    => $params{callBack},
        genreId     => $params{genreId},
        age         => $params{age},
        sex         => $params{sex},
    );

    return $self->_get_results($api_url);
}

sub auctionitemcodesearch {
    my $self = shift @_;

    my %params = _hashify(@_);

    croak "auctionitemcodesearch: missing required parameter: itemCode"
      if !defined $params{itemCode};

    my $api_url = $self->_build_url(
        developerId => $self->{developer_id},
        affiliateId => $self->{affiliate_id},
        operation   => 'AuctionItemCodeSearch',
        version     => '2007-12-13',
        url         => 'http://api.rakuten.co.jp/rws/2.0/',
        callBack    => $params{callBack},
        itemCode    => $params{itemCode},
        carrier     => $params{carrier},
    );

    return $self->_get_results($api_url);
}

sub dvdsearch {
    my $self = shift @_;

    my %params = _hashify(@_);

    my $api_url = $self->_build_url(
        developerId          => $self->{developer_id},
        affiliateId          => $self->{affiliate_id},
        operation            => 'DVDSearch',
        version              => '2007-10-25',
        url                  => 'http://api.rakuten.co.jp/rws/1.11/',
        callBack             => $params{callBack},
        keyword              => $params{keyword},
        genreId              => $params{genreId},
        hits                 => $params{hits},
        page                 => $params{page},
        sort                 => $params{sort},
        minPrice             => $params{minPrice},
        maxPrice             => $params{maxPrice},
        availability         => $params{availability},
        field                => $params{field},
        carrier              => $params{carrier},
        imageFlag            => $params{imageFlag},
        orFlag               => $params{orFlag},
        NGKeyword            => $params{NGKeyword},
        genreInformationFlag => $params{genreInformationFlag},
    );

    return $self->_get_results($api_url);
}

sub itemsearch {
    my $self = shift @_;

    my %params = _hashify(@_);

    my $api_url = $self->_build_url(
        developerId          => $self->{developer_id},
        affiliateId          => $self->{affiliate_id},
        operation            => 'ItemSearch',
        version              => '2009-04-15',
        url                  => 'http://api.rakuten.co.jp/rws/2.0/',
        callBack             => $params{callBack},
        keyword              => $params{keyword},
        shopCode             => $params{shopCode},
        genreId              => $params{genreId},
        catalogCode          => $params{catalogCode},
        hits                 => $params{hits},
        page                 => $params{page},
        sort                 => $params{sort},
        minPrice             => $params{minPrice},
        maxPrice             => $params{maxPrice},
        availability         => $params{availability},
        field                => $params{field},
        carrier              => $params{carrier},
        imageFlag            => $params{imageFlag},
        orFlag               => $params{orFlag},
        NGKeyword            => $params{NGKeyword},
        genreInformationFlag => $params{genreInformationFlag},
        purchaseType         => $params{purchaseType},
    );

    return $self->_get_results($api_url);
}

sub booksbooksearch {
    my $self = shift @_;

    my %params = _hashify(@_);

    my $api_url = $self->_build_url(
        developerId    => $self->{developer_id},
        affiliateId    => $self->{affiliate_id},
        operation      => 'BooksBookSearch',
        version        => '2009-04-15',
        url            => 'http://api.rakuten.co.jp/rws/2.0/',
        callBack       => $params{callBack},
        title          => $params{title},
        author         => $params{author},
        publisherName  => $params{publisherName},
        size           => $params{size},
        isbn           => $params{isbn},
        booksGenreId   => $params{booksGenreId},
        hits           => $params{hits},
        page           => $params{page},
        availability   => $params{availability},
        outOfStockFlag => $params{outOfStockFlag},
        sort           => $params{sort},
        carrier        => $params{carrier},
    );

    return $self->_get_results($api_url);
}

sub booksgenresearch {
    my $self = shift @_;

    my %params = _hashify(@_);

    croak "booksgenresearch: missing required parameter: booksGenreId"
      if !defined $params{booksGenreId};

    my $api_url = $self->_build_url(
        developerId  => $self->{developer_id},
        operation    => 'BooksGenreSearch',
        version      => '2009-03-26',
        url          => 'http://api.rakuten.co.jp/rws/2.0/',
        booksGenreId => $params{booksGenreId},
    );

    return $self->_get_results($api_url);
}

## Internal Methods ##

sub _hashify {

    my %params;

    if ( @_ == 1 && ref $_[0] eq 'HASH' ) {
        %params = %{ $_[0] };
    }
    elsif ( @_ % 2 == 0 ) {
        %params = @_;
    }
    croak "couldn\'t make sense of the parameters\n"
      if !keys %params;

    return %params;
}

sub _get_results {
    my ( $self, $url ) = @_;

    my $results;
    {
        my $request = HTTP::Request->new( GET => $url );
        my $response = $self->{ua}->request($request);
        $results = $response->is_success ? $response->content : undef;
    }

    utf8::decode($results);

    return $results
      if $self->{output_type} =~ m/(?: xml|json )/xms;

    return from_json($results);
}

sub _build_url {
    my $self = shift @_;
    die "unbalanced args" if @_ % 2;
    my %params = @_;

    my $type = $RESPONSE_TYPE_FOR{ $self->{output_type} };

    my $url = ( delete $params{url} ) . $type;

    my $query_str = $MT_STR;
  PARAM:
    while ( my ( $name, $value ) = each %params ) {

        next PARAM
          if !$value;

        $query_str .= "&$name=" . _url_encode( $value, 'utf8', 'utf8' );
    }
    $query_str = substr $query_str, 1;

    return "$url?$query_str";
}

sub _url_encode {
    my ( $value, $from_encoding, $to_encoding ) = @_;

    # Defaults to utf8 -> euc if encoding is not specified
    $from_encoding ||= 'utf8';
    $to_encoding   ||= 'euc';

    # the easy cases: value is empty or is a number
    return $value
      if !$value || $value =~ m/\A \d+ \z/msx;

    my $encoded_value = $value;

    eval {
        $encoded_value =
          Unicode::Japanese->new( $value, $from_encoding )->$to_encoding();
    };
    if ($@) {
        warn "$@\n";
        return $value;
    }

    $encoded_value =~ s/([^\w\/ ])/"%" . uc( unpack("H2", $1) )/eg;
    $encoded_value =~ s/ /%20/g;
    $encoded_value =~ s/[+]/%2B/g;

    return $encoded_value;
}

1;
