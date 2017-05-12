#!perl
use strict;
use Benchmark qw(:all);
use Config; printf "Perl/%vd on %s\n", $^V, $Config{archname};

use Text::ClearSilver;
use ClearSilver;
use Data::ClearSilver::HDF;

print "Text::ClearSilver/$Text::ClearSilver::VERSION\n";

my $template = <<'CS_END';
Hello, <?cs var:lang ?> world!

<?cs each:item = list ?>
    <?cs name:item ?> - <?cs var:item.lc ?> / <?cs var:item.uc ?>
<?cs /each ?>
CS_END

my %vars = (
    lang => 'ClearSilver',
    list => [
        { lc => 'foo', uc => 'FOO' },
        { lc => 'bar', uc => 'BAR' },
        { lc => 'baz', uc => 'BAZ' },
        { lc => 'qux', uc => 'QUX' },
    ],
);

#Text::ClearSilver->new->process(\$template, \%vars);

cmpthese -1, {
    'T::CS' => sub {
        my $output = '';
        my $tcs = Text::ClearSilver->new();
        $tcs->process(\$template, \%vars, \$output);
    },
    'CS & D::CS::HDF' => sub {
        my $output;
        my $hdf = Data::ClearSilver::HDF->hdf(\%vars);
        my $cs  = ClearSilver::CS->new($hdf);
        $cs->parseString($template);
        $output = $cs->render();
    },
};

