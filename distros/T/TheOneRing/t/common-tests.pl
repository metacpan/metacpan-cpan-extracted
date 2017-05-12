my @options;
@options = (debug => 1) if ($ENV{'TORDEBUG'});
our $tor = new TheOneRing(@options);
ok(ref($tor) eq 'TheOneRing', "creating an instance of the one ring");

# create a test-file of data
make_file("test-file", "hello", "world");
ok(-f "test-file", "creating a file");

# add it
$tor->dispatch("add","test-file");
ok($? == 0, "adding a file");

# commit it
$tor->dispatch("commit","-m","committing the test-file", "test-file");
ok($? == 0, "commiting a file");

# update the alternate checkout
chdir("../test2");
make_file("test-two", "hi", "there");
$tor->dispatch("update");
ok($? == 0, "updating second checkout");
ok(-f "test-file", "checking second test-file");

# move
chdir("../test");
$tor->dispatch("move", "test-file", "moved-file");
$tor->dispatch("commit", "-m", "moved test-file to moved-file");

chdir("../test2");
$tor->dispatch("update");
ok($? == 0, "updating second checkout after move");
ok(-f "moved-file", "checking moved-file");
ok(! -f "test-file", "checking DNE of test-file");


# cleanup
#system("rm -rf $tmpdir");

sub make_file {
    my ($file, @contents) = @_;
    open(O, ">$file");
    print O join("\n", @contents);
    close(O);
}

