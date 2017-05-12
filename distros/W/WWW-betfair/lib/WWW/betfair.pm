package WWW::betfair;
use strict;
use warnings;
use WWW::betfair::Template;
use WWW::betfair::Request;
use WWW::betfair::TypeCheck;
use Time::Piece;
use XML::Simple;
use Carp qw /croak/;
use feature qw/switch/;

=head1 NAME

WWW::betfair - interact with the betfair API using OO Perl

=head1 VERSION

Version 1.03

=cut

our $VERSION = '1.03';


=head1 IMPORTANT

This module is deprecated and not recommended to be used anymore. Betfair has disabled their old API, and this module no longer works.

=head1 WHAT IS BETFAIR?

L<betfair|http://www.betfair.com> is a sports betting services provider best known for hosting the largest sports betting exchange in the world. The sports betting exchange works like a marketplace: betfair provides an anonymous platform for individuals to offer and take bets on sports events at a certain price and size; it is the ebay of betting. betfair provides an API for the sports betting exchange which enables users to search for sports events and markets, place and update bets and manage their account by depositing and withdrawing funds.

=head1 WHY USE THIS LIBRARY?

The betfair API communicates using verbose XML files which contain various bugs and quirks. L<WWW::betfair> makes it easier to use the betfair API by providing a Perl interface which manages the befair session, serializing API calls to betfair into the required XML format and de-serializing and parsing the betfair responses back into Perl data structures. Additionally L<WWW::betfair> provides:

=over

=item *

100% of the free and paid methods of the betfair API

=item *

Documentation for every method with an example method call and reference to the original betfair documentation

=item *

Type-checking of arguments before they are sent to betfair

=back

=head1 WARNING

Betting using a software program can have unintended consequences. Check all argument types and values before using the methods in this library. Ensure that you adequately test any method of L<WWW::betfair> before using the method and risking money on it. As per the software license it is provided AS IS and no liability is accepted for any costs or penalties caused by using L<WWW::betfair>. 

To understand how to use the betfair API it is essential to read the L<betfair documentation|http://bdp.betfair.com/docs/> before using L<WWW::betfair>. The betfair documentation is an excellent reference.

=head1 SYNOPSIS

L<WWW::betfair> provides an object oriented Perl interface for the betfair v6 API. This library communicates via HTTPS to the betfair servers using XML. To use the API you must have an active and funded account with betfair, and be accessing the API from a location where betfair permits use (e.g. USA based connections are refused, but UK connections are allowed). L<WWW::betfair> provides methods to connect to the betfair exchange, search for market prices place and update bets and manage your betfair account.

Example

    use WWW::betfair;
    use Data::Dumper;

    my $betfair = WWW::betfair->new;
    
    # login is required before performing any other services
    if ($betfair->login({username => 'sillymoos', password => 'password123'}) {
        
        # check account balance
        print Dumper($betfair->getAccountFunds);

        # get a list of all active event types (categories of sporting events e.g. football, tennis, boxing).
        print Dumper($betfair->getActiveEventTypes);

    }
    # login failed print the error message returned by betfair
    else {
        print Dumper($betfair->getError);
    }

=head1 NON API METHODS

=head2 new

Returns a new WWW::betfair object. Does not require any parameters.

Example

    my $betfair = WWW::betfair->new;

=cut

sub new {
    my $class = shift;
    my $self = {
        xmlsent     => undef,
        xmlreceived => undef,
        headerError => undef,
        bodyError   => undef,
        response    => {},
        sessionToken=> undef,
    };
    my $obj = bless $self, $class;
    my $typechecker = WWW::betfair::TypeCheck->new;
    $obj->{type} = $typechecker;
    return $obj;
}

=head2 getError

Returns the error message from the betfair API response - this is useful when a request fails. After a successful call API the value returned by getError is 'OK'.

Example

    my $error = $betfair->getError;

=cut

sub getError {
    my $self = shift;
    return  $self->{headerError} eq 'OK' ? $self->{bodyError} : $self->{headerError};
}

=head2 getXMLSent

Returns a string of the XML message sent to betfair. This can be useful to inspect if de-bugging a failed API call.

Example

    my $xmlSent = $betfair->getXMLSent;

=cut

sub getXMLSent {
    my $self = shift;
    return $self->{xmlsent};
}

=head2 getXMLReceived

Returns a string of the XML message received from betfair. This can be useful to inspect if de-bugging a failed API call.

Example

    my $xmlReceived = $betfair->getXMLReceived;

=cut

sub getXMLReceived {
    my $self = shift;
    return $self->{xmlreceived};
}

=head2 getHashReceived

Returns a Perl data structure consisting of the entire de-serialized betfair XML response. This can be useful to inspect if de-bugging a failed API call and easier to read than the raw XML message, especially if used in conjunction with L<Data::Dumper>.

Example

    my $hashReceived = $betfair->getHashReceived;

=cut

sub getHashReceived {
    my $self = shift;
    return $self->{response};
}

=head1 GENERAL API METHODS

=head2 login

Authenticates the user and starts a session with betfair. This is required before any other methods can be used. Returns 1 on success and 0 on failure. If login fails and you are sure that you are using the correct the credentials, check the $betfair->{error} attribute. A common reason for failure on login is not having a funded betfair account. To resolve this, simply make a deposit into your betfair account and the login should work. See L<login|http://bdp.betfair.com/docs/Login.html> for details. Required arguments:

=over

=item *

username: string of your betfair username

=item *

password: string of your betfair password

=item *

productID: integer that indicates the API product to be used (optional). This defaults to 82 (the free personal API). Provide this argument if using a commercial version of the betfair API.

=back

Example

    $betfair->login({
                username => 'sillymoos',
                password => 'password123',
              });

=cut

sub login {
    my ($self, $args) = @_;
    my $paramChecks = { 
            username    => ['username', 1],
            password    => ['password', 1],
            productId   => ['int', 0],
    };
    return 0 unless $self->_checkParams($paramChecks, $args);
    my $params = {
        username    => $args->{username},
        password    => $args->{password}, 
        productId   => $args->{productId} || 82,
        locationId  => 0,
        ipAddress   => 0,
        vendorId    => 0,
        exchangeId  => 3,
    };
    return $self->_doRequest('login', $params); 
}

=head2 keepAlive

Refreshes the current session with betfair. Returns 1 on success and 0 on failure. See L<keepAlive|http://bdp.betfair.com/docs/keepAlive.html> for details. Does not require any parameters. This method is not normally required as a session expires after 24 hours of inactivity.

Example

    $betfair->keepAlive;

=cut

sub keepAlive {
    my $self = shift;
    return $self->_doRequest('keepAlive', {exchangeId => 3});
}

=head2 logout

Closes the current session with betfair. Returns 1 on success and 0 on failure. See L<logout|http://bdp.betfair.com/docs/Logout.html> for details. Does not require any parameters.

Example

    $betfair->logout;

=cut

sub logout {
    my $self = shift;
    if ($self->_doRequest('logout', {exchangeId => 3})) {
        # check body error message, different to header error
        my $self->{error} 
            = $self->{response}->{'soap:Body'}->{'n:logoutResponse'}->{'n:Result'}->{'errorCode'}->{content};
        return 1 if $self->{error} eq 'OK';
    }
    return 0;
}

=head1 READ ONLY BETTING API METHODS

=head2 convertCurrency

Returns the betfair converted amount of currency see L<convertCurrency|http://bdp.betfair.com/docs/ConvertCurrency.html> for details. Requires a hashref with the following parameters:

=over

=item *

amount: this is the decimal amount of base currency to convert.

=item *

fromCurrency : this is the base currency to convert from.

=item *

toCurrency : this is the target currency to convert to.

=back

Example

    $betfair->convertCurrency({ amount          => 5,
                                fromCurrency    => 'GBP',
                                toCurrency      => 'USD',
                              });

=cut

sub convertCurrency {
    my ($self, $args) = @_;
    my $checkParams = {
        amount              => ['decimal', 1],
        fromCurrency        => ['string', 1],
        toCurrency          => ['string', 1],
    };
    $args->{exchangeId} = 3;
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('convertCurrency', $args) ) {
        return { convertedAmount =>
                $self->{response}->{'soap:Body'}->{'n:convertCurrencyResponse'}->{'n:Result'}->{'convertedAmount'}->{content}
        };
    }
    return 0;
}

=head2 getActiveEventTypes

Returns an array of hashes of active event types or 0 on failure. See L<getActiveEventTypes|http://bdp.betfair.com/docs/GetActiveEventTypes.html> for details. Does not require any parameters.

Example

    my $activeEventTypes = $betfair->getActiveEventTypes;

=cut

sub getActiveEventTypes {
    my $self = shift;
    my $active_event_types =[];
    if ($self->_doRequest('getActiveEventTypes', {exchangeId => 3}) ) {
        foreach (@{$self->{response}->{'soap:Body'}->{'n:getActiveEventTypesResponse'}->{'n:Result'}->{'eventTypeItems'}->{'n2:EventType'}}) {
            push(@{$active_event_types},{ 
                name            => $_->{'name'}->{content},
                id              => $_->{'id'}->{content},
                exchangeId      => $_->{'exchangeId'}->{content},
                nextMarketId    => $_->{'nextMarketId'}->{content},
            });
        }
        return $active_event_types;
    }
    return 0;
}

=head2 getAllCurrencies

Returns an arrayref of currency codes and the betfair GBP exchange rate. See L<getAllCurrencies|http://bdp.betfair.com/docs/GetAllCurrencies.html>. Requires no parameters.

Example

    $betfair->getAllCurrencies;

=cut

sub getAllCurrencies {
    my $self = shift;
    my $currencies =[];
    if ($self->_doRequest('getAllCurrencies', {exchangeId => 3}) ) {
        foreach (@{$self->{response}->{'soap:Body'}->{'n:getAllCurrenciesResponse'}->{'n:Result'}->{'currencyItems'}->{'n2:Currency'}}) {
            push(@{$currencies},{
                currencyCode    => $_->{'currencyCode'}->{content},
                rateGBP         => $_->{'rateGBP'}->{content},
            });
        }
        return $currencies;
    }
    return 0;
}

=head2 getAllCurrenciesV2

Returns an arrayref of currency codes, the betfair GBP exchange rate and staking sizes for the currency. See L<getAllCurrenciesV2|http://bdp.betfair.com/docs/GetAllCurrenciesV2.html>. Requires no parameters.

Example

    $betfair->getAllCurrenciesV2;

=cut

sub getAllCurrenciesV2 {
    my $self = shift;
    my $currenciesV2 =[];
    if ($self->_doRequest('getAllCurrenciesV2', {exchangeId => 3}) ) {
        foreach (@{$self->{response}->{'soap:Body'}->{'n:getAllCurrenciesV2Response'}->{'n:Result'}->{'currencyItems'}->{'n2:CurrencyV2'}}) {
            push(@{$currenciesV2},{
                currencyCode            => $_->{'currencyCode'}->{content},
                rateGBP                 => $_->{'rateGBP'}->{content},
                minimumStake            => $_->{'minimumStake'}->{content},
                minimumRangeStake       => $_->{'minimumRangeStake'}->{content},
                minimumBSPLayLiability => $_->{'minimumBSPLayLiability'}->{content},
            });
        }
        return $currenciesV2;
    }
    return 0;
}

=head2 getAllEventTypes

Returns an array of hashes of all event types or 0 on failure. See L<getAllEventTypes|http://bdp.betfair.com/docs/GetAllEventTypes.html> for details. Does not require any parameters.

Example

    my $allEventTypes = $betfair->getAllEventTypes;

=cut

sub getAllEventTypes {
    my $self = shift;
    if ($self->_doRequest('getAllEventTypes', {exchangeId => 3})) {
        my $all_event_types = [];
        foreach (@{$self->{response}->{'soap:Body'}->{'n:getAllEventTypesResponse'}->{'n:Result'}->{'eventTypeItems'}->{'n2:EventType'} }) {
            push(@{$all_event_types},{
                name            => $_->{'name'}->{content},
                id              => $_->{'id'}->{content},
                exchangeId      => $_->{'exchangeId'}->{content},
                nextMarketId    => $_->{'nextMarketId'}->{content},
            });   
        }
        return $all_event_types;  
    } 
    return 0;
}

=head2 getAllMarkets

Returns an array of hashes of all markets or 0 on failure. See L<getAllMarkets|http://bdp.betfair.com/docs/GetAllMarkets.html> for details. Requires a hashref with the following parameters:

=over

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $allMarkets = $betfair->getAllMarkets({exchangeId => 1});

=cut

sub getAllMarkets {
    my ($self, $args) = @_;
    my $checkParams = {exchangeId => ['exchangeId', 1]};
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getAllMarkets', $args)) {
        my $all_markets = [];
        foreach (split /:/, $self->{response}->{'soap:Body'}->{'n:getAllMarketsResponse'}->{'n:Result'}->{'marketData'}->{content}) {
            next unless $_;
            my @market = split /~/;
            push @{$all_markets}, { 
                    marketId            => $market[0], 
                    marketName          => $market[1],         
                    marketType          => $market[2],
                    marketStatus        => $market[3],
                    marketDate          => $market[4], 
                    menuPath            => $market[5],
                    eventHierarchy      => $market[6],
                    betDelay            => $market[7],
                    exchangeId          => $market[8],
                    iso3CountryCode     => $market[9],
                    lastRefresh         => $market[10],
                    numberOfRunners     => $market[11],
                    numberOfWinners     => $market[12],
                    totalMatchedAmount  => $market[13],
                    bspMarket           => $market[14],
                    turningInPlay       => $market[15],
            };
        }
        return $all_markets;
    } 
    return 0; 
}

=head2 getBet

Returns a hashref of betfair's bet response, including an array of all matches to a bet. See L<getBet|http://bdp.betfair.com/docs/GetBet.html> for details. Requires a hashref with the following argument:

=over

=item *

betId - the betId integer of the bet to retrieve data about.

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $bet = $betfair->getBet({betId       => 123456789
                                exchangeId  => 1,
                              });

=cut

sub getBet {
    my ($self, $args) = @_;
    my $checkParams = { betId       => ['int', 1],
                        exchangeId  => ['exchangeId', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getBet', $args)) {
        my $response = $self->{response}->{'soap:Body'}->{'n:getBetResponse'}->{'n:Result'}->{bet};
        my $bet = {
            asianLineId     => $response->{asianLineId}->{content},
            avgPrice        => $response->{avgPrice}->{content},
            betCategoryType => $response->{betCategoryType}->{content},
            betId           => $response->{betId}->{content},
            betPersistenceType  => $response->{betPersistenceType}->{content},
            betStatus           => $response->{betStatus}->{content},
            betType             => $response->{betType}->{content},
            bspLiability        => $response->{bspLiability}->{content},
            cancelledDate       => $response->{cancelledDate}->{content},
            executedBy          => $response->{executedBy}->{content},
            fullMarketName      => $response->{fullMarketName}->{content},
            handicap            => $response->{handicap}->{content},
            lapsedDate          => $response->{lapsedDate}->{content},
            marketId            => $response->{marketId}->{content},
            marketName          => $response->{marketName}->{content},
            marketType          => $response->{marketType}->{content},
            marketTypeVariant   => $response->{marketTypeVariant}->{content},
            matchedDate         => $response->{matchedDate}->{content},
            matchedSize         => $response->{matchedSize}->{content},
            matches             => [],
            placedDate          => $response->{placedDate}->{content},
            price               => $response->{price}->{content},
            profitAndLoss       => $response->{profitAndLoss}->{content},
            remainingSize       => $response->{remainingSize}->{content},
            requestedSize       => $response->{requestedSize}->{content},
            selectionId         => $response->{selectionId}->{content},
            selectionName       => $response->{selectionName}->{content},
            settledDate         => $response->{settledDate}->{content},
            voidedDate          => $response->{voidedDate}->{content},
        };
        my $matches = $self->_forceArray($response->{matches}->{'n2:Match'});
        foreach my $match (@{$matches}){
            push @{$bet->{matches}}, {
                betStatus       => $match->{betStatus}->{content},
                matchedDate     => $match->{matchedDate}->{content},
                priceMatched    => $match->{priceMatched}->{content},
                profitLoss      => $match->{profitLoss}->{content},
                settledDate     => $match->{settledDate}->{content},
                sizeMatched     => $match->{sizeMatched}->{content},
                transactionId   => $match->{transactionId}->{content},
                voidedDate      => $match->{voidedDate}->{content},
            };
        }
        return $bet;
    } 
    return 0;
}

=head2 getBetHistory

Returns an arrayref of hashrefs of bets. See L<getBetHistory|http://bdp.betfair.com/docs/GetBetHistory.html> for details. Requires a hashref with the following parameters:

=over

=item *

betTypesIncluded : string of a valid BetStatusEnum type as defined by betfair (see L<betStatusEnum|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1028849i1028849>)

=item *

detailed : boolean string e.g. ('true' or 'false') indicating whether or not to include the details of all matches per bet.

=item *

eventTypeIds : an arrayref of integers that represent the betfair eventTypeIds. (e.g. [1, 6] would be football and boxing). This is not mandatory if the betTypesIncluded parameter equals 'M' or 'U'.

=item *

marketId : an integer representing the betfair marketId (optional).

=item *

marketTypesIncluded : arrayref of strings of the betfair marketTypesIncluded enum. See L<marketTypesIncludedEnum|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1020360i1020360> for details.

=item *

placedDateFrom : string date for which to return records on or after this date (a string in the XML datetime format see example).

=item *

placedDateTo : string date for which to return records on or before this date (a string in the XML datetime format see example).

=item *

recordCount : integer representing the maximum number of records to retrieve (must be between 1 and 100).

=item *

sortBetsBy : string of a valid BetsOrderByEnum types as defined by betfair. see L<BetsOrderByEnum|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1033170i1033170>

=item *

startRecord : integer of the index of the first record to retrieve. The index is zero-based so 0 would indicate the first record in the resultset

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $betHistory = $betfair->getBetHistory({
                            betTypesIncluded    => 'M',
                            detailed            => 'false',
                            eventTypeIds        => [6],
                            marketTypesIncluded => ['O', 'L', 'R'],
                            placedDateFrom      => '2013-01-01T00:00:00.000Z',         
                            placedDateTo        => '2013-06-16T00:00:00.000Z',         
                            recordCount         => 100,
                            sortBetsBy          => 'PLACED_DATE',
                            startRecord         => 0,
                            exchangeId          => 1,
                            });

=cut

sub getBetHistory {
    my ($self, $args) = @_;
    my $checkParams = {
        betTypesIncluded    => ['betStatusEnum', 1],
        detailed            => ['boolean', 1],
        eventTypeIds        => ['arrayInt', 1],
        sortBetsBy          => ['betsOrderByEnum', 1],
        recordCount         => ['int', 1,],
        startRecord         => ['int', 1],
        placedDateTo        => ['date', 1],
        placedDateFrom      => ['date', 1],
        marketTypesIncluded => ['arrayMarketTypeEnum', 1],
        marketId            => ['int', 0],
        exchangeId          => ['exchangeId', 1],
    };
    # eventTypeIds is not mandatory if betTypesIncluded is 'M' or 'U'
    $checkParams->{eventTypeIds}->[1] = 0 if grep{/$args->{betTypesIncluded}/} qw/M U/;

    # marketId is mandatory if betTypesIncluded is 'S', 'C', or 'V'
    $checkParams->{marketId}->[1] = 1 if grep{/$args->betTypesIncluded/} qw/S C V/;
    
    return 0 unless $self->_checkParams($checkParams, $args);

    # make eventTypeIds an array of int
    my @eventTypeIds = $args->{eventTypeIds};
    delete $args->{eventTypeIds};
    $args->{eventTypeIds}->{'int'} = \@eventTypeIds;

    # make marketTypesIncluded an array of marketTypeEnum
    my @marketTypes = $args->{marketTypesIncluded};
    delete $args->{marketTypesIncluded};
    $args->{marketTypesIncluded}->{'MarketTypeEnum'} = \@marketTypes;

    if ($self->_doRequest('getBetHistory', $args) ) {
        my $response = $self->_forceArray(
                $self->{response}->{'soap:Body'}->{'n:getBetHistoryResponse'}->{'n:Result'}->{'betHistoryItems'}->{'n2:Bet'});
        my $betHistory = [];
        foreach (@{$response}) {
            my $bet = {
                asianLineId         => $_->{asianLineId}->{content},
                avgPrice            => $_->{avgPrice}->{content},
                betCategoryType     => $_->{betCategoryType}->{content},
                betId               => $_->{betId}->{content},
                betPersistenceType  => $_->{betPersistenceType}->{content},
                betStatus           => $_->{betStatus}->{content},
                betType             => $_->{betType}->{content},
                bspLiability        => $_->{bspLiability}->{content},
                cancelledDate       => $_->{cancelledDate}->{content},
                fullMarketName      => $_->{fullMarketName}->{content},
                handicap            => $_->{handicap}->{content},
                lapsedDate          => $_->{lapsedDate}->{content},
                marketId            => $_->{marketId}->{content},
                marketName          => $_->{marketName}->{content},
                marketType          => $_->{marketType}->{content},
                marketTypeVariant   => $_->{marketTypeVariant}->{content},
                matchedDate         => $_->{matchedDate}->{content},
                matchedSize         => $_->{matchedSize}->{content},
                matches             => [],
                placedDate          => $_->{placedDate}->{content},
                price               => $_->{price}->{content},
                profitAndLoss       => $_->{profitAndLoss}->{content},
                remainingSize       => $_->{remainingSize}->{content},
                requestedSize       => $_->{requestedSize}->{content},
                selectionId         => $_->{selectionId}->{content},
                selectionName       => $_->{selectionName}->{content},
                settledDate         => $_->{settledDate}->{content},
                voidedDate          => $_->{voidedDate}->{content},
            };
            my $matches = $self->_forceArray($_->{matches}->{'n2:Match'});
            foreach my $match (@{$matches}){
                push @{$bet->{matches}}, {
                    betStatus       => $match->{betStatus}->{content},
                    matchedDate     => $match->{matchedDate}->{content},
                    priceMatched    => $match->{priceMatched}->{content},
                    profitLoss      => $match->{profitLoss}->{content},
                    settledDate     => $match->{settledDate}->{content},
                    sizeMatched     => $match->{sizeMatched}->{content},
                    transactionId   => $match->{transactionId}->{content},
                    voidedDate      => $match->{voidedDate}->{content},
                };
            }
            push @{$betHistory}, $bet;
        }
        return $betHistory;
    }
    return 0;
}

=head2 getBetLite

Returns a hashref of bet information. See L<getBetLite|http://bdp.betfair.com/docs/GetBetLite.html> for details. Requires a hashref with the following key pair/s:

=over

=item *

betId : integer representing the betfair id for the bet to retrieve data about.

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $betData = $betfair->getBetLite({betId       => 123456789
                                        exchangeId  => 2,
                                       });

=cut

sub getBetLite {
    my ($self, $args) = @_;
    my $checkParams = { betId       => ['int', 1], 
                        exchangeId  => ['exchangeId', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getBetLite', $args)) {
        my $response = $self->{response}->{'soap:Body'}->{'n:getBetLiteResponse'}->{'n:Result'}->{'betLite'};
        return {
            betCategoryType     => $response->{betCategoryType}->{content},
            betId               => $response->{betId}->{content},
            betPersistenceType  => $response->{betPersistenceType}->{content},
            betStatus           => $response->{betStatus}->{content},
            bspLiability        => $response->{bspLiability}->{content},
            marketId            => $response->{marketId}->{content},
            matchedSize         => $response->{matchedSize}->{content},
            remainingSize       => $response->{remainingSize}->{content},
        };
    } 
    return 0; 
}


=head2 getBetMatchesLite

Returns an arrayref of hashrefs of matched bet information. See L<getBetMatchesLite|http://bdp.betfair.com/docs/GetBetMatchesLite.html> for details. Requires a hashref with the following key pair/s:

=over

=item *

betId : integer representing the betfair id for the bet to retrieve data about.

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $betData = $betfair->getBetMatchesLite({ betId       => 123456789
                                                exchangeId  => 1,
                                               });

=cut

sub getBetMatchesLite {
    my ($self, $args) = @_;
    my $checkParams = { betId       => ['int', 1],
                        exchangeId  => ['exchangeId', 0],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getBetMatchesLite', $args)) {
        my $response = $self->_forceArray($self->{response}->{'soap:Body'}->{'n:getBetMatchesLiteResponse'}->{'n:Result'}->{matchLites}->{'n2:MatchLite'});
        my $matchedBets = [];
        foreach (@{$response}) {
            push @{$matchedBets}, {
                betStatus       => $_->{betStatus}->{content},
                matchedDate     => $_->{matchedDate}->{content},
                priceMatched    => $_->{priceMatched}->{content},
                sizeMatched     => $_->{sizeMatched}->{content},
                transactionId   => $_->{transactionId}->{content},
            };
        }
        return $matchedBets;
    } 
    return 0; 
}

=head2 getCompleteMarketPricesCompressed

Returns a hashref of market data including an arrayhashref of individual selection prices data. See L<getCompleteMarketPricesCompressed|http://bdp.betfair.com/docs/GetCompleteMarketPricesCompressed.html> for details. Note that this method de-serializes the compressed string returned by the betfair method into a Perl data structure. Requires:

=over

=item *

marketId : integer representing the betfair market id.

=item *

currencyCode : string representing the three letter ISO currency code. Only certain currencies are accepted by betfair GBP, USD, EUR, NOK, SGD, SEK, AUD, CAD, HKD, DKK (optional)

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $marketPriceData = $betfair->getCompleteMarketPricesCompressed({ marketId    => 123456789,
                                                                        exchangeId  => 2,
                                                                      }); 

=cut

sub getCompleteMarketPricesCompressed {
    my ($self, $args) = @_;
    my $checkParams = { 
        marketId        => ['int', 1],
        currencyCode    => ['currencyCode', 0],
        exchangeId      => ['exchangeId', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getCompleteMarketPricesCompressed', $args)) {
        my $response = $self->{response}->{'soap:Body'}->{'n:getCompleteMarketPricesCompressedResponse'}->{'n:Result'}->{'completeMarketPrices'}->{content};
        my @fields = split /:/, $response;
        #109799180~0~;name,timeRemoved,reductionFactor;
        my $idAndRemovedRunners = shift @fields; # not used yet
        my $selections = [];
        foreach my $selection (@fields) {
            my @selectionFields = split /\|/, $selection;
            my @selectionData = split /~/, shift @selectionFields;
            my $prices = [];
            next unless $selectionFields[0];
            my @selectionPrices = split /~/, $selectionFields[0];
            while (@selectionPrices) {
                push @{$prices}, {
                    price           => shift @selectionPrices,
                    back_amount     => shift @selectionPrices,
                    lay_amount      => shift @selectionPrices,
                    bsp_back_amount => shift @selectionPrices,
                    bsp_lay_amount  => shift @selectionPrices,
                }; 
            }
            push @{$selections}, {
                prices              => $prices,
                selectionId         => $selectionData[0],
                orderIndex          => $selectionData[1],
                totalMatched        => $selectionData[2],
                lastPriceMatched    => $selectionData[3],
                asianHandicap       => $selectionData[4],
                reductionFactor     => $selectionData[5],
                vacant              => $selectionData[6],
                asianLineId         => $selectionData[7],
                farPriceSp          => $selectionData[8],
                nearPriceSp         => $selectionData[9],
                actualPriceSp       => $selectionData[10],
            };
        }
        return {    marketId    => $args->{marketId},
                    selections  => $selections,
        };
    }
    return 0;
}

=head2 getCurrentBets

Returns an arrayref of hashrefs of current bets or 0 on failure. See L<getCurrentBets|http://bdp.betfair.com/docs/GetCurrentBets.html> for details. Requires a hashref with the following parameters:

=over

=item *

betStatus : string of a valid BetStatus enum type as defined by betfair see L<betStatusEnum|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1028849i1028849> for details.

=item *

detailed : string of either true or false

=item *

orderBy : string of a valid BetsOrderByEnum types as defined by betfair  (see L<orderByhttp://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1033170i1033170>)

=item *

recordCount : integer of the maximum number of records to return

=item *

startRecord : integer of the index of the first record to retrieve. The index is zero-based so 0 would indicate the first record in the resultset

=item *

noTotalRecordCount : string of either true or false

=item *

marketId : integer of the betfair market id for which current bets are required (optional)

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $bets = $betfair->getCurrentBets({
                            betStatus           => 'M',
                            detailed            => 'false',
                            orderBy             => 'PLACED_DATE',
                            recordCount         => 100,
                            startRecord         => 0,
                            noTotalRecordCount  => 'true',
                            exchangeId          => 1,
                            });

=cut

sub getCurrentBets {
    my ($self, $args) = @_;
    my $checkParams = {
        betStatus           => ['betStatusEnum', 1],
        detailed            => ['boolean', 1],
        orderBy             => ['betsOrderByEnum', 1],
        recordCount         => ['int', 1,],
        startRecord         => ['int', 1],
        noTotalRecordCount  => ['boolean', 1],
        marketId            => ['int',0],
        exchangeId          => ['exchangeId', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getCurrentBets', $args) ) {
        my $response = $self->_forceArray(
                $self->{response}->{'soap:Body'}->{'n:getCurrentBetsResponse'}->{'n:Result'}->{'bets'}->{'n2:Bet'});
        my $current_bets = [];
        foreach (@{$response}) {
            my $bet = {
                asianLineId         => $_->{asianLineId}->{content},
                avgPrice            => $_->{avgPrice}->{content},
                betCategoryType     => $_->{betCategoryType}->{content},
                betId               => $_->{betId}->{content},
                betPersistenceType  => $_->{betPersistenceType}->{content},
                betStatus           => $_->{betStatus}->{content},
                betType             => $_->{betType}->{content},
                bspLiability        => $_->{bspLiability}->{content},
                cancelledDate       => $_->{cancelledDate}->{content},
                fullMarketName      => $_->{fullMarketName}->{content},
                handicap            => $_->{handicap}->{content},
                lapsedDate          => $_->{lapsedDate}->{content},
                marketId            => $_->{marketId}->{content},
                marketName          => $_->{marketName}->{content},
                marketType          => $_->{marketType}->{content},
                marketTypeVariant   => $_->{marketTypeVariant}->{content},
                matchedDate         => $_->{matchedDate}->{content},
                matchedSize         => $_->{matchedSize}->{content},
                matches             => [],
                placedDate          => $_->{placedDate}->{content},
                price               => $_->{price}->{content},
                profitAndLoss       => $_->{profitAndLoss}->{content},
                remainingSize       => $_->{remainingSize}->{content},
                requestedSize       => $_->{requestedSize}->{content},
                selectionId         => $_->{selectionId}->{content},
                selectionName       => $_->{selectionName}->{content},
                settledDate         => $_->{settledDate}->{content},
                voidedDate          => $_->{voidedDate}->{content},
            };
            my $matches = $self->_forceArray($_->{matches}->{'n2:Match'});
            foreach my $match (@{$matches}){
                push @{$bet->{matches}}, {
                    betStatus       => $match->{betStatus}->{content},
                    matchedDate     => $match->{matchedDate}->{content},
                    priceMatched    => $match->{priceMatched}->{content},
                    profitLoss      => $match->{profitLoss}->{content},
                    settledDate     => $match->{settledDate}->{content},
                    sizeMatched     => $match->{sizeMatched}->{content},
                    transactionId   => $match->{transactionId}->{content},
                    voidedDate      => $match->{voidedDate}->{content},
                };
            }
            push @{$current_bets}, $bet;
        }
        return $current_bets;
    }
    return 0;
}

=head2 getCurrentBetsLite

Returns an arrayref of hashrefs of current bets for a single market or the entire exchange. See L<getCurrentBetsLite|http://bdp.betfair.com/docs/GetCurrentBetsLite.html> for details. Requires a hashref with the following parameters:

=over

=item *

betStatus : string of a valid BetStatus enum type as defined by betfair see L<betStatusEnum|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1028849i1028849> for details.

=item *

orderBy : string of a valid BetsOrderByEnum types as defined by betfair  (see L<orderByhttp://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1033170i1033170>)

=item *

recordCount : integer of the maximum number of records to return

=item *

startRecord : integer of the index of the first record to retrieve. The index is zero-based so 0 would indicate the first record in the resultset

=item *

noTotalRecordCount : string of either 'true' or 'false' to return a total record count

=item *

marketId : integer of the betfair market id for which current bets are required (optional)

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $bets = $betfair->getCurrentBetsLite({
                            betStatus           => 'M',
                            orderBy             => 'PLACED_DATE',
                            recordCount         => 100,
                            startRecord         => 0,
                            noTotalRecordCount  => 'true',
                            exchangeId          => 1,
                            });

=cut

sub getCurrentBetsLite {
    my ($self, $args) = @_;
    my $checkParams = {
        betStatus           => ['betStatusEnum', 1],
        orderBy             => ['betsOrderByEnum', 1],
        recordCount         => ['int', 1,],
        startRecord         => ['int', 1],
        noTotalRecordCount  => ['boolean', 1],
        marketId            => ['int', 0],
        exchangeId          => ['exchangeId', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getCurrentBetsLite', $args) ) {
        my $response = $self->_forceArray(
                $self->{response}->{'soap:Body'}->{'n:getCurrentBetsLiteResponse'}->{'n:Result'}->{'betLites'}->{'n2:BetLite'});
        my $current_bets = [];
        foreach (@{$response}) {
            push @{$current_bets}, {
                betCategoryType     => $_->{betCategoryType}->{content},
                betId               => $_->{betId}->{content},
                betPersistenceType  => $_->{betPersistenceType}->{content},
                betStatus           => $_->{betStatus}->{content},
                bspLiability        => $_->{bspLiability}->{content},
                marketId            => $_->{marketId}->{content},
                matchedSize         => $_->{matchedSize}->{content},
                remainingSize       => $_->{remainingSize}->{content},
            };
        }
        return $current_bets;
    }
    return 0;
}

=head2 getDetailAvailableMktDepth

Returns an arrayref of current back and lay offers in a market for a specific selection. See L<getAvailableMktDepth|http://bdp.betfair.com/docs/GetDetailAvailableMarketDepth.html> for details. Requires a hashref with the following arguments:

=over

=item *

marketId : integer representing the betfair market id to return the market prices for.

=item * 

selectionId : integer representing the betfair selection id to return market prices for.

=item *

asianLineId : integer representing the betfair asian line id of the market - only required if the market is an asian line market (optional).

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=item *

currencyCode : string representing the three letter ISO currency code. Only certain currencies are accepted by betfair GBP, USD, EUR, NOK, SGD, SEK, AUD, CAD, HKD, DKK (optional)

=back

Example

    my $selectionPrices = $betfair->getDetailAvailableMktDepth({marketId    => 123456789,
                                                                selectionId => 987654321,
                                                                exchangeId  => 1,
                                                               });

=cut

sub getDetailAvailableMktDepth {
    my ($self, $args) = @_;
    my $checkParams = { marketId    => ['int', 1], 
                        selectionId => ['int', 1],
                        asianLineId => ['int', 0],
                        exchangeId  => ['exchangeId', 1],
                        currencyCode=> ['currencyCode', 0],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getDetailAvailableMktDepth', $args)) {
        my $response = $self->_forceArray(
                $self->{response}->{'soap:Body'}->{'n:getDetailAvailableMktDepthResponse'}->{'n:Result'}->{'priceItems'}->{'n2:AvailabilityInfo'});
        my $marketPrices = [];
        foreach (@{$response}){
            push @{$marketPrices}, {
                odds                    => $_->{odds}->{content},
                totalAvailableBackAmount=> $_->{totalAvailableBackAmount}->{content},
                totalAvailableLayAmount => $_->{totalAvailableLayAmount}->{content},
                totalBspBackAmount      => $_->{totalBspBackAmount}->{content},
                totalBspLayAmount       => $_->{totalBspLayAmount}->{content},
            };
        }
        return $marketPrices;
    }
    return 0;
}

=head2 getEvents

Returns an array of hashes of events / markets or 0 on failure. See L<getEvents|http://bdp.betfair.com/docs/GetEvents.html> for details. Requires:

=over

=item *

eventParentId : an integer which is the betfair event id of the parent event

=back

Example

    # betfair event id of tennis is 14
    my $tennisEvents = $betfair->getEvents({eventParentId => 14});

=cut

sub getEvents {
    my ($self, $args) = @_;
    my $checkParams = { eventParentId => ['int', 1] };
    return 0 unless $self->_checkParams($checkParams, $args);
    $args->{exchangeId} = 3;
    if ($self->_doRequest('getEvents', $args)) {
        my $event_response = $self->_forceArray($self->{response}->{'soap:Body'}->{'n:getEventsResponse'}->{'n:Result'}->{'eventItems'}->{'n2:BFEvent'});
        my $events;
        foreach (@{$event_response}) {
            next unless defined($_->{eventId}->{content});
            push @{$events->{events}}, {
                eventId     => $_->{eventId}->{content},
                eventName   => $_->{eventName}->{content},
                menuLevel   => $_->{menuLevel}->{content},
                orderIndex  => $_->{orderIndex}->{content},
                eventTypeId => $_->{eventTypeId}->{content},
                startTime   => $_->{startTime}->{content},
                timezone    => $_->{timezone}->{content},
            };
        }
        my $market_response = $self->_forceArray(
                $self->{response}->{'soap:Body'}->{'n:getEventsResponse'}->{'n:Result'}->{'marketItems'}->{'n2:MarketSummary'});  
        foreach (@{$market_response}) {
            next unless defined($_->{marketId}->{content});
            push @{$events->{markets}}, {
                marketId            => $_->{marketId}->{content},
                marketName          => $_->{marketName}->{content},
                menuLevel           => $_->{menuLevel}->{content},
                orderIndex          => $_->{orderIndex}->{content},
                marketType          => $_->{marketType}->{content},
                marketTypeVariant   => $_->{marketTypeVariant}->{content},
                exchangeId          => $_->{exchangeId}->{content},
                venue               => $_->{venue}->{content},
                betDelay            => $_->{betDelay}->{content},
                numberOfWinners     => $_->{numberOfWinners}->{content},
                startTime           => $_->{startTime}->{content},
                timezone            => $_->{timezone}->{content},
                eventTypeId         => $_->{eventTypeId}->{content},
            };
        }
        return $events;
    } 
    return 0;
}

=head2 getInPlayMarkets

Returns an arrayref of hashrefs of market data or 0 on failure. See L<getInPlayMarkets|http://bdp.betfair.com/docs/GetInPlayTodayMarkets.html> for details. Requires the following parameter:

=over

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $inPlayMarkets = $betfair->getInPlayMarkets({exchangeId => 1});

=cut

sub getInPlayMarkets {
    my ($self, $args) = @_;
    my $checkParams = { exchangeId => ['exchangeId', 1] };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getInPlayMarkets', $args) ) {
        my $response = $self->{response}->{'soap:Body'}->{'n:getInPlayMarketsResponse'}->{'n:Result'}->{'marketData'}->{content};
        my @markets;
        foreach (split /:/, $response) {
            next unless $_;
            my @data = split /~/, $_;
            push(@markets, {
                marketId            => $data[0],
                marketName          => $data[1],
                marketType          => $data[2],
                marketStatus        => $data[3],
                eventDate           => $data[4],
                menuPath            => $data[5],
                eventHierarchy      => $data[6],
                betDelay            => $data[7],
                exchangeId          => $data[8],
                isoCountryCode      => $data[9],
                lastRefresh         => $data[10],
                numberOfRunner      => $data[11],
                numberOfWinners     => $data[12],
                totalAmountMatched  => $data[13],
                bspMarket           => $data[14],
                turningInPlay       => $data[15],
            });

        }
        return \@markets;
    } 
    return 0;
}

=head2 getMarket

Returns a hash of market data or 0 on failure. See L<getMarket|http://bdp.betfair.com/docs/GetMarket.html> for details. Requires:

=over

=item *

marketId : integer which is the betfair id of the market

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $marketData = $betfair->getMarket({  marketId    => 108690258,
                                            exchangeId  => 2,
                                         });

=cut

sub getMarket {
    my ($self, $args) = @_;
    my $checkParams = { marketId    => ['int', 1],
                        exchangeId  => ['exchangeId', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getMarket', $args) ) {
        my $response = $self->{response}->{'soap:Body'}->{'n:getMarketResponse'}->{'n:Result'}->{'market'};
        my $runners_list = $self->_forceArray($response->{'runners'}->{'n2:Runner'});
        my @parsed_runners = ();
        foreach (@{$runners_list}) {
            push(@parsed_runners, {
                name        => $_->{'name'}->{content},
                selectionId => $_->{'selectionId'}->{content},
            });
        }
        return {
            name                => $response->{'name'}->{content},
            marketId            => $response->{'marketId'}->{content},
            eventTypeId         => $response->{'eventTypeId'}->{content}, 
            marketTime          => $response->{'marketTime'}->{content},
            marketStatus        => $response->{'marketStatus'}->{content},
            runners             => \@parsed_runners,
            marketDescription   => $response->{'marketDescription'}->{content},
            activeFlag          => 1,
        };
    } 
    return 0;
}

=head2 getMarketInfo

Returns a hash of market data or 0 on failure. See L<getMarketInfo|http://bdp.betfair.com/docs/GetMarketInfo.html> for details. Requires a hashref with the following parameters:

=over

=item *

marketId : integer which is the betfair id of the market

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $marketData = $betfair->getMarketInfo({  marketId    => 108690258,
                                                exchangeId  => 1,
                                             });

=cut

sub getMarketInfo {
    my ($self, $args) = @_;
    my $checkParams = { marketId    => ['int', 1],
                        exchangeId  => ['exchangeId', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getMarketInfo', $args) ) {
        my $response = $self->{response}->{'soap:Body'}->{'n:getMarketInfoResponse'}->{'n:Result'}->{'marketLite'};
        return {
            delay               => $response->{'delay'}->{content},
            numberOfRunners     => $response->{'numberOfRunners'}->{content},
            marketSuspendTime   => $response->{'marketSuspendTime'}->{content}, 
            marketTime          => $response->{'marketTime'}->{content},
            marketStatus        => $response->{'marketStatus'}->{content},
            openForBspBetting   => $response->{'openForBspBetting'}->{content},
        };
    } 
    return 0;
}

=head2 getMarketPrices

Returns a hashref of market data or 0 on failure. See L<getMarketPrices|http://bdp.betfair.com/docs/GetMarketPrices.html> for details. Requires:

=over

=item *

marketId : integer which is the betfair id of the market

=item *

currencyCode : string representing the three letter ISO currency code. Only certain currencies are accepted by betfair GBP, USD, EUR, NOK, SGD, SEK, AUD, CAD, HKD, DKK (optional)

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $marketPrices = $betfair->getMarketPrices({  marketId    => 108690258
                                                    exchangeId  => 2,
                                                 });

=cut

sub getMarketPrices {
    my ($self, $args) = @_;
    my $checkParams = { 
        marketId        => ['int', 1],
        currencyCode    => ['currencyCode', 0],
        exchangeId      => ['exchangeId', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getMarketPrices', $args) ) {
        my $response = $self->{response}->{'soap:Body'}->{'n:getMarketPricesResponse'}->{'n:Result'}->{'marketPrices'};
        my $runners_list = $self->_forceArray($response->{'runnerPrices'}->{'n2:RunnerPrices'});
        my @parsed_runners = ();
        foreach my $runner (@{$runners_list}) {
            my $bestPricesToBack = $self->_forceArray($runner->{bestPricesToBack}->{'n2:Price'});
            my @backPrices = ();
            foreach my $backPrice (@{$bestPricesToBack}){
                push(@backPrices, {
                    amountAvailable => $backPrice->{amountAvailable}->{content},
                    betType         => $backPrice->{betType}->{content},
                    depth           => $backPrice->{depth}->{content},
                    price           => $backPrice->{price}->{content},
                });
            }
            my $bestPricesToLay = $self->_forceArray($runner->{bestPricesToLay}->{'n2:Price'});
            my @layPrices = ();
            foreach my $layPrice (@{$bestPricesToLay}){
                push(@layPrices, {
                    amountAvailable => $layPrice->{amountAvailable}->{content},
                    betType         => $layPrice->{betType}->{content},
                    depth           => $layPrice->{depth}->{content},
                    price           => $layPrice->{price}->{content},
                });
            }
            push(@parsed_runners, {
                actualBSP           => $runner->{'actualBSP'}->{content},
                asianLineId         => $runner->{asianLineId}->{content},
                bestPricesToBack    => \@backPrices,
                bestPricesToLay     => \@layPrices,
                farBSP              => $runner->{farBSP}->{content},
                handicap            => $runner->{handicap}->{content},
                lastPriceMatched    => $runner->{lastPriceMatched}->{content},
                nearBSP             => $runner->{nearBSP}->{content},
                reductionFactor     => $runner->{reductionFactor}->{content},
                selectionId         => $runner->{selectionId}->{content},
                sortOrder           => $runner->{sortOrder}->{content},
                totalAmountMatched  => $runner->{totalAmountMatched}->{content},
                vacant              => $runner->{vacant}->{content},
            });
        }
        return {
            bspMarket       => $response->{bspMarket}->{content},
            currencyCode    => $response->{currencyCode}->{content},
            delay           => $response->{delay}->{content}, 
            discountAllowed => $response->{discountAllowed}->{content},
            lastRefresh     => $response->{lastRefresh}->{content},
            marketBaseRate  => $response->{marketBaseRate}->{content},
            marketId        => $response->{marketId}->{content},
            marketInfo      => $response->{marketInfo}->{content},
            marketStatus    => $response->{marketStatus}->{content},
            numberOfWinners => $response->{numberOfWinners}->{content},
            removedRunners  => $response->{removedRunners}->{content},
            runners         => \@parsed_runners,
        };
    } 
    return 0;
}

=head2 getMarketPricesCompressed

Returns a hashref of market data including an arrayhashref of individual selection prices data. See L<getMarketPricesCompressed|http://bdp.betfair.com/docs/GetMarketPricesCompressed.html> for details. Note that this method de-serializes the compressed string returned by the betfair method into a Perl data structure. Requires:

=over

=item *

marketId : integer representing the betfair market id.

=item *

currencyCode : string representing the three letter ISO currency code. Only certain currencies are accepted by betfair GBP, USD, EUR, NOK, SGD, SEK, AUD, CAD, HKD, DKK (optional)

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $marketPriceData = $betfair->getMarketPricesCompressed({marketId => 123456789}); 

=cut

sub getMarketPricesCompressed {
    my ($self, $args) = @_;
    my $checkParams = { marketId    => ['int', 1],
                        currencyCode=> ['currencyCode', 0],
                        exchangeId  => ['exchangeId', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getMarketPricesCompressed', $args)) {
        my $response = $self->{response}->{'soap:Body'}->{'n:getMarketPricesCompressedResponse'}->{'n:Result'}->{'marketPrices'}->{content};
        my @fields = split /:/, $response;
        my @marketData = split /~/, shift @fields;
        my @removedRunners;
        if ($marketData[9]){
            foreach (split /;/, $marketData[9]){
                next unless $_;
                my @removedRunnerData = split /,/;
                push (@removedRunners, {
                    selectionId     => $removedRunnerData[0],
                    timeRemoved     => $removedRunnerData[1],
                    reductionFactor => $removedRunnerData[2],
                });
            }
        }
        my @selections;
        foreach my $selection (@fields) {
            my @selectionFields = split /\|/, $selection;
            next unless $selectionFields[0];
            my @selectionData = split /~/, $selectionFields[0];
            my (@backPrices, @layPrices);
            my @backPriceData = split /~/, $selectionFields[1];
            while (@backPriceData) {
                push (@backPrices, {
                    price           => shift @backPriceData,
                    amount          => shift @backPriceData,
                    offerType       => shift @backPriceData,
                    depth           => shift @backPriceData,
                }); 
            }
            my @layPriceData = split /~/, $selectionFields[2];
            while (@layPriceData) {
                push (@layPrices, {
                    price           => shift @layPriceData,
                    amount          => shift @layPriceData,
                    offerType       => shift @layPriceData,
                    depth           => shift @layPriceData,
                }); 
            }
            push (@selections, {
                backPrices          => \@backPrices,
                layPrices           => \@layPrices,
                selectionId         => $selectionData[0],
                orderIndex          => $selectionData[1],
                totalMatched        => $selectionData[2],
                lastPriceMatched    => $selectionData[3],
                asianHandicap       => $selectionData[4],
                reductionFactor     => $selectionData[5],
                vacant              => $selectionData[6],
                farPriceSp          => $selectionData[7],
                nearPriceSp         => $selectionData[8],
                actualPriceSp       => $selectionData[9],
            });
        }
        return {    marketId                => $args->{marketId},
                    currency                => $marketData[1],
                    marketStatus            => $marketData[2],
                    InPlayDelay             => $marketData[3],
                    numberOfWinners         => $marketData[4],
                    marketInformation       => $marketData[5],
                    discountAllowed         => $marketData[6],
                    marketBaseRate          => $marketData[7],
                    refreshTimeMilliseconds => $marketData[8],
                    BSPmarket               => $marketData[10],
                    removedRunnerInformation=> \@removedRunners,
                    selections              => \@selections,
        };
    }
    return 0;
}

=head2 getMUBets

Returns an arrayref of hashes of bets or 0 on failure. See L<getMUBets|http://bdp.betfair.com/docs/GetMUBets.html> for details. Requires:

=over

=item *

betStatus : string of betfair betStatusEnum type, must be either matched, unmatched or both (M, U, MU). See L<http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1028849i1028849>

=item *

orderBy : string of a valid BetsOrderByEnum types as defined by betfair. see L<BetsOrderByEnum|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1033170i1033170>

=item *

recordCount : integer of the maximum number of records to return

=item *

startRecord : integer of the index of the first record to retrieve. The index is zero-based so 0 would indicate the first record in the resultset

=item *

noTotalRecordCount : string of either true or false

=item *

marketId : integer of the betfair market id for which current bets are required (optional)

=item *

betIds : an array of betIds (optional). If included, betStatus must be 'MU'.

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $muBets = $betfair->getMUBets({
                            betStatus           => 'MU',
                            orderBy             => 'PLACED_DATE',
                            recordCount         => 1000,
                            startRecord         => 0,
                            noTotalRecordCount  => 'true',
                            sortOrder           => 'ASC',
                            marketId            => 123456789,
                            exchangeId          => 1,
                 });

=cut

sub getMUBets {
    my ($self, $args ) = @_;
    my $checkParams = {
        betStatus           => ['betStatusEnum', 1],
        orderBy             => ['betsOrderByEnum', 1],
        recordCount         => ['int', 1,],
        startRecord         => ['int', 1],
        marketId            => ['int', 0],
        sortOrder           => ['sortOrderEnum', 1],
        betIds              => ['arrayInt', 0],
        exchangeId          => ['exchangeId', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if (exists $args->{betIds}) {
        my @betIds = $args->{betIds};
        $args->{betIds} = {betId => \@betIds};
    }
    my $mu_bets = [];
    if ($self->_doRequest('getMUBets', $args)) {
        my $response = $self->_forceArray(
            $self->{response}->{'soap:Body'}->{'n:getMUBetsResponse'}->{'n:Result'}->{'bets'}->{'n2:MUBet'});
        foreach (@{$response} ) {
            push @{$mu_bets}, {
                marketId            => $_->{'marketId'}->{content},
                betType             => $_->{'betType'}->{content},
                transactionId       => $_->{'transactionId'}->{content},
                size                => $_->{'size'}->{content},
                placedDate          => $_->{'placedDate'}->{content},
                betId               => $_->{'betId'}->{content},
                betStatus           => $_->{'betStatus'}->{content},
                betCategory_type    => $_->{'betCategoryType'}->{content},
                betPersistence      => $_->{'betPersistenceType'}->{content},
                matchedDate         => $_->{'matchedDate'}->{content},
                selectionId         => $_->{'selectionId'}->{content},
                price               => $_->{'price'}->{content},
                bspLiability        => $_->{'bspLiability'}->{content},
                handicap            => $_->{'handicap'}->{content},
                asianLineId         => $_->{'asianLineId'}->{content}
            };
        }
        return $mu_bets;
    } 
    return 0;
}

=head2 getMUBetsLite

Returns an arrayref of hashes of bets or 0 on failure. See L<getMUBetsLite|http://bdp.betfair.com/docs/GetMUBetsLite.html> for details. Requires:

=over

=item *

betStatus : string of betfair betStatusEnum type, must be either matched, unmatched or both (M, U, MU). See L<http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1028849i1028849>

=item *

marketId : integer of the betfair market id for which current bets are required (optional)

=item *

excludeLastSecond : boolean string value ('true' or 'false'). If true then excludes bets matched in the past second (optional)

=item *

matchedSince : a string datetime for which to only return bets matched since this datetime. Must be a valid XML datetime format, see example below (optional)

=item *

orderBy : string of a valid BetsOrderByEnum types as defined by betfair. see L<BetsOrderByEnum|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1033170i1033170>

=item *

recordCount : integer of the maximum number of records to return

=item *

startRecord : integer of the index of the first record to retrieve. The index is zero-based so 0 would indicate the first record in the resultset

=item *

sortOrder : string of the betfair sortOrder enumerated type (either 'ASC' or 'DESC'). See L<sortOrderEnum|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1028852i1028852> for details. 

=item *

betIds : an array of betIds (optional). If included, betStatus must be 'MU'.

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $muBets = $betfair->getMUBetsLite({
                            betStatus           => 'MU',
                            orderBy             => 'PLACED_DATE',
                            excludeLastSecond   => 'false',
                            recordCount         => 100,
                            startRecord         => 0,
                            matchedSince        => '2013-06-01T00:00:00.000Z',
                            sortOrder           => 'ASC',
                            marketId            => 123456789,
                            exchangeId          => 1,
                 });

=cut

sub getMUBetsLite {
    my ($self, $args ) = @_;
    my $checkParams = {
        betStatus           => ['betStatusEnum', 1],
        orderBy             => ['betsOrderByEnum', 1],
        matchedSince        => ['date', 0],
        excludeLastSecond   => ['boolean', 0],
        recordCount         => ['int', 1,],
        startRecord         => ['int', 1],
        marketId            => ['int', 0],
        sortOrder           => ['sortOrderEnum', 1],
        betIds              => ['arrayInt', 0],
        exchangeId          => ['exchangeId', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if (exists $args->{betIds}) {
        my @betIds = $args->{betIds};
        $args->{betIds} = {betId => \@betIds};
    }
    my @muBetsLite;
    if ($self->_doRequest('getMUBetsLite', $args)) {
        my $response = $self->_forceArray(
            $self->{response}->{'soap:Body'}->{'n:getMUBetsLiteResponse'}->{'n:Result'}->{'betLites'}->{'n2:MUBetLite'});
        foreach (@{$response} ) {
            push (@muBetsLite, {
                betCategoryType     => $_->{'betCategoryType'}->{content},
                betId               => $_->{'betId'}->{content},
                betPersistenceType  => $_->{'betPersistenceType'}->{content},
                betStatus           => $_->{'betStatus'}->{content},
                bspLiability        => $_->{'bspLiability'}->{content},
                marketId            => $_->{'marketId'}->{content},
                betType             => $_->{'betType'}->{content},
                size                => $_->{'size'}->{content},
                transactionId       => $_->{'transactionId'}->{content},
            });
        }
        return \@muBetsLite;
    } 
    return 0;
}

=head2 getMarketProfitAndLoss

Returns a hashref containing the profit and loss for a particular market. See L<getMarketProfitAndLoss|http://bdp.betfair.com/docs/GetMarketProfitAndLoss.html> for details. Requires:

=over

=item *

marketId : integer representing the betfair market id to return the market traded volume for

=item *

includeSettledBets : string boolean ('true' or 'false') to include settled bets in the P&L calculation (optional)

=item *

includeBspBets : string boolean ('true' or 'false') to include BSP bets in the P&L calculation

=item *

netOfCommission : string boolean ('true' or 'false') to include commission in P&L calculation (optional) 

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $marketProfitAndLoss = $betfair->getMarketProfitAndLoss({marketId        => 923456791,
                                                                includeBspBets  => 'false',
                                                                exchangeId      => 1,
                                                                });

=cut

sub getMarketProfitAndLoss {
    my ($self, $args) = @_;
    my $checkParams = { marketId            => ['int', 1], 
                        includeSettledBets  => ['boolean', 0],
                        includeBspBets      => ['boolean', 1],
                        netOfCommission     => ['boolean', 0],
                        exchangeId          => ['exchangeId', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    # handle mis-capitalization of marketID expected by betfair
    $args->{marketID} = $args->{marketId};
    delete $args->{marketId};
    if ($self->_doRequest('getMarketProfitAndLoss', $args)) {
        my $response = $self->{response}->{'soap:Body'}->{'n:getMarketProfitAndLossResponse'}->{'n:Result'};
        my $profitAndLoss = {
            annotations         => [],
            commissionApplied   => $response->{commissionApplied}->{content},
            currencyCode        => $response->{currencyCode}->{content},
            includesSettledBets => $response->{includesSettledBets}->{content},
            includesBspBets     => $response->{includesBspBets}->{content},
            marketId            => $response->{marketId}->{content},
            marketName          => $response->{marketName}->{content},
            marketStatus        => $response->{marketStatus}->{content},
            unit                => $response->{unit}->{content},
        };
        if (exists $response->{annotations}->{'n2:ProfitAndLoss'}) {
            my $oddsAnnotations = $self->_forceArray($response->{annotations}->{'n2:ProfitAndLoss'});
            foreach (@$oddsAnnotations) {
                push @{$profitAndLoss->{annotations}}, {
                    ifWin           => $_->{ifWin}->{content},
                    selectionId     => $_->{selectionId}->{content},
                    selectionName   => $_->{selectionName}->{content},
                    ifLoss          => $_->{ifLoss}->{content},
                    to              => $_->{to}->{content},
                    from            => $_->{from}->{content},
                };
            }
        }
        return $profitAndLoss; 
    }
    return 0;
}


=head2 getMarketTradedVolume

Returns an arrayref of hashrefs containing the traded volume for a particular market and selection. See L<getMarketTradedVolume|http://bdp.betfair.com/docs/GetMarketTradedVolume.html> for details. Requires:

=over

=item *

marketId : integer representing the betfair market id to return the market traded volume for.

=item *

selectionId : integer representing the betfair selection id of the selection to return matched volume for.

=item *

asianLineId : integer representing the betfair asian line id - this is optional unless the request is for an asian line market.

=item *

currencyCode : string representing the three letter ISO currency code. Only certain currencies are accepted by betfair GBP, USD, EUR, NOK, SGD, SEK, AUD, CAD, HKD, DKK (optional)

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $marketVolume = $betfair->getMarketTradedVolume({marketId    => 923456791,
                                                        selectionId => 30571,
                                                        exchangeId  => 2,
                                                       });

=cut

sub getMarketTradedVolume {
    my ($self, $args) = @_;
    my $checkParams = { marketId    => ['int', 1], 
                        asianLineId => ['int', 0],
                        selectionId => ['int', 1],
                        currencyCode=> ['currencyCode', 0],
                        exchangeId  => ['exchangeId', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getMarketTradedVolume', $args)) {
        my $response = $self->_forceArray(
                $self->{response}->{'soap:Body'}->{'n:getMarketTradedVolumeResponse'}->{'n:Result'}->{'priceItems'}->{'n2:VolumeInfo'});
        my $tradedVolume = [];
        foreach (@{$response}) {
            push @{$tradedVolume}, {
                odds                            => $_->{odds}->{content},
                totalMatchedAmount              => $_->{totalMatchedAmount}->{content},
                totalBspBackMatchedAmount       => $_->{totalBspBackMatchedAmount}->{content},
                totalBspLiabilityMatchedAmount  => $_->{totalBspLiabilityMatchedAmount}->{content},
            };
        }
        return $tradedVolume; 
    }
    return 0;
}


=head2 getMarketTradedVolumeCompressed

Returns an arrayref of selections with their total matched amounts plus an array of all traded volume with the trade size and amount. See L<getMarketTradedVolumeCompressed|http://bdp.betfair.com/docs/GetMarketTradedVolumeCompressed.html> for details. Note that this service de-serializes the compressed string return by betfair into a Perl data structure. Requires:

=over

=item *

marketId : integer representing the betfair market id to return the market traded volume for.

=item *

currencyCode : string representing the three letter ISO currency code. Only certain currencies are accepted by betfair GBP, USD, EUR, NOK, SGD, SEK, AUD, CAD, HKD, DKK (optional)

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $marketVolume = $betfair->getMarketTradedVolumeCompressed({  marketId    => 923456791,
                                                                    exchangeId  => 2,
                                                                 });

=cut

sub getMarketTradedVolumeCompressed {
    my ($self, $args) = @_;
    my $checkParams = { 
        marketId => ['int', 1],
        currencyCode    => ['currencyCode', 0],
        exchangeId      => ['exchangeId', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getMarketTradedVolumeCompressed', $args)) {
        my $response = $self->{response}->{'soap:Body'}->{'n:getMarketTradedVolumeCompressedResponse'}->{'n:Result'}->{'tradedVolume'}->{content};
        my $marketTradedVolume = { marketId => $args->{marketId} }; 
        foreach my $selection (split /:/, $response) {
            my @selectionFields = split /\|/, $selection;
            next unless defined $selectionFields[0];
            my @selectionData = split /~/, shift @selectionFields;
            my $tradedAmounts = [];
            foreach (@selectionFields) {
                my ($odds, $size) = split /~/, $_;
                push @{$tradedAmounts}, {
                    odds => $odds,
                    size => $size,
                };
            }

            push @{$marketTradedVolume->{selections}}, {
                selectionId                 => $selectionData[0],
                asianLineId                 => $selectionData[1],
                actualBSP                   => $selectionData[2],
                totalBSPBackMatched         => $selectionData[3],
                totalBSPLiabilityMatched    => $selectionData[4],
                tradedAmounts               => $tradedAmounts,
            } if (defined $selectionData[0]);
        }
        return $marketTradedVolume; 
    }
    return 0;
}

=head2 getPrivateMarkets

Returns an arrayref of private markets - see L<getPrivateMarkets|http://bdp.betfair.com/docs/GetPrivateMarket.html> for details. Requires a hashref with the following arguments:

=over

=item *

eventTypeId : integer representing the betfair id of the event type to return private markets for.

=item *

marketType : string of the betfair marketType enum see L<marketTypeEnum|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1020360i1020360>.

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $privateMarkets = $betfair->getPrivateMarkets({  eventTypeId => 1,
                                                        marketType  => 'O',
                                                        exchangeId  => 1,
                                                    });

=cut

sub getPrivateMarkets {
    my ($self, $args) = @_;
    my $checkParams = { eventTypeId => ['int', 1],
                        marketType  => ['marketTypeEnum', 1],
                        exchangeId  => ['exchangeId', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getPrivateMarkets', $args)) {
        my $response = $self->_forceArray(
            $self->{response}->{'soap:Body'}->{'n:getPrivateMarketsResponse'}->{'n:Result'}->{'privateMarkets'}->{'n2:PrivateMarket'});
        my @privateMarkets;
        foreach (@{$response}) {
            push(@privateMarkets, {
                        name            => $_->{name}->{content},
                        marketId        => $_->{marketId}->{content},
                        menuPath        => $_->{menuPath}->{content},
                        eventHierarchy  => $_->{eventHierarchy}->{content},
                    });
        }
        return \@privateMarkets;
    }
    return 0;
}

=head2 getSilks

This method is not available on the free betfair API.

Returns an arrayref of market racing silks data or 0 on failure. See L<getSilksV2|http://bdp.betfair.com/docs/GetSilks.html> for details. Requires the following parameters:

=over

=item *

markets : an arrayref of integers representing betfair market ids

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $silks = $betfair->getSilksV2({  markets     => [123456,9273649],
                                        exchangeId  => 1, 
                                     });

=cut

sub getSilks {
    my ($self, $args) = @_;
    my $checkParams = {
        markets     => ['arrayInt', 1],
        exchangeId  => ['exchangeId', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    # adjust args into betfair api required structure
    my $params = {  markets     => { int => $args->{markets} },
                    exchangeId  => $args->{exchangeId},
    };
    if ($self->_doRequest('getSilks', $params)) {
        my $silks = [];
        my $response = $self->_forceArray(
            $self->{response}->{'soap:Body'}->{'n:getSilksResponse'}->{'n:Result'}->{'marketDisplayDetails'}->{'n2:MarketDisplayDetail'});
        foreach (@$response) {
            my $market = $_->{marketId}->{content};
            next unless $market;
            my $runners = $self->_forceArray($_->{racingSilks}->{'n2:RacingSilk'}); 
            my @racingSilks;
            foreach (@$runners) {
                    push(@racingSilks, {
                        selectionId      => $_->{selectionId}->{content},
                        silksURL         => 'http://content-cache.betfair.com/feeds_images/Horses/SilkColours/' . $_->{silksURL}->{content},
                        silksText        => $_->{silksText}->{content},
                        trainerName      => $_->{trainerName}->{content},
                        ageWeight        => $_->{ageWeight}->{content},
                        form             => $_->{form}->{content},
                        daysSinceLastRun => $_->{daysSince}->{content},
                        jockeyClaim      => $_->{jockeyClaim}->{content},
                        wearing          => $_->{wearing}->{content},
                        saddleClothNumber=> $_->{saddleCloth}->{content},
                        stallDraw        => $_->{stallDraw}->{content},
                    });
            }
            push(@$silks, {
                        marketId    => $market,
                        runners     => \@racingSilks,
            });
        }
        return $silks;
    } 
    return 0; 
}

=head2 getSilksV2

This method is not available on the free betfair API.

Returns an arrayref of market racing silks data or 0 on failure. See L<getSilksV2|http://bdp.betfair.com/docs/GetSilks.html> for details. Requires the following parameters:

=over

=item *

markets : an arrayref of integers representing betfair market ids

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $silks = $betfair->getSilksV2({  markets     => [123456,9273649],
                                        exchangeId  => 1, 
                                     });

=cut

sub getSilksV2 {
    my ($self, $args) = @_;
    my $checkParams = {
        markets     => ['arrayInt', 1],
        exchangeId  => ['exchangeId', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    # adjust args into betfair api required structure
    my $params = {  markets     => { int => $args->{markets} },
                    exchangeId  => $args->{exchangeId},
    };
    if ($self->_doRequest('getSilksV2', $params)) {
        my $silks = [];
        my $response = $self->_forceArray(
            $self->{response}->{'soap:Body'}->{'n:getSilksV2Response'}->{'n:Result'}->{'marketDisplayDetails'}->{'n2:MarketDisplayDetail'});
        foreach (@$response) {
            my $market = $_->{marketId}->{content};
            next unless $market;
            my $runners = $self->_forceArray($_->{racingSilks}->{'n2:RacingSilk'}); 
            my @racingSilks;
            foreach (@$runners) {
                    push(@racingSilks, {
                        selectionId             => $_->{selectionId}->{content},
                        silksURL                => 'http://content-cache.betfair.com/feeds_images/Horses/SilkColours/' . $_->{silksURL}->{content},
                        silksText               => $_->{silksText}->{content},
                        trainerName             => $_->{trainerName}->{content},
                        ageWeight               => $_->{ageWeight}->{content},
                        form                    => $_->{form}->{content},
                        daysSinceLastRun        => $_->{daysSince}->{content},
                        jockeyClaim             => $_->{jockeyClaim}->{content},
                        wearing                 => $_->{wearing}->{content},
                        saddleClothNumber       => $_->{saddleCloth}->{content},
                        stallDraw               => $_->{stallDraw}->{content},
                        ownerName               => $_->{ownerName}->{content},
                        jockeyName              => $_->{jockeyName}->{content},
                        colour                  => $_->{colour}->{content},
                        sex                     => $_->{sex}->{content},
                        forecastPriceNumerator  => $_->{forecastPriceNumerator}->{content},
                        forecastPriceDenominator=> $_->{forecastPriceDenominator}->{content},
                        officialRating          => $_->{officialRating}->{content},
                        sire                    => {name    => $_->{sire}->{name}->{content},
                                                    bred    => $_->{sire}->{bred}->{content},
                                                    yearBorn=> $_->{sire}->{yearBorn}->{content},
                                                   },
                        dam                     => {name    => $_->{dam}->{name}->{content},
                                                    bred    => $_->{dam}->{bred}->{content},
                                                    yearBorn=> $_->{dam}->{yearBorn}->{content},
                                                   },
                        damSire                 => {name    => $_->{damSire}->{name}->{content},
                                                    bred    => $_->{damSire}->{bred}->{content},
                                                    yearBorn=> $_->{damSire}->{yearBorn}->{content},
                                                   },
                    });
            }
            push(@$silks, {
                        marketId    => $market,
                        runners     => \@racingSilks,
            });
        }
        return $silks;
    } 
    return 0; 
}

=head1 BET PLACEMENT API METHODS

=head2 cancelBets

Cancels up to 40 unmatched and active bets on betfair. Returns an arrayref of hashes of cancelled bets. See L<cancelBets|http://bdp.betfair.com/docs/CancelBets.html> for details. Requires a hashref with the following parameters:

=over

=item *

betIds : an arrayref of integers of betIds that should be cancelled, up to 40 betIds are permitted by betfair.

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $cancelledBetsResults = $betfair->cancelBets({betIds     => [123456789, 987654321]
                                                     exchangeId => 2,   
                                                    });

=cut

sub cancelBets {
    my ($self, $args) = @_;
    my $checkParams = {
        betIds      => ['arrayInt', 1],
        exchangeId  => ['exchangeId', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    # adjust args into betfair api required structure
    my $params = { bets       => { CancelBets => {betId => $args->{betIds}} },
                   exchangeId => $args->{exchangeID},
    };
    my $cancelled_bets = [];
    if ($self->_doRequest('cancelBets', $params)) {
        my $response = $self->_forceArray( 
            $self->{response}->{'soap:Body'}->{'n:cancelBetsResponse'}->{'n:Result'}->{'betResults'}->{'n2:CancelBetsResult'});
        foreach (@{$response} ) {
            $cancelled_bets = _add_cancelled_bet($cancelled_bets, $_);
        }
        return $cancelled_bets;
    } 
    return 0;
    sub _add_cancelled_bet {
        my ($cancelled_bets, $bet_to_be_added) = @_;
        push(@$cancelled_bets, {
            success           => $bet_to_be_added->{'success'}->{content},
            result_code       => $bet_to_be_added->{'resultCode'}->{content},
            size_matched      => $bet_to_be_added->{'sizeMatched'}->{content},
            size_cancelled    => $bet_to_be_added->{'sizeCancelled'}->{content},
            bet_id            => $bet_to_be_added->{'betId'}->{content},
        });
        return $cancelled_bets;
    }
}

=head2 cancelBetsByMarket

Receives an arrayref of marketIds and cancels all unmatched bets on those markets. Returns an arrayref of hashrefs of market ids and results. See L<cancelBetsByMarket|http://bdp.betfair.com/docs/CancelBetsByMarket.html> for details. Requires a hashref with the following parameters:

=over

=item *

markets : arrayref of integers representing market ids.

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $cancelledBets = $betfair->cancelBetsByMarket({markets       => [123456789, 432596611],
                                                      exchangeId    => 1,
                                                     });

=cut

sub cancelBetsByMarket {
    my ($self, $args) = @_;
    my $checkParams = {
        markets     => ['arrayInt', 1],
        exchangeId  => ['exchangeId', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    # adjust args into betfair api required structure
    my $params = {  markets     => { int => $args->{markets} },
                    exchangeId  => $args->{exchangeId},
    };
    my $cancelled_bets = [];
    if ($self->_doRequest('cancelBetsByMarket', $params)) {
        my $response = $self->_forceArray( 
            $self->{response}->{'soap:Body'}->{'n:cancelBetsByMarketResponse'}->{'n:Result'}->{results}->{'n2:CancelBetsByMarketResult'});
        foreach (@{$response} ) {
            push(@$cancelled_bets, {
                marketId    => $_->{'marketId'}->{content},
                resultCode  => $_->{'resultCode'}->{content},
            });
        }
        return $cancelled_bets;
    } 
    return 0;
}


=head2 placeBets

Places up to 60 bets on betfair and returns an array of results or zero on failure. See L<placeBetshttp://bdp.betfair.com/docs/PlaceBets.html> for details. Requires:

=over

=item *

bets : an arrayref of hashes of bets. Up to 60 hashes are permitted by betfair. Every bet hash should contain:

=over 8

=item *

asianLineId : integer of the ID of the asian handicap market, usually 0 unless betting on an asian handicap market

=item *

betCategoryType : a string of the betCategoryTypeEnum, usually 'E' for exchange, see L<http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#d83e452> for details.

=item *

betPersistenceType : a string of the betPersistenceTypeEnum, usually 'NONE' for standard exchange bets. See L<http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#d83e531> for details.

=item *

betType : a string of the betTypeEnum. Either 'B' to back or 'L' to lay.

=item *

bspLiability : a number of the maximum amount to risk for a bsp bet. For a back / lay bet this is equivalent to the whole stake amount.

=item *

marketId : integer of the marketId for which the bet should be placed.

=item *

price : number of the decimal odds for the bet.

=item *

selectionId : integer of the betfair id of the runner (selection option) that the bet should be placed on.

=item *

size : number for the stake amount for this bet.

=back

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    $myBetPlacedResults = $betfair->placeBets({
                                        bets        => [{   asianLineId         => 0,
                                                            betCategoryType     => 'E',
                                                            betPersistenceType  => 'NONE',
                                                            betType             => 'B',
                                                            bspLiability        => 2,
                                                            marketId            => 123456789,
                                                            price               => 5,
                                                            selectionId         => 99,
                                                            size                => 10,
                                                        }],
                                         exchangeId => 1,
                                    });

=cut

sub placeBets {
    my ($self, $args) = @_;
    # handle exchange id separately
    if (exists $args->{exchangeId}) {
        return 0 unless $self->_checkParams({exchangeId => ['exchangeId', 1]}, {exchangeId => $args->{exchangeId}});
    }
    else {
        return 0;
    }
    my $checkParams = { 
        asianLineId         => ['int', 1],
        betCategoryType     => ['betCategoryTypeEnum', 1],
        betPersistenceType  => ['betPersistenceTypeEnum', 1],
        betType             => ['betTypeEnum', 1],
        bspLiability        => ['int', 1],
        marketId            => ['int', 1],
        price               => ['decimal', 1],
        selectionId         => ['int', 1],
        size                => ['decimal', 1],
    };
    foreach (@{$args->{bets}}) {
        return 0 unless $self->_checkParams($checkParams, $_);
    }
    # adjust args into betfair api required structure
    my $params = {  bets        => { PlaceBets =>  $args->{bets} },
                    exchangeId  => $args->{exchangeId},
    };
    if ($self->_doRequest('placeBets', $params)) {
        my $response = $self->_forceArray($self->{response}->{'soap:Body'}->{'n:placeBetsResponse'}->{'n:Result'}->{'betResults'}->{'n2:PlaceBetsResult'});
        my $placed_bets = [];
        foreach (@{$response}) {
            push @{$placed_bets}, {
            success             => $_->{'success'}->{content},
            result_code         => $_->{'resultCode'}->{content},
            bet_id              => $_->{'betId'}->{content},
            size_matched        => $_->{'sizeMatched'}->{content},
            avg_price_matched   => $_->{'averagePriceMatched'}->{content}
            };
        }
        return $placed_bets;
    } 
    return 0;
}

=head2 updateBets

Updates existing unmatched bets on betfair: the size, price and persistence can be updated. Note that only the size or the price can be updated in one request, if both parameters are provided betfair ignores the new size value. Returns an arrayref of hashes of updated bet results. See L<http://bdp.betfair.com/docs/UpdateBets.html> for details. Requires:

=over

=item *

bets : an arrayref of hashes of bets to be updated. Each hash represents one bet and must contain the following key / value pairs:

=over 8

=item *

betId : integer of the betId to be updated

=item *

newBetPersistenceType : string of the betfair betPersistenceTypeEnum to be updated to see L<http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#d83e531> for more details.

=item *

newPrice : number for the new price of the bet

=item *

newSize : number for the new size of the bet

=item *

oldBetPersistenceType : string of the current bet's betfair betPersistenceTypeEnum see L<http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#d83e531> for more details.

=item *

oldPrice : number for the old price of the bet

=item *

oldSize : number for the old size of the bet

=back

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $updateBetDetails = $betfair->updateBets({
                                        bets        => [{betId                   => 12345,
                                                         newBetPersistenceType   => 'NONE',
                                                         newPrice                => 5,
                                                         newSize                 => 10,
                                                         oldBetPersistenceType   => 'NONE',
                                                         oldPrice                => 2,
                                                         oldSize                 => 10,
                                                        }],
                                        exchangeId  => 1,
                                    });


=cut

sub updateBets {
    my ($self, $args) = @_;
    # handle exchange id separately
    if (exists $args->{exchangeId}) {
        return 0 unless $self->_checkParams({exchangeId => ['exchangeId', 1]}, {exchangeId => $args->{exchangeId}});
    }
    else {
        return 0;
    }
    my $checkParams = { 
        betId                   => ['int', 1],
        newBetPersistenceType   => ['betPersistenceTypeEnum', 1],
        oldBetPersistenceType   => ['betPersistenceTypeEnum', 1],
        newSize                 => ['decimal', 1],
        oldSize                 => ['decimal', 1],
        newPrice                => ['decimal', 1],
        oldPrice                => ['decimal', 1],
    };
    foreach (@{$args->{bets}}) {
        return 0 unless $self->_checkParams($checkParams, $_);
    }
    my $params = {
        bets        => { UpdateBets => $args->{bets} },
        exchangeId  => $args->{exchangeId},
    };
    my $updated_bets = [];
    if ($self->_doRequest('updateBets', $params)) {
        my $response = $self->_forceArray($self->{response}->{'soap:Body'}->{'n:updateBetsResponse'}->{'n:Result'}->{'betResults'}->{'n2:UpdateBetsResult'});
        foreach (@{$response}) {
            push @{$updated_bets}, {
                success         => $_->{'success'}->{content},
                size_cancelled  => $_->{'sizeCancelled'}->{content},
                new_price       => $_->{'newPrice'}->{content},
                bet_id          => $_->{'betId'}->{content},
                new_bet_id      => $_->{'newBetId'}->{content},
                result_code     => $_->{content}->{content},
                new_size        => $_->{'newSize'}->{content},
            };
        }
        return $updated_bets;
    }
    return 0;
}


=head1 ACCOUNT MANAGEMENT API METHODS

=head2 addPaymentCard

Adds a payment card to your betfair account. Returns an arrayref of hashes of payment card responses or 0 on failure. See L<addPaymentCard|http://bdp.betfair.com/docs/AddPaymentCard.html>. Requires:

=over

=item *

cardNumber : string of the card number

=item *

cardType : string of a valid betfair cardTypeEnum (e.g. 'VISA'). See L<http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1028865i1028865>

=item *

cardStatus : string of a valid betfair paymentCardStatusEnum, either 'LOCKED' or 'UNLOCKED'

=item *

startDate : string of the card start date, optional depending on type of card

=item *

expiryDate : string of the card expiry date

=item *

issueNumber : string of the issue number or NULL if the cardType is not Solo or Switch

=item *

billingName : name of person on the billing account for the card

=item *

nickName : string of the card nickname must be less than 9 characters

=item *

password : string of the betfair account password

=item *

address1 : string of the first line of the address for the payment card

=item *

address2 : string of the second line of the address for the payment card

=item *

address3 : string of the third line of the address for the payment card (optional)

=item *

address4 : string of the fourth line of the address for the payment card (optional)

=item *

town : string of the town for the payment card

=item *

county : string of the county for the payment card

=item *

zipCode : string of the zip / postal code for the payment card

=item *

country : string of the country for the payment card

=back

Example

    my $addPaymentCardResponse = $betfair->addPaymentCard({
                                            cardNumber  => '1234123412341234',
                                            cardType    => 'VISA',
                                            cardStatus  => 'UNLOCKED',
                                            startDate   => '0113',
                                            expiryDate  => '0116',
                                            issueNumber => 'NULL',
                                            billingName => 'The Sillymoose',
                                            nickName    => 'democard',
                                            password    => 'password123',
                                            address1    => 'Tasty bush',
                                            address2    => 'Mountain Plains',
                                            town        => 'Hoofton',
                                            zipCode     => 'MO13FR',
                                            county      => 'Mooshire',
                                            country     => 'UK',
                                 });

=cut

sub addPaymentCard {
    my ($self, $args) = @_;
    my $checkParams = {
        cardNumber  => ['int', 1],
        cardType    => ['cardTypeEnum', 1],
        cardStatus  => ['cardStatusEnum', 1],
        startDate   => ['cardDate', 1],
        expiryDate  => ['cardDate', 1],
        issueNumber => ['int', 1],
        billingName => ['string', 1],
        nickName    => ['string9', 1],
        password    => ['password', 1],
        address1    => ['string', 1],
        address2    => ['string', 1],
        address3    => ['string', 0],
        address4    => ['string', 0],
        town        => ['string', 1],
        zipCode     => ['string', 1],
        county      => ['string', 1],
        country     => ['string', 1],

    };
    return 0 unless $self->_checkParams($checkParams, $args);
    $args->{exchangeId} = 3;
    if ($self->_doRequest('addPaymentCard', $args) ) {
        return  $self->_addPaymentCardLine([], $self->{response}->{'soap:Body'}->{'n:addPaymentCardResponse'}->{'n:Result'}->{'n2:PaymentCard'});
    }
    return 0;
}

=head2 deletePaymentCard

Deletes a registered payment card from your betfair account. See L<deletePaymentCard|http://bdp.betfair.com/docs/deletePaymentCard.html> for further details. Returns the betfair response as a hashref or 0 on failure. Requires:

=over

=item *

nickName : string of the card nickname to be deleted (must be less than 9 characters)

=item *

password : string of the betfair account password

=back

Example

    my $deleteCardResponse = $betfair->deletePaymentCard({
                                            nickName  => 'checking',
                                            password  => 'password123',
                                    });

=cut

sub deletePaymentCard {
    my ($self, $args) = @_;
    my $checkParams = {
         nickName   => ['string9', 1],
         password   => ['password', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    $args->{exchangeId} = 3;
    if ($self->_doRequest('deletePaymentCard', $args)) {
        my $response = $self->{response}->{'soap:Body'}->{'n:deletePaymentCardResponse'}->{'n:Result'};
        return  {
            nickName        => $response->{nickName}->{content},
            billingName     => $response->{billingName}->{content},
            cardShortNumber => $response->{cardShortNumber}->{content},
            cardType        => $response->{cardType}->{content},
            issuingCountry  => $response->{issuingCountry}->{content},
            expiryDate      => $response->{expiryDate}->{content},
        };
    }
    return 0;
}

=head2 depositFromPaymentCard

Deposits money in your betfair account using a payment card. See L<depositFromPaymentCard|http://bdp.betfair.com/docs/DepositFromPaymentCard.html> for further details. Returns the betfair response as a hashref or 0 on failure. Requires:

=over

=item *

amount : number which represents the amount of money to deposit

=item *

cardIdentifier : string of the nickname for the payment card

=item *

cv2 : string of the CV2 digits from the payment card (also known as the security digits)

=item *

password : string of the betfair account password

=back

Example

    my $depositResponse = $betfair->depositFromPaymentCard({
                                            amount          => 10,
                                            cardIdentifier  => 'checking',
                                            cv2             => '999',
                                            password        => 'password123',
                                    });

=cut

sub depositFromPaymentCard {
    my ($self, $args) = @_;
    my $checkParams = {
         amount         => ['decimal', 1],
         cardIdentifier => ['string9', 1],
         cv2            => ['cv2', 1],
         password       => ['password', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    $args->{exchangeId} = 3;
    if ($self->_doRequest('depositFromPaymentCard', $args)) {
        my $deposit_response = $self->{response}->{'soap:Body'}->{'n:depositFromPaymentCardResponse'}->{'n:Result'};
        return  {
            fee                 => $deposit_response->{'fee'}->{content},
            transactionId      => $deposit_response->{'transactionId'}->{content},
            minAmount          => $deposit_response->{'minAmount'}->{content},
            errorCode          => $deposit_response->{'errorCode'}->{content},
            minorErrorCode    => $deposit_response->{'minorErrorCode'}->{content},
            maxAmount          => $deposit_response->{'maxAmount'}->{content},
            netAmount          => $deposit_response->{'netAmount'}->{content},
        };
    }
    return 0;
}

=head2 forgotPassword

NB. This service is largely redundant as it requires an authenticated session to work, however it is included for the sake of completeness.

Resets the betfair account password via a 2 stage process. See L<forgotPassword|http://bdp.betfair.com/docs/forgotPassword.html> and the example below for details. Returns the betfair response as a hashref for stage 1, 1 on a successful passwprd reset or 0 on failure. Note that this service can be difficult to succeed with - user the getError method to inspect the response message from betfair. Requires:

=over

=item *

username : string of the betfair username for the account to reset the password for

=item *

emailAddress : string of the betfair account email address

=item *

countryOfResidence : string of the country of residence the betfair account is registered to

=item *

forgottenPasswordAnswer1 : string of the answer to question1 as returned by this service on the first request (optional)

=item *

forgottenPasswordAnswer2 : string of the answer to question2 as returned by this service on the first request (optional)

=item *

newPassword : string of the new account password (optional)

=item *

newPasswordRepeat : string of the new account password (optional)

=back

Example

    use Data::Dumper;

    my $securityQuestions = $betfair->forgotPassword({
                                            username            => 'sillymoose',
                                            emailAddress        => 'sillymoos@cpan.org',
                                            countryOfResidence  => 'United Kingdom',
                                    });
    print Dumper($securityQuestions);

    # now call service again with answers to security questions and new password parameters
    my $resetPasswordResponse =  $betfair->forgotPassword({
                                            username                    => 'sillymoose',
                                            emailAddress                => 'sillymoos@cpan.org',
                                            countryOfResidence          => 'United Kingdom',
                                            forgottenPasswordAnswer1    => 'dasher',
                                            forgottenPasswordAnswer2    => 'hoofs',
                                            newPassword                 => 'moojolicious',
                                            newPasswordRepeat           => 'moojolocious',
                                    });

=cut

sub forgotPassword {
    my ($self, $args) = @_;
    my $checkParams = {
        username                    => ['username', 1],
        emailAddress                => ['string', 1],
        countryOfResidence          => ['string',1],
        forgottenPasswordAnswer1    => ['string', 0],
        forgottenPasswordAnswer2    => ['string', 0],
        newPassword                 => ['password', 0],
        newPasswordRepeat           => ['password', 0],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    $args->{exchangeId} = 3;
    if ($self->_doRequest('forgotPassword', $args)) {
        my $response = $self->{response}->{'soap:Body'}->{'n:forgotPasswordResponse'}->{'n:Result'};
        return 1 if exists $args->{forgottenPasswordAnswer1};
        return  {
            question1   => $response->{'question1'}->{content},
            question2   => $response->{'question2'}->{content},
        };
    }
    return 0;
}

=head2 getAccountFunds

Returns a hashref of the account funds betfair response. See L<getAccountFunds|http://bdp.betfair.com/docs/GetAccountFunds.html> for details. Requires a hashref with the following parameters:

=over

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    my $funds = $betfair->getAccountFunds({exchangeId => 1});

=cut

sub getAccountFunds {
    my ($self, $args) = @_;
    my $checkParams = {
        exchangeId  => ['exchangeId', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    if ($self->_doRequest('getAccountFunds', $args)) {
        return {
            availBalance => $self->{response}->{'soap:Body'}->{'n:getAccountFundsResponse'}->{'n:Result'}->{'availBalance'}->{content},
            balance => $self->{response}->{'soap:Body'}->{'n:getAccountFundsResponse'}->{'n:Result'}->{'balance'}->{content},
            exposure => $self->{response}->{'soap:Body'}->{'n:getAccountFundsResponse'}->{'n:Result'}->{'exposure'}->{content},
            withdrawBalance => $self->{response}->{'soap:Body'}->{'n:getAccountFundsResponse'}->{'n:Result'}->{'withdrawBalance'}->{content}
        };
    } 
    return 0;
}

=head2 getAccountStatement

Returns an arrayref of hashes of account statement entries or 0 on failure. See L<getAccountStatement|http://bdp.betfair.com/docs/GetAccountStatement.html> for further details. Requires:

=over

=item *

startRecord : integer indicating the first record number to return. Record indexes are zero-based, hence 0 is the first record

=item *

recordCount : integer of the maximum number of records to return

=item *

startDate : date for which to return records on or after this date (a string in the XML datetime format see example)

=item *

endDate : date for which to return records on or before this date (a string in the XML datetime format see example)

=item *

itemsIncluded : string of the betfair AccountStatementIncludeEnum see L<AccountStatementIncludeEnum|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1028861i1028861> for details

=item *

exchangeId : integer representing the exchange id to connect to, either 1 (UK and rest of the world) or 2 (Australia)

=back

Example

    # return an account statement for all activity starting at record 1 up to 1000 records between 1st January 2013 and 16th June 2013
    my $statement = $betfair->getAccountStatement({
                                    startRecord     => 0,
                                    recordCount     => 1000,
                                    startDate       => '2013-01-01T00:00:00.000Z',         
                                    endDate         => '2013-06-16T00:00:00.000Z',         
                                    itemsIncluded   => 'ALL',
                                    exchangeId      => 2,
                              });

=cut

sub getAccountStatement {
    my ($self, $args) = @_; 
    my $checkParams = {
        startRecord     => ['int', 1],
        recordCount     => ['int', 1],
        startDate       => ['date', 1],         
        endDate         => ['date', 1],         
        itemsIncluded   => ['accountStatementIncludeEnum', 1],
        exchangeId      => ['exchangeId', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    my @account_statement;
    if ($self->_doRequest('getAccountStatement', 1, $args)) {
        my $response = 
            $self->_forceArray($self->{response}->{'soap:Body'}->{'n:getAccountStatementResponse'}->{'n:Result'}->{'items'}->{'n2:AccountStatementItem'});
        foreach (@{$response}) {
            push(@account_statement, {
                betType         => $_->{'betType'}->{content},
                transactionId   => $_->{'transactionId'}->{content},
                transactionType => $_->{'transactionType'}->{content},
                betSize         => $_->{'betSize'}->{content},            
                placedDate      => $_->{'placedDate'}->{content},
                betId           => $_->{'betId'}->{content},
                marketName      => $_->{'marketName'}->{content},
                grossBetAmount  => $_->{'grossBetAmount'}->{content},
                marketType      => $_->{'marketType'}->{content},
                eventId         => $_->{'eventId'}->{content},
                accountBalance  => $_->{'accountBalance'}->{content},
                eventTypeId     => $_->{'eventTypeId'}->{content},            
                betCategoryType => $_->{'betCategoryType'}->{content},
                selectionName   => $_->{'selectionName'}->{content},
                selectionId     => $_->{'selectionId'}->{content},
                commissionRate  => $_->{'commissionRate'}->{content},
                fullMarketName  => $_->{'fullMarketName'}->{content},
                settledDate     => $_->{'settledDate'}->{content},
                avgPrice        => $_->{'avgPrice'}->{content},
                startDate       => $_->{'startDate'}->{content},
                winLose         => $_->{'winLose'}->{content},
                amount          => $_->{'amount'}->{content}
            });
        }
        return \@account_statement;
    } 
    return 0;
}

=head2 getPaymentCard

Returns an arrayref of hashes of payment card or 0 on failure. See L<getPaymentCard|http://bdp.betfair.com/docs/GetPaymentCard.html> for details. Does not require any parameters.

Example

    my $cardDetails = $betfair->getPaymentCard;

=cut

sub getPaymentCard {
    my $self = shift;
    my $payment_cards = [];
    if ($self->_doRequest('getPaymentCard', {exchangeId => 3})) {
        my $response = $self->_forceArray(
                $self->{response}->{'soap:Body'}->{'n:getPaymentCardResponse'}->{'n:Result'}->{'paymentCardItems'}->{'n2:PaymentCard'});
        foreach (@{$response}) {
            $payment_cards = $self->_addPaymentCardLine($payment_cards, $_);
        }
        return $payment_cards;
    }
    return 0;
}

=head2 getSubscriptionInfo

This service is not available with the free betfair API.

Returns an arrayref of hashes of subscription or 0 on failure. See L<getSubscriptionInfo|http://bdp.betfair.com/docs/GetSubscriptionInfo.html> for details. Does not require any parameters.

Example

    my $subscriptionData = $betfair->getSubscriptionInfo;

=cut

sub getSubscriptionInfo {
    my ($self, $args) = @_;
    $args->{exchangeId} = 3;
    if ($self->_doRequest('getSubscriptionInfo', $args) ) {
        my $response = $self->{response}->{'soap:Body'}->{'n:getSubscriptionInfoResponse'}->{'n:Result'}->{subscriptions}->{'n2:Subscription'};
        my $subscriptionInfo = {
            billingAmount       => $response->{billingAmount}->{content},
            billingDate         => $response->{billingDate}->{content},
            billingPeriod       => $response->{billingPeriod}->{content},
            productId           => $response->{productId}->{content},
            productName         => $response->{productName}->{content},
            subscribedDate      => $response->{subscribedDate}->{content},
            status              => $response->{status}->{content},
            vatEnabled          => $response->{vatEnabled}->{content},
            setupCharge         => $response->{setupCharge}->{content},
            setupChargeActive   => $response->{setupChargeActive}->{content},
            services            => [],
        };
        foreach (@{$response->{services}->{'n2:ServiceCall'}}) {
            push @{$subscriptionInfo->{services}}, {
                        maxUsages   => $_->{maxUsages}->{content},
                        period      => $_->{period}->{content},
                        periodExpiry=> $_->{periodExpiry}->{content},
                        serviceType => $_->{serviceType}->{content},
                        usageCount  => $_->{usageCount}->{content},
            };
        }
        return $subscriptionInfo;
    }
    return 0;
}

=head2 modifyPassword

Changes the betfair account password. See L<modifyPassword|http://bdp.betfair.com/docs/modifyPassword.html> for details. Returns the betfair response as a hashref or 0 on failure. Requires:

=over

=item *

password : string of the current account password

=item *

newPassword : string of the new account password

=item *

newPasswordRepeat : string of the new account password

=back

Example

    my $response = $betfair->modifyPassword({
                                        password            => 'itsasecret',
                                        newPassword         => 'moojolicious',
                                        newPasswordRepeat   => 'moojolicious',
                                    });

=cut

sub modifyPassword {
    my ($self, $args) = @_;
    my $checkParams = {
        password                    => ['password', 1],
        newPassword                 => ['password', 1],
        newPasswordRepeat           => ['password', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    $args->{exchangeId} = 3;
    if ($self->_doRequest('modifyPassword', $args)) {
        return 1;
    }
    return 0;
}

=head2 modifyProfile

Modifies the account profile details of the betfair account. See L<modifyProfile|http://bdp.betfair.com/docs/ModifyProfile.html> for details. Returns 1 on success or 0 on failure. Requires a hashref with the following parameters:

=over

=item *

password : string of the password for the betfair account

=item *

address1 : string of address line 1 (optional)

=item *

address2 : string of address line 2 (optional)

=item *

address3 : string of address line 3 (optional)

=item *

townCity : string of the town/city (optional)

=item *

countyState : string of the county or state - note for Australian accounts this must be a valid state (optional)

=item *

postCode : string of the postcode (aka zipcode). (optional)

=item *

countryOfResidence : string of the country of residence (optional)

=item *

homeTelephone : string of the home telephone number (optional)

=item *

workTelephone : string of the work telephone number (optional)

=item *

mobileTelephone : string of the mobile telephone number (optional)

=item *

emailAddress : string of the email address (optional)

=item *

timeZone : string of the timezone (optional)

=item *

depositLimit : integer of the deposite limit to set (optional)

=item *

depositLimitFrequency : string of the betfair GamcareLimitFreq enumerated type. See L<gamcareLimitFreqEnum|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1028855i1028855> for details (optional)

=item *

lossLimit : integer of the Gamcare loss limit for the account (optional)

=item *

lossLimitFrequency : string of the betfair GamcareLimitFreq enumerated type. See L<gamcareLimitFreqEnum|http://bdp.betfair.com/docs/BetfairSimpleDataTypes.html#i1028855i1028855> for details (optional)

=item *

nationalIdentifier : string of the national identifier (optional)

=back

Example

    # update mobile number
    my $response = $betfair->modifyProfile({
                                    password        => 'itsasecret',
                                    mobileTelephone => '07777777777',
                                });

=cut


sub modifyProfile {
    my ($self, $args) = @_;
    my $checkParams = {
        password                => ['password', 1],
        address1                => ['string', 0],
        address2                => ['string', 0],
        address3                => ['string', 0],
        townCity                => ['string', 0],
        countyState             => ['string', 0],
        postCode                => ['string', 0],
        countryOfResidence      => ['string', 0],
        homeTelephone           => ['string', 0],
        workTelephone           => ['string', 0],
        mobileTelephone         => ['string', 0],
        emailAddress            => ['string', 0],
        timeZone                => ['string', 0],
        depositLimit            => ['int', 0],
        depositLimitFrequency   => ['gamcareLimitFreqEnum', 0],
        lossLimit               => ['int', 0],
        lossLimitFrequency      => ['gamcareLimitFreqEnum', 0],
        nationalIdentifier      => ['string', 0],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    $args->{exchangeId} = 3;
    if ($self->_doRequest('modifyProfile', $args)) {
        return 1;
    }
    return 0;
}

=head2 retrieveLIMBMessage

This service is not available with the betfair free API.

Returns a hashref of the betfair response. See L<retrieveLIMBMessage|http://bdp.betfair.com/docs/RetrieveLIMBMessage.html> for details. No parameters are required.

Example

    my $limbMsg = $betfair->retrieveLimbMessage;

=cut

sub retrieveLIMBMessage {
    my $self = shift;
    if ($self->_doRequest('retrieveLIMBMessage', {exchangeId => 3})) {
        my $response = $self->{response}->{'soap:Body'}->{'n:retrieveLIMBMessageResponse'}->{'n:Result'};
        my $limbMsg = {
              totalMessageCount                     => $response->{totalMessageCount}->{content},
              
              retrievePersonalMessage               => {
                  message       => $response->{retrievePersonalMessage}->{message}->{content},                           
                  messageId     => $response->{retrievePersonalMessage}->{messageId}->{content},                           
                  enforceDate   => $response->{retrievePersonalMessage}->{enforceDate}->{content},                           
                  indicator     => $response->{retrievePersonalMessage}->{indicator}->{content},
              },

              retrieveTCPrivacyPolicyChangeMessage  => {
                  reasonForChange   => $response->{retrieveTCPrivacyPolicyChangeMessage}->{reasonForChange}->{content},                           
                  messageId         => $response->{retrieveTCPrivacyPolicyChangeMessage}->{messageId}->{content},                           
                  enforceDate       => $response->{retrieveTCPrivacyPolicyChangeMessage}->{enforceDate}->{content},                           
                  indicator         => $response->{retrieveTCPrivacyPolicyChangeMessage}->{indicator}->{content},
              },
              retrievePasswordChangeMessage         => {
                  messageId         => $response->{retrievePasswordChangeMessage}->{messageId}->{content},                           
                  enforceDate       => $response->{retrievePasswordChangeMessage}->{enforceDate}->{content},                           
                  indicator         => $response->{retrievePasswordChangeMessage}->{indicator}->{content},
              },
              retrieveBirthDateCheckMessage         => {
                  messageId         => $response->{retrieveBirthDateCheckMessage}->{messageId}->{content},                           
                  enforceDate       => $response->{retrieveBirthDateCheckMessage}->{enforceDate}->{content},                           
                  indicator         => $response->{retrieveBirthDateCheckMessage}->{indicator}->{content},
                  birthDate         => $response->{retrieveBirthDateCheckMessage}->{birthDate}->{content},
              },
              retrieveAddressCheckMessage           => {
                  messageId         => $response->{retrieveAddressCheckMessage}->{messageId}->{content},                           
                  enforceDate       => $response->{retrieveAddressCheckMessage}->{enforceDate}->{content},                           
                  indicator         => $response->{retrieveAddressCheckMessage}->{indicator}->{content},
                  address1          => $response->{retrieveAddressCheckMessage}->{address1}->{content},
                  address2          => $response->{retrieveAddressCheckMessage}->{address2}->{content},
                  address3          => $response->{retrieveAddressCheckMessage}->{address3}->{content},
                  town              => $response->{retrieveAddressCheckMessage}->{town}->{content},
                  county            => $response->{retrieveAddressCheckMessage}->{county}->{content},
                  zipcode           => $response->{retrieveAddressCheckMessage}->{zipcode}->{content},
                  country           => $response->{retrieveAddressCheckMessage}->{country}->{content},
              },
              retrieveContactDetailsCheckMessage    => {
                  messageId         => $response->{retrieveContactDetailsCheckMessage}->{messageId}->{content},                           
                  enforceDate       => $response->{retrieveContactDetailsCheckMessage}->{enforceDate}->{content},                           
                  indicator         => $response->{retrieveContactDetailsCheckMessage}->{indicator}->{content},
                  homeTelephone     => $response->{retrieveContactDetailsCheckMessage}->{homeTelephone}->{content},
                  workTelephone     => $response->{retrieveContactDetailsCheckMessage}->{workTelephone}->{content},
                  mobileTelephone   => $response->{retrieveContactDetailsCheckMessage}->{mobileTelephone}->{content},
                  emailAddress      => $response->{retrieveContactDetailsCheckMessage}->{emailAddress}->{content},
              },
              retrieveChatNameChangeMessage    => {
                  messageId         => $response->{retrieveChatNameChangeMessage}->{messageId}->{content},                           
                  enforceDate       => $response->{retrieveChatNameChangeMessage}->{enforceDate}->{content},                           
                  indicator         => $response->{retrieveChatNameChangeMessage}->{indicator}->{content},
                  chatName          => $response->{retrieveChatNameChangeMessage}->{chatName}->{content},
              },
        };
        my $billingAddressItems = $self->_forceArray(
            $response->{retrieveCardBillingAddressCheckItems}->{'n2:retrieveCarBillingAddressCheckLIMBMessage'});
        foreach (@{$billingAddressItems}) {
            push @{$limbMsg->{retrieveCardBillingAddressCheckItems}}, {
                        messageId       => $_->{messageId}->{content},
                        enforceDate     => $_->{enforceDate}->{content},
                        indicator       => $_->{indicator}->{content},
                        nickName        => $_->{nickName}->{content},
                        cardShortNumber => $_->{cardShortNumber}->{content},
                        address1        => $_->{address1}->{content},
                        address2        => $_->{address2}->{content},
                        address3        => $_->{address3}->{content},
                        town            => $_->{town}->{content},
                        county          => $_->{county}->{content},
                        zipcode         => $_->{zipcode}->{content},
                        country         => $_->{country}->{content},
             };
        }
        return $limbMsg;
    }
    return 0;
}

=head2 selfExclude

WARNING - using this method will deactivate your betfair account for a minimum of 6 months. See L<selfExclude|http://bdp.betfair.com/docs/SelfExclude.html> for details. Returns 1 on success or 0 on failure. Requires the following parameters in a hashref:

=over

=item *

selfExclude : string boolean response (should be 'true' to succeed)

=item *

password : string of the betfair account password

=back

Example

    $excludeResult = $betfair->selfExclude({
                                selfExclude => 'true',
                                password    => 'itsasecret',
                            });

=cut

sub selfExclude {
    my ($self, $args) = @_;
    my $checkParams = {
        password    => ['password', 1],
        selfExclude => ['boolean', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    $args->{exchangeId} = 3;
    if ($self->_doRequest('selfExclude', $args)) {
        return 1;
    }
    return 0;
}

=head2 setChatName

This service is not available with the free betfair API, nor with the paid personal betfair API.

Sets the chat name of the betfair account. See L<setChatName|http://bdp.betfair.com/docs/SetChatName.html> for details. Returns 1 on success or 0 on failure. Requires the following parameters in a hashref:

=over

=item *

chatName : string of the desired chatname

=item *

password : string of the betfair account password

=back

Example

    $excludeResult = $betfair->setChatName({
                                chatName => 'sillymoose',
                                password => 'itsasecret',
                            });

=cut

sub setChatName {
    my ($self, $args) = @_;
    my $checkParams = {
        password => ['password', 1],
        chatName => ['string', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    $args->{exchangeId} = 3;
    if ($self->_doRequest('setChatName', $args)) {
        return 1;
    }
    return 0;
}

=head2 submitLIMBMessage

This service is not available with the betfair free API.

Submits a LIMB message to the betfair API. See L<submitLIMBMessage|http://bdp.betfair.com/docs/SubmitLIMBMessage.html> for details. Returns 1 on success or 0 on failure. betfair returns additional validation error information on failure, so be sure to check the error message using the getError method. Requires a hashref with the following parameters:

=over

=item *

password : string of the betfair account password

=item *

submitPersonalMessage : a hashref containing the following key / pair values (optional):

=over 8

=item *

messageId : integer of the message Id

=item *

acknowledgement : string 'Y'

=back

=item *

submitTCPrivacyPolicyChangeMessage : a hashref containing the following key / value pairs (optional):

=over 8

=item *

messageId : integer of the message Id

=item *

tCPrivacyPolicyChangeAcceptance : string 'Y'

=back

=item *

submitPasswordChangeMessage : a hashref containing the following key / value pairs (optional):

=over 8

=item *

messageId : integer of the message Id

=item *

newPassword : string of the new password

=item *

newPasswordRepeat : string of the new password

=back

=item *

submitBirthDateCheckMessage : a hashref containing the following key / value pairs (optional):

=over 8

=item *

messageId : integer of the message Id

=item *

detailsCorrect : string of either 'Y' or 'N'

=item *

correctBirthDate : string of the correct birthdate - should be a valid XML datetime format

=back

=item *

submitAddressCheckMessage : a hashref containing the following key / value pairs (optional):

=over 8

=item *

messageId : integer of the message Id

=item *

detailsCorrect : string of either 'Y' or 'N'

=item *

newAddress1 : string of the first line of the address

=item *

newAddress2 : string of the second line of the address

=item *

newAddress3 : string of the third line of the address

=item *

newTown: string of the town of the address

=item *

newZipCode: string of the postal code of the address

=item *

newCountry: string of the the Country of the address

=back

submitContactDetailsCheckMessage: a hashref containing the following key / value pairs (optional):

=over 8

=item *

messageId : integer of the message Id

=item *

detailsCorrect : string of either 'Y' or 'N'

=item *

newHomeTelephone : string of the new home telephone number

=item *

newWorkTelephone : string of the new work telephone number

=item *

newMobileTelephone : string of the new mobile telephone number

=item *

newEmailAddress : string of the new email address

=back

=item *

submitChatNameChangeMessage : a hashref containing the following key / value pairs (optional):

=over 8

=item *

messageId : integer of the message Id

=item *

newChatName : string of the new chat name

=back

=item *

submitCardBillingAddressCheckItems : an arrayref of hashrefs containing the following key / value pairs (optional):

=over 8

=item *

messageId : integer of the message Id

=item *

detailsCorrect : string of either 'Y' or 'N'

=item *

nickName : string of the card nick name (8 characters or less)

=item *

newAddress1 : string of the first line of the address

=item *

newAddress2 : string of the second line of the address

=item *

newAddress3 : string of the third line of the address

=item *

newTown: string of the town of the address

=item *

newZipCode: string of the postal code of the address

=item *

newCountry: string of the the Country of the address

=back

=back

Example

    my $limbMsg = $betfair->submitLimbMessage({
                                        password                => 'itsasecret',
                                        submitPersonalMessage   => { messageId      => 123456789,
                                                                     acknowledgement=> 'Y',
                                                                   },
                                        });

=cut

sub submitLIMBMessage {
    my ($self, $args) = @_;
    my $checkParams = {
        password                            => ['password', 1],
        submitPersonalMessage               => ['hash', 0],
        submitTCPrivacyPolicyChangeMessage  => ['hash', 0],
        submitPasswordChangeMessage         => ['hash', 0],
        submitBirthDateCheckMessage         => ['hash', 0],
        submitAddressCheckMessage           => ['hash', 0],
        submitContactDetailsCheckMessage    => ['hash', 0],
        submitChatNameChangeMessage         => ['hash', 0],
        submitCardBillingAddressCheckItems  => ['hash', 0],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    $args->{exchangeId} = 3;
    if ($self->_doRequest('submitLIMBMessage', $args) ) {
        return 1;
    }
    # add any validation errors to the header error message so that user can retrieve the information using getError

    return 0 unless exists $self->{response}->{'soap:Body'}->{'n:submitLIMBMessageResponse'}->{'n:Result'}->{validationErrors};
    my $response = $self->_forceArray(
        $self->{response}->{'soap:Body'}->{'n:submitLIMBMessageResponse'}->{'n:Result'});
    my $validationErrors;
    foreach (@{$response}) {
            $validationErrors .= ' ' . $_->{content};
    }
    $self->{headerError} .= ' ' . $validationErrors;
    return 0;
}

=head2 transferFunds

Transfers funds between the UK and Australian wallets. See L<transferFunds|http://bdp.betfair.com/docs/TransferFunds.html> for details. Returns a hashref of the betfair response or 0 on failure. Requires the following parameters in a hashref:

=over

=item *

sourceWalletId : integer either: 1 for UK wallet or 2 for the Australian wallet

=item *

targetWalletId : integer either: 1 for UK wallet or 2 for the Australian wallet

=item *

amount : number representing the amount of money to transfer between wallets

=back

Example

    # transfer 15 from the UK wallet to the Australian wallet
    $excludeResult = $betfair->transferFunds({
                                sourceWalletId  => 1,
                                targetWalletId  => 2,
                                amount          => 15.0,
                            });

=cut

sub transferFunds {
    my ($self, $args) = @_;
    my $checkParams = {
        sourceWalletId  => ['int', 1],
        targetWalletId  => ['int', 1],
        amount          => ['decimal', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    $args->{exchangeId} = 3;
    if ($self->_doRequest('transferFunds', $args)) {
        my $response = $self->{response}->{'soap:Body'}->{'n:transferFundsResponse'}->{'n:Result'};
        return {
            monthlyDepositTotal => $response->{monthlyDepositTotal}->{content},
        };
    }
    return 0;
}

=head2 updatePaymentCard

Updates a payment card on your betfair account. Returns a hashref betfair response or 0 on failure. See L<updatePaymentCard|http://bdp.betfair.com/docs/UpdatePaymentCard.html>. Requires:

=over

=item *

cardStatus : string of a valid betfair paymentCardStatusEnum, either 'LOCKED' or 'UNLOCKED'

=item *

startDate : string of the card start date, optional depending on type of card

=item *

expiryDate : string of the card expiry date

=item *

issueNumber : string of the issue number or NULL if the cardType is not Solo or Switch

=item *

nickName : string of the card nickname must be less than 9 characters

=item *

password : string of the betfair account password

=item *

address1 : string of the first line of the address for the payment card

=item *

address2 : string of the second line of the address for the payment card

=item *

address3 : string of the third line of the address for the payment card (optional)

=item *

address4 : string of the fourth line of the address for the payment card (optional)

=item *

town : string of the town for the payment card

=item *

county : string of the county for the payment card

=item *

zipCode : string of the zip / postal code for the payment card

=item *

country : string of the country for the payment card

=back

Example

    my $updatePaymentCardResponse = $betfair->updatePaymentCard({
                                            cardStatus  => 'UNLOCKED',
                                            startDate   => '0113',
                                            expiryDate  => '0116',
                                            issueNumber => 'NULL',
                                            billingName => 'The Sillymoose',
                                            nickName    => 'democard',
                                            password    => 'password123',
                                            address1    => 'Tasty bush',
                                            address2    => 'Mountain Plains',
                                            town        => 'Hoofton',
                                            zipCode     => 'MO13FR',
                                            county      => 'Mooshire',
                                            country     => 'UK',
                                 });

=cut

sub updatePaymentCard {
    my ($self, $args) = @_;
    my $checkParams = {
        cardStatus  => ['cardStatusEnum', 1],
        startDate   => ['cardDate', 1],
        expiryDate  => ['cardDate', 1],
        issueNumber => ['int', 1],
        billingName => ['string', 1],
        nickName    => ['string9', 1],
        password    => ['password', 1],
        address1    => ['string', 1],
        address2    => ['string', 0],
        address3    => ['string', 0],
        address4    => ['string', 0],
        town        => ['string', 1],
        zipCode     => ['string', 1],
        county      => ['string', 1],
        country     => ['string', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    $args->{exchangeId} = 3;
    if ($self->_doRequest('updatePaymentCard', $args) ) {
        my $response = $self->{response}->{'soap:Body'}->{'n:updatePaymentCardResponse'}->{'n:Result'};
        return {
            nickName    => $response->{nickName}->{content},
            billingName => $response->{billingName}->{content},
            cardType    => $response->{cardType}->{content},
            expiryDate  => $response->{expiryDate}->{content},
            startDate   => $response->{startDate}->{content},
            address1    => $response->{address1}->{content},
            address2    => $response->{address2}->{content},
            address3    => $response->{address3}->{content},
            address4    => $response->{address4}->{content},
            zipCode     => $response->{zipCode}->{content},
            country     => $response->{country}->{content},
        };
    }
    return 0;
}

=head2 viewProfile

Returns a hashref betfair response or 0 on failure. See L<viewProfile|http://bdp.betfair.com/docs/ViewProfile.html>. Requires no parameters.

Example

    my $profile = $betfair->viewProfile;

=cut

sub viewProfile {
    my $self = shift;
    if ($self->_doRequest('viewProfile', {exchangeId => 3})) {
        my $response = $self->{response}->{'soap:Body'}->{'n:viewProfileResponse'}->{'n:Result'};
        return {
            title               => $response->{title}->{content},
            firstName           => $response->{firstName}->{content},
            surname             => $response->{surname}->{content},
            userName            => $response->{userName}->{content},
            forumName           => $response->{forumName}->{content},
            address1            => $response->{address1}->{content},
            address2            => $response->{address2}->{content},
            address3            => $response->{address3}->{content},
            townCity            => $response->{townCity}->{content},
            countyState         => $response->{countyState}->{content},
            postCode            => $response->{postCode}->{content},
            countryOfResidence  => $response->{countryOfResidence}->{content},
            homeTelephone       => $response->{homeTelephone}->{content},
            workTelephone       => $response->{workTelephone}->{content},
            mobileTelephone     => $response->{mobileTelephone}->{content},
            emailAddress        => $response->{emailAddress}->{content},
            timeZone            => $response->{timeZone}->{content},
            currency            => $response->{currency}->{content},
            gamecareLimit       => $response->{gamcareLimit}->{content},
            gamcareFrequency    => $response->{gamcareFrequency}->{content},
            gamecareLossLimit   => $response->{gamcareLossLimit}->{content},
            gamcareLossLimitFrequency=> $response->{gamcareLossLimitFrequency}->{content},
        };
    }
    return 0;
}

=head2 viewProfileV2

Returns a hashref betfair response or 0 on failure. See L<viewProfileV2|http://bdp.betfair.com/docs/ViewProfileV2.html>. Requires no parameters.

Example

    my $profile = $betfair->viewProfileV2;

=cut

sub viewProfileV2 {
    my $self = shift;
    if ($self->_doRequest('viewProfileV2', {requestVersion  => 'V1',
                                            exchangeId      => 3,
                                           })) {
        my $response = $self->{response}->{'soap:Body'}->{'n:viewProfileV2Response'}->{'n:Result'};
        return {
            title               => $response->{title}->{content},
            firstName           => $response->{firstName}->{content},
            surname             => $response->{surname}->{content},
            userName            => $response->{userName}->{content},
            forumName           => $response->{forumName}->{content},
            address1            => $response->{address1}->{content},
            address2            => $response->{address2}->{content},
            address3            => $response->{address3}->{content},
            townCity            => $response->{townCity}->{content},
            countyState         => $response->{countyState}->{content},
            postCode            => $response->{postCode}->{content},
            countryOfResidence  => $response->{countryOfResidence}->{content},
            homeTelephone       => $response->{homeTelephone}->{content},
            workTelephone       => $response->{workTelephone}->{content},
            mobileTelephone     => $response->{mobileTelephone}->{content},
            emailAddress        => $response->{emailAddress}->{content},
            timeZone            => $response->{timeZone}->{content},
            currency            => $response->{currency}->{content},
            gamecareLimit       => $response->{gamcareLimit}->{content},
            gamcareFrequency    => $response->{gamcareFrequency}->{content},
            gamecareLossLimit   => $response->{gamcareLossLimit}->{content},
            gamcareLossLimitFrequency=> $response->{gamcareLossLimitFrequency}->{content},
            tAN                 => $response->{tAN}->{content},
            referAndEarnCode    => $response->{referAndEarnCode}->{content},
            earthportId         => $response->{earthportId}->{content},
            kYCStatus           => $response->{kYCStatus}->{content},
            nationalIdentifier  => $response->{nationalIdentifier}->{content},
        };
    }
    return 0;
}

=head2 viewReferAndEarn

Returns a hashref containing the betfair account's refer and earn code or 0 on failure. See L<viewReferAndEarn|http://bdp.betfair.com/docs/ViewReferAndEarn.html> for details. Requires no parameters.

Example

    my $referAndEarnCode = $betfair->viewReferAndEarn;

=cut

sub viewReferAndEarn {
    my $self = shift;
    if ($self->_doRequest('viewReferAndEarn', {exchangeId => 3})) {
        my $response = $self->{response}->{'soap:Body'}->{'n:viewReferAndEarnResponse'}->{'n:Result'};
        return {
            referAndEarnCode => $response->{'referAndEarnCode'}->{content},
        };
    }
    return 0;
}

=head2 withdrawToPaymentCard

Withdraws money from your betfair account to the payment card specified. Returns a hashref of the withdraw response from betfair or 0 on failure. See L<withdrawToPaymentCard|http://bdp.betfair.com/docs/WithdrawToPaymentCard.html> for details. Requires:

=over

=item *

amount : number representing the amount of money to withdraw

=item *

cardIdentifier : string of the nickname of the payment card

=item *

password : string of your betfair password

=back

Example

    my $withdrawalResult = $betfair->withdrawToPaymentCard({
                                        amount          => 10,
                                        cardIdentifier  => 'checking',
                                        password        => 'password123',
                                    }); 

=cut

sub withdrawToPaymentCard {
    my ($self, $args) = @_; 
    my $checkParams = {
        amount          => ['decimal', 1],
        cardIdentifier  => ['string9', 1],
        password        => ['password', 1],
    };
    return 0 unless $self->_checkParams($checkParams, $args);
    $args->{exchangeId} = 3;
    if ($self->_doRequest('withdrawToPaymentCard', $args) ) {
        my $response = $self->{response}->{'soap:Body'}->{'n:withdrawToPaymentCardResponse'}->{'n:Result'};
        return {
            amountWithdrawn   => $response->{'amountWithdrawn'}->{content},
            maxAmount         => $response->{'maxAmount'}->{content}            
        };
    }
    return 0;
}

=head1 INTERNAL METHODS

=head2 _doRequest

Processes requests to and from the betfair API.

=cut

sub _doRequest {
    my ($self, $action, $params) = @_;

    # get the server url and remove the server id from $params
    my $server = $params->{exchangeId};
    my $uri = $self->_getServerURI($server);
    delete $params->{exchangeId};

    # clear data from previous request
    $self->_clearData;
  
    # add header to $params
    $params->{header}->{sessionToken} = $self->{sessionToken} if defined $self->{sessionToken}; 
    $params->{header}->{clientStamp} = 0;

    # build xml message
    $self->{xmlsent} = WWW::betfair::Template::populate($uri, $action, $params);

    # save response, session token and error as attributes
    my $uaResponse = WWW::betfair::Request::new_request($uri, $action, $self->{xmlsent});
    $self->{xmlreceived} = $uaResponse->decoded_content(charset => 'none');
    $self->{response} = eval {XMLin($self->{xmlreceived})};
    if ($@) {
        croak 'error parsing betfair XML response ' . $@;
    }
    if ($self->{response}){

        $self->{sessionToken} 
            = $self->{response}->{'soap:Body'}->{'n:'.$action.'Response'}->{'n:Result'}->{'header'}->{'sessionToken'}->{content};
        
        $self->{headerError}
            = $self->{response}->{'soap:Body'}->{'n:'.$action.'Response'}->{'n:Result'}->{'header'}->{'errorCode'}->{content} 
                || 'OK';

        $self->{bodyError} 
            = $self->{response}->{'soap:Body'}->{'n:'.$action.'Response'}->{'n:Result'}->{'errorCode'}->{content}
                || 'OK';
        return 1 if $self->getError eq 'OK';
    }
    return 0;
}

=head2 _getServerURI

Returns the URI for the target betfair server depending on whether it is an exchange server (1 and 2) or the global server.

=cut

sub _getServerURI {
    my ($self, $server) = @_;
    given($server) {
        when (/1/) { return 'https://api.betfair.com/exchange/v5/BFExchangeService'}
        when (/2/) { return 'https://api-au.betfair.com/exchange/v5/BFExchangeService'} 
        default    { return 'https://api.betfair.com/global/v3/BFGlobalService'}
    }
}


=head2 _sortArrayRef

Returns a sorted arrayref based on price.

=cut

sub _sortArrayRef {
    my $array_ref = shift;
    if (ref($array_ref) eq 'ARRAY'){
       return sort { $b->{price} <=> $a->{price} } @$array_ref;
    }
    return $array_ref;
}

=head2 _addPaymentCardLine

Pushes a hashref of payment card key / value pairs into an arrayref and returns the result.

=cut

sub _addPaymentCardLine {
    my ($self, $payment_card, $line_to_be_added) = @_;
    push(@{$payment_card}, {
        countryCodeIso3     => $line_to_be_added->{'billingCountryIso3'}->{content},
        billingAddress1     => $line_to_be_added->{'billingAddress1'}->{content},
        billingAddress2     => $line_to_be_added->{'billingAddress2'}->{content},
        billingAddress3     => $line_to_be_added->{'billingAddress3'}->{content},
        billingAddress4     => $line_to_be_added->{'billingAddress4'}->{content},
        cardType            => $line_to_be_added->{'cardType'}->{content},
        issuingCountryIso3  => $line_to_be_added->{'issuingCountryIso3'}->{content},
        totalWithdrawals    => $line_to_be_added->{'totalWithdrawals'}->{content},
        expiryDate          => $line_to_be_added->{'expiryDate'}->{content},
        nickName            => $line_to_be_added->{'nickName'}->{content},
        cardStatus          => $line_to_be_added->{'cardStatus'}->{content},
        issueNumber         => $line_to_be_added->{'issueNumber'}->{content},
        country             => $line_to_be_added->{'country'}->{content},
        county              => $line_to_be_added->{'county'}->{content},
        billingName         => $line_to_be_added->{'billingName'}->{content},
        town                => $line_to_be_added->{'town'}->{content},
        postcode            => $line_to_be_added->{'postcode'}->{content},
        netDeposits         => $line_to_be_added->{'netDeposits'}->{content},
        cardShortNumber     => $line_to_be_added->{'cardShortNumber'}->{content},
        totalDeposits       => $line_to_be_added->{'totalDeposits'}->{content}            
    });
    return $payment_card;
}

=head2 _forceArray

Receives a reference variable and if the data is not an array, returns a single-element arrayref. Else returns the data as received.

=cut

sub _forceArray {
    my ($self, $data) = @_;
    return ref($data) eq 'ARRAY' ? $data : [$data];
}

=head2 _checkParams

Receives an hashref of parameter types and a hashref of arguments. Checks that all mandatory arguments are present using _checkParam and that no additional parameters exist in the hashref. 

=cut

sub _checkParams {
    my ($self, $paramChecks, $args) = @_;

    # check no rogue arguments have been included in parameters
    foreach my $paramName (keys %{$args}) {
        if (not exists $paramChecks->{$paramName}) {
            $self->{headerError} = "Error: unexpected parameter $paramName is not a correct argument for the method called.";
            return 0;
        }
        # if exists now check that the type is correct
        else {
            return 0 unless $self->_checkParam( $paramChecks->{$paramName}->[0],
                                                $args->{$paramName});
        }
    }
    # check all mandatory parameters are present 
    foreach my $paramName (keys %{$paramChecks}){
        if ($paramChecks->{$paramName}->[1]){
            unless (exists $args->{$paramName}) {
                $self->{headerError} = "Error: missing mandatory parameter $paramName.";
                return 0;
            }
        }
    }
    return 1;
}

=head2 _checkParam

Checks the parameter using the TypeCheck.pm object, returns 1 on success and 0 on failure.

=cut

sub _checkParam {
    my ($self, $type, $value) = @_;
    unless($self->{type}->checkParameter($type, $value)) {
        $self->{headerError} = "Error: message not sent as parameter $value failed the type requirements check for $type. Check the documentation at the command line: perldoc WWW::betfair::TypeCheck";
        return 0;
    }
    return 1;
}

=head2 _clearData

Sets all message related object attributes to null - this is so that the error message from the previous API call is not mis-read as relevant to the current call.

=cut

sub _clearData {
    my $self = shift;
    $self->{xmlsent}        = undef;
    $self->{xmlreceived}    = undef;
    $self->{headerError}    = undef;
    $self->{bodyError}      = undef;
    $self->{response}       = {};
    return 1;
}


1;

=head1 AUTHOR

David Farrell, C<< <davidnmfarrell at gmail.com> >>, L<perltricks.com|http://perltricks.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-betfair at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-betfair>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::betfair


You can also look for information at:

=over

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-betfair>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-betfair>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-betfair>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-betfair/>

=back

=head1 ACKNOWLEDGEMENTS

This project was inspired by the L<betfair free|http://code.google.com/p/betfairfree/> Perl project. Although L<WWW::betfair> uses a different approach, the betfair free project was a useful point of reference at inception. Thanks guys!

Thanks to L<betfair|http://www.betfair.com> for creating the exchange and API.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 David Farrell.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
