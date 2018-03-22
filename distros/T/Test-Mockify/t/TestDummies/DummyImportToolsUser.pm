package t::TestDummies::DummyImportToolsUser;
use strict;
use warnings;
use FindBin;
use lib ($FindBin::Bin.'/..');
use t::TestDummies::DummyImportTools qw (Doubler);
use TestDummies::FakeModuleForMockifyTest;
sub new {
    return bless({},$_[0]);
}

sub useDummyImportTools {
    my $self = shift;
    my ($Value) = @_;
    my $Doubled = Doubler($Value);
    return "In useDummyImportTools, result Doubler call: \"$Doubled\"";
}
sub callAConstructor {
    my ($Parameter) = @_;
    return TestDummies::FakeModuleForMockifyTest->new($Parameter)->returnParameterListNew();
}
sub callAlternativConstructor {
    my ($Parameter) = @_;
    return TestDummies::FakeModuleForMockifyTest->create($Parameter)->returnParameterListCreate();
}
1;