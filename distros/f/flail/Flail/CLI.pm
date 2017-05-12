=pod

=head1 NAME

Flail::CLI - Description

=head1 VERSION

  Time-stamp: <2006-12-04 18:00:23 attila@stalphonsos.com>

=head1 SYNOPSIS

  use Flail::CLI;
  blah;

=head1 DESCRIPTION

Describe the module.

=cut

package Flail::CLI;
use strict;
use Carp;
use Flail;
use Flail::Thing;
use Term::ReadLine;
use base qw(Flail::Thing);

sub _struct {
    shift->SUPER::_struct, (
        'cfg' => undef,
        'exec' => undef,
        'readline_obj' => ':none',
    );
}

sub init_signals {
}

sub banner {
    return <<__BaNN3r__;
flail $Flail::VERSION - the perl mua from stalphonsos.com
Copyright (C) 1999,2000 by St.Alphonsos.  All Rights Reserved.
Copyright (C) 2000-2006 by Sean Levy <snl\@cluefactory>
Email: flail\@cluefactory.com
  Web: http://flail.org

  Type "help license" for the license, "help warranty" for the non-warranty.
  Type "help brief" for a brief list of commands, and just "help" for a
  full list of commands and their syntax.
__BaNN3r__
}

sub say {
    print "** @_\n" if ($::Verbose || $::Debug);
}

sub emit {
    print "@_[1..$#_]";
}

sub print_banner { $_[0]->emit($_[0]->banner); }

sub init_readline {
    my($self) = @_;
    my $repl = $self->readline_obj;
    return $repl if ref($repl);
    $repl = Term::ReadLine->new($::P);
    $repl->ornaments(0);
    $self->readline_obj($repl);
    return $repl;
}

sub prompt_msg_summary {
    return undef;
}

sub prompt_str {
    my($self) = @_;
    my $rez = undef;
    my $proc = $::HOOKS{'__PROMPT'};
    if (defined($proc)) {
        eval {
            $rez = &$proc();
        };
        $self->emit("prompt_hook: $@") if $::Debug;
        $rez = undef if $@;
    }
    if (!defined($rez)) {
        my $sum = $self->prompt_msg_summary;
        $rez .= "$sum " if defined($sum);
        $rez .= "$::P> ";
    }
    return $rez;
}

sub readline {
    my($self) = @_;
    return $self->init_readline->readline($self->prompt_str);
}

sub cleanup {
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
