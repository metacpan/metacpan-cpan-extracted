#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Test::More;

BEGIN {
    use_ok('Wrap::Sub');
};

{
    my $w;
    my $wrap = Wrap::Sub->new;

    eval {$w = $wrap->wrap('wrap_1', pre => 'adsf'); };
    like ($@, qr/\Qwrap()'s 'pre' param\E/, "wrap() pre param needs cref");
}
{
    my $w;
    my $wrap = Wrap::Sub->new;

    eval { $w = $wrap->wrap('wrap_1', pre => sub { return 10; } ); };
    is (ref $w, 'Wrap::Sub::Child', "wrap()'s pre param works with a cref" );
}
{
    my $wrap = Wrap::Sub->new;
    my $w = $wrap->wrap('wrap_1');

    eval { $w->post('asdf'); };
    like ($@, qr/invalid parameters to post/, "post() breaks with invalid params" );
}
{
    my $w;
    my $wrap = Wrap::Sub->new;

    eval { $w = $wrap->wrap('wrap_1', post => sub { return 10; }); };
    is (ref $w, 'Wrap::Sub::Child', "wrap()'s post param works with a cref" );
}
{
    my $msg;
    local $SIG{__WARN__} = sub { $msg = shift; };

    my $wrap = Wrap::Sub->new;
    my $w = $wrap->wrap('wrap_2');

    $w->pre( sub { warn "test" ; } );

    wrap_2();

    like ($msg, qr/test/, "pre() sub does the right thing");
}
{
    my $wrap = Wrap::Sub->new;
    my $w = $wrap->wrap('wrap_3');

    $w->pre( sub { return 50; } );
    $w->post( sub { return $_[0]->[0] + 50; }, post_return => 1);

    my $ret = wrap_3();

    is ($ret, 100, "wrap() with pre() and post() pass args ok");
}
{
    my $wrap = Wrap::Sub->new;
    my $w = $wrap->wrap('wrap_1');

    $w->post(
        sub { my $x = $_[1]->[0]; $x =~ s/_1//; return $x; },
        post_return => 1
    );

    my $ret = wrap_1();

    is ($ret, 'wrap', "return param in post() works");
}
{
    my $wrap = Wrap::Sub->new;
    my $w = $wrap->wrap('wrap_3');

    $w->post( sub { shift; my @a = @{$_[0]}; return $a[0] + 500; } );

    my $ret = wrap_3();

    is ($ret, 500, "post() without return param returns original sub return");
}
{
    my ($msg, $w);
    local $SIG{__WARN__} = sub { $msg = shift; };

    my $wrap = Wrap::Sub->new;

    $w = $wrap->wrap('wrap_3', pre => sub { warn "pre"; } );

    wrap_3();

    like ($msg, qr/pre/, "pre() param in wrap() works");
    $msg = '';

    $w->pre(undef);

    wrap_3();

    is ($msg, '', "pre() with undef resets pre");
}
{
    my $wrap = Wrap::Sub->new;

    my $w = $wrap->wrap(
        'wrap_3',
        post => sub { return $_[1]->[0] + 1000; },
        post_return => 1,
    );

    my $ret = wrap_3();

    is ($ret, 1500, "post param set in wrap() ok");

    $w->post(undef);

    $ret = wrap_3();

    is ($ret, 500, "post() with undef param eliminates post");
}
{
    my $wrap = Wrap::Sub->new;

    my $w = $wrap->wrap('wrap_3');

    $w->post( sub { return $_[1]->[0] + 1000; } );

    my $ret = wrap_3();

    is ($ret, 500, "post method works with no return");

    $w->post(post_return => 1);

    $ret = wrap_3();

    is ($ret, 1500, "post method works return set, and post() can set it");

    $w->post(undef);

    $ret = wrap_3();

    is ($ret, 500, "post() with undef param eliminates post");
}

done_testing();

sub wrap_1 {
    return "wrap_1";
}
sub wrap_2 {
    my @args = @_;
    my $list = [qw(1 2 3 4 5)];
    return (@args, $list);
}
sub wrap_3 {
    return 500;
}
sub wrap_4 {
    my @args = @_;
    my @nums;
    for (@args){
        push @nums, $_ * 10;
    }
    return @nums;
}
sub wrap_5 {
    my $args = @_;
}
