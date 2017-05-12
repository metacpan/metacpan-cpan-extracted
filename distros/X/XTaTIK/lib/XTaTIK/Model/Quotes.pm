package XTaTIK::Model::Quotes;

our $VERSION = '0.005002'; # VERSION

use Mojo::Base -base;
use XTaTIK::Model::Products;
use XTaTIK::Model::Quote;
use Mojo::Pg;
use JSON::Meth;

use experimental 'postderef';

has [qw/
    pg
/];

sub all {
    my $self = shift;

    my $db_data = $self->pg->db->query('SELECT * FROM quotes')->hashes;
    my @quotes;

    for my $row ( @$db_data ) {
        my $q = XTaTIK::Model::Quote->new;
        $q->$_( $row->{$_} ) for $q->accessors;
        $q->contents( ($row->{contents}//'[]')->$j );
        push @quotes, $q;
    }

    return \@quotes;
}

1;

__END__
