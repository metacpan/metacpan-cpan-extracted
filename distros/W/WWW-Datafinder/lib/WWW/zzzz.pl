    my $res = $df->append_email(
        {
            d_zip      => $cust->{ZIP},
            d_fulladdr => $cust->{Address},
            d_state    => $cust->{State},
            d_city     => $cust->{City},
            d_first    => $cust->{Name},
            d_last     => $cust->{Surname}
        }
    );
    if ($res) {
        if ( $res->{ num-results } ) {
            # there is a match!
            print "Got a match: " . Dumper( $res->{results} );
        }
    } else {
        warn 'Something went wrong ' . $df->error_message();
    }
