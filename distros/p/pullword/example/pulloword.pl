use pullword;

my $value=shift;
#=pod
my $value='关关雎鸠，在河之洲。窈窕淑女，君子好逑。
参差荇菜，左右流之。窈窕淑女，寤寐求之。
求之不得，寤寐思服。悠哉悠哉，辗转反侧。
参差荇菜，左右采之。窈窕淑女，琴瑟友之。
参差荇菜，左右芼之。窈窕淑女，钟鼓乐之。';
#=cut
my $threshold=0.5;
my $debug=1;

print PWget($value,$threshold,$debug);
my $fchash=PWhash($value);

print "$_ $fchash->{$_} \n" for(sort{$fchash->{$b}<=>$fchash->{$a}} keys %{$fchash});

