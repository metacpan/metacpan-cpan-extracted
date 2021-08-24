package oCLI::Command;
use Import::Into;
use Package::Stash;
push our @ISA, qw( Exporter );
push our @EXPORT, qw( setup define );

sub import {
    shift->export_to_level(1);
    my $target = caller;
    Package::Stash->new($target)->add_symbol( '%stash', { class => $target } );
    Moo->import::into($target);
}

sub define {
    my ( $name, @args ) = @_;

    ${Package::Stash->new(scalar caller)->get_symbol('%stash')}{command}->{$name} = { @args };
}

sub setup {
    my ( $name, @args ) = @_;

    ${Package::Stash->new(scalar caller)->get_symbol('%stash')}{info} = { name => $name, @args };
}

1;
