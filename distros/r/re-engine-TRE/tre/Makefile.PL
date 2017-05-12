use ExtUtils::MakeMaker;

my @C = grep { not /test/ } glob "*.c";
my $object = join " ", map { s/\.c$/\$(OBJ_EXT)/; $_ } @C;

WriteMakefile(
    NAME => 'libtre',
    C => [ @C ],
    OBJECT => $object,
    INC => '-I.',
    DEFINE => '-DHAVE_CONFIG_H',
);
