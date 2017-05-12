package XSLT::Dependencies;

use vars qw ($VERSION);
$VERSION = '0.2';

use strict;
use XML::LibXML;
use File::Spec;
use Cwd qw(realpath);

sub new {
    my $class = shift;
    
    my $this = {
        start => undef,
        inc   => {},        
    };
    bless $this, $class;
    
    return $this;
}

sub explore {
    my ($this, $filename) = @_;

    $this->{start} = realpath($filename);
    $this->{inc} = {};
    $this->dep_list($this->{start});
    
    return grep {$_ ne $this->{start}} keys %{$this->{inc}};
}

sub dep_list {
    my ($this, $filepath) = @_;

    return [] if defined $this->{inc}{$filepath};
    
    $this->{inc}{$filepath} = 1;
    
    my ($volume, $directory, $file) = File::Spec->splitpath($filepath);

    my $parser = new XML::LibXML;
    my $doc = $parser->parse_file($filepath);
    my $root = $doc->documentElement();
    my @dependencies = $root->findnodes('//xsl:include | //xsl:import');
    
    my @deps;
    for my $dependency (@dependencies) {
        my $relative_href = $dependency->find('string(@href)')->value();
        my $absolute_path = realpath(File::Spec->catfile($directory, $relative_href));
        
        push @deps, $this->dep_list($absolute_path);        
    }

    return \@deps;
}

1;

__END__

=head1 NAME

XSLT::Dependencies - Finds all the files included or imported by particular XSLT

=head1 SYNOPSIS

 use XSLT::Dependencies;
 my $dep = new XSLT::Dependencies;
 my @dep_list = XSLT::Dependencies->explore('myfile.xslt');

=head1 ABSTRACT

XSLT::Dependencies builds a list of all the files included or imported by a given
XSTL one. Recursive dependencies always result in a flattened list.

=head1 DESCRIPTION

XSLT::Dependencies scans the given XSTL file and all the files it includes by
C<xsl:include> or C<xsl:import> directives.

=head2 new

Creates a new instance of XSLT::Dependencies object.

 my $dep = new XSLT::Dependencies;
 
=head2 explore

Scans a file together with all its dependencies and returns a list of absolute
paths for every dependent file.

 my @dep_list = XSLT::Dependencies->explore('myfile.xslt');

Resultant list does not include the path to the top-level file for which C<explore>
was called. If some file is included more then once, it gives a single item
in the result. The list is not sorted in any way.

=head1 RANDOM THOUGHTS

Note that version 0.2 does not follow any non-standard namespace scheme except
C<xsl:>.

The idea behind XSLT::Dependencies was to find all the files that are used to
create the final XSLT transformation tree and take a decision whether you need
to refresh cached version of the main one.

=head1 AUTHOR

Andrew Shitov, <andy@shitov.ru>

=head1 COPYRIGHT AND LICENSE

XSLT::Dependencies module is a free software. 
You may redistribute and (or) modify it under the same terms as Perl, which ever version you mean.

=cut
