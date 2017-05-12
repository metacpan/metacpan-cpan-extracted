
package WWW::EchoNest::Proxy;

use 5.010;
use strict;
use warnings;
use Carp;

use WWW::EchoNest;
our $VERSION = $WWW::EchoNest::VERSION;

use WWW::EchoNest::Util qw( call_api );

BEGIN {
    our @EXPORT        = ();
    our @EXPORT_OK     = ();
}
use parent qw[ Exporter ];


sub new {
    my($class, $args_ref)    = @_;
    my $object_type          = $args_ref->{object};
    croak 'No object field'  if ! $object_type;

    my $types_alternation
        = join ( '|', qw( artist catalog playlist song track ) );
    
    croak "Unrecognized type: $object_type"
        if $object_type !~ /$types_alternation/;

    return bless ( $args_ref, ref($class) || $class );
}

sub get_attribute {
    my($self, $args_ref)    = @_;
    my $object              = $self->{object};
    my $method              = delete $args_ref->{method};
    my $api_method          = "$object/$method";

    croak 'no object type'  if ! $object;
    croak 'no method'       if ! $method;

    my $result = call_api(
                          {
                           format    => 'json',
                           method    => $api_method,
                           params    => $args_ref,
                          }
                         );
    
    return $result->{response};
}

sub post_attribute {
    my($self, $args_ref) = @_;
    
    my $method   = delete $args_ref->{method};
    my $data     = delete $args_ref->{data};
    
    my $object_type  = $self->{object};
    my $api_method   = "$object_type/$method";
    
    croak "invalid method: $method"    if $method !~ /\w/;
    croak 'No object type provided!'   if ! $object_type;
    
    my $api_call = call_api(
                            {
                             format      => 'json',
                             method      => $api_method,
                             post        => 1,
                             data        => $data,
                             params      => $args_ref,
                            },
                           );
    return $api_call->{response};
}

1;

__END__



=head1 NAME

WWW::EchoNest::Proxy
For internal use only!

=head1 AUTHOR

Brian Sorahan, C<< <bsorahan@gmail.com> >>

=head1 SUPPORT

Join the Google group: <http://groups.google.com/group/www-echonest>

=head1 ACKNOWLEDGEMENTS

Thanks to all the folks at The Echo Nest for providing access to their
powerful API.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Brian Sorahan.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
