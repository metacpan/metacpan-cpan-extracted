package XML::LibXML::SAX::ChunkParser;
use strict;
use base qw(XML::SAX::Base);
use XML::LibXML;
use Carp qw(croak);

our $VERSION = '0.00008';

sub DESTROY {
    my $self = shift;
    $self->clean_parser;
}

sub clean_parser {
    my $self = shift;

    my $option = delete $self->{ParserOptions};
    if (! $option) {
        return;
    }
    my $parser = delete $option->{LibParser};
    if (! $parser) {
        return;
    }
    # break a possible circular reference    
    $parser->set_handler( undef );
}

sub get_parser {
    my $self = shift;
    my $options = $self->{ParserOptions};
    if (! $options) {
        $options = {};
        $self->{ParserOptions} = $options;
    }

    my $parser = $options->{LibParser};
    if (! $parser) {
        $parser = $options->{LibParser} = XML::LibXML->new;
        $parser->set_handler($self);
    }
    return $parser;
}

sub parse_chunk {
    my ($self, $chunk) = @_;

    my $parser = $self->get_parser();
    eval {
        $parser->parse_chunk( $chunk );
    };

    if ( $parser->{SAX}->{State} == 1 ) {
        croak( "SAX Exception not implemented, yet; Data ended before document ended\n" );
    }

    if ( $@ ) {
        croak $@;
    }
}

sub finish {
    my $self = shift;

    my $parser = $self->get_parser();
    if ($parser) {
        $parser->parse_chunk("", 1);
    }

    $self->clean_parser();
}

1;

__END__

=head1 NAME

XML::LibXML::SAX::ChunkParser - Parse XML Chunks Via LibXML SAX

=head1 SYNOPSIS

  local $XML::SAX::ParserPackage = 'XML::LibXML::SAX::ChunkParser';
  my $parser = XML::SAX::ParserFactory->parser(Handler => $myhandler);

  $parser->parse_chunk($xml_chunk);

=head1 DESCRIPTION

XML::LibXML::SAX::ChunkParser uses XML::LibXML's parse_chunk (as opposed to
parse_xml_chunk/parse_balanced_chunk), which XML::LibXML::SAX uses.

Its purpose is to simply keep parsing possibly incomplete XML fragments,
for example, from a socket.

=head1 METHODS

=head2 parse_chunk

Parses possibly incomplete XML fragment

=head2 finish

Explicitly tell the parser that we're done parsing

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut