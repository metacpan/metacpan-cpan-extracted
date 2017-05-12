package XML::Struct::Writer::Stream;
use strict;
use Moo;

our $VERSION = '0.26';

has fh     => (is => 'rw', default => sub { *STDOUT });
has pretty => (is => 'rw');

our %ESCAPE = (
    '&' => '&amp;',
    '<' => '&lt;',
    '>' => '&gt;',
    '"' => '&quot;',
);

use constant {
    DOCUMENT_STARTED => 0,
    TAG_STARTED      => 1,
    CHAR_CONTENT     => 2,
    CHILD_ELEMENT    => 3,
};

sub xml_decl { 
    my ($self, $data) = @_;

    my $xml =  "<?xml version=\"$data->{Version}\"";
    $xml .= " encoding=\"$data->{Encoding}\"" if $data->{Encoding};
    $xml .= " standalone=\"$data->{Standalone}\"" if $data->{Standalone};
    $xml .= "?>\n";

    print {$self->fh} $xml;
}

sub start_document { 
    my ($self) = @_;
    $self->{_stack} = [];
    $self->{_status} = DOCUMENT_STARTED;
}

sub start_element {  
    my ($self, $data) = @_;

    my $tag = $data->{Name};
    my $attr = $data->{Attributes};
    my $xml = "<$tag";

    if ($self->{_status} == TAG_STARTED) {
        print {$self->fh} '>';
        if ($self->pretty) {
            print {$self->fh} "\n".('  ' x (scalar @{$self->{_stack}}));
        }
    } elsif ($self->{_status} == CHILD_ELEMENT) {
        if ($self->pretty) {
            print {$self->fh} "\n".('  ' x (scalar @{$self->{_stack}}));
        }
    } elsif ($self->{_status} == CHAR_CONTENT) {
        print {$self->fh} $self->{_chars};
    } # else: DOCUMENT_STARTED

    push @{$self->{_stack}}, $tag;

    if ($attr && %$attr) {
        foreach my $key (sort keys %$attr) {
            my $value = $attr->{$key};
            $value =~ s/([&<>"'])/$ESCAPE{$1}/geo;
            $xml .= " $key=\"$value\"";
        }
    }

    $self->{_status} = TAG_STARTED;

    print {$self->fh} $xml;
}

sub end_element {
    my ($self) = @_;

    my $tag = pop @{$self->{_stack}} or return;

    if ($self->{_status} == TAG_STARTED) {
        print {$self->fh} '/>';
    } elsif ($self->{_status} == CHAR_CONTENT) {
        print {$self->fh} $self->{_chars} . "</$tag>";
        $self->{_chars} = "";
    } else { # CHILD_ELEMENT
        if ($self->pretty) {
            print {$self->fh} "\n".('  ' x (scalar @{$self->{_stack}}));
        }
        print {$self->fh} "</$tag>";
    }

    $self->{_status} = CHILD_ELEMENT;
}

sub characters {
    my ($self, $data) = @_;

    my $xml = $data->{Data};
    $xml =~ s/([&<>])/$ESCAPE{$1}/geo;

    if ($self->{_status} == TAG_STARTED) {
        print {$self->fh} '>';
        $self->{_status} = CHAR_CONTENT; 
        $self->{_chars} = $xml;
    } elsif ($self->{_status} == CHILD_ELEMENT) {
        print {$self->fh} $xml;
    } else {
        $self->{_chars} .= $xml;
    }
}

sub end_document { 
    my ($self) = @_;
    $self->end_element while @{$self->{_stack}};
    print {$self->fh} "\n";
}


1;
__END__

=head1 NAME

XML::Struct::Writer::Stream - simplified SAX handler to serialize (Micro)XML

=head1 DESCRIPTION

This class implements a simplfied SAX handler for stream-based serialization
of XML. DTDs, comments, processing instructions and similar features not part
of MicroXML are not supported.

The handler is written to reproduce the serialization of libxml.

=head1 CONFIGURATION

=over

=item fh

File handle or compatible object to write to (standard output by default).

=item pretty

Pretty-print XML if enabled. 

=back

=head1 SEE ALSO

See L<XML::SAX::Writer>, L<XML::Genx::SAXWriter>, and L<XML::Handler::YAWriter>
for more elaborated SAX writers and L<XML::Writer> for a general XML writer,
not based on SAX.

=cut
