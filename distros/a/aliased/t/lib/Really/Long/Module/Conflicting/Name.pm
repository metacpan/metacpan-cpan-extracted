package Really::Long::Module::Conflicting::Name;

sub import {
    my ($class, @args) = @_;
    my $callpack = caller(0);
    no strict 'refs';
    *{"${callpack}::echo"} = sub { @_ } if $args[0] eq 'echo';
}

sub new { bless {} => shift }

sub echo { @_ }

1;
