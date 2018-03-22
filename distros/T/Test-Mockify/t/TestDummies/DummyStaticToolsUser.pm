package t::TestDummies::DummyStaticToolsUser;
use strict;
use warnings;
use FindBin;
use lib ($FindBin::Bin.'/..');
use t::TestDummies::DummyStaticTools;
sub new {
    return bless({},$_[0]);
}

sub useDummyStaticTools {
    my $self = shift;
    my ($Value) = @_;
    my $Triplet = t::TestDummies::DummyStaticTools::Tripler($Value);
    return "In useDummyStaticTools, result Tripler call: \"$Triplet\"";
}
1;