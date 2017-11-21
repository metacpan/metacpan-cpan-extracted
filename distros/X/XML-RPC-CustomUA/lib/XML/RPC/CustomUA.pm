package XML::RPC::CustomUA;
use base qw(XML::RPC);

use 5.010;
use strict;
use warnings;

our $VERSION = 0.91;

sub call {
    my $self = shift;
    my ( $methodname, @params ) = @_;

    die 'no url' if ( !$self->{url} );

    my $xml_out = $self->create_call_xml( $methodname, @params );

    $self->{xml_out} = $xml_out;

    my ( $result, $xml_in ) = $self->{tpp}->parsehttp(
        POST => $self->{url},
        $xml_out,
        {
            'Content-Type'   => 'text/xml',
            'User-Agent'     => defined($self->{tpp}->{'User-Agent'}) ? $self->{tpp}->{'User-Agent'} : 'XML-RPC/' . $VERSION,
            'Content-Length' => length($xml_out)
        }
    );

    $self->{xml_in} = $xml_in;

    my @data = $self->unparse_response($result);
    return @data == 1 ? $data[0] : @data;
}


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

XML::RPC::CustomUA - XML::RPC with custom user agent string

=head1 DEPRECATION WARNING

XML::RPC with Version 1.0 or higher now includes this patch. Don't use XML::RPC::CustomUA 1.0 (or higher) for new projects.

If at all possible, switch to the standard XML::RPC for existong projects as well! You only need to change the lines with "use" and "new", everything else is exactly the same.

=head1 SYNOPSIS

  use XML::RPC::CustomUA;
  
  my $rpcfoo = XML::RPC::CustomUA->new($apiurl, ('User-Agent' => 'Baz/3000'));

=head1 DESCRIPTION

This overloads XML::RPC to allow a custom user agent string. Everything else stays the same.

=head1 SEE ALSO

XML::RPC

=head1 WARNING

This module overrides an internal method of a module by another author. This might break in time
or might not even work for you. USE WITH CAUTION!

=head1 AUTHOR

Rene Schickbauer, E<lt>maplat@cavac.atE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
