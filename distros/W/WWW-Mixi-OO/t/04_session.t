# -*- cperl -*-

use strict;
use warnings;

use Test::More;
use IO::File;
use Data::Dumper;
BEGIN {
    if ($] < 5.007) {
	plan skip_all => 'maybe Encode not found';
    }
}

use Encode;
use open ':locale';

my %login_opt;

BEGIN {
    my $dot_mixi = IO::File->new('<.mixi');
    if (!defined $dot_mixi) {
	plan skip_all => 'not specified mixi email/password';
    }
    my @fields = qw(email password);
    while (<$dot_mixi>) {
	chomp;
	next unless length;
	$login_opt{shift(@fields)} = $_;
	last unless @fields;
    }
    undef $dot_mixi;
    if (@fields) {
	plan skip_all => 'email/password data not enough';
    } else {
	plan 'no_plan'; # please supply nums for release
    }
}

my $pkg;
BEGIN {
    $pkg = 'WWW::Mixi::OO::Session';
    use_ok $pkg;
}

my $utf8_dumper = sub {
    my $text;
    $text = Dumper(shift);
    $text =~ s/\\x\{([0-9a-f]+)\}/pack('U', oct('0x'.$1))/eg;
    $text;
};

my $utf8_dump_diager = sub {
    local $SIG{__WARN__} = sub {};
    diag($utf8_dumper->(@_));
};

my $mixi;
TODO: {
    can_ok($pkg, 'new');
    can_ok($pkg, 'set_content');
    $mixi = $pkg->new(%login_opt);
    isa_ok($mixi, $pkg);
    ok($mixi->login, 'login returns true value');
    diag('session-id: ' . $mixi->session_id);
    my $page = $mixi->page('home');
    ok($page->set_content, 'set to home');
    can_ok($page, 'parse_banner');
    can_ok($page, 'parse_mainmenu');
    can_ok($page, 'parse_tool_bar');
    my @tries;
    my @tests = qw(banner mainmenu tool_bar);
    my $do_test = sub {
	my %current;
	push (@tries, \%current);
	foreach (@tests) {
	    my $method = "parse_$_";
	    $current{$_} = [$page->$method];
	    ok(@{$current{$_}} > 0, "$_ parsing successfully");
	}
    };
    $do_test->();
    $mixi->refresh_content;
    $do_test->();
    $utf8_dump_diager->($tries[0]);
    foreach (qw(mainmenu tool_bar)) {
	is_deeply((map $_->{$_}, @tries[0, 1]),
		  "2 $_ pages are identical");
    }
};
