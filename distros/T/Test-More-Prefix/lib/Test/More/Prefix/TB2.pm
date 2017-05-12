package Test::More::Prefix::TB2;
$Test::More::Prefix::TB2::VERSION = '0.007';
# Load Test::More::Prefix for later versions of Test::Builder

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(test_prefix);

our $prefix = '';

sub import { __PACKAGE__->export_to_level( 2, @_ ); }

sub test_prefix {
    $prefix = shift();
}

Test2::API::test2_stack->top->filter(
    sub {
        my ( $stream, $e ) = @_;

        return $e unless $prefix;
        return $e unless $e->isa('Test2::Event::Diag')
                      || $e->isa('Test2::Event::Note');

        $e->set_message( "$prefix: " . $e->message );

        return $e;
    }
);

1;
