#line 1
# $Id: SAX.pm,v 1.29 2007/06/27 09:09:12 grant Exp $

package XML::SAX;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);

$VERSION = '0.16';

use Exporter ();
@ISA = ('Exporter');

@EXPORT_OK = qw(Namespaces Validation);

use File::Basename qw(dirname);
use File::Spec ();
use Symbol qw(gensym);
use XML::SAX::ParserFactory (); # loaded for simplicity

use constant PARSER_DETAILS => "ParserDetails.ini";

use constant Namespaces => "http://xml.org/sax/features/namespaces";
use constant Validation => "http://xml.org/sax/features/validation";

my $known_parsers = undef;

# load_parsers takes the ParserDetails.ini file out of the same directory
# that XML::SAX is in, and looks at it. Format in POD below

#line 45

sub load_parsers {
    my $class = shift;
    my $dir = shift;
    
    # reset parsers
    $known_parsers = [];
    
    # get directory from wherever XML::SAX is installed
    if (!$dir) {
        $dir = $INC{'XML/SAX.pm'};
        $dir = dirname($dir);
    }
    
    my $fh = gensym();
    if (!open($fh, File::Spec->catfile($dir, "SAX", PARSER_DETAILS))) {
        XML::SAX->do_warn("could not find " . PARSER_DETAILS . " in $dir/SAX\n");
        return $class;
    }

    $known_parsers = $class->_parse_ini_file($fh);

    return $class;
}

sub _parse_ini_file {
    my $class = shift;
    my ($fh) = @_;

    my @config;
    
    my $lineno = 0;
    while (defined(my $line = <$fh>)) {
        $lineno++;
        my $original = $line;
        # strip whitespace
        $line =~ s/\s*$//m;
        $line =~ s/^\s*//m;
        # strip comments
        $line =~ s/[#;].*$//m;
        # ignore blanks
        next if $line =~ /^$/m;
        
        # heading
        if ($line =~ /^\[\s*(.*)\s*\]$/m) {
            push @config, { Name => $1 };
            next;
        }
        
        # instruction
        elsif ($line =~ /^(.*?)\s*?=\s*(.*)$/) {
            unless(@config) {
                push @config, { Name => '' };
            }
            $config[-1]{Features}{$1} = $2;
        }

        # not whitespace, comment, or instruction
        else {
            die "Invalid line in ini: $lineno\n>>> $original\n";
        }
    }

    return \@config;
}

sub parsers {
    my $class = shift;
    if (!$known_parsers) {
        $class->load_parsers();
    }
    return $known_parsers;
}

sub remove_parser {
    my $class = shift;
    my ($parser_module) = @_;

    if (!$known_parsers) {
        $class->load_parsers();
    }
    
    @$known_parsers = grep { $_->{Name} ne $parser_module } @$known_parsers;

    return $class;
}
 
sub add_parser {
    my $class = shift;
    my ($parser_module) = @_;

    if (!$known_parsers) {
        $class->load_parsers();
    }
    
    # first load module, then query features, then push onto known_parsers,
    
    my $parser_file = $parser_module;
    $parser_file =~ s/::/\//g;
    $parser_file .= ".pm";

    require $parser_file;

    my @features = $parser_module->supported_features();
    
    my $new = { Name => $parser_module };
    foreach my $feature (@features) {
        $new->{Features}{$feature} = 1;
    }

    # If exists in list already, move to end.
    my $done = 0;
    my $pos = undef;
    for (my $i = 0; $i < @$known_parsers; $i++) {
        my $p = $known_parsers->[$i];
        if ($p->{Name} eq $parser_module) {
            $pos = $i;
        }
    }
    if (defined $pos) {
        splice(@$known_parsers, $pos, 1);
        push @$known_parsers, $new;
        $done++;
    }

    # Otherwise (not in list), add at end of list.
    if (!$done) {
        push @$known_parsers, $new;
    }
    
    return $class;
}

sub save_parsers {
    my $class = shift;
    
    ### DEBIAN MODIFICATION
    print "\n";
    print "Please use 'update-perl-sax-parsers(8) to register this parser.'\n";
    print "See /usr/share/doc/libxml-sax-perl/README.Debian.gz for more info.\n";
    print "\n";

    return $class; # rest of the function is disabled on Debian.
    ### END DEBIAN MODIFICATION

    # get directory from wherever XML::SAX is installed
    my $dir = $INC{'XML/SAX.pm'};
    $dir = dirname($dir);
    
    my $file = File::Spec->catfile($dir, "SAX", PARSER_DETAILS);
    chmod 0644, $file;
    unlink($file);
    
    my $fh = gensym();
    open($fh, ">$file") ||
        die "Cannot write to $file: $!";

    foreach my $p (@$known_parsers) {
        print $fh "[$p->{Name}]\n";
        foreach my $key (keys %{$p->{Features}}) {
            print $fh "$key = $p->{Features}{$key}\n";
        }
        print $fh "\n";
    }

    print $fh "\n";

    close $fh;

    return $class;
}

sub save_parsers_debian {
    my $class = shift;
    my ($parser_module,$directory, $priority) = @_;

    # add parser
    $known_parsers = [];
    $class->add_parser($parser_module);
    
    # get parser's ParserDetails file
    my $file = $parser_module;
    $file = "${priority}-$file" if $priority != 0;
    $file = File::Spec->catfile($directory, $file);
    chmod 0644, $file;
    unlink($file);
    
    my $fh = gensym();
    open($fh, ">$file") ||
        die "Cannot write to $file: $!";

    foreach my $p (@$known_parsers) {
        print $fh "[$p->{Name}]\n";
        foreach my $key (keys %{$p->{Features}}) {
            print $fh "$key = $p->{Features}{$key}\n";
        }
        print $fh "\n";
    }

    print $fh "\n";

    close $fh;

    return $class;
}

sub do_warn {
    my $class = shift;
    # Don't output warnings if running under Test::Harness
    warn(@_) unless $ENV{HARNESS_ACTIVE};
}

1;
__END__

#line 421

