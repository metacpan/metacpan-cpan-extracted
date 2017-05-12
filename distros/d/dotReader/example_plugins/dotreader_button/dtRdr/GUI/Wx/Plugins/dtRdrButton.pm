package dtRdr::GUI::Wx::Plugins::dtRdrButton;

use warnings;
use strict;

our $VERSION = '0.01';

use constant {
  NAME => 'dotReader Info Button',
  DESCRIPTION => 'Toolbar button for info on customizing dotReader.',
};

use dtRdr::PluginHelpers::Data qw(DATA_DIR);

=head1 NAME

dtRdr::GUI::Wx::Plugins::dtRdrButton - a button/plugin demo

=head1 SYNOPSIS

=cut


=head2 init

This is the simplest form of plugin.  It is just a class method that
does something with the frame.

  dtRdr::GUI::Wx::Plugins::dtRdrButton->init($frame);

=cut

sub init {
  my $package = shift;
  my ($frame) = @_;

  my $url = 'http://www.dotreader.com/site/?q=node/131';
  my $icon = $package->DATA_DIR . 'dotreader.png';
  my $tool = $frame->menumap->append_toolbar(
    name    => 'dr_home',
    icon    => $icon,
    tooltip => 'Customization Info',
    action  => sub { $frame->bv_manager->load_url($url); },
  );
} # end subroutine init definition
########################################################################


=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2006 Eric L. Wilhelm and OSoft, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatseover.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
