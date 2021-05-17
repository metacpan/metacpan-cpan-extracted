$self->{CC} = 'g++';
$self->{LD} = 'g++';
$self->{LDDLFLAGS} .= "-shared $Config{ccflags}";
