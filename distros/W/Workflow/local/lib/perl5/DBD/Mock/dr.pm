package DBD::Mock::dr;

use strict;
use warnings;

our $imp_data_size = 0;

sub connect {
    my ( $drh, $dbname, $user, $auth, $attributes ) = @_;
    if ( $drh->{'mock_connect_fail'} == 1 ) {
        $drh->set_err( 1, "Could not connect to mock database" );
        return;
    }
    $attributes ||= {};

    if ( $dbname && $DBD::Mock::AttributeAliasing ) {

        # this is the DB we are mocking
        $attributes->{mock_attribute_aliases} =
          DBD::Mock::_get_mock_attribute_aliases($dbname);
        $attributes->{mock_database_name} = $dbname;
    }

    # holds statement parsing coderefs/objects
    $attributes->{mock_parser} = [];

    # holds all statements applied to handle until manually cleared
    $attributes->{mock_statement_history} = [];

    # ability to fake a failed DB connection
    $attributes->{mock_can_connect} = 1;

    # ability to make other things fail :)
    $attributes->{mock_can_prepare} = 1;
    $attributes->{mock_can_execute} = 1;
    $attributes->{mock_can_fetch}   = 1;

    my $dbh = DBI::_new_dbh( $drh, { Name => $dbname } )
      || return;

    return $dbh;
}

sub FETCH {
    my ( $drh, $attr ) = @_;
    if ( $attr =~ /^mock_/ ) {
        if ( $attr eq 'mock_connect_fail' ) {
            return $drh->{'mock_connect_fail'};
        }
        elsif ( $attr eq 'mock_data_sources' ) {
            unless ( defined $drh->{'mock_data_sources'} ) {
                $drh->{'mock_data_sources'} = ['DBI:Mock:'];
            }
            return $drh->{'mock_data_sources'};
        }
        else {
            return $drh->SUPER::FETCH($attr);
        }
    }
    else {
        return $drh->SUPER::FETCH($attr);
    }
}

sub STORE {
    my ( $drh, $attr, $value ) = @_;
    if ( $attr =~ /^mock_/ ) {
        if ( $attr eq 'mock_connect_fail' ) {
            return $drh->{'mock_connect_fail'} = $value ? 1 : 0;
        }
        elsif ( $attr eq 'mock_data_sources' ) {
            if ( ref($value) ne 'ARRAY' ) {
                $drh->set_err( 1,
                    "You must pass an array ref of data sources" );
                return;
            }
            return $drh->{'mock_data_sources'} = $value;
        }
        elsif ( $attr eq 'mock_add_data_sources' ) {
            return push @{ $drh->{'mock_data_sources'} } => $value;
        }
    }
    else {
        return $drh->SUPER::STORE( $attr, $value );
    }
}

sub data_sources {
    my $drh = shift;
    return
      map { (/^DBI\:Mock\:/i) ? $_ : "DBI:Mock:$_" }
      @{ $drh->FETCH('mock_data_sources') };
}

# Necessary to support DBI < 1.34
# from CPAN RT bug #7057

sub disconnect_all {

    # no-op
}

sub DESTROY { undef }

1;
