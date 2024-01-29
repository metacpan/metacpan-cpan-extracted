use strict;
use warnings;
use Config;

my $in = $ARGV[0];

my $t;
{
    local $/;
    open my $fh, '<', $in
        or die 'open: ', $in, ': ', $!;
    $t = <$fh>;
}

$t =~ s{\@SIZEOF_INT\@}      {$Config{intsize}}sg;
$t =~ s{\@SIZEOF_LONG\@}     {$Config{longsize}}sg;
$t =~ s{\@SIZEOF_LONG_LONG\@}{$Config{longlongsize}}sg;
$t =~ s{\@SIZEOF_SHORT\@}    {$Config{shortsize}}sg;

print $t;

exit 0;
