package XTaTIK;

our $VERSION = '0.005002'; # VERSION

use Mojo::Base 'Mojolicious';

use XTaTIK::Model::Cart;
use XTaTIK::Model::Quotes;
use XTaTIK::Model::Products;
use XTaTIK::Model::Users;
use XTaTIK::Model::Blog;
use XTaTIK::Model::ProductSearch;
use XTaTIK::Model::XVars;
use File::Find::Rule;
use File::Basename 'dirname';
use File::Spec::Functions qw/catfile  curdir  catdir  rel2abs/;
use Carp qw/croak/;
use HTML::Entities;
use Mojo::Pg;
use experimental qw/postderef/;
use lib;

my $PG;

sub startup {
    my $self = shift;
    $self->moniker('XTaTIK');
    $self->home->parse(catdir(dirname(__FILE__), 'XTaTIK'));
    $self->plugin('Config');
    $self->static->paths->[0] = $self->home->rel_dir('public');
    $self->renderer->paths->[0] = $self->home->rel_dir('templates');

    my @sass_path = split /:/, $ENV{SASS_PATH}//'';

    if ( $ENV{XTATIK_COMPANY} ) {
        unshift @{ $self->renderer->paths },
            catdir $ENV{XTATIK_COMPANY}, 'templates';

        unshift @{ $self->static->paths },
            catdir $ENV{XTATIK_COMPANY}, 'public';

        unshift @sass_path,
            catdir $ENV{XTATIK_COMPANY}, 'public', 'sass';

        lib->import( catdir $ENV{XTATIK_COMPANY}, 'lib' );

        blasdsdasdsa->import;
    }

    unshift @sass_path,
            catdir rel2abs(curdir),
                qw/lib XTaTIK public  sass  fake-company/
        unless $ENV{XTATIK_COMPANY}
            and -r catfile $ENV{XTATIK_COMPANY},
                qw/public  sass  bootstrap  company-variables.scss/;

    my $silo_path = $ENV{XTATIK_SITE_ROOT}
        // catfile 'silo', $self->config('site');

    $self->config('_silo_path', $silo_path);

    unshift @{ $self->renderer->paths },
            catdir $silo_path, 'templates';

    unshift @{ $self->static->paths },
        catdir $silo_path, 'public';

    unshift @sass_path,
        catdir $silo_path, 'public', 'sass';

    lib->import( catdir $silo_path, 'lib' );

    unshift @sass_path,
            catdir rel2abs(curdir), qw/lib XTaTIK public  sass  fake-site/
        unless -r catfile $silo_path,
                qw/public  sass  bootstrap  site-variables.scss/;

    $ENV{SASS_PATH} = join ':', @sass_path;

    $self->log->debug('*** XTaTIK LOADED: ***');
    $self->log->debug('Site: ' . $self->config('site') );
    $self->log->debug("XTATIK_COMPANY: $ENV{XTATIK_COMPANY}");
    $self->log->debug("XTATIK_SITE_ROOT: $ENV{XTATIK_SITE_ROOT}");
    $self->log->debug("Silo path: $silo_path");
    $self->log->debug("SASS path: $ENV{SASS_PATH}");
    $self->log->debug("Database: "
      . (($self->config('pg_url') =~ m{^(?:postgresql:///)?(\w+)}i)[0] //'')
    );
    $self->log->debug('**********************');

    $self->secrets([ $self->config('mojo_secrets') ]);

    $self->plugin('AntiSpamMailTo');
    $self->plugin('FormChecker' => error_class => 'foo');
    $self->plugin('IP2Location');
    $self->plugin('bootstrap3');

    $self->asset(
        'app.css' => qw{
            /sass/reset.scss
            /sass/bs-callout.scss
            /sass/bootstrap-extras.scss
            /sass/main.scss
        },
        (
            sort map s{^\Q$silo_path\E[\\/]?public[\\/]}{}r,
                File::Find::Rule->name('*.scss')
                ->in( catdir $silo_path, qw/public sass user/),
        ),
        (
            $ENV{XTATIK_COMPANY}
            ? (
                sort map s{^\Q$ENV{XTATIK_COMPANY}\E[\\/]?public[\\/]}{}r,
                  File::Find::Rule->name('*.css', '*.scss')
                  ->in( catdir $ENV{XTATIK_COMPANY}, qw/public sass user/ )
            ) : ()
        )
    );

    $self->asset(
        'app.js' => qw{
            /JS/ie10-viewport-bug-workaround.js
            /JS/main.js
        },
        (
            map s{^\Q$silo_path\E[\\/]public[\\/]}{}r,
                File::Find::Rule->name('*.js')
                ->in( catfile($silo_path, 'public', 'JS') ),
        ),
        (
            $ENV{XTATIK_COMPANY}
            ? (
                map s{^\Q$ENV{XTATIK_COMPANY}\E[\\/]public[\\/]}{}r,
                    File::Find::Rule->name('*.js')
                    ->in( catfile($ENV{XTATIK_COMPANY}, 'public', 'JS') )
            ) : ()
        )
    );

    my $mconf = {
        how     => $self->config('mail')->{how},
        howargs => $self->config('mail')->{howargs},
    };
    $self->plugin(mail => $mconf);

    # Initialize globals (this is probably a stupid way to do things)
    $PG = Mojo::Pg->new( $self->config('pg_url') );

    $self->session( expiration => 60*60*24*7 );

    $self->helper( xtext          => \&_helper_xtext          );
    $self->helper( xvar           => \&_helper_xvar           );
    $self->helper( users          => \&_helper_users          );
    $self->helper( products       => \&_helper_products       );
    $self->helper( quotes         => \&_helper_quotes         );
    $self->helper( cart           => \&_helper_cart           );
    $self->helper( cart_dollars   => \&_helper_cart_dollars   );
    $self->helper( cart_cents     => \&_helper_cart_cents     );
    $self->helper( product_search => $self->_gen_helper_product_search );
    $self->helper(
        blog => sub {
            state $blog = XTaTIK::Model::Blog->new(
                blog_root => $ENV{XTATIK_BLOG_SRC}
                    // catfile $silo_path, 'blog_src'
            );
        }
    );
    $self->helper( active_page => sub {
        my ( $c, $name ) = @_;
        my $active = $c->stash('active_page') // '';
        return $active eq $name ? ' class="active"' : '';
    });
    $self->helper( items_in => sub {
        my ( $c, $what ) = @_;
        return unless defined $what;
        $what = $c->stash($what) // [] unless ref $what;
        return @$what;
    });


    # use Acme::Dump::And::Dumper;
    # die DnD [ grep -e catfile($_, 'content-pics', 'nav-logo.png'),
            # @{ $self->static->paths } ];
    $self->config('text')->{show_nav_logo}
        //= $self->static->file('content-pics/nav-logo.png');

    my $r = $self->routes;
    { # Root routes
        $r->get('/'        )->to('root#index'        );
        $r->get('/contact' )->to('root#contact'      );
        $r->get('/about'   )->to('root#about'        );
        $r->get('/search'  )->to('search#search'     );
        $r->get('/history' )->to('root#history'      );
        $r->get('/login'   )->to('root#login'        );
        $r->post('/contact')->to('root#contact_post' );
        $r->get('/feedback')->to('root#feedback'     );
        $r->get('/sitemap' )->to('root#sitemap'      );
        $r->get('/robots'  )->to('root#robots'       );
        $r->post('/feedback')->to('root#feedback_post');
        $r->get('/product/(*url)')->to('root#product');
        $r->get('/products(*category)')
            ->to('root#products_category', { category => '' });
        $r->get('/privacy-policy')
                            ->to('root#privacy_policy');
        $r->get('/terms-and-conditions')
                            ->to('root#terms_and_conditions');
    }

    { # Cart routes
        my $rc = $r->under('/cart');
        $rc->get( '/'               )->to('cart#index'          );
        $rc->post('/add'            )->to('cart#add'            );

        for my $plug ( $self->config('checkout_system')->@* ) {
            my ( $name, $conf ) = ref $plug ? ( @$plug ) : ( $plug );

            my $handler = "XTaTIK::Plugin::Cart::$name";
            eval "require $handler"
                or die "Failed to load cart handler $handler: $@";

            my $h = $handler->new( $conf ? ( conf => $conf ) : () );
            $h->_add_routes( $rc );
        }
    }

    unless ( $self->config('no_blog') ) {
        { # Blog routes
            my $rb = $r->under('/blog');
            $rb->get('/'     )->to('blog#index');
            $rb->get('/*post')->to('blog#read');
        }
    }

    { # User section routes
        $r->post('/login' )->to('user#login' );
        $r->any( '/logout')->to('user#logout');

        my $ru = $r->under('/user')->to('user#is_logged_in');
        $ru->get('/')->to('user#index')->name('user/index');
        $ru->get('/site-products')->to('user#site_products');
        $ru->post('/site-products')->to('user#site_products');
        $ru->get('/master-products-database')
            ->to('user#master_products_database')
            ->name('user/master_products_database');
        $ru->post('/master-products-database')
            ->to('user#master_products_database_post');
        $ru->post('/master-products-database/update')
            ->to('user#master_products_database_update');
        $ru->post('/master-products-database/delete')
            ->to('user#master_products_database_delete');
        $ru->get('/manage-users')->to('user#manage_users');
        $ru->post('/manage-users/add')->to('user#add_user');
        $ru->post('/manage-users/update')->to('user#update_users');
        $ru->post('/manage-users/delete')->to('user#delete_users');
        $ru->get('/hot-products')->to('user#hot_products');
        $ru->post('/hot-products')->to('user#hot_products_post');
        $ru->get('/quotes')->to('user#quotes_handler');
    }
}

#### HELPERS

sub _helper_xtext {
    my ( $c, $var, $v ) = @_;
    $c->config('text')->{ $var } = $v
        if @_ == 3;

    return $c->config('text')->{ $var };
}

sub _helper_xvar {
    my ( undef, $var, $value ) = @_;
    state $xvars = XTaTIK::Model::XVars->new(pg => $PG);

    if ( defined $value ) {
        $xvars->set($var, $value);
    }
    else {
        return $xvars->get($var);
    }
};

sub _helper_users {
    state $users = XTaTIK::Model::Users->new(
        pg => $PG,
    );
};

sub _gen_helper_product_search {
    my $self = shift;

    # Create search dir and touch index files, unless we already have them
    my $dir = catdir $self->config('_silo_path'), 'search_index';
    unless ( -d $dir ) {
        mkdir $dir
            or croak "Failed to create search_index directory $dir: $!";
    }

    for ( map catfile($dir, $_), qw/ixd.bdb  ixp.bdb  ixw.bdb/ ) {
        next if -f and -r;
        open my $fh, '>', $_
            or croak "Failed to create search_index file $_: $!";
    }

    return sub {
        state $search = XTaTIK::Model::ProductSearch->new( dir => $dir );
    };
}

sub _helper_products {
    my $c = shift;
    state $products = XTaTIK::Model::Products->new(
        pg => $PG,
        custom_cat_sorting => $c->config('custom_cat_sorting'),
        site => $c->config('site'),
    );

    $products->pricing_region( $c->geoip_region );
    return $products;
};

sub _helper_quotes {
    # my $c = shift;

    state $quotes = XTaTIK::Model::Quotes->new( pg => $PG );
    return $quotes;
};

sub _helper_cart {
    my $c = shift;

    return $c->stash('__cart') if $c->stash('__cart');

    my $cart = XTaTIK::Model::Cart->new(
        pg       => $PG,
        products => $c->products,
    );

    if ( my $id = $c->session('cart_id') ) {
        $cart->id( $id );
    }
    else {
        $c->session( cart_id => $cart->new_cart );
    }

    $cart->load;

    $c->stash( __cart => $cart );
    return $cart;
};

sub _helper_cart_dollars {
    my $c = shift;
    my $is_refresh = shift;
    my $dollars = $is_refresh
        ? $c->cart->dollars
        : $c->session('cart_dollars') // $c->cart->dollars;
    $c->session( cart_dollars => $dollars );
    return $dollars;
};

sub _helper_cart_cents {
    my $c = shift;
    my $is_refresh = shift;
    my $cents = $is_refresh
        ? $c->cart->cents
        : $c->session('cart_cents') // $c->cart->cents;
    $c->session( cart_cents => $cents);
    return $cents;
};

1;

__END__

=encoding utf8

=for stopwords eCommerce Analytics GeoIP Perlbrew PostgreSQL deployable  jQuery Cassi


=head1 NAME

XTaTIK - Rapidly deployable, multi-website eCommerce website base

=head1 WARNING

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-warning.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

This software is currently EXPERIMENTAL and the way it works might
be changed. The first stable release is currently expected to appear
before the end of 2015. Please consult
L<milestones on GitHub|https://github.com/XTaTIK/XTaTIK/milestones>
for what's to come I<(Note: milestone dates might be moved)>.

=for html  </div></div>

=head1 SYNOPSIS

The following code in your C<XTaTIK.conf> is all you
need to launch a new eCommerce website with the default theme.
You'd then log in as the admin and tell the site which products from
the master product database to display on it.

    {
        site => 'awesomewidgets',
        text => {
            market           => 'Awesome Widgets',
            website_domain   => 'example.com',
            google_analytics => 'UA-00000000-00',
            paypal_custom    => 'AW: $promo_code',
            order_number     => 'AWX%06d',
            quote_number     => 'AWQ%06d',
            market_tag       => 'The Most Awesome Widgets In The World!',
        },
        mojo_secrets => 'b4q34qgfdxw35t#$@!',
    };

=head1 DEMO

You can view a demo website running on XTaTIK at L<http://demo.xtatik.org/>

=head1 DESCRIPTION

XTaTIK is a typical eCommerce website base that can be used to run
a single website, but its true power shows when you want to run many
separate websites that belong to one company and offer overlapping
sets of products (for example, single company serving several markets).

    XTaTIK Core
    │
    ├── Single database for products and customer data
    │
    └── Company Silo────── Single product images directory
        │
        ├── Site 1 Silo
        ├── Site 2 Silo
        ├── Site 3 Silo
        └── Site 4 Silo

I<"Silo" is just a term for a directory with a subset of website files.>

The idea, depicted above, is that core eCommerce functionality, like
"About us" pages, product search, purchasing a product or adding one
to a quote, and check out pages are all handled by XTaTIK core.

Company Silo offers any configuration that is to be shared among all the
websites. This would be your company's branch addresses, maps,
email addresses, etc. You can also override default XTaTIK's pages
and even business logic. This is also where you keep all the product images.

In Site Silos, you setup anything that you can't specify in your Company
Silo. This would be market name and Google Analytics tracking code,
among others. As with the Company Silo, in Site Silos you can override
any config, files, and business logic provided by the Company Silo or
the XTaTIK core.

The end result is you don't duplicate anything that you don't need to.
Each site is using the same master products database and master
product pictures directory, so any changes done in one place are propagated
to all of your sites. Same goes for any config you specify in the Company
Silo.

=head1 INSTALLATION AND USE

To learn how to install and use XTaTIK, please see L<XTaTIK::Docs>

=head1 FEATURE LIST

I<Note: many of the features can be disabled>

=over 4

=item * Offering products for online purchases

=item * Offering products for quote requests

=item * Plugin-based checkout systems (currently only PayPal is implemented)

=item * GeoIP based pricing

=item * Product search

=item * Blog

=item * Site feedback

=item * I<Home>, I<About Us>, I<Company History>, I<Contact Us>,
    I<Terms and Conditions>, and I<Privacy Policy> pages

=back

=head1 VERSION SUPPORT

XTaTIK is tested in and supports the current and previous major releases of
Internet Explorer, Firefox, and Safari, as well as the current
version of Google Chrome. There's unofficial support for IE8, IE9, and
IE10, which will most likely end in 2016.

XTaTIK supports the current and previous major releases of Perl
(not counting developer releases) and
likely no attempt will be made to provide support for earlier versions.
You can use L<Perlbrew|http://perlbrew.pl/> to obtain the latest
versions of Perl, if you're currently lacking one.

=head1 TECHNOLOGIES USED

XTaTIK relies on technologies listed below.
Depending on how much customization
you desire, you may need to be familiar with some of them:

=over 4

=item * L<Bootstrap|http://getbootstrap.com>

=item * L<SASS|http://sass-lang.com/>

=item * L<CSS3|http://www.w3.org/Style/CSS/current-work.en.html>

=item * L<HTML5|http://www.w3.org/TR/html5/>

=item * L<jQuery|https://jquery.com/>

=item * L<PostgreSQL|http://www.postgresql.org/>

=item * L<Mojolicious> (also, see
     L<www.mojolicio.us|http://www.mojolicio.us/>)

=item * And of course, the lovely L<Perl 5|https://www.perl.org/>

=back

=head1 CONNECT WITH XTaTIK USERS

=over 4

=item * Like XTaTIK on Facebook: L<https://www.facebook.com/XTaTIKPerl>

=item * Star and Watch XTaTIK GitHub repo:
    L<https://github.com/XTaTIK/XTaTIK>

=back

=head1 SEE ALSO

L<http://www.XTaTIK.org>, L<Mojolicious>, L<Mojo::Pg>

=for html <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>

=head1 REPOSITORY

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

Fork this module on GitHub:
L<https://github.com/XTaTIK/XTaTIK>

=for html  </div></div>

=head1 BUGS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

To report bugs or request features, please use
L<https://github.com/XTaTIK/XTaTIK/issues>

If you can't access GitHub, you can email your request
to C<bug-XTaTIK at rt.cpan.org>

=for html  </div></div>

=head1 AUTHOR

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>

=over 4

=item * Cassi Bryant (L<https://github.com/cassi42>)

=back

=for html  </div></div>

=head1 LICENSE

    Copyright © 2015, Zoffix Znet

You can use and distribute this module under
The Artistic License 2.0.
See the C<LICENSE> file included in this distribution for complete
details.

B<Note:> for convenience of distribution, this module includes works
created by other organizations. They retain their copyright and their
original licenses:

=head2 Bootstrap3

    Copyright © 2011-2015, Twitter, Inc

L<http://getbootstrap.com/>. Licensed under the L<MIT License|https://github.com/twbs/bootstrap/blob/master/LICENSE>

=head2 jQuery

    Copyright © 2005, 2015 jQuery Foundation, Inc.

L<https://jquery.org>. Licensed under the L<MIT License|https://tldrlegal.com/license/mit-license>

=cut