package mRuby::Bool;
use strict;
use warnings;

use Exporter 5.57 qw/import/;
our @EXPORT_OK = qw/mrb_true mrb_false mrb_bool/;

use overload
    bool     => sub { ${+shift} },
    q{""}    => sub { ${+shift} || "" },
    q{0+}    => sub { ${+shift} || 0 },
    fallback => 1;

sub _new_bool {
    my $p = shift;
    my $class = $p ? 'mRuby::Bool::True' : 'mRuby::Bool::False';
    my $bool = bless \$p, $class;
    Internals::SvREADONLY($bool, 1);
    return $bool;
}

my $true  = _new_bool(1);
my $false = _new_bool(undef);

sub mrb_true () { ## no critic
    return $true;
}

sub mrb_false () { ## no critic
    return $false;
}

sub mrb_bool ($) { ## no critic
    my $v = shift;
    return $v ? $true : $false;
}

package # hide from PAUSE
    mRuby::Bool::True;
our @ISA = qw/mRuby::Bool/;

package # hide from PAUSE
    mRuby::Bool::False;
our @ISA = qw/mRuby::Bool/;

1;
__END__

=pod

=encoding utf-8

=head1 NAME

mRuby::Bool - mruby boolean value.

=head1 SYNOPSIS

    use mRuby::Bool qw/mrb_true mrb_false mrb_bool/;

    mrb_true;    ## true in mruby context.
    mrb_false;   ## false in mruby context.
    mrb_bool(1); ## true in mruby context.

=head1 FUNCTIONS

=over

=item C<< my $bool = mrb_true() : mRuby::Bool::True >>

Generate C<true> boolean value in mruby.

=item C<< my $bool = mrb_false() : mRuby::Bool::False >>

Generate C<false> boolean value in mruby.

=item C<< my $bool = mrb_bool($bool) : mRuby::Bool::True|mRuby::Bool::False >>

Generate C<true> or C<false> boolean value in mruby from C<$bool>.

=back

=cut
