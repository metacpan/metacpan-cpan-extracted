use strict;
use warnings;

use PerlIO ();
my %Layers;

sub get_layers {
    my $fh = shift;
    return { map {$_ => 1} PerlIO::get_layers($fh) };
}

BEGIN {
    $Layers{STDERR} = get_layers(*STDERR);
    $Layers{STDOUT} = get_layers(*STDOUT);
}

use Test2::Plugin::TermEncoding;
use Test2::Tools::Basic;
use Test2::Tools::Compare;
use Test2::API qw(test2_stack);

use Term::Encoding;

note "pragma"; {
    ok(utf8::is_utf8("発"), "utf8 pragma is on");
}

note "io_layers"; {
    is get_layers(*STDOUT), $Layers{STDOUT}, "STDOUT encoding is untouched";
    is get_layers(*STDERR), $Layers{STDERR}, "STDERR encoding is untouched";
}

note "format_handles"; {
    my $encoding = (-t STDOUT) ? Term::Encoding::term_encoding : 'utf8';
    my $format = test2_stack()->top->format;
    my $handles = $format->handles;
    for my $hn (0 .. @$handles) {
        my $h = $handles->[$hn] || next;
        my $layers = get_layers($h);
        ok($layers->{$encoding}, "encoding: $encoding is on for formatter handle $hn");
    }
}

done_testing;
