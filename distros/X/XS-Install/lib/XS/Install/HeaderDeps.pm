package
    XS::Install::HeaderDeps;
use strict;
use warnings;
use Cwd 'abs_path';

sub find_deps {
    my $p = shift;
    my $headers = [ grep {$_} map { abs_path($_) } @{$p->{headers} || []} ];
    my $inc     = [ grep {$_} map { abs_path($_) } @{$p->{inc} || []} ];
    my $cache   = {};
    $headers = undef unless @$headers;
    
    my %ret;
    foreach my $file (@{$p->{files}}) {
        my $absfile = abs_path($file) or next;
        next unless -f $absfile;
        my $deps = _find_deps($absfile, $cache, $inc, $headers) or next;
        $ret{$file} = [keys %$deps];
    }
    
    return \%ret;
}

sub _find_deps {
    my ($file, $cache, $inc, $headers) = @_;
    return $cache->{$file} if exists $cache->{$file};
    
    my $deps = $cache->{$file} = {};
    my $content = readfile($file);
    my $dir = $file;
    $dir =~ s#[^/\\]+$##;
    
    while ($content =~ /^\s*#\s*include\s*("|<)([^">]+)(?:"|>)/mg) {
        my ($type, $dep) = ($1, $2);
        my $absdep;
        if ($type eq '"') { # try to find locally first
            $absdep = getfile($dir.$dep);
        }
        unless ($absdep) { # try to find globally
            foreach my $dir (@$inc) {
                $absdep = getfile($dir.'/'.$dep);
                last if $absdep;
            }
        }
        if ($absdep and $headers) { # if supplied, ignore everything that is outside of specified dirs
            my $found;
            foreach my $dir (@$headers) {
                next unless index($absdep, $dir) == 0;
                $found = 1;
                last;
            }
            $absdep = undef unless $found;
        }
        next unless $absdep;
        
        $deps->{$absdep}++;
        my $subdeps = _find_deps($absdep, $cache, $inc, $headers);
        $deps->{$_}++ for keys %$subdeps;
    }
    
    return $deps;
}

sub getfile {
    my $f = abs_path($_[0]);
    return undef unless $f and -f $f;
    return $f;
}

sub readfile {
    my $file = shift;
    open my $fh, '<', $file or die "cannot open $file: $!";
    local $/ = undef;
    my $content = <$fh>;
    close $fh;
    return $content;
}

1;