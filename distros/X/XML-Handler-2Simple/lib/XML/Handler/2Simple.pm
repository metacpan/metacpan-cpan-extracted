=head1 NAME

XML::Handler::2Simple - SAX => XML::Simple handler

=head1 SYNOPSIS

    my $h = XML::Handler::2Simple->new(
        %xml_simple_options,
        DataHandler => \&sub_to_handle_result, ## optional
    );

    my $p = XML::SAX::ParserFactory->parser( Handler => $h );

    my $data_struct = $p->parse_uri( $file );

=head1 DESCRIPTION

This module accepts a SAX stream and converts it in to a Perl data structure
using L<XML::Simple|XML::Simple>.  The resulting object can be passed to
a subroutine and is returned after the parse.

For example, here's a SAX machine that outputs all of the records in
a record oriented XML file:

    use XML::Handler::2Simple;
    use XML::SAX::Machines qw( ByRecord );

    use IO::Handle;   ## Needed because LibXML uses it without loading it
    use Data::Dumper;

    $Data::Dumper::Indent    = 1;  ## Clean up Data::Dumper's output a wee bit
    $Data::Dumper::Terse     = 1;
    $Data::Dumper::Quotekeys = 1;

    ByRecord(
        XML::Handler::2Simple->new(
            DataHandler => sub {
                warn Dumper( $_[1] );
            },
        )
    )->parse_file( \*STDIN );

=cut

package XML::Handler::2Simple;

$VERSION= 0.1;

use XML::Handler::Trees;

@ISA = qw( XML::Handler::Tree );

sub new {
    my $proto = shift;
    my $self = $proto->SUPER::new();

    $self->{MySimple} = XML::Handler::2Simple::MySimple->new( @_ );

    return $self;
}

sub set_handler {
    ## We don't need no steenkin' handler, but if we're last in a machine
    ## we might be asked to set one.
}

sub end_document {
    my $self = shift;

    my $output = $self->{MySimple}->XMLin(
        $self->SUPER::end_document( {} )
    );

    if ( exists $self->{DataHandler} ) {
        $self->{DataHandler}->( $self, $output );
    }

    return $output;
}

package XML::Handler::2Simple::MySimple;
use XML::Simple;
@ISA = qw( XML::Simple );

sub build_tree { return $_[2] }

=head1 AUTHOR

    Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

    Copyright 2002, Barrie Slaymaker, All Rights Reserved.

You may use this module under the terms of any of the Artistic, GNU Public,
or BSD licenses, your choice.

=cut

1;
