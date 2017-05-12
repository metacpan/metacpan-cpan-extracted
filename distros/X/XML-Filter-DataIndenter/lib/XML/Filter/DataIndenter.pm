package XML::Filter::DataIndenter;

$VERSION = 0.1;

=head1 NAME

XML::Filter::DataIndenter - SAX2 Indenter for data oriented XML

=head1 SYNOPSIS

    use XML::Filter::DataIndenter;

    use XML::SAX::Machines qw( Pipeline );

    Pipeline( XML::Filter::DataIndenter => \*STDOUT );

=head1 DESCRIPTION

B<ALPHA CODE ALERT>: This is the first release.  Feedback and patches
welcome.

In data oriented XML, leaf elements (those which contain no elements)
contain only character content, all other elements contain only child
elements and ignorable whitespace.  This filter consumes all whitespace
not in leaf nodes and replaces it with whitespace that indents all
elements.  Character data in leaf elements is left unmolested.

This filter assumes you're emitting data oriented XML.  It will die if
it sees non-whitespace character data outside of a leaf element.  It
also dies if it sees start-tag / end-tag mismatch, just as a service to
the programmer.

Processing instructions and comments are indented as though they were
leaf elements except when they occur in leaf elements.

=head2 Example:

This document:

    <a><?A?>
    <!--A--><b><?B?><!--B-->B</b>
        <!--A-->
        </a>

gets reindented as:

    <a>
      <?A?>
      <!--A-->
      <b><?B?><!--B-->B</b>
      <!--A-->
    </a>

(plus or minus a space in each PI, depending on your XML writer).

=cut

use XML::SAX::Base;
@ISA = qw( XML::SAX::Base );

use strict;
use XML::SAX::EventMethodMaker qw( compile_missing_methods sax_event_names);

sub start_document {
    my $self = shift;
    $self->{Depth} = 0;
    $self->{Queue} = [];
    $self->{HasKids} = 0;
    $self->{HasData} = 0;  ## Data = Non-WS text, that is
    $self->{Indent} = "  " unless defined $self->{Indent};
    $self->{Stack} = [];
    $self->SUPER::start_document( @_ );
}


sub _flush_content { 
    ## Called only when a child element has been detected
    my $self = shift;

    my $ctx = $self->{Stack}->[-1];

    my $content = delete $ctx->{Content};
    return unless defined $content;

    while ( @$content ) {
        my $event = shift @$content;

        my $method = shift @$event;

        next if $method eq "characters"
            ||  $method eq "start_cdata"
            ||  $method eq "end_cdata";

        if ( $method eq "comment" || $method eq "processing_instruction") {
            my $indent = $self->{Indent} x @{$self->{Stack}};
            $self->SUPER::characters( { Data => "\n$indent" } );
        }

        $method = "SUPER::$method";
        $self->$method( @$event );
    }
}


sub _flush_leaf_content { 
    ## Called only when no child elements have been detected
    my $self = shift;
    my $ctx = $self->{Stack}->[-1];

    my $content = delete $ctx->{Content};
    return unless defined $content;

    while ( @$content ) {
        my $event = shift @$content;
        my $method = "SUPER::" . shift @$event;
        $self->$method( @$event );
    }
}


sub start_element {
    my $self = shift;

    if ( @{$self->{Stack}} ) {
        my $ctx = $self->{Stack}->[-1];
        die "$ctx->{Name} has both child elements and non-whitespace\n"
            if $ctx->{HasData};

        $self->_flush_content;

        my $indent = $self->{Indent} x @{$self->{Stack}};
        $self->SUPER::characters( { Data => "\n$indent" } );

        $ctx->{HasKids}++;
    }

    push @{$self->{Stack}}, { Name => $_[0]->{Name} };
    $self->SUPER::start_element( @_ );
}


sub characters {
    my $self = shift;

    
    if ( @{$self->{Stack}} ) {
        my $ctx = $self->{Stack}->[-1];

        $ctx->{HasData} ||= $_[0]->{Data} =~ /[^ \t\n]/;

        die "$ctx->{Name} has both child elements and non-whitespace\n"
            if $ctx->{HasData} && $ctx->{HasKids};

        unless ( $ctx->{HasData} ) {
            push @{$ctx->{Content}}, [ characters => @_ ];
            return;
        }

        return if $ctx->{HasKids};
    }
    $self->_flush_leaf_content;
    $self->SUPER::characters( @_ );
}


compile_missing_methods __PACKAGE__, <<'EVENT_END', sax_event_names;
#line 1 XML::Filter::DataIndenter::<EVENT>
sub <EVENT> {
    my $self = shift;
    if ( $self->{Stack} && @{$self->{Stack}} ) {
        my $ctx = $self->{Stack}->[-1];
        unless ( $ctx->{HasData} ) {
            push @{$ctx->{Content}}, [ "<EVENT>", @_ ];
            return;
        }
    }
    ## We get here if the context has data or there's no stack.
    $self->SUPER::<EVENT>( @_ );
}
EVENT_END


sub end_element {
    my $self = shift;

    my $ctx = $self->{Stack}->[-1];

    die "Expected </$ctx->{Name}>, got </$_->[0]->{Name}>\n"
        unless $ctx->{Name} eq $_[0]->{Name};

    if ( $ctx->{HasKids} ) {
        $self->_flush_content;
        my $indent = $self->{Indent} x ( @{$self->{Stack}} - 1 );
        $self->SUPER::characters( { Data => "\n$indent" } );
    }
    else {
        $self->_flush_leaf_content;
    }

    pop @{$self->{Stack}};

    $self->SUPER::end_element( @_ );
}

sub end_document {
    my $self = shift;
    my $ctx = $self->{Stack}->[-1];

    die "Missing end_element events for ",
        map( "<$_->{Name}>", @{$self->{Stack}} ),
        "\n"
        if $self->{Stack} && @{$self->{Stack}};

    $self->SUPER::end_document( @_ );
}


=head1 LIMITATIONS

Considers only [\r\n \t] to be whitespace; does not think about
the broader Unicode definition of whitespace.  This will be addressed
when time and need permit.

=head1 COPYRIGHT

    Copyright 2003, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, oir GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1;
