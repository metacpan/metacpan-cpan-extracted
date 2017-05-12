package CmdTest::C3;
use Command::V2;
use strict;
use warnings;
use CmdTest::C2;

class CmdTest::C3 {
    is => ['CmdTest::C2'],
    has => [
        thing_name => { is => 'Text', via => 'thing', to => 'name' },
    ],
    doc => "test command 3"
};

sub execute {
    my $self = shift;
    no warnings;
    print "thing_id is " . $self->thing_id . "\n";
    return 1;
}

if ($0 eq __FILE__) {
    exit __PACKAGE__->_cmdline_run(@ARGV)
}

sub help_detail {
    return "HELP DETAIL";
}


1;

