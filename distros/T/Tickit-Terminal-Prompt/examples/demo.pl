#!/usr/bin/env perl
use v5.36;
use Tickit::Terminal::Prompt;

my $ui = Tickit::Terminal::Prompt->new(
    prompt => 'demo> ',
    on_enter => sub ($ui, $line) {
        if ($line eq 'quit' || $line eq 'exit') {
            $ui->stop;
        }
        elsif ($line eq 'help') {
            $ui->say('Commands: help, quit; all other text is echoed.');
        }
        else {
            $ui->say("You entered: $line");
        }
    },
);

$ui->say('Enter a command, or type help or quit.');
$ui->run;
