#line 1
# $Id: ParserFactory.pm,v 1.13 2002/11/19 18:25:47 matt Exp $

package XML::SAX::ParserFactory;

use strict;
use vars qw($VERSION);

$VERSION = '1.01';

use Symbol qw(gensym);
use XML::SAX;
use XML::SAX::Exception;

sub new {
    my $class = shift;
    my %params = @_; # TODO : Fix this in spec.
    my $self = bless \%params, $class;
    $self->{KnownParsers} = XML::SAX->parsers();
    return $self;
}

sub parser {
    my $self = shift;
    my @parser_params = @_;
    if (!ref($self)) {
        $self = $self->new();
    }
    
    my $parser_class = $self->_parser_class();

    my $version = '';
    if ($parser_class =~ s/\s*\(([\d\.]+)\)\s*$//) {
        $version = " $1";
    }

    {
        no strict 'refs';
        if (!keys %{"${parser_class}::"}) {
            eval "use $parser_class $version;";
        }
    }

    return $parser_class->new(@parser_params);
}

sub require_feature {
    my $self = shift;
    my ($feature) = @_;
    $self->{RequiredFeatures}{$feature}++;
    return $self;
}

sub _parser_class {
    my $self = shift;

    # First try ParserPackage
    if ($XML::SAX::ParserPackage) {
        return $XML::SAX::ParserPackage;
    }

    # Now check if required/preferred is there
    if ($self->{RequiredFeatures}) {
        my %required = %{$self->{RequiredFeatures}};
        # note - we never go onto the next try (ParserDetails.ini),
        # because if we can't provide the requested feature
        # we need to throw an exception.
        PARSER:
        foreach my $parser (reverse @{$self->{KnownParsers}}) {
            foreach my $feature (keys %required) {
                if (!exists $parser->{Features}{$feature}) {
                    next PARSER;
                }
            }
            # got here - all features must exist!
            return $parser->{Name};
        }
        # TODO : should this be NotSupported() ?
        throw XML::SAX::Exception (
                Message => "Unable to provide required features",
            );
    }

    # Next try SAX.ini
    for my $dir (@INC) {
        my $fh = gensym();
        if (open($fh, "$dir/SAX.ini")) {
            my $param_list = XML::SAX->_parse_ini_file($fh);
            my $params = $param_list->[0]->{Features};
            if ($params->{ParserPackage}) {
                return $params->{ParserPackage};
            }
            else {
                # we have required features (or nothing?)
                PARSER:
                foreach my $parser (reverse @{$self->{KnownParsers}}) {
                    foreach my $feature (keys %$params) {
                        if (!exists $parser->{Features}{$feature}) {
                            next PARSER;
                        }
                    }
                    return $parser->{Name};
                }
                XML::SAX->do_warn("Unable to provide SAX.ini required features. Using fallback\n");
            } 
            last; # stop after first INI found
        }
    }

    if (@{$self->{KnownParsers}}) {
        return $self->{KnownParsers}[-1]{Name};
    }
    else {
        return "XML::SAX::PurePerl"; # backup plan!
    }
}

1;
__END__

#line 231

