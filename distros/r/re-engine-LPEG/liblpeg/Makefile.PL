use ExtUtils::MakeMaker;

my @C = glob "*.c";
my $object = join " ", map { s/\.c$/\$(OBJ_EXT)/; $_ } @C;

WriteMakefile(
    NAME => 'liblpeg',
    C => [ @C ],
    OBJECT => $object,
    INC => '-I. -I../liblua',
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
