package WWW::FreshMeat::API::Agent::XML::RPC;
use Moose::Role;
use XML::RPC;

our $VERSION = '0.01';

#requires 'session';

has 'agent' => ( 
    isa      => 'XML::RPC', 
    is       => 'ro', 
    default  => sub { XML::RPC->new( 'http://freshmeat.net/xmlrpc/' ) },
    handles  => [ qw/call/ ],
    lazy     => 1,
    required => 1,
);


no Moose::Role;

1;


__END__


=head1 NAME

WWW::FreshMeat::API::Agent::XML::RPC - Agent role to access FreshMeat XML-RPC

=head1 VERSION

Version 0.01


=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 EXPORT

None.


=head1 ATTRIBUTES

=head2 agent

Delegation of XML::RPC performed here.


=head1 METHODS

None.


=head1 AUTHOR

Barry Walsh, C<< <draegtun at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-freshmeat-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-FreshMeat-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::FreshMeat::API::Agent::XML::RPC


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-FreshMeat-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-FreshMeat-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-FreshMeat-API>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-FreshMeat-API/>

=back


=head1 ACKNOWLEDGEMENTS

=head2 XML::RPC

Thanks to Niek Albers, http://www.daansystems.com/ for his excellent L<XML::RPC> module.


=head1 SEE ALSO

=head2 Other WWW::FreshMeat::API modules

L<WWW::FreshMeat::API>


=head1 COPYRIGHT & LICENSE

Copyright 2009 Barry Walsh (Draegtun Systems Ltd), all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

