package Yahoo::Finance;

use 5.006;
use strict;
use warnings;
use Carp;
use Exporter ();

use vars qw($VERSION @EXPORT @ISA $BASE_URL %DEFAULT);

use DateTime;
use LWP::UserAgent;

@ISA = qw(Exporter);

@EXPORT = qw( get_historic_data );

# https://query1.finance.yahoo.com/v7/finance/download/GAIL.BO?period1=864000000&period2=1588032000&interval=1d&events=split
############################################################
# DEFAULT base url
############################################################
$DEFAULT{BASE_URL} = 'https://query1.finance.yahoo.com/v7/finance/download/';
############################################################
# DEFAULT from date  01-01-1800
############################################################
$DEFAULT{period1} = '-5364662400';
############################################################
# DEFAULT to date todays date
############################################################
$DEFAULT{period2} = time();
############################################################
# DEFAULT interval 1d
############################################################
$DEFAULT{interval} = '1d';
############################################################
# DEFAULT event history
############################################################
$DEFAULT{events} = 'history';
############################################################
# DEFAULT time out 60 sec
############################################################
$DEFAULT{timeout} = 60;
############################################################
# Set version
############################################################

our $VERSION = '0.01';

=head1 SYNOPSIS

    (2020) Yahoo::Finance get the symbols historic data from yahoo

Perhaps a little code snippet.


    #oject oriented interface

    use Yahoo::Finance;

    my $fin = Yahoo::Finance->new();

        my $param = {
            symbol   => 'GAIL.BO',     
            period1  => '25-12-2015',  #optional default '01-01-1800'
            period2  => '25-12-2019',  #optional default 'todays date'
            interval => '1mo',         #optional default '1d'
            events   => 'split',       #optional default 'history'
            timeout  => '30',          #optional default '60'
        };

        print $fin->get_historic_data( $param );

                                or

        #only div for week interval
        my $param = {
            symbol   => 'GAIL.BO',
            interval => '1wk',
            events   => 'div',
        };

        print $fin->get_historic_data( $param );

                                or

        print $fin->get_historic_data({ 'symbol' => 'GAIL.BO' });



        #non-oject oriented interface

          use Yahoo::Finance;
          print get_historic_data( { 'symbol' => 'GOLD' } );


=head1 SUBROUTINES/METHODS

=head2 new

    used to create a constructor of Yahoo::Finance

=cut

sub new {
    bless( {}, shift );
}

=pod

=head2 get_historic_data

     params hash ref of following valid keys

=over 7

=item *  B<invocant>  { optional but required when using object oriented interface }


=item *  B<symbol>  { scalar string }

C<symbol> name used by the yahoo fianance.

Please note yahoo uses suffix on every symbol.

Pass the symobl with suffix.

    eg symbol GAIL listed on BSE represented by yahoo-finance as "GAIL.BO"


=item *   B<period1>

C<period1> B<scalar string optional default is "01-01-1800"> format B<MM-DD-YYYY>

period1 is the start date from where the data is needed 

    format is strictly MM-DD-YYYY

=item * B<period2>

C<period2> B<scalar string optional default is todays date> format B<MM-DD-YYYY>

period2 is the to date till when the data is needed.

    format is strictly MM-DD-YYYY

=item *  B<interval>

C<interval> scalar string (optional default 1d)

This is the interval at which data is needed.

    allowed options "1d" or "1w" or "1mo"

    1d is 1 day
    1w is 1 week
    1mo is 1 month


=item *  B<events> 

C<events> scalar string  (optional default history)
This the event data needed.

        allowed options  "history" or "split" or "div"


=item *  B<timeout>

C<timeout> scalar string in sec (optional default 60)

request timeout.

        in seconds default is 60

=back

=cut

############################################################
# get_historic_data
############################################################
sub get_historic_data {
    my ( $result, $valid_params );

    if ( scalar @_ > 1 ) {
        my ( $self, $params ) = @_;
        $valid_params = $self->_validate_set_default( $params );
        $result       = $self->_get_data( $valid_params );
    } else {
        my $params = shift;
        $valid_params = _validate_set_default( $params );
        $result       = _get_data( $valid_params );
    }

    return $result;
}

############################################################
# _validate_set_default internal function
############################################################
sub _validate_set_default {
    my ( $self, $params );

    if ( scalar @_ > 1 ) {
        ( $self, $params ) = @_;
    } else {
        $params = shift;
    }

    croak 'key  sybmol not provided eg. $params->{symbol} ="GOLD" ' unless ( defined $params->{symbol} );

    my $result;
############################################################
    # mandatory fields iterate or set default
############################################################
    foreach ( qw/symbol period1 period2 interval events timeout/ ) {
        $result->{$_} = $params->{$_} // $DEFAULT{$_};
############################################################
        # change date to epoch
############################################################
        if ( $_ =~ /Period\d/ ) {

            #mm-dd-yyyy
            if ( $result->{$_} =~ /(\d{1,2})\-(\d{1,2})\-(\d{4})/ ) {
                my $dt = DateTime->new(
                    year      => $3,
                    month     => $1,
                    day       => $2,
                    time_zone => 'floating',
                );
                $result->{$_} = $dt->epoch();
            }
        }
    }

    return $result;
}

sub _get_data {
    my ( $self, $params );

    if ( scalar @_ > 1 ) {
        ( $self, $params ) = @_;
    } else {
        $params = shift;
    }

############################################################
    # generate url
############################################################
    my $ua = LWP::UserAgent->new( timeout => $params->{timeout} );

    # https://query1.finance.yahoo.com/v7/finance/download/GAIL.BO?period1=864000000&period2=1588032000&interval=1d&events=split
    $ua->env_proxy;

    my $url =
        "$DEFAULT{BASE_URL}"
      . uc( $params->{symbol} )
      . "?period1="
      . $params->{period1}
      . "&period2="
      . $params->{period2}
      . "&interval="
      . $params->{interval}
      . "&events="
      . $params->{events};

    my $response;
############################################################
    # retry 3 times
############################################################
    foreach ( 1 .. 3 ) {
        $response = $ua->get( $url );
        last if ( $response->is_success );
    }

    unless ( $response->is_success ) {
        carp "Error occured while fetching data error: " . $response->status_line . "\n try following url in browser or curl '$url'";
    }
############################################################
    # return if valid resposne recieved
############################################################
    return $response->decoded_content;
}

=head1 AUTHOR

Sushrut Pajai, C<< <spajai at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-yahoo-finance at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Yahoo-Finance>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Yahoo::Finance


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Yahoo-Finance>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Yahoo-Finance>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Yahoo-Finance>

=item * Search CPAN

L<https://metacpan.org/release/Yahoo-Finance>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Sushrut Pajai.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Yahoo::Finance
