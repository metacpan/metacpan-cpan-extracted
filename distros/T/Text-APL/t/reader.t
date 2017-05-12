use strict;
use warnings;
use utf8;

use Test::More;

use Text::APL::Reader;

is_deeply reader(\'foo'), ['foo', undef];

is_deeply reader('t/template'), ["Hello.Привет.\n", undef];

open my $fh, '<:encoding(UTF-8)', 't/template';
is_deeply reader($fh), ["Hello.Привет.\n", undef];
close $fh;

is_deeply reader(sub { $_[0]->('foo') }), ['foo'];

sub reader {
    my @args  = @_;
    my $stack = [];
    my $reader = Text::APL::Reader->new(charset => 'UTF-8')->build(@_);
    $reader->(sub { push @$stack, $_[0] });
    return $stack;
}

done_testing;
