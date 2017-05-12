use Command::V2;
use strict;
use warnings;

package CmdTest::C2;
use CmdTest::Stuff;

class CmdTest::Thing {
    has => [ name => { is => 'Text' } ]
};

CmdTest::Thing->create(id => 111, name => 'one');
CmdTest::Thing->create(id => 222, name => 'two');
CmdTest::Thing->create(id => 333, name => 'three');

class CmdTest::C2 {
    is => 'Command::V2',
    has => [
        thing => { is => 'CmdTest::Thing', id_by => 'thing_id' },
    ],
    doc => "test command 2"
};

sub execute {
    my $self = shift;
    print "running $self with args: " . Data::Dumper::Dumper($self) . "\n";
    return 1;
}

if ($0 eq __FILE__) {
    exit __PACKAGE__->_cmdline_run(@ARGV)
}

sub help_detail {
    return "HELP DETAIL";
}


1;

