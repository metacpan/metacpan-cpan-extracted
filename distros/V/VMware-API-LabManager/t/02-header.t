use Test;
use VMware::API::LabManager;
use strict;

BEGIN { plan tests => 11 };

my $labman = new VMware::API::LabManager (
  qw/username password localhost organizationname workspacename/
);

ok( ref $labman->{auth_header} eq 'SOAP::Header' );
ok( ref $labman->{auth_header}->{_value} eq 'ARRAY' );
ok( ref $labman->{auth_header}->{_value}->[0] eq 'HASH' );

my $header = $labman->{auth_header}->{_value}->[0];

for my $field ( qw/workspacename password organizationname username/ ) {
  ok( defined $header->{$field} );
  ok( $header->{$field} eq $field );
}
