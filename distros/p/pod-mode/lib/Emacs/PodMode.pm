package Emacs::PodMode;
BEGIN {
  $Emacs::PodMode::AUTHORITY = 'cpan:SCHWIGON';
}
BEGIN {
  $Emacs::PodMode::VERSION = '1.04';
} 
# ABSTRACT: Emacs major mode for editing .pod-files

1;


__END__
=pod

=head1 NAME

Emacs::PodMode - Emacs major mode for editing .pod-files

=head1 VERSION

version 1.04

=head1 DESRIPTION

POD is the Plain Old Documentation format of Perl. This mode supports
writing POD.

=head1 USAGE

Put the file F<pod-mode.el> into your load-path and the following into
your F<~/.emacs>:

    (autoload 'pod-mode "pod-mode"
      "Mode for editing POD files" t)

To associate pod-mode with .pod files add the following to your
F<~/.emacs>:

    (add-to-list 'auto-mode-alist '("\\.pod$" . pod-mode))

To automatically turn on font-lock-mode add the following to your
F<~/.emacs>:

    (add-hook 'pod-mode-hook 'font-lock-mode)

In addition to the standard POD commands, custom commands as defined
by a L<Pod::Weaver> configuration are supported. However, for those to
work, F<eproject.el> as available at
L<http://github.com/jrockway/eproject> is required.

Make sure to require F<eproject.el> or create an autoload for
C<eproject-maybe-turn-on> if you expect custom commands to work.

When automatically inserting hyperlink formatting codes to modules or
sections within modules, autocompletion for module names will be
provided if perldoc.el, as available at
L<git://gaffer.ptitcanardnoir.org/perldoc-el.git>, is present.

=head1 SEE ALSO

For the actual mode please refer to F<pod-mode.el>.

=head1 AUTHORS

=over 4

=item *

Steffen Schwigon <ss5@renormalist.net>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Steffen Schwigon.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

