package WWW::betfair::Template;
use strict;
use warnings;

=head2 populate

Returns the XML message required for the betfair API

=cut

sub populate {
    my ($uri, $action, $params) = @_;

    #handle getAccountStatement betfair syntax exception
    my $req = $action eq 'getAccountStatement' ? 'req' : 'request';
    
    my $templateHeader = qq~<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Body><$action xmlns="$uri"><$req>~;

    my $templateBody = '';
    $templateBody .= markup_data(undef,$params);
    my $templateFooter = "</$req></$action></soap:Body></soap:Envelope>";
    return $templateHeader . $templateBody . $templateFooter;
}

=head2 markup_data

Recursive tagging subroutine for a Perl data structure

=cut

sub markup_data {
    my ($key, $data) = @_;
    my $string = '';
    if (ref($data) eq 'HASH') {
        $string .= "<$key>" if $key;
        foreach (keys %{$data}) {
             $string .= markup_data($_, $data->{$_});
        }
        $string .= "</$key>" if $key;
        return $string;
    }
    elsif (ref($data) eq 'ARRAY') {
        my $string = '';
        foreach (@{$data}) {
            $string .= markup_data($key, $_);
        }
        return $string;
    }
    else {
        return "<$key>$data</$key>";
    }
} 
1;
