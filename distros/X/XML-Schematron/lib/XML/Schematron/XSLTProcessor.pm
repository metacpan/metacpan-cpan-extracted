package XML::Schematron::XSLTProcessor;
use Moose::Role;
use namespace::autoclean;
with 'XML::Schematron::Schema';

has template_buffer => (
    traits    => ['String'],
    is          => 'rw',
    isa         => 'Str',
    default     => sub { return '' },
    handles     => {
          append_template     => 'append',
          reset_template      => 'clear',
    },

);

sub tests_to_xsl {
    my $self = shift;
    my $mode = 'M0';
    my $ns = qq|xmlns:xsl="http://www.w3.org/1999/XSL/Transform"|;

    $self->append_template(
        qq|<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <xsl:stylesheet $ns version="1.0">
        <xsl:output method="text"/>
        <xsl:template match="/">
        <xsl:apply-templates select="/" mode="$mode"/>|
    );


    my $last_context_path = '';
    my $priority = 4000;
    foreach my $test ( $self->all_tests) {

        if ($test->context ne $last_context_path) {
             $self->append_template(
                 qq|\n<xsl:apply-templates mode="$mode"/>\n|
             ) unless $priority == 4000;

             $self->append_template(
                 sprintf(qq|</xsl:template>\n<xsl:template match="%s" priority="$priority" mode="$mode">|, $test->context)
             );
             $priority--;
        }

        $self->append_template( $test->as_xsl );

        $last_context_path = $test->context;
    }


    $self->append_template(
        qq|<xsl:apply-templates mode="$mode"/>\n</xsl:template>\n
           <xsl:template match="text()" priority="-1" mode="M0"/>
           </xsl:stylesheet>|
    );
}

sub dump_xsl {
    my $self = shift;
    $self->tests_to_xsl;
    return $self->template_buffer;
}

1;