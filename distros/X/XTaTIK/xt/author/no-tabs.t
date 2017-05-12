use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/XTaTIK',
    'lib/XTaTIK.pm',
    'lib/XTaTIK/Common.pm',
    'lib/XTaTIK/Controller/Blog.pm',
    'lib/XTaTIK/Controller/Cart.pm',
    'lib/XTaTIK/Controller/Root.pm',
    'lib/XTaTIK/Controller/Search.pm',
    'lib/XTaTIK/Controller/User.pm',
    'lib/XTaTIK/Docs.pm',
    'lib/XTaTIK/Docs/01_Installation.pm',
    'lib/XTaTIK/Docs/02_PreparingCompanySilo.pm',
    'lib/XTaTIK/Docs/03_PreparingSiteSilo.pm',
    'lib/XTaTIK/Docs/04_Launch.pm',
    'lib/XTaTIK/Docs/Appendix/SASSVariables.pm',
    'lib/XTaTIK/Docs/Appendix/StaticFiles.pm',
    'lib/XTaTIK/Docs/Appendix/Templates.pm',
    'lib/XTaTIK/Docs/Appendix/XTaTIK_conf.pm',
    'lib/XTaTIK/Model/Blog.pm',
    'lib/XTaTIK/Model/Cart.pm',
    'lib/XTaTIK/Model/ProductSearch.pm',
    'lib/XTaTIK/Model/Products.pm',
    'lib/XTaTIK/Model/Quote.pm',
    'lib/XTaTIK/Model/Quotes.pm',
    'lib/XTaTIK/Model/Users.pm',
    'lib/XTaTIK/Model/XVars.pm',
    'lib/XTaTIK/Plugin/Cart/PayPal.pm',
    'lib/XTaTIK/Utilities/Misc.pm',
    'lib/XTaTIK/Utilities/ToadFarmer.pm',
    't/00-compile.t',
    't/01-cat-traversal.t',
    't/02-unit-multi-calculation.t',
    't/03-custom-cat-sorting.t',
    't/04-blog.t',
    't/05-hot-products.t',
    't/06-product-search.t',
    't/07-google-analytics.t',
    't/08-sitemap.t',
    't/09-price-activated-features.t',
    't/10-product-pic-finder.t',
    't/11-shipping_free-conf.t',
    't/12-shop-titles.t',
    't/13-meta-tags.t',
    't/99-temp-restore-db.t',
    't/Test/XTaTIK.pm',
    't/blog_src/2015-05-10-Test-Post.md',
    't/blog_src/2015-05-12-Test-Post-2.md',
    't/blog_src/2015-05-14-Test-Post-3.md'
);

notabs_ok($_) foreach @files;
done_testing;
