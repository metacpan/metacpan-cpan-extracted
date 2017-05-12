use strict;
use Test::More qw(no_plan);
use lib "lib";

BEGIN { use_ok('Text::DHCPLeases'); }

my $file = 't/dhcpd.leases.sample';

my $dl = Text::DHCPLeases->new(file=>$file);
isa_ok($dl, 'Text::DHCPLeases', 'Constructor');

my $it = $dl->get_objects();
is($it->count, 34, 'count');

is($it->first->ip_address, '192.168.10.87', 'get_leases2');
is($it->last->ip_address, '192.168.10.55', 'get_leases3');

$it = $dl->get_objects(type=>'lease', ip_address=>'192.168.10.55');
is($it->last->tsfp, '3 2007/08/15 20:31:07', 'get_leases1');

my @objs = $dl->get_objects('mac_address'=>'08:00:09:7c:c5:9a');
is(scalar @objs, 2, 'search');

open(FILE, $file) or die "Can't open file $file: $!\n";

my $text;
while(<FILE>){
    $text .= $_;
}
is($dl->print, $text, 'print');

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007-2010, Carlos Vicente <cvicente@cpan.org>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

