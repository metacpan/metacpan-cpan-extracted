$self->{CC} = 'g++';
$self->{LD} = 'g++';
$self->{LIBS} = ['-L/lib/w32api -lnetapi32 -lwininet -lversion -lmpr -lodbc32 -lodbccp32 -lwinmm -lole32 -loleaut32 -luuid -lcomctl32 -lgdi32 -lcomdlg32 -lntdll'];
$self->{LDDLFLAGS} .= "-shared $Config{ccflags}";
