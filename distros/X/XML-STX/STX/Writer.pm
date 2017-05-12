# A fallback SAX writer 

package XML::STX::Writer;
$VERSION = '0.03';

sub new {
    my $class = shift;
    my $options = ($#_ == 0) ? shift : { @_ };

    if (exists $options->{Output}) {
	open(RES, ">$options->{Output}") 
	  or die "Can't open $options->{Output} for writing!";

	$options->{RES} = *RES;
    }

    return bless $options, $class;
}

# content --------------------------------------------------

sub start_document {
    my ($self, $document) = @_;

    local *STDOUT = $self->{RES} if exists $self->{RES};

    print '<?xml version="1.0"?>';
}

sub end_document {
    my ($self, $document) = @_;
    close $self->{RES} if exists $self->{RES};
}

sub start_element {
    my ($self, $element) = @_;
    
    local *STDOUT = $self->{RES} if exists $self->{RES};

    my $out= "<$element->{Name}";

    foreach (keys %{$element->{Attributes}}) {
	$out .= " $element->{Attributes}->{$_}->{Name}=\"$element->{Attributes}->{$_}->{Value}\"";
    }

    foreach (keys %{$self->{_start_prefmap}}) {
	my $attName = $_ ? "xmlns:$_" : 'xmlns';
	$out .= " $attName=\"$self->{_start_prefmap}->{$_}\"";
    }

    print "$out>";
    $self->{_start_prefmap} = {};
}

sub end_element {
    my ($self, $element) = @_;
    
    local *STDOUT = $self->{RES} if exists $self->{RES};

    print "</$element->{Name}>";
}

sub characters {
    my ($self, $characters) = @_;
    
    local *STDOUT = $self->{RES} if exists $self->{RES};

    unless ($self->{CDATA}) {
	$characters->{Data} =~ s/&/&amp;/g;
	$characters->{Data} =~ s/</&lt;/g;
	$characters->{Data} =~ s/>/&gt;/g;
    }

    print $characters->{Data};
}

sub processing_instruction {
    my ($self, $pi) = @_;

    local *STDOUT = $self->{RES} if exists $self->{RES};

    print "<?$pi->{Target} $pi->{Data}?>";
}

sub start_prefix_mapping {
    my ($self, $map) = @_;
    $self->{_start_prefmap}->{$map->{Prefix}} = $map->{NamespaceURI};
}

sub end_prefix_mapping {
    my ($self, $map) = @_;

}

# lexical --------------------------------------------------

sub start_cdata {
    my $self = shift;

    local *STDOUT = $self->{RES} if exists $self->{RES};

    $self->{CDATA} = 1;
    print '<![CDATA[';
}

sub end_cdata {
    my $self = shift;

    local *STDOUT = $self->{RES} if exists $self->{RES};

    $self->{CDATA} = 0;
    print ']]>';
}

sub comment {
    my ($self, $comment) = @_;

    local *STDOUT = $self->{RES} if exists $self->{RES};

    print "<!-- $comment->{Data} -->";
}

sub start_dtd {
    my ($self, $options) = @_;
}

sub end_dtd {
    my ($self, $options) = @_;
}

# error --------------------------------------------------

sub warning {
    my ($self, $exception) = @_;
    
    print STDERR "Warning: $exception->{Message}\n";
}

sub error {
    my ($self, $exception) = @_;
    
    print STDERR "Error: $exception->{Message}\n";
}

sub fatal_error {
    my ($self, $exception) = @_;
    
    print STDERR "Fatal Error: $exception->{Message}\n";
}

1;

__END__

=head1 NAME

XML::STX::Writer - a lightweight fallback SAX2 writer

=head1 AUTHOR

Petr Cimprich (Ginger Alliance), petr@gingerall.cz

=head1 SEE ALSO

XML::STX, perl(1).

=cut
