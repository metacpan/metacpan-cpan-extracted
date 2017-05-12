use strict;

my ($fn, $cgi, $sysdir) = @ARGV;

if ( -f $fn ) {
    open(I, $fn) || die $!;
    while (<I>) {
        if (/^#\s*BEGIN HTPL/) {
            close(I);
            &diet;
            last;
        }
        exit if (/application\/x-htpl/);
    }
    close(I);
} 

open(O, ">>$fn");
print O <<EOC;
# BEGIN HTPL

AddType application/x-htpl .htpl
Action application/x-htpl /htpl-code-exec/
ScriptAlias /htpl-code-exec/ $cgi/

<Directory $sysdir>
AuthType Basic
AuthName "HTPL site administration"
AuthUserFile $sysdir/.passwd
AuthGroupFile /dev/null

<Limit GET POST>
require valid-user
</Limit>
<Files ~ ^.passwd\$>
  order deny,allow
  deny from all
</Files>
</Directory>

# END HTPL
EOC
close(O);

mkdir 0777, $sysdir;
my $pfile = "$sysdir/.passwd";
my $flag;
if (-f $pfile) {
    open(I, $pfile) || die $!;
    while (<I>) {
        $flag ||= (/^admin:/);
    }
    close(I);
}
unless ($flag) {
    open(O, ">>$pfile") || die $!;
    print O "admin:" . crypt("admin", pack("CC", rand(26) + 65, rand(26) + 65)), "\n";
    close(O);
}

my @ps = `ps -ax`;
my @pps = grep /httpd/, @ps;
my @pids;
foreach (@pps) {
    s/^\s+//;
    my @items = split(/\s/);
    push(@pids, $items[0]);
}

if (@pids && !$<) {
print "\n\nKilling -HUP processes " . join(", ", @pids) . "\n";

eval 'kill -1, @pids;';
}

print <<EOM;


---------------------------------------------------------------------
---------------------------------------------------------------------
You can login to http://yoursite/htpl (or any other directory
you chose) with the user admin and password admin
---------------------------------------------------------------------
---------------------------------------------------------------------


EOM

sub diet {
    open(I, $fn) || die $!;
    my $text = join("", <I>);
    close(I);
    unless ($text =~ s/\n\s*#\s*BEGIN HTPL.*?\n\s*#\s*END HTPL.*?\n/\n/s) {
        die "Failed";
    }
    open(O, ">$fn") || die $!;
    print O $text;
    close(O);
}
