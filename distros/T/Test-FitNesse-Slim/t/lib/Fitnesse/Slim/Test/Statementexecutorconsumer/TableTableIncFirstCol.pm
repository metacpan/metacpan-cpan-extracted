package Fitnesse::Slim::Test::Statementexecutorconsumer::TableTableIncFirstCol;

use strict;
use warnings;

my $SYMBOL_HANDLING = 'SLIM_AGENT_FIXTURE_HANDLES_SYMBOLS';

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub set_statement_executor {
    my ($self, $executor) = @_;
    $self->{executor} = $executor;
    $executor->set_symbol($SYMBOL_HANDLING, 'tableTable.*\\.doTable');
    return;
}

sub do_table {
    my ($self, $table) = @_;
    my $result = eval {
        [ map {
            my ($input, $assignment) = @$_;
            my $old_value = $self->_replace_symbols_in_string($input);
            die "java.lang.NumberFormatException: For input string: \"$old_value\"\n"
                unless defined($old_value) && $old_value =~ /\A[+-]?\d+\z/;
            my $new_value = 0 + $old_value + 1;
            $self->_assign_symbol_if_applicable($assignment, $new_value);
            [ 'no change', "pass:$new_value" ];
        } @$table ];
    };
    my $error = $@;
    $self->{executor}->set_symbol($SYMBOL_HANDLING, undef);
    die $error if $error;
    return $result;
}

sub _replace_symbols_in_string {
    my ($self, $text) = @_;
    $text =~ s{\$(\w+)}{
        my $value = $self->{executor}->get_symbol($1);
        defined($value) ? "$value" : 'null';
    }gex;
    return $text;
}

sub _assign_symbol_if_applicable {
    my ($self, $text, $value) = @_;
    return unless defined($text) && $text =~ /\A\$(\w+)=\z/;
    $self->{executor}->set_symbol($1, $value);
    return 1;
}

1;
