package XML::Validator::Schema::Util;
use strict;
use warnings;

=head1 NAME

XML::Validator::Schema::Util

=head1 DESCRIPTION

This is an internal module containing a few commonly used functions.

=cut

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(_attr _err XSD);
use XML::SAX::Exception;

# setup an exception class for validation errors
@XML::SAX::Exception::Validator::ISA = qw(XML::SAX::Exception);

use constant XSD => 'http://www.w3.org/2001/XMLSchema';

# get an attribute value by name, ignoring namespaces
sub _attr {
    my ($data, $name) = @_;
    return $data->{Attributes}{'{}' . $name}{Value}
      if exists $data->{Attributes}{'{}' . $name};
    foreach my $attr (keys %{$data->{Attributes}}) {
        return $data->{$attr}->{Value} if $attr =~ /^\{.*?\}$name/;
    }
    return;
}

# throw a validator exception
sub _err {
    XML::SAX::Exception::Validator->throw(Message => shift);
}



1;
