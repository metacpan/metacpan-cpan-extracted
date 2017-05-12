use strict;
use warnings;

use Test::More;

use Text::APL::Writer;

my $output = '';
writer('foo', \$output);
is $output, 'foo';

$output = '';
writer('foo', sub { $output = $_[0] });
is $output, 'foo';

unlink 't/template.out';

writer('foo', 't/template.out');
is do { local $/; open my $fh, '<', 't/template.out'; <$fh> }, 'foo';

open my $fh, '>', 't/template.out';
writer('foo', $fh);
close $fh;
is do { local $/; open my $fh, '<', 't/template.out'; <$fh> }, 'foo';

unlink 't/template.out';

sub writer {
    my ($input, $arg) = @_;

    my $writer = Text::APL::Writer->new->build($arg);
    $writer->($input);
}

done_testing;
