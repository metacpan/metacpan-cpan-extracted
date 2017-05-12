package Test::XTaTIK;

use Mojo::Base -base;
use Carp;
use File::Copy;
use Mojo::Pg;
use XTaTIK::Model::Products;

my $PG_URL = $ENV{XTATIK_PG_URL};
my $DB_FILE_NAME = 'NOOP';
my $BACKUP_DB_FILE_NAME = "backup_$DB_FILE_NAME";

sub save_db {
    warn 'save_db is currently a noop';
    return;
    return unless -e $DB_FILE_NAME;
    return if -e 'squash-db';
    move $DB_FILE_NAME, $BACKUP_DB_FILE_NAME
        or die "FAILED TO SAVE products database $DB_FILE_NAME $!";
}

sub restore_db {
    warn 'restore_db is currently a noop';
    return;
    return if -e 'squash-db' or -e 'do-not-restore-db';
    unless ( -e $BACKUP_DB_FILE_NAME ) {
        warn "We did not find backup products database. Aborting restore";
        return;
    }

    unlink $DB_FILE_NAME;
    move $BACKUP_DB_FILE_NAME, $DB_FILE_NAME
        or die "Failed to move products database backup file: $!";
}

sub load_test_products {
    my ( $self, $products_to_load ) = @_;
    $products_to_load
        or croak 'Must provide test products';

    for my $idx ( 0..$#$products_to_load ) {
        my $p = $products_to_load->[$idx];
        $p = {
            number              => '001-TEST' . ($idx+1),
            title               => 'Test Product ' . ($idx+1),
            image               => '',
            category            => '[]',
            group_master        => '',
            group_desc          => '',
            unit                => '',
            description         => 'Test Desc ' . ($idx+1),
            tip_description     => '',
            quote_description   => '',
            recommended         => '',
            price               => undef,

            %$p,
        },

        $p->{price} //= '0.00';
        $p->{price} = qq|{"default":{"00":$p->{price}}}|
            unless $p->{price} =~ /^\s*\{/;

        $products_to_load->[$idx] = $p;
    }

    my $p = XTaTIK::Model::Products->new;
    save_db();
    $PG_URL // die "\n\nMust set XTATIK_PG_URL env var to a PostgreSQL "
                . "database URL if you plan on running tests\n\n\n";
    $p->pg( Mojo::Pg->new($PG_URL) );

    $p->pg->db->query(
        'drop table if exists carts'
    );
    $p->pg->db->query(
        'drop table if exists quotes'
    );
    $p->pg->db->query(
        'drop table if exists products'
    );
    $p->pg->db->query(
        'drop table if exists users'
    );
    $p->pg->db->query(
        'drop table if exists xvars'
    );
    $p->pg->db->query(
        'CREATE TABLE xvars (
            name TEXT,
            value TEXT
        )'
    );
    $p->pg->db->query(
        'INSERT INTO xvars (name, value) VALUES (?, ?)',
        'hot_products',
        "001-TEST1\n001-TEST3\n001-TEST6",
    );
    $p->pg->db->query(
        'CREATE TABLE carts (
            id          SERIAL PRIMARY KEY,
            created_on  INT,
            data        JSON
        )'
    );
    $p->pg->db->query(
        'CREATE TABLE quotes (
            id          TEXT,
            created_on  INT,
            contents    TEXT,
            name        TEXT,
            lname       TEXT,
            email       TEXT,
            phone       TEXT,
            address1    TEXT,
            address2    TEXT,
            city        TEXT,
            province    TEXT,
            zip         TEXT
        )'
    );
    $p->pg->db->query(
        'CREATE TABLE users (
            id      SERIAL PRIMARY KEY,
            login   TEXT,
            pass    TEXT,
            salt    TEXT,
            name    TEXT,
            email   TEXT,
            phone   TEXT,
            roles   TEXT
        )'
    );
    $p->pg->db->query(
        q{INSERT INTO users (login, pass, salt, name, email, phone, roles)
            VALUES('admin',
                '9c0b8b6275baaa1abe5492fcb83bf06e380f7219e82aa0',
                'rw1Gl1p/4Sn540Is+o9wpw==', 'Zoffix Znet',
                'zoffix@zoffix.com', '416-402-9999',
                'products,users,quotes')}
    );
    $p->pg->db->query(
        'CREATE TABLE products (
            id            SERIAL PRIMARY KEY,
            url           TEXT,
            number        TEXT,
            image         TEXT,
            title         TEXT,
            category      TEXT,
            group_master  TEXT,
            group_desc    TEXT,
            price         TEXT,
            unit          TEXT,
            description   TEXT,
            sites         TEXT,
            tip_description   TEXT,
            quote_description TEXT,
            recommended       TEXT
        );'
    );
    $p->pg->db->query('DELETE FROM "products"');

    for ( @$products_to_load ) {
        my $id = $p->add( %$_ );

        delete @$_{qw/price  unit  recommended  image
            group_master  url  id
        /};
        $_->{category} =~ s/\W/ /g;
    }
}


1;