#!/gsc/bin/perl

use strict;
use warnings;
use above 'Vending';

my $machine = Vending::Machine->get();
unless ($machine) {
    print STDERR "Out of order...\n";
    exit;
}

my %command_map = (
    help => \&help,
    done => \&done,
    'check-again' => \&clear_query_cache,
    'coin-return' => 'Vending::Command::CoinReturn',
    dollar => 'Vending::Command::Dollar',
    quarter => 'Vending::Command::Quarter',
    dime => 'Vending::Command::Dime',
    nickel => 'Vending::Command::Nickel',
    buy => 'Vending::Command::Buy',
    menu => 'Vending::Command::Menu',
);

$|=1;
&help();
while (1) {
    print "command> ";
    my $line = <>;
    last unless $line;
    chomp($line);

    my @words = split(/\s+/, $line);

    my $thing = $command_map{shift @words};
    if (ref($thing)) {
        # It's a sub we can just call
        $thing->();
    } elsif($thing) {
        # It's a command class name
        my $command = $thing->create(bare_args => \@words);
        if ($command->execute() ) {
            UR::Context->commit();
        }
    } else {
        print "That is not a valid command\n";
    }

}

&done();


sub done {
    print "\nGoodbye\n";
    exit(0);
}

sub help {
    print q(
Vendco Vending Machine available commands:
dollar - insert a dollar
quarter - insert a quarter
dime - insert a dime
nickel - insert a nickel
menu - See what is available
buy <slot> - purchase an item from the menu
coin-return - return any coins you inserted
help - this help text
check-again - secret backdoor to use when another progrtam reloads the inventory

);

}

sub clear_query_cache {
    print "Forgetting about Vending::Merchandises and Vending::Coins\n";
    Vending::Merchandise->unload();
    Vending::Coin::Change->unload();
}

    
