package XML::Schematron::Test;
use Moose;

has [qw|expression context message test_type|] => (
    traits    => ['String'],
    is          => 'rw',
    isa         => 'Str',
    required    => 1, 
);

has pattern => (
    is          => 'ro',
    isa         => 'Maybe[Str]',
    default     => sub { '[none]' },
);

sub as_xsl {
    my $self = shift;
    my $priority = shift;

    my $context     = $self->context;
    my $expression  = $self->expression;
    my $message     = $self->message;

    $context    =~ s/"/'/g;
    $expression =~ s/</&lt;/g;
    $expression =~ s/>/&gt;/g;
    $message    =~ s/\n//g;
    $message =~ s/^[ \t]+|[ \t]+$//;
    $message   .= "\n";
    
    my $buffer;
    if ( $self->test_type eq 'assert' ) {
        $buffer = sprintf(qq|<xsl:choose><xsl:when test="%s"/><xsl:otherwise>In pattern %s: %s</xsl:otherwise></xsl:choose>|, $expression, $self->pattern, $message)
    }
    else {
        $buffer = sprintf(qq|<xsl:if test="%s">In pattern %s: %s</xsl:if>|, $expression, $self->pattern, $message);
    }
    
    return $buffer;
}

1;