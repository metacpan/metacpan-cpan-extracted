# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 145;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
    my $ftitle = "Title of the site";
    my $fdesc  = "Description of the site";
    my $ilink  = "http://www.kawa.net/";
# ----------------------------------------------------------------
    my $hash = {
        'elem1'             =>  'ELEM01',
        'elem2@attr2'       =>  'ATTR02',
        'elem3'             =>  'ELEM03',
        'elem3@attr3'       =>  'ATTR03',
        'elem4'             =>  'ELEM03',
        'elem4@attr4'       =>  'ATTR04',
        'elem4@attr5'       =>  'ATTR05',
        'elem4/elem6'       =>  'ELEM06',
        'elem7/elem8'       =>  'ELEM08',
        'elem7/elem8@attr8' =>  'ATTR08',
        'elem7/elem8'       =>  'ELEM08',
        'elem9/elem10'      =>  'ATTR10',
        'elem9/elem11'          =>  'ELEM10',
	'elem9/elem12@attr12'   =>  'ELEM12',
        '@attr13'           =>  'ATTR13',
    };
# ----------------------------------------------------------------
    my $noexists = [
        'not:exist',
        'not@exist',
        'not/exist',
        'not/exist@attr',
        'elem1/not:exist',
        'elem1/not:exist@attr',
        'elem2/not:exist',
        'elem2/not:exist@attr',
        'elem4/not:exist',
        'elem4/not:exist@attr',
    ];
# ----------------------------------------------------------------
    my $feeds = [
        XML::FeedPP::RDF->new(),
        XML::FeedPP::RSS->new(),
        XML::FeedPP::RDF->new(),
    ];
# ----------------------------------------------------------------
    foreach my $feed1 ( @$feeds ) {
        my $type = ref $feed1;
        $feed1->title( $ftitle );
        $feed1->set( %$hash );
        foreach my $key ( sort keys %$hash ) {
            is( $feed1->get($key), $hash->{$key}, "$type channel $key" );
        }
        foreach my $key ( @$noexists ) {
            ok( ! defined $feed1->get($key), "$type channel $key" );
        }
        my $item1 = $feed1->add_item( $ilink );
        $item1->set( %$hash );
        foreach my $key ( sort keys %$hash ) {
            is( $item1->get($key), $hash->{$key}, "$type item $key" );
        }
        foreach my $key ( @$noexists ) {
            ok( ! defined $item1->get($key), "$type item $key" );
        }
    }
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
