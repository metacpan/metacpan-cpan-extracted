package XTaTIK::Controller::User;

our $VERSION = '0.005002'; # VERSION

use Mojo::Base 'Mojolicious::Controller';
use experimental 'postderef';
use JSON::Meth qw/$json/;

sub login {
    my $self = shift;

    my $user = $self->users->check(
        $self->param('login'), $self->param('pass')
    );

    if ( $user ) {
        $self->session(
            is_logged_in => 1,
            user         => $user,
        );
        $self->redirect_to('user/index');
    }
    else {
        $self->flash( is_login_failed => 1 );
        $self->redirect_to('/login');
    }
}

sub logout {
    my $self = shift;
    $self->session( is_logged_in => 0 );
    $self->redirect_to('/login');
}

sub is_logged_in {
    my $self = shift;

    return 1 if $self->session('is_logged_in');
    return $self->redirect_to('/login');
}

sub site_products {
    my $self = shift;

    if ( $self->param('save') ) {
        my %to_remove = map +( $_->{number} => $_->{id} ),
            $self->products->get_all( $self->config('site') )->@*;

        my @lines;
        for ( split /\n/, $self->param('products') ) {
            /^\s*#?(\S+)(?:\s+(\S+))?/ or next;

            my $line = { num => $1, price => $2 };
            $line->{price} //= '00_0.00';
            $line->{price} = join ',', map tr/$//dr,
                map +(/_/ ? $_ : "00_$_"), split /,/, $line->{price};

            push @lines, $line;
            delete $to_remove{ $line->{num} };
        }

        # Dump removed products from the site and its search index
        $self->products->unset_site(
            $self->config('site'), [keys %to_remove]
        ) if keys %to_remove;

        $self->product_search->delete( $_ ) for values %to_remove;

        $self->products
        ->set_site( $self->config('site'), [ map $_->{num}, @lines ], );

        $self->products->set_pricing( \@lines );
    }

    my $products = $self->products->get_all( $self->config('site') );

    # update search index
    if ( $self->param('save') ) {
        for ( @$products ) {
            $self->product_search->delete( $_->{id} )->add(
                $_->{id},
                join ' ', grep defined,
                @$_{qw/number  group_desc  title  category description  tip_description  quote_description/}
            );
        }
    }

    my @prods = $self->products->get_all( $self->config('site') )->@*;
    my @list;
    for ( @prods ) {
        my $pr = $_->{price_raw}->$json->{ $self->config('site') };
        if ( ref $pr ) {
            $pr = join ',', map "${_}_$pr->{$_}", sort keys %$pr;
        }
        $pr =~ s/\b00_// if $pr;
        push @list, "$_->{number}\t" . ($pr // '0.00');
    }
    $self->param( products => join "\n", @list );
}

sub master_products_database {
    my $self = shift;

    $self->stash( products => $self->products->get_all('*') );
}

sub master_products_database_post {
    my $self = shift;

    $self->form_checker(
        rules => {
            number => { max => 1000, },
            ( map +( $_ => { optional => 1, max => 1000 } ),
                    qw/image  title  category  group_master
                    group_desc unit/ ),
            ( map +( $_ => { optional => 1, max => 1000_000 } ),
                    qw/description  tip_description  quote_description
                    recommended/ ),
        },
    );

    return $self->render( template => 'user/master_products_database' )
        unless $self->form_checker_ok;

    # Check CSRF token
    return $self->render(text => 'Bad CSRF token!', status => 403)
        if $self->validation->csrf_protect->has_error('csrf_token');

    if ( $self->products->exists( $self->param('number') ) ) {
        $self->stash( already_have_this_product => 1 );
        return $self->render( template => 'user/master_products_database' );
    }

    $self->stash( product_add_ok => 1 );
    $self->products->add(
        map +( $_ => $self->param( $_ ) ),
            qw/number  image  title  category  group_master
                    group_desc unit description  tip_description  quote_description recommended/,
    );

    $self->render( template => 'user/master_products_database');
}

sub master_products_database_update {
    my $self = shift;

    # Check CSRF token
    return $self->render(text => 'Bad CSRF token!', status => 403)
        if $self->validation->csrf_protect->has_error('csrf_token');

    my @ids = map /\d+/g, grep /^id/, @{$self->req->body_params->names};

    for my $id ( @ids ) {
        $self->products->update(
            $id,
            map +( $_ => $self->param( $_ . '_' . $id ) ),
            qw/number  image  title  category  group_master
                    group_desc unit description  tip_description  quote_description recommended  price/,
        );
    }

    $self->flash( product_update_ok => 1 );
    return $self->redirect_to('/user/master-products-database');

}

sub master_products_database_delete {
    my $self = shift;

    # Check CSRF token
    return $self->render(text => 'Bad CSRF token!', status => 403)
        if $self->validation->csrf_protect->has_error('csrf_token');

    # TODO: implement proper deletion
    # ... https://github.com/XTaTIK/XTaTIK/issues/122
    $self->product_search->delete( $_ )
        for $self->products->delete( split ' ', $self->param('to_delete') );

    $self->flash( product_delete_ok => 1 );
    return $self->redirect_to('/user/master-products-database');
}

sub manage_users {
    my $self = shift;

    $self->stash(
        users => $self->users->get_all,
    );
}

sub add_user {
    my $self = shift;

    $self->form_checker(
        rules => {
            login => {
                max => 3000,
                code => sub {
                    return $self->users->get(shift) ? 0 : 1;
                },
                code_error => 'User with this login already exists',
            },
            name  => { max => 3000 },
            email => { max => 3000 },
            phone => { max => 3000 },
            roles => {
                max => 10_000,
                code => sub {
                    my $v = shift =~ s/^\s+|\s+$//gr;
                    for my $role ( split /\s*,\s*/, $v ) {
                        return 0
                            unless grep $role eq $_,
                                $self->users->valid_roles;
                    }
                    return 1;
                },
                code_error => 'One of the roles you provided is not valid',
            },
        },
    );

    return $self->render( template => 'user/manage_users' )
        unless $self->form_checker_ok;

    $self->users->add(
        map +( $_ => $self->param($_) ),
            qw/login  pass  name  email  phone  roles/,
    );

    $self->flash( add_success => 1, );
    $self->redirect_to('/user/manage-users');
}

sub update_users {
    my $self = shift;

    # TODO: implement parameter checking for each user we're updating

    my @ids = map /\d+/g, grep /^id/, @{$self->req->body_params->names};

    for my $id ( @ids ) {
        $self->users->update(
            $id,
            map +( $_ => $self->param( $_ . '_' . $id ) ),
                qw/login  name  email  phone  roles/,
        );
    }

    $self->flash( users_update_ok => 1 );
    return $self->redirect_to('/user/manage-users');
}

sub delete_users {
    my $self = shift;
    $self->users->delete( $_ ) for split ' ', $self->param('to_delete');

    $self->flash( users_delete_ok => 1 );
    return $self->redirect_to('/user/manage-users');
}

sub hot_products {
    my $self = shift;
    $self->param( hot_products => $self->xvar('hot_products') );
}

sub hot_products_post {
    my $self = shift;

    $self->xvar('hot_products', $self->param('hot_products'));
    $self->stash( update_success => 1, );
    $self->render('user/hot_products');
}

sub quotes_handler {
    my $self = shift;
    $self->stash( quotes => $self->quotes->all );
}

1;