package mRuby::Symbol;
use strict;
use warnings;

use Exporter 5.57 qw/import/;
our @EXPORT_OK = qw/mrb_sym/;

use overload
    q{""} => sub { ${+shift} },
    fallback => 1;

sub mrb_sym ($) { ## no critic
    my $v = shift;
    return bless \$v, __PACKAGE__;
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

mRuby::Symbol - mruby symbol value.

=head1 SYNOPSIS

    use mRuby::Symbol qw/mrb_sym/;

    mrb_sym('foo'); ## :foo in mruby context.

=head1 FUNCTIONS

=over

=item C<< my $sym = mrb_sym($str) : mRuby::Symbol >>

Generate symbol value named C<$str> in mruby.

=back

=cut
