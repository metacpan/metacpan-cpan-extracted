use strict;
use warnings;

package ful;

our $VERSION = '0.03';

use Cwd;
use File::Spec;

my $cursor;

my $FS = 'File::Spec';

our $crum = undef;

sub import {
    my $me = shift;

    my @user    = caller();
    my $used_me = $user[1];

    $cursor = Cwd::abs_path($used_me);

    my %args    = ();
    my @libdirs = ('lib');

    if (@_ && ref($_[0]) eq 'HASH') {
        %args = %{$_[0]};
    }
    elsif(@_) {
        @libdirs = @_;
    }

    @libdirs = @{$args{libdirs}} if ref($args{libdirs}) eq 'ARRAY';

    if (my $file = $args{file} // $args{target_file} // $args{target}) {
        $me->_ascend until $me->_is_file($file) or $me->_heaven;
    }
    elsif (my $dir = $args{dir} // $args{has_dir} // $args{child_dir}) {
        $me->_ascend until $me->_is_dir($dir) or $me->_heaven;
    }
    elsif ($args{git}) {
        my @gitparts = qw(.git config);
        $me->_ascend until $me->_is_file(@gitparts) or $me->_heaven;
    }
    else {
        while (!$me->_heaven) {
            last if scalar @libdirs == grep { $me->_is_dir($_) } @libdirs;
            $me->_ascend;
        }
    }

    return if $me->_heaven;
    $crum = $me->_comb($cursor);
    unshift @INC => $me->_comb($cursor, $_) for @libdirs;
}

sub _is_file { -f shift->_comb($cursor, @_) }
sub _is_dir  { -d shift->_comb($cursor, @_) }
sub _comb    { $FS->catfile(@_[1..$#_])     }

sub _ascend  { $cursor = $FS->catdir(($FS->splitpath($cursor))[0..1]) }
sub _heaven  { $cursor eq $FS->rootdir }

1;

__END__