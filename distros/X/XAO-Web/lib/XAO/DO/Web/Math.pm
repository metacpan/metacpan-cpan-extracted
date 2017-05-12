=head1 NAME

XAO::DO::Web::Math - calculate and output a value

=head1 SYNOPSIS

 <%Math formula='{x}+{y}' value.x='2' value.y='3'%>

=head1 DESCRIPTION

Given a formula and some values calculates the result and displays it
optionally formatting according to the given format:

 <%Math formula='{x}+{y}' value.x='2' value.y='3'%>
    -- output '5'

 <%Math formula='1/{x}' value.x='3' format='%.3'%>
    -- output '0.333'

 <%Math formula='1 / ({a} - {b})' value.a='7' value.b='7' default='-'%>
    -- output '-'

Formulas should not be received from untrusted sources. They are
'eval'ed to calculate the result. Some care is taken to avoid illegal
formulas, but there are no guarantees.

When an operation cannot be performed (division by zero for instance)
the result is 'default' value or empty if not set. Illegal arguments,
such as non-numeric, produce the same result.

If a 'path' or 'template' is given then the result is shown in that
template with the following parameters:

  FORMULA   => formula with substituted values, as calculated
  RESULT    => calculation result
  ERROR     => error message if calculation could not be performed
  ERRCODE   => more concise error code (FORMULA, VALUE, FUNCTION, CALCULATE)

Some mathematical functions are also supported: min(), max(), sum(),
abs(), and sqrt(). The first three work on any number of arguments.

=head1 METHODS

=over

=cut

###############################################################################
package XAO::DO::Web::Math;
use strict;
use XAO::Utils;
use XAO::Objects;
use Error qw(:try);
use base XAO::Objects->load(objname => 'Web::Page');

###############################################################################

# Some useful functions that are not a part of standard perl

sub min (@) {
    my $a=shift;
    foreach my $b (@_) {
        $a=$b if $a>$b;
    }
    return $a;
}

sub max (@) {
    my $a=shift;
    foreach my $b (@_) {
        $a=$b if $a<$b;
    }
    return $a;
}

sub sum (@) {
    my $a=0;
    foreach my $b (@_) {
        $a+=$b;
    }
    return $a;
}

###############################################################################

my %functions=map { $_ => 1 } qw(
    min
    max
    sum
    abs
    sqrt
);

###############################################################################

sub display ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $formula=$args->{'formula'} ||
        throw $self "- need a formula";

    my $default=defined $args->{'default'} ? $args->{'default'} : '';

    my $format=$args->{'format'};

    my $result;
    my $error;
    my $errcode;

    try {
        my @fparts=split(/(\{\w+\})/,$formula);

        foreach my $part (@fparts) {
            if($part =~ /^\{(\w+)\}$/) {
                my $value=$args->{'value.'.$1} || 0;
                $value=~s/[\s\$\,_]//g;
                $value =~ /^([\d\.\+e-]+)$/ ||
                    throw $self "- {{VALUE: Illegal value for '$part'}}";
                $part=$value;
            }
            else {
                $part=~/^[\s\w\(\)\.\+\*\/,-]*$/ ||
                    throw $self "- {{FORMULA: Illegal formula part '$part'}}";

                if($part=~/(\w+)\s*\(/) {
                    $functions{$1} ||
                        throw $self "- {{FUNCTION: Illegal function '$1'}}";
                }
            }
        }

        ### dprint ".'$formula'";

        $formula=join('',@fparts);

        ### dprint "..->'$formula'";

        $result=eval '0.0+('.$formula.')';

        ### dprint "....=",$result;

        $@ && throw $self "- {{CALCULATE: Unable to calculate '$formula'}} ($@)";

        # Formatting if necessary
        #
        if($format) {
            $result=sprintf($format,$result);
            ### dprint "....=$result (formatted)";
        }
    }
    otherwise {
        my $e=shift;
        my $etext="$e";

        if($etext=~/\{\{(\w+):\s*(.*?)\s*\}\}/) {
            $errcode=$1;
            $error=$2;
        }
        else {
            $errcode='SYSTEM';
            $error=$etext;
        }

        $result=$default;

        dprint "Math error in '$formula': $error ($errcode)";
    };

    if($args->{'path'} || $args->{'template'}) {
        $self->object->display($args,{
            FORMULA     => $formula,
            RESULT      => $result,
            ERROR       => $error || '',
            ERRCODE     => $errcode || ($error ? 'UNKNOWN' : ''),
        });
    }
    else {
        $self->textout($result);
    }
}

###############################################################################
1;
__END__

=back

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2012 Andrew Maltsev

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Web::Page>.
