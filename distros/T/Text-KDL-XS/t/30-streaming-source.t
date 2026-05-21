use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use Text::KDL::XS qw(parse_kdl);

my $kdl = "a 1\nb 2\nc 3\n";

# Coderef source - feed in tiny chunks to exercise the trampoline.
{
    my @chunks = split //, $kdl;
    my $reader = sub {
        my ($want) = @_;
        return '' unless @chunks;
        return shift @chunks;
    };
    my $doc = parse_kdl($reader);
    is scalar(@{ $doc->nodes }), 3, 'coderef source: 3 nodes';
    is $doc->nodes->[1]->name, 'b', 'coderef source: name';
    is $doc->nodes->[1]->args->[0]->as_perl, 2, 'coderef source: arg';
}

# Filehandle source.
{
    my ($fh, $path) = tempfile(UNLINK => 1);
    print $fh $kdl;
    close $fh;
    open my $in, '<', $path or die "open: $!";
    my $doc = parse_kdl($in);
    is scalar(@{ $doc->nodes }), 3, 'fh source: 3 nodes';
    is $doc->nodes->[2]->name, 'c', 'fh source: name';
}

done_testing;
