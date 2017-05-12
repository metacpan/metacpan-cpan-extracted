use strict;
use warnings;

package # hide from PAUSE
    Author;
use Moo;
use autobox::Core;

has name      => ( is => "lazy" );
has publisher => ( is => "lazy" );
has books     => ( is => "lazy" );
sub _build_books { [] }

sub publisher_affiliation {
    my $self = shift;
    my ($of) = @_;
    return $self->name . " $of " . $self->publisher->name;
}

sub is_prolific {
    my $self = shift;
    return $self->books->length > 1;
}

package # hide from PAUSE
    Book;
use Moo;
has title      => ( is => "lazy" );
has genre      => ( is => "lazy" );
has page_count => ( is => "lazy" );
has price      => ( is => "lazy" );
sub _build_price { 10 }
has author => ( is => "rw", weak_ref => 1 );

sub price_with_tax {
    my $self = shift;
    my ($tax_percent) = @_;
    return $self->price + ( $self->price * $tax_percent );
}

sub title_uc {
    my $self = shift;
    return $self->title->uc;
}

package # hide from PAUSE
    Publisher;
use Moo;
has name => ( is => "lazy" );
sub _build_authors { [] }



package # hide from PAUSE
    Literature;
use autobox::Core;

sub literature {

    my $p_orbit    = Publisher->new({ name => "Orbit" });
    my $p_zeus     = Publisher->new({ name => "Head of Zeus" });
    my $p_gollancz = Publisher->new({ name => "Gollanz" });

    # Corey
    my $b_leviathan = Book->new({
        title      => "Leviathan Wakes",
        genre      => "Sci-fi",
        page_count => 342,
        price      => 6,
    });
    my $b_caliban = Book->new({
        title      => "Caliban's War",
        genre      => "Sci-fi",
        page_count => 430,
        price      => 6,
    });

    # Liu
    my $b_three = Book->new({
        title      => "The Tree-Body Problem",
        genre      => "Sci-fi",
        page_count => 400,
        price      => 5,
    });

    # Rothfuss
    my $b_wind = Book->new({
        title      => "The Name of the Wind",
        genre      => "Fantasy",
        page_count => 676,
        price      => 11,
    });

    my $a_corey = Author->new({
        name      => "James A. Corey",
        publisher => $p_orbit,
        books     => [ $b_leviathan, $b_caliban ],
    });
    my $a_liu = Author->new({
        name      => "Cixin Liu",
        publisher => $p_zeus,
        books     => [ $b_three ],
    });
    my $a_rothfuss = Author->new({
        name      => "Patrick Rothfuss",
        publisher => $p_gollancz,
        books     => [ $b_wind ],
    });


    my $reviews = [
        {
            id    => 1,
            score => 7,
        },
        {
            id    => 2,
            score => 6,
        },
        {
            id    => 3,
            score => 9,
        },
    ];

    my $literature = {
        books      => ( my $books = [ $b_leviathan, $b_caliban, $b_three, $b_wind ] ),
        authors    => ( my $authors = [ $a_corey, $a_liu, $a_rothfuss ] ),
        publishers => ( my $publishers = [ $p_orbit, $p_zeus, $p_gollancz ] ),
        reviews    => $reviews,
    };

    for my $author (@$authors) {
        $_->author( $author ) for ( $author->books->elements );
    }

    return $literature;
}

1;

