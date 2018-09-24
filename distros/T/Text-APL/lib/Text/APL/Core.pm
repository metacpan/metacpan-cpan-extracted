package Text::APL::Core;

use strict;
use warnings;

use base 'Text::APL::Base';

our $VERSION = '0.09';

use Text::APL::Compiler;
use Text::APL::Context;
use Text::APL::Parser;
use Text::APL::Reader;
use Text::APL::Translator;
use Text::APL::Writer;

sub _BUILD {
    my $self = shift;

    $self->{parser}     ||= Text::APL::Parser->new;
    $self->{translator} ||= Text::APL::Translator->new;
    $self->{compiler}   ||= Text::APL::Compiler->new;
    $self->{reader}     ||= Text::APL::Reader->new;
    $self->{writer}     ||= Text::APL::Writer->new;
}

sub render {
    my $self = shift;
    my (%params) = @_;

    my $return = '';

    my $writer =
      $self->{writer}
      ->build(exists $params{output} ? $params{output} : \$return);

    my $context = Text::APL::Context->new(
        helpers => $params{helpers},
        vars    => $params{vars},
        name    => $params{name}
    );
    $context->add_helper(__print => sub { $writer->(@_) });
    $context->add_helper(
        __print_escaped => sub {
            my ($input) = @_;

            return $writer->('') unless defined $input;

            for ($input) { s/&/&amp;/g; s/</&lt;/g; s/>/&gt;/g; s/"/&quot;/g; s/'/&#039;/g }

            $writer->($input);
        }
    );

    $self->_process(
        $params{input},
        $context,
        sub {
            my $self = shift;
            my ($sub_ref) = @_;

            $sub_ref->($context);

            $writer->();
        }
    );

    return exists $params{output} ? $self : $return;
}

sub _process {
    my $self = shift;
    my ($input, $context, $cb) = @_;

    $self->_parse(
        $input => sub {
            my $self = shift;
            my ($tape) = @_;

            my $code = $self->_translate($tape);

            my $sub_ref = $self->_compile($code, $context);

            $cb->($self, $sub_ref);
        }
    );
}

sub _parse {
    my $self = shift;
    my ($input, $cb) = @_;

    my $parser = $self->{parser};

    my $reader = $self->{reader}->build($input);

    my $tape      = [];
    my $reader_cb = sub {
        my ($chunk) = @_;

        if (!defined $chunk) {
            my $leftover = $parser->parse();
            push @$tape, @$leftover if $leftover;

            $cb->($self, $tape);
        }
        else {
            my $subtape = $parser->parse($chunk);
            push @$tape, @$subtape if @$subtape;
        }
    };

    $reader->($reader_cb, $input);
}

sub _translate {
    my $self = shift;
    my ($tape) = @_;

    return $self->{translator}->translate($tape);
}

sub _compile {
    my $self = shift;
    my ($code, $context) = @_;

    return $self->{compiler}->compile($code, $context);
}

1;
__END__

=pod

=head1 NAME

Text::APL::Core - implementation

=head1 DESCRIPTION

This is the actual L<Text::APL> implementation core class.

=cut
