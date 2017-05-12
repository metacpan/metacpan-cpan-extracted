package YAML::Diff::Command;
use Mo;

has args => ();

use YAML::XS;
use IO::All;

sub run {
    my ($self) = @_;

    my $args = $self->args;
    @$args == 2 or die 'Command requires 2 YAML file paths';

    my ($file1, $file2) = @$args;

    my $yaml1 = YAML::XS::Dump(YAML::XS::LoadFile($file1));
    my $yaml2 = YAML::XS::Dump(YAML::XS::LoadFile($file2));

    (my $tmp1 = $file1) =~ s!.*/!!;
    (my $tmp2 = $file2) =~ s!.*/!!;
    $tmp1 = "/tmp/$tmp1";
    $tmp2 = "/tmp/$tmp2";

    if ($yaml1 eq $yaml2) {
        print "Matched\n";
    }
    else {
        io($tmp1)->print($yaml1);
        io($tmp2)->print($yaml2);
        system "diff -u $tmp1 $tmp2";
    }
}

1;
