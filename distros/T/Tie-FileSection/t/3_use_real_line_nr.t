use Test::More;
use_ok 'Tie::FileSection';
my $pos_ori = tell(*DATA);
my $line_ori= $.;

sub getline{ 
	my $fh = shift;
	$_ = <$fh>;
	s/[\r\n]+//r; 
}

sub reset_DATA{
	seek(*DATA, $pos_ori, 0); #reset DATA filehandle.
	$. = $line_ori;
}

my $f = Tie::FileSection->new( file => \*DATA, first_line => 2, use_real_line_nr => 1 );
cmp_ok getline($f), 'eq', 'Line 2', 'section data line 1';
cmp_ok $f->input_line_number, '==', 2, 'section line number = 2';
cmp_ok getline($f), 'eq', 'Line 3', 'section data line 2';
cmp_ok $f->input_line_number, '==', 3, 'section line number = 3';
undef $f;

reset_DATA;
$f = Tie::FileSection->new( file => \*DATA, first_line => 2 );
cmp_ok getline($f), 'eq', 'Line 2', 'section data line 1';
cmp_ok $., '==', 1, 'section line number = 1';
cmp_ok getline($f), 'eq', 'Line 3', 'section data line 2';
cmp_ok $., '==', 2, 'section line number = 2';


reset_DATA;
$f = Tie::FileSection->new( file => \*DATA, first_line => -2, use_real_line_nr => 1 );
cmp_ok getline($f), 'eq', 'Line 5', 'section data line 1';
cmp_ok $., '==', 5, 'section line number = 5';
cmp_ok getline($f), 'eq', 'Line 6', 'section data line 2';
cmp_ok $., '==', 6, 'section line number = 6';

reset_DATA;
$f = Tie::FileSection->new( file => \*DATA, first_line => -1, use_real_line_nr => 1 );
cmp_ok getline($f), 'eq', 'Line 6', 'section data line 1';
cmp_ok $., '==', 6, 'section line number = 6';
done_testing( );

__DATA__
Line 1
Line 2
Line 3
Line 4
Line 5
Line 6