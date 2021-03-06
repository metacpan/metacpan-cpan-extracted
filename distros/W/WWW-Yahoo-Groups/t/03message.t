#!/usr/bin/perl -w
use strict;
use File::Spec;

use Test::More tests => 10;
use Test::Differences;
BEGIN { use_ok 'WWW::Yahoo::Groups' }

my $w = WWW::Yahoo::Groups->new();

isa_ok( $w => 'WWW::Yahoo::Groups' );

# Our special user
$w->login( 'perligain7ya5h00grrzogups' => 'redblacktrees' );

# Our special list
my $list = eval {
    $w->list( 'www_yaho_t' );
    return $w->list();
};
if ($@ and ref $@ and $@->isa('X::WWW::Yahoo::Groups')) {
    fail("Failed setting/getting list: ".$@->error);
} elsif ($@) {
    fail("Failed setting/getting list");;
} else {
    pass("Did not fail setting list.");
}
is($list => 'www_yaho_t' => 'List set correctly.');

# Fetch message 1 - a message with no attachment
{
    my $no_attach = eval
    {
	$w->fetch_message( 1 )
    };
    if ($@ and ref $@ and $@->isa('X::WWW::Yahoo::Groups')) {
	fail("fetch 1 failed ".$@->error);
    } elsif ($@) {
	fail("fetch 1 failed, for some reason.");
	diag $@;
    } else {
	pass("fetch 1 succeeded.");
    }

    my $first_body = read_file( 'msgs_01.txt' );
    eq_or_diff ($no_attach => $first_body, 'Retrieved message 1 correctly');
}

# Second message, with attachment
{
    my $attach = eval
    {
	$w->fetch_message( 2 )
    };
    if ($@ and ref $@ and $@->isa('X::WWW::Yahoo::Groups')) {
	fail("fetch 2 failed ".$@->error);
    } elsif ($@) {
	fail("fetch 2 failed, for some reason.");
	diag $@;
    } else {
	pass("fetch 2 succeeded.");
    }

    my $second_body = read_file( 'msgs_02.txt' );
    eq_or_diff ($attach => $second_body, 'Retrieved message 2 correctly');
}

# Third message, non-existent
{
    my $attach = eval
    {
	$w->fetch_message( 242390 )
    };
    if ($@ and ref $@ and $@->isa('X::WWW::Yahoo::Groups::NotThere')) {
	pass("fetch 3 failed ".$@->error);
    } elsif ($@) {
	fail("fetch 3 failed, for some reason.");
	diag $@;
    } else {
	fail("fetch 3 succeeded. Should not have");
    }
}


pass("All done");

sub read_file {
    my $file = shift;
    $file = File::Spec->catfile( 't', $file ) if -d 't';
    open my $fh, '<', $file or die $!;
    my $rv;
    read( $fh, $rv, -s $fh );
    $rv;
}
