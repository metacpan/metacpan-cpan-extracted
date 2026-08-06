use strict;
use warnings;

use Test::More tests => 6;

use XML::Hash::XS qw();

my $xml = '<root><a>one</a><b>two</b></root>';

{
    my $conv;
    {
        my $filter = '/root/a';
        $conv = XML::Hash::XS->new(filter => $filter, keep_root => 1);
    }

    is_deeply(
        [ map { $conv->xml2hash($xml) } 1 .. 3 ],
        [
            [ { a => 'one' } ],
            [ { a => 'one' } ],
            [ { a => 'one' } ],
        ],
        'object filter remains valid across repeated calls',
    );
}

{
    my @nodes;
    my $cb = sub { push @nodes, $_[0] };
    my $conv = XML::Hash::XS->new(
        filter => '/root/a',
        keep_root => 1,
        cb => $cb,
    );
    undef $cb;

    $conv->xml2hash($xml) for 1 .. 3;

    is_deeply(
        \@nodes,
        [
            { a => 'one' },
            { a => 'one' },
            { a => 'one' },
        ],
        'object callback remains valid across repeated calls',
    );
}

{
    my (@base, @override);
    my $conv = XML::Hash::XS->new(
        filter => '/root/a',
        keep_root => 1,
        cb => sub { push @base, $_[0] },
    );

    $conv->xml2hash($xml);
    $conv->xml2hash(
        $xml,
        filter => '/root/b',
        cb => sub { push @override, $_[0] },
    );
    $conv->xml2hash($xml);

    is_deeply(
        \@base,
        [ { a => 'one' }, { a => 'one' } ],
        'per-call override preserves object callback',
    );
    is_deeply(\@override, [ { b => 'two' } ], 'per-call override uses replacement callback');
}

{
    my $output = '';
    my $conv;

    {
        open(my $fh, '>', \$output) or die "Can't open scalar filehandle: $!";
        $conv = XML::Hash::XS->new(output => $fh, root => 'doc', xml_decl => 0);
    }

    $conv->hash2xml({ item => 'value' });

    is($output, '<doc><item>value</item></doc>', 'object retains output filehandle');
}

{
    my $output = '';
    open(my $fh, '>', \$output) or die "Can't open scalar filehandle: $!";
    local $XML::Hash::XS::output = $fh;

    XML::Hash::XS::hash2xml({ item => 'value' }, root => 'doc', xml_decl => 0);

    is($output, '<doc><item>value</item></doc>', 'global output filehandle is normalized');
}
