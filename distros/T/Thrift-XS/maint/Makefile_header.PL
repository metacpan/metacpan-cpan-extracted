my %args;
my (@INC, @LIBPATH, @LIBS);

my $DEFINES = '-O2';
$DEFINES .= ' -Wall' unless $^O =~ /sun|solaris/i;
$DEFINES .= ' -Wno-unused-value -Wno-format-security' unless $^O =~ /Win32|sun|solaris/i;

unshift @INC, '-Isrc';

my $inc_files = join(' ', glob 'src/*.h');
my $src_files = join(' ', glob 'src/*.c');
my $xs_files  = join(' ', glob '*.xs');

$args{INC} = join(' ', @INC);
$args{LIBS} = [ join(' ', @LIBPATH, @LIBS) ];
$args{DEFINE} = $DEFINES;
$args{depend} = { 'XS.c' => "$inc_files $src_files $xs_files" };

