#line 1
package Exporter::Lite;

require 5.004;

# Using strict or vars almost doubles our load time.  Turn them back
# on when debugging.
#use strict 'vars';  # we're going to be doing a lot of sym refs
#use vars qw($VERSION @EXPORT);

$VERSION = 0.02;
@EXPORT = qw(import);   # we'll know pretty fast if it doesn't work :)



sub import {
    my($exporter, @imports)  = @_;
    my($caller, $file, $line) = caller;

    unless( @imports ) {        # Default import.
        @imports = @{$exporter.'::EXPORT'};
    }
    else {
        # Because @EXPORT_OK = () would indicate that nothing is
        # to be exported, we cannot simply check the length of @EXPORT_OK.
        # We must to oddness to see if the variable exists at all as
        # well as avoid autovivification.
        # XXX idea stolen from base.pm, this might be all unnecessary
        my $eokglob;
        if( $eokglob = ${$exporter.'::'}{EXPORT_OK} and *$eokglob{ARRAY} ) {
            if( @{$exporter.'::EXPORT_OK'} ) {
                # This can also be cached.
                my %ok = map { s/^&//; $_ => 1 } @{$exporter.'::EXPORT_OK'},
                                                 @{$exporter.'::EXPORT'};

                my($denied) = grep {s/^&//; !$ok{$_}} @imports;
                _not_exported($denied, $exporter, $file, $line) if $denied;
            }
            else {      # We don't export anything.
                _not_exported($imports[0], $exporter, $file, $line);
            }
        }
    }

    _export($caller, $exporter, @imports);
}



sub _export {
    my($caller, $exporter, @imports) = @_;

    # Stole this from Exporter::Heavy.  I'm sure it can be written better
    # but I'm lazy at the moment.
    foreach my $sym (@imports) {
        # shortcut for the common case of no type character
        (*{$caller.'::'.$sym} = \&{$exporter.'::'.$sym}, next)
            unless $sym =~ s/^(\W)//;

        my $type = $1;
        my $caller_sym = $caller.'::'.$sym;
        my $export_sym = $exporter.'::'.$sym;
        *{$caller_sym} =
            $type eq '&' ? \&{$export_sym} :
            $type eq '$' ? \${$export_sym} :
            $type eq '@' ? \@{$export_sym} :
            $type eq '%' ? \%{$export_sym} :
            $type eq '*' ?  *{$export_sym} :
            do { require Carp; Carp::croak("Can't export symbol: $type$sym") };
    }
}


#"#
sub _not_exported {
    my($thing, $exporter, $file, $line) = @_;
    die sprintf qq|"%s" is not exported by the %s module at %s line %d\n|,
        $thing, $exporter, $file, $line;
}

1;

__END__

#line 196
