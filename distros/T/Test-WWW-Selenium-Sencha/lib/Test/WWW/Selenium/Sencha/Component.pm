package Test::WWW::Selenium::Sencha::Component;

use Moose;
use namespace::clean;

has '_sencha' => (is => 'rw');
has 'id' => (is => 'rw');

sub tbar_item {
    my ($self, $index) = @_;

    my $cmd = "window.Ext.getCmp('" . $self->id . "').getDockedItems()[0].items.getAt(" . $index . ").getEl().id";
	my $id = $self->_sencha->get_eval($cmd);

    return Test::WWW::Selenium::Sencha::Component->new({_sencha => $self->_sencha,
                                                        id => $id,
                                                       });
}



sub click {
    my ($self, $testname) = @_;
    $self->_sencha->click($testname,$self->id);
}


1;
