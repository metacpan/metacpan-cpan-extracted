package App::SmokeBrew::Plugin::Null;
$App::SmokeBrew::Plugin::Null::VERSION = '0.48';
#ABSTRACT: A smokebrew plugin for does nothing.

use strict;
use warnings;

use Moose;

with 'App::SmokeBrew::PerlVersion', 'App::SmokeBrew::Plugin';

sub configure {
  return 1;
}

no Moose;

__PACKAGE__->meta->make_immutable;

qq[Smokin'];

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SmokeBrew::Plugin::Null - A smokebrew plugin for does nothing.

=head1 VERSION

version 0.48

=head1 SYNOPSIS

  smokebrew --plugin App::SmokeBrew::Plugin::Null

=head1 DESCRIPTION

App::SmokeBrew::Plugin::CPANPLUS::YACSmoke is a L<App::SmokeBrew::Plugin> for L<smokebrew> which
does nothing.

This plugin merely returns when C<configure> is called, leaving the given perl installation un-configured.
=head1 METHODS

=over

=item C<configure>

Returns true as soon as it is called.

=back

=head1 SEE ALSO

L<App::SmokeBrew::Plugin>

L<smokebrew>

L<CPANPLUS>

L<CPANPLUS::YACSmoke>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
