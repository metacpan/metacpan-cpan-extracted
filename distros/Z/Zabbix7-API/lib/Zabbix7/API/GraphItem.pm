package Zabbix7::API::GraphItem;

use strict;
use warnings;
use 5.010;
use Carp;

use Moo;
extends qw/Exporter Zabbix7::API::CRUDE/;

1;
__END__
=pod

=head1 NAME

Zabbix7::API::GraphItem -- Zabbix graph item objects

=head1 SYNOPSIS

  my $graph = $zabbix->fetch_single('Graph', params => { ... });
  
  # get existing GraphItem objects
  my $graph_items = $graph->graphitems;
  
  # create some more
  my $items = $zabbix->fetch('Item', params => { ... });
  $graph->add_items(@{$items});
  $graph->update;

=head1 DESCRIPTION

While technically a subclass of L<Zabbix7::API::CRUDE>, this class
does not actually implement all methods necessary to behave as a
full-fledged Zabbix object.  Instead, we recommend using
L<Zabbix7::API::GraphItem> objects via their parent
L<Zabbix7::API::Graph> object.  This is in part due to the fact that
the server's API does not implement all methods, only
C<graphitem.get>.  Calls to unimplemented methods will throw an
exception.

L<Zabbix7::API::GraphItem> objects will be automatically created from
a L<Zabbix7::API::Graph> object's properties whenever it is pulled
from the server.  Conversely, if you call the L<Zabbix7::API::Graph>
C<add_items> method, which creates new L<Zabbix7::API::GraphItem>
objects for you, or if you add them manually to a
L<Zabbix7::API::Graph> object (for greater control and customization),
the L<Zabbix7::API::GraphItem> objects will be automatically turned
into properties just before a call to C<create> or C<update>, causing
the relevant graph item objects to be created or updated on the
server.

=head1 SEE ALSO

L<Zabbix7::API::CRUDE>, L<Zabbix7::API::Graph>

=head1 AUTHOR

SCOTTH

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2012, 2013, 2014 SFR
Copyright (C) 2020 Fabrice Gabolde
Copyright (C) 2025 ScottH

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
