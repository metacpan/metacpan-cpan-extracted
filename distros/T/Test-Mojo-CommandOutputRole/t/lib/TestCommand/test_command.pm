package TestCommand::test_command;
use Mojo::Base 'Mojolicious::Command', -signatures;

has description => 'Test description';
has usage       => 'Test usage';

sub run ($self, @args) {say "Test command has run with @args."}

1;
__END__
