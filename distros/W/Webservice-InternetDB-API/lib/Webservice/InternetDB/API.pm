package Webservice::InternetDB::API;


use strict;
use warnings;

use Feature::Compat::Class;
use Feature::Compat::Try;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '1.004';

class Webservice::InternetDB::API;

use HTTP::Tiny;
use JSON::PP;
use Carp;

field $ua = HTTP::Tiny->new(timeout => 7);
field $base = "https://internetdb.shodan.io/";


method get ($address //= ""){
    my $response = $ua->get("$base$address");

    # croak on errors with nice error messages
    if( !$response->{success}  ){

        if( $response->{'headers'}{'content-type'} =~ /json/ ){

            croak $response->{status}." ".decode_json($response->{content})->{detail} ;

        }else{

            croak $response->{status}." ".$response->{content} ;
        }

    }

    try{
        $response->{content} = decode_json($response->{content});
    }catch($e){
        croak "unable to decode message from API ".$e;
    }

    return $response->{content};
}
1;

__END__

=pod

=head1 NAME

Webservice::InternetDB::API - Fast IP Lookups for Open Ports and Vulnerabilities using InternetDB API

=head1 SYNOPSIS

    use v5.40;
    use Webservice::InternetDB::API;

    # get information about this current machine:
    my $response = Webservice::InternetDB::API->new()->get();

    # get information about another machine:
    $response = Webservice::InternetDB::API->new()->get('1.1.1.1');

    # re-use the same object:
    my $api = Webservice::InternetDB::API->new();
    $api->get('1.1.1.1');

=head1 DESCRIPTION

This module provides an object oriented interface via the keyword "class" feature to the InternetDB free API endpoint provided by L<https://internetdb.shodan.io/>. Shodan also provides much more robust paid services with subscription that this module does not provide access to.

=head1 METHODS

=over

=item C<get()>

=back

Accepts a string that is the IP address to be scanned.
Returns a hash reference with the results of the scan.

example response:

    {
        cpes        [],
        hostnames   [
            "one.one.one.one"
        ],
        ip          "1.1.1.1",
        ports       [
            53,
            80,
            443,
            2082,
            2083,
            2087,
            8080,
            8443,
            8880
        ],
        tags        [],
        vulns       []
    }


=head1 SEE ALSO

=over 3

=item Call for API implementations on PerlMonks: L<https://perlmonks.org/?node_id=11161472>

=item Listed at  freepublicapis.com: L<https://www.freepublicapis.com/ipify-api>

=item Official api webpage: L<https://www.ipify.org/>

=back

=head1 AUTHOR

Joshua Day, E<lt>hax@cpan.orgE<gt>

=head1 SOURCECODE

Source code is available on Github.com : L<https://github.com/haxmeister/perl-InternetDB>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Joshua Day

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
