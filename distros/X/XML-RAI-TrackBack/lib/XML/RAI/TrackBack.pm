package XML::RAI::TrackBack;
use strict;

use vars qw( $VERSION );
$VERSION = 0.1;

sub import {

# XML::RSS::Parser already knows about the TrackBack namespace. If we were
# using a namespace not known to the parser you would need to set it here
# before creating mappings.
# XML::RSS::Parser->register_ns_prefix('trackback','http://madskills.com/public/xml/rss/module/trackback/');
    XML::RAI::Item->add_mapping(
                                'ping',
                                'trackback:ping/@rdf:resource',
                                'trackback:ping'
    );
    XML::RAI::Item->add_mapping(
                                'pinged',
                                'trackback:about/@rdf:resource',
                                'trackback:about'
    );
}

1;

__END__

=begin

=head1 NAME

XML::RAI::TrackBack - Adds TrackBack element mappings to XML::RAI items.

=head1 SYNOPSIS

 use XML::RAI;
 use XML::RAI::TrackBack; # Automatically adds ping and pinged accessors 
                          #  to XML::RAI::Item objects.

=head1 DEPENDENCIES

L<XML::RAI> 1.3

=head1 LICENSE

The software is released under the Artistic License. The terms of
the Artistic License are described at
L<http://www.perl.com/language/misc/Artistic.html>.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, XML::RAI::TrackBack is
Copyright 2005, Timothy Appnel, cpan@timaoutloud.org. All
rights reserved.

=cut

=end
