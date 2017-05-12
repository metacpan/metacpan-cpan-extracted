# -*- perl -*-
# Copyright (C) 2004 Identity Commons.  All Rights Reserved.
# See LICENSE for licensing details

# Authors:
#       Fen Labalme <fen@idcommons.net>, <fen@comedia.com>
#       Eugene Eric Kim <eekim@blueoxen.org>

use Test::More;
plan tests => scalar keys(%tests) + 5;

use XRI::Descriptor;

while (my ($name, $test) = each %tests) {
    ($function = $name) =~ s/^([^\d]*)\d*$/$1/;
    my ($xml, $expected) = @$test;
    my $xd = XRI::Descriptor->new( $xml );
    my $result = $xd->$function;
    if ( ref $expected ) {
        is_deeply($result, $expected, $name);
    }
    else {
        is($result, $expected, $name);
    }
}
# LocalAccess test.  Can't use the %test hash because getLocalAccess
# returns a list of objects.
my $xd = XRI::Descriptor->new($localAccessTest);
my @localAccess = $xd->getLocalAccess;
is(scalar @localAccess, 1);
isa_ok($localAccess[0], 'XRI::Descriptor::LocalAccess');
is(scalar @{$localAccess[0]->uris}, 2);
is(${$localAccess[0]->uris}[0], 'testuri');
is(${$localAccess[0]->uris}[1], 'test2uri');


BEGIN {
    ##
    ## the format used for tests is:
    ##  1. method (with optional digit to separate tests)
    ##  2. array of [ descriptor, test_result ]
    ##
    %tests = ( getResolved => [
'<XRIDescriptor xmlns="xri:$r.s/XRIDescriptor">
  <Resolved>.foo</Resolved>
  <XRIAuthority>
    <URI>testuri</URI>
  </XRIAuthority>
</XRIDescriptor>', ".foo" ],
               getXRIAuthorityURIs1 => [
'<XRIDescriptor xmlns="xri:$r.s/XRIDescriptor">
  <Resolved>.foo</Resolved>
  <XRIAuthority>
    <URI>testuri</URI>
  </XRIAuthority>
</XRIDescriptor>', ['testuri'] ],
               getXRIAuthorityURIs2 => [
'<XRIDescriptor xmlns="xri:$r.s/XRIDescriptor">
  <Resolved>.foo</Resolved>
  <XRIAuthority>
    <URI>testuri</URI>
    <URI>test2uri</URI>
  </XRIAuthority>
</XRIDescriptor>', ['testuri', 'test2uri'] ],
               getMappings => [
'<XRIDescriptor xmlns="xri:$r.s/XRIDescriptor">
  <Resolved>.foo</Resolved>
  <Mapping>xri:=Foo</Mapping>
  <Mapping>xri:1.2.3</Mapping>
</XRIDescriptor>', ['xri:=Foo', 'xri:1.2.3'] ],
               getXRIAuthorityURIs3 => [
'<XRIDescriptor xmlns="xri:$r.s/XRIDescriptor">
  <Resolved>@</Resolved>
  <XRIAuthority>
    <URI>http://localhost/xri/at</URI>
  </XRIAuthority>
</XRIDescriptor>', [ 'http://localhost/xri/at' ]],
               );

    $localAccessTest = 
'<XRIDescriptor xmlns="xri:$r.s/XRIDescriptor">
  <Resolved>.foo</Resolved>
  <LocalAccess>
    <URI>testuri</URI>
    <URI>test2uri</URI>
  </LocalAccess>
</XRIDescriptor>';
}
