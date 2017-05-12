sub slurp {
    my $file = shift;
    local $/ = undef;
    open my $fh, $file or die "Could not open $file: $!\n";
    return <$fh>;
}
