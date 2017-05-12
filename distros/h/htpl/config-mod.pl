($fn) = @ARGV;

if ( -f $fn ) {
open(I, $fn);
while (<I>) {
    exit if (/Apache::HTPL/);
}
close(I);
} 

open(O, ">>$fn");
print O <<EOC;

PerlModule Apache::HTPL

<Files ~ "*.htpl">
SetHandler perl-script
PerlHandler Apache::HTPL
</Files>

EOC
close(O);

@ps = `ps -ax`;
@pps = grep /httpd/, @ps;
foreach (@pps) {
    s/^\s+//;
    @items = split(/\s/);
    push(@pids, $items[0]);
}

if (@pids && !$<) {
print "\n\nKilling -HUP processes " . join(", ", @pids) . "\n";

eval 'kill -1, @pids;';
}

