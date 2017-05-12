use lib 't/lib';
use BlockMobileTest qw/no_plan/;

my $data = load_data();
spec_string( $data );

run {
    my $block = shift;
    BlockMobileTest->run_test( $block );
};

sub load_data {
    my $dir = 't/block-mobile';

    opendir(DIR, $dir) or die $@;
    my @list = readdir(DIR);
    closedir(DIR);

    my $data = '';
    for my $file ( @list ) {
        next unless $file =~ /\.dat$/;
        my $dat = $dir .'/'. $file; 
        my $name = "\e[33m" . $dat . "\e[0m";
        open(FH , $dat ); 
        while(<FH>){
            $_ =~ s/^=== /=== [$name] /;
            $data .= $_;
        }
        close(FH);
    }
    return $data;
}
