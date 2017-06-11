package builder::CaboCha::Const;

sub write_files {
    my $class = shift;

    write_config_const($version);
}

sub write_config_const {
    my $class = shift;

    my $contents = config_const_from_enum();

    open my $f, '>', 'src/config-const.h'
        or die "Could not open file: $!";
    print $f $contents;
    close $f;
}

my @const_names = qw(
    CABOCHA_FORMAT_TREE
    CABOCHA_FORMAT_LATTICE
    CABOCHA_FORMAT_TREE_LATTICE
    CABOCHA_FORMAT_XML
    CABOCHA_FORMAT_CONLL
    CABOCHA_FORMAT_NONE
);

sub config_const_from_enum {
    my $contents = "";

    foreach my $name (@const_names) {
        $contents .= "#define HAVE_$name 1\n";
    }

    return $contents;
}

1;