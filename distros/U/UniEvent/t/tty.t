use 5.012;
use lib 't/lib';
use MyTest;
use UniEvent::Tty;

plan skip_all => 'Need interactive stdin, stderr' unless -t STDIN and -t STDERR;

my $l = UniEvent::Loop->default;

my $tty_out = UniEvent::Tty->new(\*STDERR);
my $tty_in  = UniEvent::Tty->new(\*STDIN);

is $tty_out->type, UniEvent::Tty::TYPE, "type ok";
is $tty_in->type, UniEvent::Tty::TYPE;

unless (win32()) {
	$tty_out->set_mode(UniEvent::Tty::MODE_STD);
	$tty_out->set_mode(UniEvent::Tty::MODE_IO);
}
$tty_in->set_mode(UniEvent::Tty::MODE_RAW);
UniEvent::Tty::reset_mode();

my ($w, $h) = $tty_out->get_winsize();
diag "$w x $h";
cmp_ok $w, '>=', 1, "Term width is natural";
cmp_ok $h, '>=', 1, "Term height is natural";

sub logo {
    local $/;
    open(my $fh, '<', 'misc/panda.txt');
    my $contents = <$fh>;
    $tty_out->write("\n".$contents);
}

logo();
$l->run;

done_testing();
