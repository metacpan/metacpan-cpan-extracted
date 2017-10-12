package WWW::Salesforce::Deserializer;

use strict;
use warnings;
use SOAP::Lite;

our $VERSION = '0.303';
$VERSION = eval $VERSION;

our @ISA = qw( SOAP::Deserializer );
use strict 'refs';

our $XSD_NSPREFIX     = "xsd";
our $XSI_NSPREFIX     = "xsi";
our $SOAPENV_NSPREFIX = "SOAP-ENV";
our $SOAPENC_NSPREFIX = "SOAP-ENC";
our $NSPREFIX         = "wsisup";

BEGIN {
    no strict 'refs';
    for my $class (qw(LoginResult)) {
        my $method_name = "as_" . $class;
        my $class_name  = "WWW::Salesforce::" . $class;
        my $method_body = <<END_OF_SUB;

            sub $method_name {
                my (\$self,\$f,\$name,\$attr) = splice(\@_,0,4);
                my \$ns = pop;
                my \$${class} = WWW::Salesforce::${class}->new;
                foreach my \$elem (\@_) {
                    \$elem = shift \@\$elem if (ref(\$elem->[0]) eq 'ARRAY');
                    my (\$name2, \$attr2, \$value2, \$ns2) = splice(\@{\$elem},0,4);
                    my (\$pre2,\$type2) = (\${attr2}->{\$XSI_NSPREFIX.":type"} =~ /([^:]*):(.*)/);
                    if (\$pre2 && \$pre2 eq \$XSD_NSPREFIX) {
                        \$${class}->{'_'.\$name2} = \$value2;
                    }
                    else {
                        my \$cmd = '\$self->as_'.\$type2.'(\$f,\@\$value2);';
                        \$${class}->{'_'.\$name2} = eval \$cmd;
                    }
                }
                return \$${class};
            }
END_OF_SUB

        #    print STDERR $method_body;
        #    *$method_name = eval $method_body;
        eval $method_body;
    }
}

#**************************************************************************
# as_Array()
#   -- returns the data as an array
#**************************************************************************
sub as_Array {
    my $self = shift;
    my $f    = shift;
    my @Array;
    foreach my $elem (@_) {
        my ( $name, $attr, $value, $ns ) = splice( @$elem, 0, 4 );
        my $attrv = ${attr}->{ $XSI_NSPREFIX . ":type" };
        my ( $pre, $type ) = ( $attrv =~ /([^:]*):(.*)/ );
        my $result;
        if ( $pre eq $XSD_NSPREFIX ) {
            $result = $value;
        }
        else {
            my $cmd =
              '$self->as_' . $type . '(1, $name, $attr, @$value, $ns );';

            #        print STDERR $cmd . "\n";
            $result = eval $cmd;
        }
        push( @Array, $result );
    }
    return \@Array;
}

1;
