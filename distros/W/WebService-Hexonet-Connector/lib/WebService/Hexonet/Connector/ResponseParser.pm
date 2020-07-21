package WebService::Hexonet::Connector::ResponseParser;

use 5.030;
use strict;
use warnings;

use version 0.9917; our $VERSION = version->declare('v2.10.0');


sub parse {
    my $response = shift;
    my %hash     = ();
    $response =~ s/\r\n/\n/gmsx;
    foreach ( split /\n/msx, $response ) {
        if (/^([^\=]*[^\t\= ])[\t ]*=[\t ]*(.+)/msx) {
            my $attr  = $1;
            my $value = $2;
            $value =~ s/[\t ]*$//msx;
            if ( $attr =~ /^property\[([^\]]*)\]/imsx ) {
                if ( !defined $hash{PROPERTY} ) {
                    $hash{PROPERTY} = {};
                }
                my $prop = uc $1;
                $prop =~ s/\s//ogmsx;
                if ( defined $hash{PROPERTY}{$prop} ) {
                    push @{ $hash{PROPERTY}{$prop} }, $value;
                } else {
                    $hash{PROPERTY}{$prop} = [ $value ];
                }
            } else {
                $hash{ uc $attr } = $value;
            }
        }
    }
    return \%hash;
}


sub serialize {
    my $h     = shift;
    my $plain = '[RESPONSE]';
    if ( defined $h->{PROPERTY} ) {
        my $props = $h->{PROPERTY};
        foreach my $key ( sort keys %{$props} ) {
            my $i = 0;
            foreach my $val ( @{ $props->{$key} } ) {
                $plain .= "\r\nPROPERTY[${key}][${i}]=${val}";
                $i++;
            }
        }
    }
    if ( defined $h->{CODE} ) {
        $plain .= "\r\nCODE=" . $h->{CODE};
    }
    if ( defined $h->{DESCRIPTION} ) {
        $plain .= "\r\nDESCRIPTION=" . $h->{DESCRIPTION};
    }
    if ( defined $h->{QUEUETIME} ) {
        $plain .= "\r\nQUEUETIME=" . $h->{QUEUETIME};
    }
    if ( defined $h->{RUNTIME} ) {
        $plain .= "\r\nRUNTIME=" . $h->{RUNTIME};
    }
    $plain .= "\r\nEOF\r\n";
    return $plain;
}

1;

__END__

=pod

=head1 NAME

WebService::Hexonet::Connector::ResponseParser - Library that provides functionality to parse
plain-text API response data into Hash format and to serialize it back to plain-text format
if necessary.

=head1 SYNOPSIS

This module is internally used by the WebService::Hexonet::Connector::Response module.
To be used in the way:

    # specify the API plain-text response (this is just an example that won't fit to the command above)
    $plain = "[RESPONSE]\r\nCODE=200\r\nDESCRIPTION=Command completed successfully\r\nEOF\r\n";

    # parse a plain-text response into hash
    $hash = WebService::Hexonet::Connector::ResponseParser::parse($plain);

    # serialize that hash format back to plain-text
    $plain = WebService::Hexonet::Connector::ResponseParser::serialize($hash);

=head1 DESCRIPTION

HEXONET Backend API always responds in plain-text format that needs to get parsed into a useful data structure.
Within automated tests we also need the reverse way to serialize a parsed response back to plain-text.
This module cares about exactly all that.


=head2 Methods

=over

=item C<parse( $plain )>

Returns the parsed API response as Hash.
Specifiy the plain-text API response as $plain.

=item C<serialize( $hash )>

Returns the serialized API response as string. 
Specifiy the hash notation of the API response as $hash.

=back

=head1 LICENSE AND COPYRIGHT

This program is licensed under the L<MIT License|https://raw.githubusercontent.com/hexonet/perl-sdk/master/LICENSE>.

=head1 AUTHOR

L<HEXONET GmbH|https://www.hexonet.net>

=cut
