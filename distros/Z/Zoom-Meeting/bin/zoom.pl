# PODNAME: zoom.pl
# ABSTRACT: Example script to launch Zoom

use v5.37.12;

use lib "$ENV{HOME}/Zoom-Meeting/lib";
use lib "$ENV{HOME}/perl5/lib/perl5";
# use lib '/usr/local/lib/perl5/5.37.12/';

use Zoom::Meeting;

my $zoom = Zoom::Meeting -> new (id => '0' x 11);
# Create object with required ID

say $zoom -> password('NEW_PASS');
# Set password via a method call

say $zoom;
# Show the URL

$zoom -> launch;
# Launch Windows Zoom from WSL

__END__

=pod

=encoding UTF-8

=head1 NAME

zoom.pl - Example script to launch Zoom

=head1 VERSION

version 0.231740

=head1 AUTHOR

Elvin Aslanov <rwp.primary@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Elvin Aslanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
