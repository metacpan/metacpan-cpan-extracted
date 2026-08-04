use strict;
use warnings;
use Test::More tests => 13;
use XML::Sig;

# verified_ids() and verified_elements() report what verify() actually
# checked, letting a caller confirm the data it consumes is the data that
# was signed.

my $CERT = 't/rsa.cert.pem';
my $KEY  = 't/rsa.private.key';

my $signed = XML::Sig->new({ key => $KEY, cert => $CERT })
    ->sign('<Document><Claim ID="legit">low privilege</Claim><Claim ID="another_legit">med privilege</Claim></Document>');

# Before verify() both accessors are empty rather than undef.
my $sig = XML::Sig->new({ cert => $CERT });
is_deeply($sig->verified_ids,      [], 'verified_ids empty before verify');
is_deeply($sig->verified_elements, [], 'verified_elements empty before verify');

ok($sig->verify($signed), 'genuine signature verifies');
is_deeply($sig->verified_ids, ['legit', 'another_legit'],
    'verified_ids reports both signed ids in document order');

my $els = $sig->verified_elements;
is(scalar @$els, 2, 'both signed elements reported');
is($els->[0]->getAttribute('ID'), 'legit',         'first element named by the first id');
is($els->[1]->getAttribute('ID'), 'another_legit', 'second element named by the second id');
like($els->[0]->textContent, qr/low privilege/, 'first element carries its signed content');
like($els->[1]->textContent, qr/med privilege/, 'second element carries its signed content');

# A document signed more than once reports every reference it verified.
{
    open my $fh, '<', 't/signed/one-of-three-sigs-unassocated.xml' or die $!;
    my $xml = do { local $/; <$fh> };

    my $multi = XML::Sig->new({});
    ok($multi->verify($xml), 'multiply signed document verifies');
    cmp_ok(scalar @{ $multi->verified_ids }, '>', 1, 'and reports each verified reference');
}

# Results must not survive into a later failed verify.
(my $tampered = $signed) =~ s{>low privilege<}{>I am an admin<};
ok(!$sig->verify($tampered), 'tampered document fails to verify');
is_deeply($sig->verified_ids, [], 'results cleared by the failed verify');
