package WebService::Aladdin::Item;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw/ 
publisher categoryId stockStatus author customerReviewRank description itemPage
priceSales creator content category categoryName link date priceStandard itemId isbn title cover pubDate guid mileage
/);

sub init {}

1;
