use Command::V2;
use strict;
use warnings;

package CmdTest::C1;
use CmdTest::Stuff;

class CmdTest::C1 {
    is => 'Command::V2',
    has_optional_input => [
        z => { is => "Text" },
        a => { is => "Text" },
        b20 => { is => "Text" },
        b3  => { is => "Text" },
    ],
    has_optional_param => [
        p3 => { is => 'Number' },
        p1 => { is => 'Number' },
        p2 => { is => 'Number' },
    ],
    has_input => [
        rz => { is => "Text" },
        ra => { is => "Text" },
        rb20 => { is => "Text" },
        rb3  => { is => "Text" },
    ],
    has_param => [
        rp3 => { is => 'Number' },
        rp1 => { is => 'Number' },
        rp2 => { is => 'Number' },
    ],
    has_output => [
        #stuff => { is => 'CmdTest::Stuff' },
        more  => { is => 'Text' }
    ],
    doc => "test command 1"
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

