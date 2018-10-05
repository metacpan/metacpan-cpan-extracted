package WebService::Google::Client::Util;
our $VERSION = '0.07';

# ABSTRACT: Portable functions

# use Exporter 'import'; # gives you Exporter's import() method directly
# our @EXPORT_OK = qw(substitute_placeholders);  # symbols to export on request

use Moo;
use Log::Log4perl::Shortcuts qw(:all);

has 'debug' => ( is => 'rw', default => 0, lazy => 1 );

# has 'calendarId' => ( is => 'rw' );

use Data::Dumper;


sub substitute_placeholders {
    my ( $self, $string, $parameters ) = @_;

    # find all parameters in string
    my @matches = $string =~ /{[-+]?([a-zA-Z_]+)}/g;

    warn "Util substitute_placeholders() matches: " . Dumper \@matches
      if ( $self->debug );

    for my $prm (@matches) {

        # warn $prm;
        if ( defined $parameters->{$prm} ) {
            my $s = $parameters->{$prm};
            warn "Value of " . $prm . " took from passed parameters: " . $s
              if ( $self->debug );
            $string =~ s/{[+-]?$prm}/$s/g;

            #}
            #  elsif (defined $self->$prm) {
            #   my $s = $self->$prm;
            #   warn "Value of ".$prm." took from class attributes: ".$s;
            #   $string =~ s/{$prm}/$s/g;
        }
        else {
            die "cant replace " . $prm . " placeholder: no source";
        }
    }
    return $string;
}


sub substitute_placeholder {
    my ( $self, $string, $var ) = @_;
    my $param_name;
    if ( $string =~ /{([a-zA-Z]+)}/ ) {
        $param_name = $1;
    }
    if ( defined $var ) {
        $string =~ s/{([a-zA-Z]+)}/$var/;
    }
    else {
        my $subst = $self->$param_name;
        $string =~ s/{([a-zA-Z]+)}/$subst/;
    }
    return $string;
}

1;

__END__

=pod

=head1 NAME

WebService::Google::Client::Util - Portable functions

=head1 VERSION

version 0.07

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
