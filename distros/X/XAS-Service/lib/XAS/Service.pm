package XAS::Service;

use strict;
use warnings;

our $VERSION = '0.01';

1;

__END__
  
=head1 NAME

XAS::Service - A set of modules and utilities to implement Micro Services

=head1 DESCRIPTION

A Micro Service is software architectural design for software development and
deployment. If you do a google search, you will find many different opinions on
how they should work and function. 

XAS is a cross platform suite of modules and procedures. So a XAS based micro 
service would also have to be the same. Our micro services are based on 
standard Web technologies. Their interfaces are accessed over HTTP. That 
interface will be REST based. They will return either HTML or JSON depending 
on HTTP headers. The HTML interface will be a simple layer to the underlaying 
api. They have simple embedded HTTP servers. That server understands just 
enough HTTP to implement the api. It is not a full fledged HTTP server,
nor do you need one to run a XAS micro service. They will run as daemons or 
services depending on platform and this will be transparent to the code base.

=head2 HTTP SERVER

The HTTP server uses L<XAS::Lib::Net::Server|XAS::Lib::Net::Server> with the
appropriate POE filter. The filter that we are using is 
L<POE::Filter::HTTP::Parser|https://metacpan.org/pod/POE::Filter::HTTP::Parser>.
which seems to be the most up to date. 

=head2 PLACK

L<Plack|https://metacpan.org/pod/Plack> is the glue between the web interface and the web application. XAS 
depends on POE for the multi-tasking in our daemons. Surprisingly, there is 
no supported glue module between the two environmnets. So the HTTP Server 
provides that glue. This "glue" also allows us to control the service with
the standard XAS methods. A XAS micro service can be stopped, started, 
paused and resumed.

=head2 HTTP ENGINE

Once the HTTP request has been received and translated into a Plack request,
it needs to be acted upon. This is done by L<XAS::Service::Resource|XAS::Service::Resource>
which is a wrapper around L<Web::Machine|https://metacpan.org/pod/Web::Machine>.
Web::Machine is the Perl5 port of the L<Erlang Webmachine|https://github.com/webmachine/webmachine>, 
which was developed to handle the normal flow of processing for REST based 
applications.

=head2 VALIDATION

You also need to validate your input. Any posted JSON data is converted into a
L<Hash::MultiValue|https://metacpan.org/pod/Hash::MultiValue> object. This is
then used to validate the input using L<Date::FormValidator|https://metacpan.org/pod/Data::FormValidator>.
A predefined profile for the search capibility has been included. This profile 
can be combined with other profiles with L<XAS::Service::Profile|XAS::Service::Profile> and
checked with the mixin L<XAS::Service::CheckParameters|XAS::Service::CheckParamters>. 

=head2 SEARCH

Any mirco service that involves a database needs search capability. 
L<XAS::Service::Search|XAS::Service::Search> provides that capability. 

With the combination of these modules, you can build reliable micro services
quickly and easily.

=head1 SEE ALSO

=over 4

=item L<Plack|https://metacpan.org/pod/Plack>

=item L<Web::Machine|https://metacpan.org/pod/Web::Machine>

=item L<Erlang Webmachine|https://github.com/webmachine/webmachine>

=item L<POE::Filter::HTTP::Parser|https://metacpan.org/pod/POE::Filter::HTTP::Parser>

=item L<Hash::MultiValue|https://metacpan.org/pod/Hash::MultiValue>

=item L<Data::FormValidator|https://metacpan.org/pod/Data::FormValidator>

=item L<XAS::Lib::Net::Server|XAS::Lib::Net::Server>

=item L<XAS::Service::Server|XAS::Service::Server>

=item L<XAS::Service::Profile|XAS::Service::Profile>

=item L<XAS::Service::CheckParameters|XAS::Service::CheckParamters>

=item L<XAS::Service::Search|XAS::Service::Search>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
