# Copyrights 2009-2013 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package XML::Compile::RPC::Util;
use vars '$VERSION';
$VERSION = '0.17';

use base 'Exporter';

our @EXPORT = qw/
   struct_to_hash
   struct_to_rows
   struct_from_rows
   struct_from_hash

   rpcarray_values
   rpcarray_from

   fault_code
   fault_from
  /;


sub struct_to_hash($)
{   my $s = shift;
    my %h;

    foreach my $member ( @{$s->{member} || []} )
    {   my ($type, $value) = %{$member->{value}};
        $h{$member->{name}} = $value;
    }

    \%h;
}


sub struct_to_rows($)
{   my $s = shift;
    my @r;

    foreach my $member ( @{$s->{member} || []} )
    {   my ($type, $value) = %{$member->{value}};
        push @r, [ $member->{name}, $type, $value ];
    }

    @r;
}


sub struct_from_rows(@)
{   my @members = map { +{name => $_->[0], value => {$_->[1] => $_->[2]}}} @_;
   +{ struct => {member => \@members} };
}


sub struct_from_hash($$)
{   my ($type, $hash) = @_;
    my @members = map { +{name => $_, value => {$type => $hash->{$_}}} }
        sort keys %{$hash || {}};
   +{ struct => {member => \@members} };
}


sub rpcarray_values($)
{   my $rpca = shift;
    my @v;
    foreach ( @{$rpca->{data}{value} || []} )
    {   my ($type, $value) = %$_;
        push @v, $value;
    }
    @v;
}


sub rpcarray_from($@)
{   my $type = shift;
    my @values = map { +{$type => $_} } @_;
    +{array => {data => {value => \@values}}};
}


sub fault_code($)
{   my $h  = struct_to_hash shift->{value}{struct};
    my $fc = $h->{faultCode} || -1;
    wantarray ? ($fc, $h->{faultString}) : $fc;
}


sub fault_from($$)
{   my ($rc, $msg) = @_;
    my @rows = ([faultCode => int => $rc], [faultString => string => $msg]);
    +{fault => {value => struct_from_rows(@rows)}};
}

1;
