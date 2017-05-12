package t::TestLess;
use Test::Base -Base;
use Test::Less;
our @EXPORT = qw(
    test_less_new
    reset_test_env
    check_index_content
);

sub test_less_new {
    my $t = Test::Less->new;
    $t->comment('');
    return $t;
}

sub reset_test_env {
    require File::Path;
    File::Path::rmtree('t/Test-Less');
}

sub check_index_content() {
    my $expected = shift;
    my $name = shift;
    my $file = 't/Test-Less/index.txt';
    open FILE, $file 
      or die "Can't open $file for input:\n$!";
    my $index = do { local $/; <FILE> };
    close FILE;
    $index =~ s/^#.*\n//gm;
    is $index, $expected, $name;
}

package t::TestLess::Filter;
use base 'Test::Base::Filter';

sub backticks {
    my $command = shift;
    return scalar `$command`;
}

sub write_file {
    my $file_path = $self->arguments;
    my $content = shift;
    if ($file_path =~ /^(.*[\\\/])/ and not -e $1) {
        my $path = $1;
        require File::Path;
        File::Path::mkpath($path) 
          or die "Can't make $path:\n$1";
    }
    open FILE, "> $file_path"
      or die "Can't open $file_path for output:\n$!";
    print FILE $content;
    close FILE;
    return '';
}

sub read_file {
    my $file_path = shift;
    chomp $file_path;
    open FILE, $file_path
      or die "Can't open $file_path for input";
    local $/;
    my $content = <FILE>;
    close FILE;
    return $content;
}

sub split {
    my $value = shift;
    chomp $value;
    split /\s+/, $value;
}
