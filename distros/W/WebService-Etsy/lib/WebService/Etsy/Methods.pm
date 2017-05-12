
package WebService::Etsy::Methods;
use strict;
use warnings;

sub getMethodTable {
    my $self = shift;
    my $info = {
        name => 'getMethodTable',
        uri  => '/',
        type => 'Method',
        params => {},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Get a list of all methods available.",
    };
    return $self->_call_method( $info, @_ );
}

sub getCategory {
    my $self = shift;
    my $info = {
        name => 'getCategory',
        uri  => '/categories/:tag',
        type => 'Category',
        params => {'tag' => 'string'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Retrieves a top-level Category by tag.",
    };
    return $self->_call_method( $info, @_ );
}

sub getSubCategory {
    my $self = shift;
    my $info = {
        name => 'getSubCategory',
        uri  => '/categories/:tag/:subtag',
        type => 'Category',
        params => {'subtag' => 'string','tag' => 'string'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Retrieves a second-level Category by tag and subtag.",
    };
    return $self->_call_method( $info, @_ );
}

sub getSubSubCategory {
    my $self = shift;
    my $info = {
        name => 'getSubSubCategory',
        uri  => '/categories/:tag/:subtag/:subsubtag',
        type => 'Category',
        params => {'subsubtag' => 'string','subtag' => 'string','tag' => 'string'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Retrieves a third-level Category by tag, subtag and subsubtag.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllCountry {
    my $self = shift;
    my $info = {
        name => 'findAllCountry',
        uri  => '/countries',
        type => 'Country',
        params => {},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Finds all Country.",
    };
    return $self->_call_method( $info, @_ );
}

sub getCountry {
    my $self = shift;
    my $info = {
        name => 'getCountry',
        uri  => '/countries/:country_id',
        type => 'Country',
        params => {'country_id' => 'array(int)'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Retrieves a Country by id.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllFeaturedUsers {
    my $self = shift;
    my $info = {
        name => 'findAllFeaturedUsers',
        uri  => '/featured/users',
        type => 'FeaturedUser',
        params => {'limit' => 'int','offset' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'limit' => 25,'offset' => 0},
        description => "Finds all FeaturedUser.",
    };
    return $self->_call_method( $info, @_ );
}

sub getFeaturedUser {
    my $self = shift;
    my $info = {
        name => 'getFeaturedUser',
        uri  => '/featured/users/:featured_user_id',
        type => 'FeaturedUser',
        params => {'featured_user_id' => 'array(int)'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Retrieves a FeaturedUser by id.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllFeaturedListing {
    my $self = shift;
    my $info = {
        name => 'findAllFeaturedListing',
        uri  => '/homepages/listings/',
        type => 'FeaturedListing',
        params => {'limit' => 'int','offset' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'limit' => 25,'offset' => 0},
        description => "Finds all FeaturedListings regardless of Listing state",
    };
    return $self->_call_method( $info, @_ );
}

sub getFeaturedListing {
    my $self = shift;
    my $info = {
        name => 'getFeaturedListing',
        uri  => '/homepages/listings/:featured_listing_id',
        type => 'FeaturedListing',
        params => {'featured_listing_id' => 'array(int)'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Retrieves a FeaturedListing by id.",
    };
    return $self->_call_method( $info, @_ );
}

sub getFeaturedListingListing {
    my $self = shift;
    my $info = {
        name => 'getFeaturedListingListing',
        uri  => '/homepages/listings/:featured_listing_id/listing',
        type => 'Listing',
        params => {'featured_listing_id' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Retrieves a set of Listing objects associated to a FeaturedListing.",
    };
    return $self->_call_method( $info, @_ );
}

sub getFeaturedListingPicker {
    my $self = shift;
    my $info = {
        name => 'getFeaturedListingPicker',
        uri  => '/homepages/listings/:featured_listing_id/picker',
        type => 'FeaturedListingPicker',
        params => {'featured_listing_id' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Retrieves a set of FeaturedListingPicker objects associated to a FeaturedListing.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllFeaturedListingActive {
    my $self = shift;
    my $info = {
        name => 'findAllFeaturedListingActive',
        uri  => '/homepages/listings/active',
        type => 'FeaturedListing',
        params => {'limit' => 'int','offset' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'limit' => 25,'offset' => 0},
        description => "Finds all FeaturedListings that point to active Listings",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllFeaturedListingPickerActive {
    my $self = shift;
    my $info = {
        name => 'findAllFeaturedListingPickerActive',
        uri  => '/homepages/pickers/',
        type => 'FeaturedListingPicker',
        params => {'limit' => 'int','offset' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'limit' => 25,'offset' => 0},
        description => "Finds all FeaturedListingPicker in scope active.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllFeaturedListingPickerFeatured {
    my $self = shift;
    my $info = {
        name => 'findAllFeaturedListingPickerFeatured',
        uri  => '/homepages/pickers/:featured_listing_picker_id/featured',
        type => 'FeaturedListing',
        params => {'limit' => 'int','featured_listing_picker_id' => 'int','offset' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'limit' => 25,'offset' => 0},
        description => "Retrieves a set of FeaturedListing objects associated to a FeaturedListingPicker.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllFeaturedListingPickerListings {
    my $self = shift;
    my $info = {
        name => 'findAllFeaturedListingPickerListings',
        uri  => '/homepages/pickers/:featured_listing_picker_id/listings',
        type => 'Listing',
        params => {'limit' => 'int','featured_listing_picker_id' => 'int','offset' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'limit' => 25,'offset' => 0},
        description => "Retrieves a set of Listing objects associated to a FeaturedListingPicker.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllFeaturedListingPickerListingsActive {
    my $self = shift;
    my $info = {
        name => 'findAllFeaturedListingPickerListingsActive',
        uri  => '/homepages/pickers/:featured_listing_picker_id/listings/active',
        type => 'Listing',
        params => {'limit' => 'int','featured_listing_picker_id' => 'int','offset' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'limit' => 25,'offset' => 0},
        description => "Retrieves a set of Listing objects associated to a FeaturedListingPicker in scope active.",
    };
    return $self->_call_method( $info, @_ );
}

sub getListing {
    my $self = shift;
    my $info = {
        name => 'getListing',
        uri  => '/listings/:listing_id',
        type => 'Listing',
        params => {'listing_id' => 'array(int)'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Retrieves a Listing by id.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllListingFavoredBy {
    my $self = shift;
    my $info = {
        name => 'findAllListingFavoredBy',
        uri  => '/listings/:listing_id/favored-by',
        type => 'FavoriteListing',
        params => {'limit' => 'int','offset' => 'int','listing_id' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'limit' => 25,'offset' => 0},
        description => "Retrieves a set of FavoriteListing objects associated to a Listing.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllListingImages {
    my $self = shift;
    my $info = {
        name => 'findAllListingImages',
        uri  => '/listings/:listing_id/images',
        type => 'ListingImage',
        params => {'listing_id' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Retrieves a set of ListingImage objects associated to a Listing.",
    };
    return $self->_call_method( $info, @_ );
}

sub getListingImage {
    my $self = shift;
    my $info = {
        name => 'getListingImage',
        uri  => '/listings/:listing_id/images/:listing_image_id',
        type => 'ListingImage',
        params => {'listing_image_id' => 'array(int)','listing_id' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'listing_id' => undef},
        description => "Retrieves a ListingImage by id.",
    };
    return $self->_call_method( $info, @_ );
}

sub getListingPaymentInfo {
    my $self = shift;
    my $info = {
        name => 'getListingPaymentInfo',
        uri  => '/listings/:listing_id/payments',
        type => 'ListingPayment',
        params => {'listing_id' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Retrieves a set of ListingPayment objects associated to a Listing.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllListingShippingInfo {
    my $self = shift;
    my $info = {
        name => 'findAllListingShippingInfo',
        uri  => '/listings/:listing_id/shipping/info',
        type => 'ShippingInfo',
        params => {'limit' => 'int','offset' => 'int','listing_id' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'limit' => 25,'offset' => 0},
        description => "Retrieves a set of ShippingInfo objects associated to a Listing.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllListingActive {
    my $self = shift;
    my $info = {
        name => 'findAllListingActive',
        uri  => '/listings/active',
        type => 'Listing',
        params => {'sort_order' => 'enum(up, down)','min_price' => 'float','tags' => 'array(string)','keywords' => 'string','max_price' => 'float','color' => 'color_triplet','materials' => 'array(string)','sort_on' => 'enum(created, price, score)','color_accuracy' => 'color_wiggle','category' => 'category','limit' => 'int','offset' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'sort_order' => 'down','min_price' => undef,'tags' => undef,'keywords' => undef,'max_price' => undef,'color' => undef,'materials' => undef,'sort_on' => 'created','color_accuracy' => 0,'category' => undef,'limit' => 25,'offset' => 0},
        description => "Finds all active Listing",
    };
    return $self->_call_method( $info, @_ );
}

sub getListingPayment {
    my $self = shift;
    my $info = {
        name => 'getListingPayment',
        uri  => '/payments/:listing_payment_id',
        type => 'ListingPayment',
        params => {'listing_payment_id' => 'array(int)'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Retrieves a ListingPayment by id.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllRegion {
    my $self = shift;
    my $info = {
        name => 'findAllRegion',
        uri  => '/regions',
        type => 'Region',
        params => {},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Finds all Region.",
    };
    return $self->_call_method( $info, @_ );
}

sub getRegion {
    my $self = shift;
    my $info = {
        name => 'getRegion',
        uri  => '/regions/:region_id',
        type => 'Region',
        params => {'region_id' => 'array(int)'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Retrieves a Region by id.",
    };
    return $self->_call_method( $info, @_ );
}

sub getShopSection {
    my $self = shift;
    my $info = {
        name => 'getShopSection',
        uri  => '/sections/:shop_section_id',
        type => 'ShopSection',
        params => {'shop_section_id' => 'array(int)'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Retrieves a ShopSection by id.",
    };
    return $self->_call_method( $info, @_ );
}

sub getServerEpoch {
    my $self = shift;
    my $info = {
        name => 'getServerEpoch',
        uri  => '/server/epoch',
        type => 'Int',
        params => {},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Get server time, in epoch seconds notation.",
    };
    return $self->_call_method( $info, @_ );
}

sub ping {
    my $self = shift;
    my $info = {
        name => 'ping',
        uri  => '/server/ping',
        type => 'String',
        params => {},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Check that the server is alive.",
    };
    return $self->_call_method( $info, @_ );
}

sub getShippingInfo {
    my $self = shift;
    my $info = {
        name => 'getShippingInfo',
        uri  => '/shipping/info/:shipping_info_id',
        type => 'ShippingInfo',
        params => {'shipping_info_id' => 'array(int)'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Retrieves a ShippingInfo by id.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllShops {
    my $self = shift;
    my $info = {
        name => 'findAllShops',
        uri  => '/shops',
        type => 'Shop',
        params => {'limit' => 'int','shop_name' => 'string (length >= 3)','offset' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'limit' => 25,'shop_name' => undef,'offset' => 0},
        description => "Finds all Shops.  If there is a keywords parameter, finds shops with shop_name starting with keywords.",
    };
    return $self->_call_method( $info, @_ );
}

sub getShop {
    my $self = shift;
    my $info = {
        name => 'getShop',
        uri  => '/shops/:shop_id',
        type => 'Shop',
        params => {'shop_id' => 'array(shop_id_or_name)'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Retrieves a Shop by id.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllShopListingsActive {
    my $self = shift;
    my $info = {
        name => 'findAllShopListingsActive',
        uri  => '/shops/:shop_id/listings/active',
        type => 'Listing',
        params => {'sort_order' => 'enum(up, down)','shop_id' => 'shop_id_or_name','min_price' => 'float','tags' => 'array(string)','keywords' => 'string','max_price' => 'float','color' => 'color_triplet','materials' => 'array(string)','sort_on' => 'enum(created, price, score)','color_accuracy' => 'color_wiggle','category' => 'category','limit' => 'int','offset' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'sort_order' => 'down','min_price' => undef,'tags' => undef,'keywords' => undef,'max_price' => undef,'color' => undef,'materials' => undef,'sort_on' => 'created','color_accuracy' => 0,'category' => undef,'limit' => 25,'offset' => 0},
        description => "Finds all active Listings associated with a Shop",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllShopListingsFeatured {
    my $self = shift;
    my $info = {
        name => 'findAllShopListingsFeatured',
        uri  => '/shops/:shop_id/listings/featured',
        type => 'Listing',
        params => {'shop_id' => 'shop_id_or_name','limit' => 'int','offset' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'limit' => 25,'offset' => 0},
        description => "Retrieves Listings associated to a Shop that are featured",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllShopSections {
    my $self = shift;
    my $info = {
        name => 'findAllShopSections',
        uri  => '/shops/:shop_id/sections',
        type => 'ShopSection',
        params => {'shop_id' => 'shop_id_or_name'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Retrieves a set of ShopSection objects associated to a Shop.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllTopCategory {
    my $self = shift;
    my $info = {
        name => 'findAllTopCategory',
        uri  => '/taxonomy/categories',
        type => 'Category',
        params => {},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Retrieves all top-level Categories.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllTopCategoryChildren {
    my $self = shift;
    my $info = {
        name => 'findAllTopCategoryChildren',
        uri  => '/taxonomy/categories/:tag',
        type => 'Category',
        params => {'tag' => 'string'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Retrieves children of a top-level Category by tag.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllSubCategoryChildren {
    my $self = shift;
    my $info = {
        name => 'findAllSubCategoryChildren',
        uri  => '/taxonomy/categories/:tag/:subtag',
        type => 'Category',
        params => {'subtag' => 'string','tag' => 'string'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Retrieves children of a second-level Category by tag and subtag.",
    };
    return $self->_call_method( $info, @_ );
}

sub findPopularTags {
    my $self = shift;
    my $info = {
        name => 'findPopularTags',
        uri  => '/taxonomy/tags',
        type => 'Tag',
        params => {'limit' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'limit' => 25},
        description => "Retrieves all related tags for the given tag set.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllRelatedTags {
    my $self = shift;
    my $info = {
        name => 'findAllRelatedTags',
        uri  => '/taxonomy/tags/:tags',
        type => 'Tag',
        params => {'limit' => 'int','tags' => 'array(string)'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'limit' => 25},
        description => "Retrieves all related tags for the given tag set.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllTreasuries {
    my $self = shift;
    my $info = {
        name => 'findAllTreasuries',
        uri  => '/treasuries',
        type => 'Treasury',
        params => {'keywords' => 'string','sort_order' => 'enum(up, down)','sort_on' => 'enum(hotness, created)','limit' => 'int','maturity' => 'enum(safe_only, safe_and_mature)','offset' => 'int','detail_level' => 'enum(low, medium)'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'keywords' => undef,'sort_order' => 'down','sort_on' => 'hotness','limit' => 25,'maturity' => 'safe_only','offset' => 0,'detail_level' => 'low'},
        description => "Search Treasuries or else List all Treasuries",
    };
    return $self->_call_method( $info, @_ );
}

sub getTreasury {
    my $self = shift;
    my $info = {
        name => 'getTreasury',
        uri  => '/treasuries/:treasury_id',
        type => 'Treasury',
        params => {'treasury_id' => 'treasury_id'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Get a Treasury",
    };
    return $self->_call_method( $info, @_ );
}

sub getUser {
    my $self = shift;
    my $info = {
        name => 'getUser',
        uri  => '/users/:user_id',
        type => 'User',
        params => {'user_id' => 'array(user_id_or_name)'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Retrieves a User by id.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllUserFavoredBy {
    my $self = shift;
    my $info = {
        name => 'findAllUserFavoredBy',
        uri  => '/users/:user_id/favored-by',
        type => 'FavoriteUser',
        params => {'limit' => 'int','user_id' => 'user_id_or_name','offset' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'limit' => 25,'offset' => 0},
        description => "Retrieves a set of FavoriteUser objects associated to a User.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllUserFavoriteListings {
    my $self = shift;
    my $info = {
        name => 'findAllUserFavoriteListings',
        uri  => '/users/:user_id/favorites/listings',
        type => 'FavoriteListing',
        params => {'limit' => 'int','user_id' => 'user_id_or_name','offset' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'limit' => 25,'offset' => 0},
        description => "Finds all favorite listings for a user",
    };
    return $self->_call_method( $info, @_ );
}

sub findUserFavoriteListings {
    my $self = shift;
    my $info = {
        name => 'findUserFavoriteListings',
        uri  => '/users/:user_id/favorites/listings/:listing_id',
        type => 'FavoriteListing',
        params => {'user_id' => 'user_id_or_name','listing_id' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Finds a favorite listing for a user",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllUserFavoriteUsers {
    my $self = shift;
    my $info = {
        name => 'findAllUserFavoriteUsers',
        uri  => '/users/:user_id/favorites/users',
        type => 'FavoriteUser',
        params => {'limit' => 'int','user_id' => 'user_id_or_name','offset' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'limit' => 25,'offset' => 0},
        description => "Finds all favorite users for a user",
    };
    return $self->_call_method( $info, @_ );
}

sub findUserFavoriteUsers {
    my $self = shift;
    my $info = {
        name => 'findUserFavoriteUsers',
        uri  => '/users/:user_id/favorites/users/:target_user_id',
        type => 'FavoriteUser',
        params => {'target_user_id' => 'user_id_or_name','user_id' => 'user_id_or_name'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {},
        description => "Finds a favorite user for a user",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllUserFeedbackAsAuthor {
    my $self = shift;
    my $info = {
        name => 'findAllUserFeedbackAsAuthor',
        uri  => '/users/:user_id/feedback/as-author',
        type => 'Feedback',
        params => {'limit' => 'int','user_id' => 'user_id_or_name','offset' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'limit' => 25,'offset' => 0},
        description => "Retrieves a set of Feedback objects associated to a User.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllUserFeedbackAsBuyer {
    my $self = shift;
    my $info = {
        name => 'findAllUserFeedbackAsBuyer',
        uri  => '/users/:user_id/feedback/as-buyer',
        type => 'Feedback',
        params => {'limit' => 'int','user_id' => 'user_id_or_name','offset' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'limit' => 25,'offset' => 0},
        description => "Retrieves a set of Feedback objects associated to a User.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllUserFeedbackAsSeller {
    my $self = shift;
    my $info = {
        name => 'findAllUserFeedbackAsSeller',
        uri  => '/users/:user_id/feedback/as-seller',
        type => 'Feedback',
        params => {'limit' => 'int','user_id' => 'user_id_or_name','offset' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'limit' => 25,'offset' => 0},
        description => "Retrieves a set of Feedback objects associated to a User.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllUserFeedbackAsSubject {
    my $self = shift;
    my $info = {
        name => 'findAllUserFeedbackAsSubject',
        uri  => '/users/:user_id/feedback/as-subject',
        type => 'Feedback',
        params => {'limit' => 'int','user_id' => 'user_id_or_name','offset' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'limit' => 25,'offset' => 0},
        description => "Retrieves a set of Feedback objects associated to a User.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllUserShops {
    my $self = shift;
    my $info = {
        name => 'findAllUserShops',
        uri  => '/users/:user_id/shops',
        type => 'Shop',
        params => {'limit' => 'int','user_id' => 'user_id_or_name','offset' => 'int'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'limit' => 25,'offset' => 0},
        description => "Retrieves a set of Shop objects associated to a User.",
    };
    return $self->_call_method( $info, @_ );
}

sub findAllUserTreasuries {
    my $self = shift;
    my $info = {
        name => 'findAllUserTreasuries',
        uri  => '/users/:user_id/treasuries',
        type => 'Treasury',
        params => {'sort_order' => 'enum(up, down)','sort_on' => 'enum(hotness, created)','limit' => 'int','user_id' => 'user_id_or_name','maturity' => 'enum(safe_only, safe_and_mature)','offset' => 'int','detail_level' => 'enum(low, medium)'},
        visibility => 'public',
        http_method => 'GET',
        defaults => {'sort_order' => 'down','sort_on' => 'hotness','limit' => 25,'maturity' => 'safe_only','offset' => 0,'detail_level' => 'low'},
        description => "Get a user's Treasuries",
    };
    return $self->_call_method( $info, @_ );
}

1;
