# $Id: LibXSLT.pm,v 1.4 2002/02/25 13:08:55 matt Exp $

package XML::Filter::XSLT::LibXSLT;
use strict;

use XML::LibXSLT;
use XML::LibXML::SAX::Builder;
use XML::LibXML::SAX::Parser;

use vars qw(@ISA);
@ISA = qw(XML::LibXML::SAX::Builder);

sub new {
    my $class = shift;
    my %params = @_;
    my $self = bless \%params, $class;
    return $self;
}

sub set_stylesheet_uri {
    # <ubu> hey look, now it does what the synopsis says it can.. ;->
    my $self = shift;
    my $uri = shift;
    $self->{Source}{SystemId} = $uri;
}

sub start_document {
    my $self = shift;

    # copy logic from XML::SAX::Base for getting "something" out of Source key.
    # parse stylesheet
    # store
    # return
    my $parser = XML::LibXML->new;
    my $styledoc;
    if (defined $self->{Source}{CharacterStream}) {
        die "CharacterStream is not supported";
    }
    elsif (defined $self->{Source}{ByteStream}) {
        $styledoc = $parser->parse_fh($self->{Source}{ByteStream}, $self->{Source}{SystemId} || '');
    }
    elsif (defined $self->{Source}{String}) {
        $styledoc = $parser->parse_string($self->{Source}{String}, $self->{Source}{SystemId} || '');
    }
    elsif (defined $self->{Source}{SystemId}) {
        $styledoc = $parser->parse_file($self->{Source}{SystemId});
    }
    
    if (!$styledoc) {
        die "Could not create stylesheet DOM";
    }

    $self->{StylesheetDOM} = $styledoc;
    $self->SUPER::start_document(@_)

}

sub end_document {
    my $self = shift;
    my $dom = $self->SUPER::end_document(@_);
    # parse stylesheet 
    my $xslt = XML::LibXSLT->new;
    my $stylesheet = $xslt->parse_stylesheet($self->{StylesheetDOM});
    # transform
    my $results = $stylesheet->transform($dom);
    # serialize to Handler and co.
    my $parser = XML::LibXML::SAX::Parser->new(%$self);
    $parser->generate($results);
}

sub set_handler {
    my $self = shift;
    $self->{Handler} = shift;
    $self->{Parser}->set_handler( $self->{Handler} )
        if $self->{Parser};
}

1;
__END__

=head1 NAME

XML::Filter::XSLT::LibXSLT - LibXSLT SAX Filter

=head1 SYNOPSIS

None - use via XML::Filter::XSLT please.

=head1 DESCRIPTION

See above. This is a black box!

=cut
