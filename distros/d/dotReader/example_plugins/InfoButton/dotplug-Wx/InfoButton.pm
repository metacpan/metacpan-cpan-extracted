package dtRdr::GUI::Wx::Plugins::InfoButton;
# note the full package name, even though this is in a plug-wx directory

use warnings;
use strict;

our $VERSION = '0.01';

use constant {
  NAME => 'Info Button',
  DESCRIPTION => 'General-purpose toolbar button linking to information.',
};

use dtRdr::PluginHelpers::Data qw(DATA_DIR load_yml_files);

=head1 NAME

dtRdr::GUI::Wx::Plugins::InfoButton - a button/plugin demo

=head1 SYNOPSIS

=cut


=head2 init

This is the simplest form of plugin.  It is just a class method that
does something with the frame.

  dtRdr::GUI::Wx::Plugins::InfoButton->init($frame);

=cut

sub init {
  my $package = shift;
  my ($frame) = @_;

  my $data_dir = $package->DATA_DIR;
  my %infos = $package->load_yml_files($data_dir);
  foreach my $item (keys(%infos)) {
    my $info = $infos{$item};
    my $url = $info->{url};
    my $icon =  $data_dir . $info->{icon};
    unless(defined($url)) {
      $frame->error("url is undefined in '$item'");
      next;
    }
    unless(-e $icon) {
      next;
      $frame->error("missing icon file '$icon' in '$item'");
    }
    my $tool = $frame->menumap->append_toolbar(
      name    => 'dr_info',
      icon    => $icon,
      tooltip => $info->{tooltip},
      action  => sub { $frame->bv_manager->load_url($url); },
    );
  }
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
