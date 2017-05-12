package Wiki::Toolkit::Formatter::Mediawiki::Link;

use warnings;
use strict;

=head1 NAME

Wiki::Toolkit::Formatter::Mediawiki::Link - Link object returned by Wiki::Toolkit::Formatter::Mediawiki's
find_internal_links method.

=cut

our $VERSION = $Wiki::Toolkit::Formatter::Mediawiki::VERSION;

=head1 SYNOPSIS

This package implements a link object for the Wiki::Toolkit::Formatter::Mediawiki 
which stores a link 'name' and its 'type' be it page, external, or a template link. 
If both 'name' and 'type' are not provided, the method returns undef. 

    use Wiki::Toolkit
    use Wiki::Toolkit::Store::Mediawiki;
    use Wiki::Toolkit::Formatter::Mediawiki;
    
    my $store = Wiki::Toolkit::Store::Mediawiki->new ( ... );
    # See below for parameter details.
    my $formatter = Wiki::Toolkit::Formatter::Mediawiki->new (%config,
							      store => $store);
    my $wiki = Wiki::Toolkit->new (store => $store, formatter => $formatter);
    
    my $content = $config{wiki}->retrieve_node ($node);
    my @links_to = $config{formatter}->find_internal_links ($content);
    
    foreach my $link (@links_to){
	print $link . "\n"
	  unless $link->{type} eq 'EXTERNAL';
    }

=cut


use overload ('""' => '_string');


=head1 METHODS

=head2 new

=cut

sub new
{
    my ($class, $name, $type) = @_;

    my $self = {};
    bless $self, $class;
    return undef
      unless $name && $type;
    $self->{name} = $name;
    $self->{type} = $type;

    return $self;
}

# Overload the stringify.
sub _string {
  my $this = shift;

  return $this->{name};
}


=head1 SEE ALSO

=over 4

=item L<Wiki::Toolkit::Kwiki>

=item L<Wiki::Toolkit>

=item L<Wiki::Toolkit::Formatter::Mediawiki>

=item L<Wiki::Toolkit::Store::Mediawiki>

=back

=head1 AUTHOR

Derek R. Price, C<< <derek at ximbiot.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-wiki-formatter-mediawiki-link at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Wiki-Toolkit-Formatter-Mediawiki-Link>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Wiki::Toolkit::Formatter::Mediawiki::Link

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Wiki-Toolkit-Formatter-Mediawiki-Link>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Wiki-Toolkit-Formatter-Mediawiki-Link>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Wiki-Toolkit-Formatter-Mediawiki-Link>

=item * Search CPAN

L<http://search.cpan.org/dist/Wiki-Toolkit-Formatter-Mediawiki-Link>

=back

=head1 ACKNOWLEDGEMENTS

My thanks go to Kake Pugh, for providing the well written L<Wiki::Toolkit> and
L<Wiki::Toolkit::Kwiki> modules, which got me started on this.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Ximbiot LLC., all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Wiki::Toolkit::Formatter::Mediawiki::Link
