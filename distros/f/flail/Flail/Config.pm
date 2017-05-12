=pod

=head1 NAME

Flail::Config - configuration control

=head1 VERSION

  Time-stamp: <2006-12-04 18:25:45 attila@stalphonsos.com>

=head1 SYNOPSIS

  use Flail::Config;
  blah;

=head1 DESCRIPTION

Describe the module.

=cut

package Flail::Config;
use strict;
use Carp;
use Flail::Thing;
use base qw(Flail::Thing);

sub _struct {
    shift->SUPER::_struct, (
        'args' => undef,
        'globals' => {},
    );
}

sub Default {
    return $Flail::Config::FIRST;
}

sub _init_new {
    my $self = shift->SUPER::_init_new(@_);
    $Flail::Config::FIRST ||= $self;
    return $self;
}

sub load_globals_in_main {
    foreach (keys %{$self->globals}) {
        my($name,$val) = ($_,$self->globals->{$_});
        $val = &$val($self,$name) if (ref($val) eq 'CODE');
        eval "\$::${name}=\"${val}\";";
        ($::Debug || $@) && warn(qq|load_globals_in_main: $name => "$val" ($@)\n|);
    }
}

sub get {
}

sub set {
}

sub load {
}

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
