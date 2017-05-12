use ExtUtils::MakeMaker;

my @C = grep { not /^(lua|print)/ } glob "*.c";
my $object = join " ", map { s/\.c$/\$(OBJ_EXT)/; $_ } @C;

WriteMakefile(
    NAME => 'liblua',
    C => [ @C ],
    OBJECT => $object,
    INC => '-I.',
);

package MY;

# Don't make .bs files
sub dynamic
{
    my $self = shift;
    my $res = $self->SUPER::dynamic(@_);
    $res =~ s/\s*\$\(INST_BOOT\)//;
    $res;
}

# Don't make dynamic libs from the .o files, just the objects
sub dynamic_lib
{
    '$(INST_DYNAMIC): $(OBJECT)' . "\n" .
    "\t" . '$(NOECHO) $(NOOP)' . "\n"
}
