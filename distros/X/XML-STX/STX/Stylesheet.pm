require 5.005_02;
BEGIN { require warnings if $] >= 5.006; }
use strict;

# --------------------------------------------------
package XML::STX::Stylesheet;

sub new {
    my $class = shift;

    my $options = {'stxpath-default-namespace' => [''],
		   'output-encoding' => 'utf-8',
		  };

    my $group = XML::STX::Group->new(0, undef);

    my $self = bless {
		      Options => $options,
		      dGroup => $group,
		      next_gid => 1,
		      next_tid => 1,
		      alias  => [], 
		     }, $class;
    return $self;
}

# --------------------------------------------------

package XML::STX::Group;

sub new {
    my ($class, $gid, $group) = @_;

    my $options = {'pass-through' => 0,
		   'recognize-cdata' => 1,
		   'strip-space' => 0,
		  };

    my $self = bless {
		      Options => $options,
		      gid => $gid,
		      group => $group, # parent group
		      templates => {}, # contained templates
		      vGroup => [],  # group templates for non attributes
		      vGroupA => [], # group templates for attributes
		      vGroupP => [], # group templates for procedures
		      pc1  => [],    # precedence category 1 for non attributes
		      pc1A => [],    # precedence category 1 for attributes
		      pc1P => {},    # precedence category 1 for procedures
		      pc2  => [],    # precedence category 2 for non attributes
		      pc2A => [],    # precedence category 2 for attributes
		      pc2P => {},    # precedence category 2 for procedures
		      pc3  => [],    # precedence category 3 for non attributes
		      pc3A => [],    # precedence category 3 for attributes
		      pc3P => {},    # precedence category 3 for procedures
		      groups => {},  # child groups
		      vars => [{}],  # variables declared in this group
		      bufs => [{}],  # buffers declared in this group
		     }, $class;
    return $self;
}

# --------------------------------------------------

package XML::STX::Template;

sub new {
    my $class = shift;
    my $tid = shift;
    my $group = shift;

    my $self = bless {
		      tid => $tid,
		      group => $group,
		      instructions => [],
		      vars => [{}], # local variables
		      bufs => [{}], # local buffers
		      _attr => 0,
		      _attr_only => 1,
		      _self => 0,
		     }, $class;
    return $self;
}

1;
__END__

=head1 NAME

XML::STX::Stylesheet/Group/Template - stylesheet objects for XML::STX

=head1 SYNOPSIS

no API

=head1 AUTHOR

Petr Cimprich (Ginger Alliance), petr@gingerall.cz

=head1 SEE ALSO

XML::STX, perl(1).

=cut
