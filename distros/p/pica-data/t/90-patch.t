use strict;
use Test::More;
use Test::Exception;
use PICA::Data ':all';

is_diff("", "001A \$x0", "+ 001A \$x0", 'add field');
is_diff("001A \$x0", "", "- 001A \$x0", 'remove field');
is_diff("001A \$x0", "001A \$x0\n002A \$x0", '+ 002A $x0', 'append field');
is_diff("001A \$x0\n002A \$x0", "001A \$x0", '- 002A $x0', 'remove last field');
is_diff("001A \$x0\n002A \$x0", "001A \$x0\n002A \$y1",
    "- 002A \$x0\n+ 002A \$y1", 'changed field');
is_diff("001A \$x0\n002A \$x0", "002A \$x0\n001A \$x0", '', 'compare sorted');

is_patch("001A \$x.", "+ 001A \$y.", "001A \$x.\n001A \$y.", 'add same field id');
is_patch("002A \$x.", "+ 001A \$y.", "001A \$y.\n002A \$x.", 'add before first field');
is_patch("001A \$x.", "- 001A \$x.\n+ 001A \$y.", "001A \$y.", 'replace field id');

is_patch("003@ \$01", "  003@ \$01", "003@ \$01", 'nothing changed');
is_patch("003@ \$01\n099X \$01", "  003@ \$01", "003@ \$01\n099X \$01", 'nothing changed');
is_patch("001A \$x.\n003@ \$01", "  003@ \$01", "001A \$x.\n003@ \$01", 'nothing changed');

# TODO: ignore non-existing fields to remove


# TODO: test keeping same fields before and after modifications
# my $s = "000A \$0.";
# is_patch("$s\n001A \$x.", "  $s\n+ 001A \$y.", "$s\n001A \$x.\n001A \$y.", 'add same field id');
#
# $s = "009A \$0.";
# is_patch("001A \$x.\n$s", "+ 001A \$y.\n  $s", "001A \$x.\n001A \$y.\n$s", 'add same field id');


throws_ok {
    is_patch("001A \$x.", "- 001A \$y.", "");
} qr/records don't match, expected: 001A \$y\./, 'patch error';

throws_ok {
    is_patch("001A \$x0\n101A \$x0", "", "");
} qr{diff/patch only allowed on atomic records}, 'patch error';

sub is_diff {
    my ($reca, $recb) = (shift, shift);
    my $a = pica_parser(plain => \$reca)->next || [];
    my $b = pica_parser(plain => \$recb)->next || [];

    my $diff = pica_diff($a, $b);
    my $diffstr = $diff->string('plain');
    $diffstr =~ s/\n$//mg;

    is($diffstr, $_[0], "diff: $_[1]");

    # TODO: test option 'keep'
    
    test_patch($a, $diff, $b, 'reverse via patch') if $_[1] !~ 'sort';
}

sub test_patch {
    my ($record, $diff, $expect, $msg) = @_;
    is pica_patch($record, $diff)->string, pica_string($expect), $msg;
}

sub is_patch {
    my $msg = @_ > 3 ? pop @_ : 'patch';    
    my @args = map { pica_parser(plain => \$_)->next || [] } @_;
    test_patch(@args, $msg);
}

done_testing;
