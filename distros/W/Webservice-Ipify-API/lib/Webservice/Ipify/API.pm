
package Webservice::Ipify::API;


use strict;
use warnings;

use Feature::Compat::Class;
use Feature::Compat::Try;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '1.003';


class Webservice::Ipify::API;

use HTTP::Tiny;
use JSON::PP;
use Carp;

my $ua  = HTTP::Tiny->new(timeout => 7);


method get_ipv4(){
    return fetch('https://api4.ipify.org');
}

method get_ipv6(){
    return fetch('https://api6.ipify.org');
}

method get(){
    return fetch('https://api64.ipify.org');
}

sub fetch($url){
    my $response = $ua->get($url);
    # croak on errors with nice error messages
    if( !$response->{success}  ){
        croak $response->{status}." ".$response->{content} ;
    }

    return $response->{content};
}


__END__

=pod

=head1 NAME

Webservice::Ipify::API - Lookup your IP address using Ipify.org

=head1 SYNOPSIS

    use v5.40;
    use Webservice::Ipify::API;

    my $api = Webservice::Ipify::API->new();

    # Universal: IPv4/IPv6
    say $api->get();

    # used for IPv4.
    say $api->get_ipv4();

    # used for IPv6 request only. If you don't have an IPv6 address, the request will fail.
    say $api->get_ipv6();


=head1 DESCRIPTION

Look up your external IP address through the ipify public API via the feature "class" keyword.

=head1 SEE ALSO

=over 3

=item Call for API implementations on PerlMonks: L<https://perlmonks.org/?node_id=11161472>

=item Listed at  freepublicapis.com: L<https://www.freepublicapis.com/ipify-api>

=item Official api webpage: L<https://www.ipify.org/>

=back

=head1 AUTHOR

Joshua Day, E<lt>hax@cpan.orgE<gt>

=head1 SOURCE CODE

Source code is available on Github.com : L<https://github.com/haxmeister/perl-ipify>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Joshua Day

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
