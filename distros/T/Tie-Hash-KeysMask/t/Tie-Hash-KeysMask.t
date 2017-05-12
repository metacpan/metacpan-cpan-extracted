
use Test::More tests => 14;
BEGIN {
    use_ok('Tie::Hash::KeysMask');
    };

sub expecty
{
    my ($x,$y,$h,$message)=@_;
    is ($h->{$x},$y,"$message [$x=>$y] Y");
}

sub expectn
{
    my ($x,$y,$h,$message)=@_;
    isnt ($h->{$x},$y,"$message [$x=>$y] N");
}

sub isdef
{
    my ($x,$h,$message)=@_;
    ok(exists $h->{$x}, "$message [$x] Y");
}

sub notdef
{
    my ($x,$h,$message)=@_;
    ok(!(exists $h->{$x}), "$message [$x] N");
}

my @compass = qw(north east south west);
my @direction = qw(up right down left);
my @D = qw(north up east right south down west left);

{
    my $myh = Tie::Hash::KeysMask->newHASH(sub {substr($_[0],0,1);});
    %$myh = @D;
    my $msg = '1st char significant';

    notdef 'N',$myh,$msg ;
    isdef  'n',$myh,$msg;
    expecty qw(we left),$myh,$msg;
    expecty qw(sw down),$myh,$msg;
}

{
    my $myh = Tie::Hash::KeysMask->newHASH('uc');
    %$myh = @D;
    my $msg = 'ignore case';

    isdef 'North',$myh,$msg;
    isdef 'EAST',$myh,$msg;
    expecty qw(West left),$myh,$msg;
    expecty qw(WEST left),$myh,$msg;
    expecty qw(south down),$myh,$msg;
}

{
    my $myh = Tie::Hash::KeysMask->newHASH
    ({qw(North N north N south S SOUTH S Greenland N w west west W e east east E)});
    %$myh = @D;
    my $msg = 'alias by hash-mapping';
    #my @t = $myh,$msg;

    notdef 'NORTH',$myh,$msg;
    isdef 'SOUTH',$myh,$msg;
    expecty qw(N up),$myh,$msg;;
    expecty qw(Greenland up),$myh,$msg;;

=begin ignore

# shows funny results caused by an abuse, that is because
# 'w'=>'west','west'=>'W' are included in the key-mask-hash
# & similarly with 'east'. This is a break with a rule described in the
# pod in section CAVEAT.
# -------------------------------------------------------------------------
    $myh->{q(west)} = 'L';
    $myh->{q(e)} = 'R';
    $myh->{q(ne)} = 'RU';
    print '-'x50,qq(\n);
    print join qq(\n), map sprintf('%s => %s',$_,$myh->{$_}), (keys %$myh);
    print qq(\n);
    print '-'x50,qq(\n);
    printf 'w => %s, west => %s, W => %s.'.qq(\n),@$myh{qw(w west W)};
    print qq(\n);
    printf 'e => %s, east => %s, E => %s.'.qq(\n),@$myh{qw(w east E)};

=end ignore

=cut

}