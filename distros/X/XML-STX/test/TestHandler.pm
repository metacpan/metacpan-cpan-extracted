# An example of simple SAX handler

package TestHandler;

sub new {
    my $type = shift;
    return bless {result => '',
		  warnings => 0,
		  errors => 0,
		  fatals => 0,
		 }, $type;
}

# content --------------------------------------------------

sub start_document {
    my ($self, $document) = @_;
}

sub end_document {
    my ($self, $document) = @_;

    return $self->{result};
}

sub start_element {
    my ($self, $element) = @_;
    
    $self->{result} .= "<$element->{Name} ";

    # attributes are ordered to get predictable (and testable) results
    foreach (sort keys %{$element->{Attributes}}) {
	$self->{result} .= "$element->{Attributes}->{$_}->{Name}=\"$element->{Attributes}->{$_}->{Value}\" ";
    }

    foreach (sort keys %{$self->{_start_prefmap}}) {
	my $attName = $_ ? "xmlns:$_" : 'xmlns';
	$self->{result} .= "$attName=\"$self->{_start_prefmap}->{$_}\" ";
    }

    $self->{result} .= ">";
    $self->{_start_prefmap} = {};
}

sub end_element {
    my ($self, $element) = @_;
    
    $self->{result} .= "</$element->{Name}>";
}

sub characters {
    my ($self, $characters) = @_;
    
    $characters->{Data} =~ s/\n//g;
    $characters->{Data} =~ s/\s{2,}/ /g;
    $self->{result} .= "$characters->{Data}";
}

sub processing_instruction {
    my ($self, $pi) = @_;

    $self->{result} .= "<?$pi->{Target} $pi->{Data}?>";
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

    $self->{result} .= "<![CDATA[";
}

sub end_cdata {
    my $self = shift;

    $self->{result} .= "]]>";
}

sub comment {
    my ($self, $comment) = @_;

    $self->{result} .= "<!-- $comment->{Data} -->";
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
    
    $self->{warnings}++;
}

sub error {
    my ($self, $exception) = @_;
    
    $self->{errors}++;
}

sub fatal_error {
    my ($self, $exception) = @_;
    
    $self->{fatals}++;
}

1;
