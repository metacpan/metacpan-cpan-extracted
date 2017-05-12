package t::Regen;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT_OK = qw(test_setup write_config);
use File::Path;
use File::Copy;

sub test_setup {
    my $kind = shift || '';
    my $arg = shift;
    my $testdir = "t/tests";
    $testdir = "t/other/tests" if $kind eq 'different test dir';
    !-d $testdir or rmtree $testdir or die "Can't rmtree $testdir: $!";
    mkpath $testdir or die "Can't mkpath $testdir: $!";

    my $content = '';
    $content .= "# comment before title\n" if $kind eq "comment before title";
    $content .= <<EOT;
    some title
    | open | /foo |
    | verifyText | id=foo | bar |
# comment
# next line has spaces at the end
    | verifyLocation | /bar |   
    | type | ipaddress | 0 |
EOT
    $content .= "include foo.incl\n" if $kind eq "include";
    $content .= $arg if $kind eq 'extra-wiki';
    write_file("$testdir/foo.wiki", $content);

    if ($kind eq "with orphan") {
        write_file("$testdir/orphan.html", 
                   "Auto-generated from $testdir/orphan.wiki at 23\n");
    }

    if ($kind eq "include") {
        write_file("$testdir/foo.incl",
                   "| click | included |\n| pause | 1234 |\n");
    }

    write_file("$testdir/bar.html", <<EOT);
    <html>
      <body>
        <table>
          <tr>
            <td>Test title</td>
          </tr>
          <tr>
            <td>open</td><td>/foo</td><td></td>
          </tr>
        </table>
      </body>
    </html>
EOT

    if ($kind eq "multi-dir") {
        mkdir "$testdir/baz" or die "Can't mkdir $testdir/baz: $!";
        copy "$testdir/foo.wiki", "$testdir/baz/foo.wiki" or 
            die "Can't copy foo.wiki: $!";
        mkdir "$testdir/empty" or die "Can't mkdir $testdir/empty: $!";
    }

    return $testdir;
}

sub write_config {
    my $root = shift;
    my $type = shift || '';
    my $etc = "$root/etc";
    rmtree($etc) if -e $etc;
    mkpath($etc) or die "Can't mkpath $etc: $!";
    my $contents = <<'EOT';
$test_dir = 't/tests';
$perdir = 1;
EOT
    $contents = <<EOT if $type eq 'old style';
test_dir = 't/tests'
perdir = 1
EOT
    write_file("$etc/selutils.conf", $contents);
}

sub write_file {
    my ($file, $contents) = @_;
    open(my $fh, ">$file") or die "Can't open $file: $!";
    print $fh $contents;
    close $fh or die "Can't write $file: $!";
}

1;
