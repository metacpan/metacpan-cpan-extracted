=pod

=head1 NAME

Flail::module - Description

=head1 VERSION

  Time-stamp: <2006-12-01 14:55:33 attila@stalphonsos.com>

=head1 SYNOPSIS

  use Flail::module;
  blah;

=head1 DESCRIPTION

Describe the module.

=cut

package Flail::module;
use strict;
use Carp;
use base qw(Exporter);

sub new { bless({ @_[1..$#_] },ref($_[0]) || $_[0]); }

1;

__END__

=pod

=head1 AUTHOR

  attila <attila@stalphonsos.com>

=head1 COPYRIGHT AND LICENSE

  (C) 2002-2006 by attila <attila@stalphonsos.com>.  all rights reserved.

  This code is released under a BSD license.  See the LICENSE file
  that came with the package.

=cut

##
# Local variables:
# mode: perl
# tab-width: 4
# perl-indent-level: 4
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# indent-tabs-mode: nil
# comment-column: 40
# time-stamp-line-limit: 40
# End:
##
