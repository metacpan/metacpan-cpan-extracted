package XML::Schematron::SchemaReader;
use Moose;
use namespace::autoclean;
use MooseX::NonMoose;
extends 'XML::SAX::Base';

use XML::Schematron::Test;
use Data::Dumper;

has test_stack => (
    traits      => ['Array'],
    is          =>  'rw',
    isa         =>  'ArrayRef[XML::Schematron::Test]',
    default     =>  sub { [] },
    handles     => {
        add_test    => 'push',
    }
);

has [qw|context test_type expression|] => (
    traits    => ['String'],
    is          => 'rw',
    isa         => 'Str',
    default     => sub { return ''; }
);

has pattern => (
    traits    => ['String'],
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    default     => sub { '[none]' },
);

has message => (
    traits    => ['String'],
    is          => 'rw',
    isa         => 'Str',
    default     => sub { return '' },
    handles     => {
          add_to_message     => 'append',
          reset_message     => 'clear',
    },

);

sub start_element {
    my ($self, $el) = @_;
    #warn "processing element " . $el->{LocalName} . "\n";

    # simplify
    my $attrs = {};
    foreach my $attr ( keys ( %{$el->{Attributes}} ) ) {
        $attrs->{$el->{Attributes}->{$attr}->{LocalName}} = $el->{Attributes}->{$attr}->{Value};
    }

    #warn "EL " . Dumper( $el );

    if ( defined( $attrs->{context} )) {
        $self->context( $attrs->{context} );
    }


    if (( $el->{LocalName} =~ /(assert|report)$/)) {
        if ( defined( $attrs->{test} )) {
            $self->expression( $attrs->{test} );
        }
        else {
            warn "Schema Warning: Assert/Report element found with no associated 'test' attribute.";
            $self->expression('');
        }
    }
    elsif ($el->{LocalName} eq 'pattern' && defined( $attrs->{name} )) {
        $self->pattern( $attrs->{name} );
    }
}

sub end_element {
    my ($self, $el) = @_;

    if (( $el->{LocalName} =~ /(assert|report)$/)) {
        $self->test_type( $el->{LocalName} );

        my $test = XML::Schematron::Test->new(
                        test_type   => $self->test_type,
                        expression  => $self->expression,
                        context     => $self->context,
                        message     => $self->message,
                        pattern     => $self->pattern,
                    );

        $self->add_test( $test );
        $self->reset_message;
    }
}

sub characters {
    my ($self, $characters) = @_;
    $self->add_to_message( $characters->{Data} );
}

no Moose;
__PACKAGE__->meta->make_immutable;

=cut

1;

