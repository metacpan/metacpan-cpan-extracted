#!/usr/bin/perl

package XML::LibXSLT::Easy::Batch;
use Moose;

use Carp qw(croak);

use XML::LibXSLT::Easy;

use File::Glob;

use MooseX::Types::Path::Class;

use namespace::clean -except => [qw(meta)];

has proc => (
    isa => "XML::LibXSLT::Easy",
    is  => "rw",
    lazy_build => 1,
    handles => { "process_file" => "process" },
);

sub _build_proc {
    XML::LibXSLT::Easy->new;
}

has files => (
    isa => "ArrayRef[HashRef[Str|Path::Class::File]]",
    is  => "ro",
);

sub process {
    my ( $self, @files ) = @_;

    foreach my $entry ( @files ? @files : @{ $self->files || croak "No files to process" } ) {
        $self->process_entry(%$entry);
    }
}

sub process_entry {
    my ( $self, %args ) = @_;

    if ( -f $args{xml} and -f $args{xsl} ) {
        $self->process_file(%args);
    } elsif ( $args{xml} =~ /\*/ ) {
        $self->process_file(%$_) for $self->expand(%args);
    }
}

sub expand {
    my ( $self, %args ) = @_;

    my ( $xml_glob, $xsl_glob, $out_glob ) = @args{qw(xml xsl out)};

    ( $out_glob = $xml_glob ) =~ s/xml$/html/ unless $out_glob;
    ( $xsl_glob = $xml_glob ) =~ s/xml$/xsl/  unless $xsl_glob;

    croak "output cannot be the same as input" unless $out_glob ne $xml_glob;
    croak "xsl cannot be the same as input"    unless $xsl_glob ne $xml_glob;

    # from Locale::Maketext:Lexicon
    my $pattern = quotemeta($xml_glob);
    $pattern =~ s/\\\*(?=[^*]+$)/\([-\\w]+\)/g or croak "bad glob: $xml_glob";

    # convert glob to regex
    $pattern =~ s/\\\*/.*?/g; # foo*bar
    $pattern =~ s/\\\?/./g;   # foo?bar
    $pattern =~ s/\\\[/[/g;   # [a-z]
    $pattern =~ s/\\\]/]/g;   # [a-z]
    $pattern =~ s[\\\{(.*?)\\\\}][ '(?:' . join('|', split(/,/, $1)). ')' ]eg; # {foo,bar}

    my @ret;

    foreach my $xml ( File::Glob::bsd_glob($xml_glob) ) {
        $xml =~ /$pattern/ or next;
        my $basename = $1;

        my ( $xsl, $out ) = ( $xsl_glob, $out_glob );

        s/\*/$basename/e for $xsl, $out;

        push @ret, { xml => $xml, xsl => $xsl, out => $out };
    }

    return @ret;
}

__PACKAGE__

__END__

=pod

=head1 NAME

XML::LibXSLT::Easy::Batch - 

=head1 SYNOPSIS

    use XML::LibXSLT::Easy::Batch;

=head1 DESCRIPTION

=cut


