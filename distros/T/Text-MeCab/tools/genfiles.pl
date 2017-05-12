use strict;
use warnings;

package MeCabBuild;

sub write_files {
    my $version = shift;

    write_config_const($version);
}

sub write_config_const {
    my ($version) = @_;

    my $contents;
    if ($version >= 0.99) {
        $contents = config_const_from_enum();
    } else {
        $contents = config_const_from_symbol();
    }

    open my $f, '>', 'xs/config-const.h'
        or die "Could not open file: $!";
    print $f $contents;
    close $f;
}

my @const_names = qw(
    MECAB_NOR_NODE
    MECAB_UNK_NODE
    MECAB_BOS_NODE
    MECAB_EOS_NODE
    MECAB_EON_NODE

    MECAB_SYS_DIC
    MECAB_USR_DIC
    MECAB_UNK_DIC

    MECAB_ONE_BEST
    MECAB_NBEST
    MECAB_PARTIAL
    MECAB_MARGINAL_PROB
    MECAB_ALTERNATIVE
    MECAB_ALL_MORPHS
    MECAB_ALLOCATE_SENTENCE
);

# for >= 0.99
sub config_const_from_enum {
    my $contents = "";

    foreach my $name (@const_names) {
        $contents .= <<"END_TEMPLATE";
#define HAVE_$name 1
END_TEMPLATE
    }

    return $contents;
}

# for <= 0.98
sub config_const_from_symbol {
    my $contents = "";

    foreach my $name (@const_names) {
        $contents .= <<"END_TEMPLATE";
#ifdef $name
#define HAVE_$name 1
#endif
END_TEMPLATE
    }

    return $contents;
}
