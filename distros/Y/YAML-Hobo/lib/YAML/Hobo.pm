
package YAML::Hobo;
$YAML::Hobo::VERSION = '0.1.0';
# ABSTRACT: Poor man's YAML

BEGIN {
    require YAML::Tiny;
    YAML::Tiny->VERSION('1.70');
    our @ISA = qw(YAML::Tiny);
}

our @EXPORT_OK = qw(Dump Load);

sub Dump {
    return YAML::Hobo->new(@_)->_dump_string;
}

sub Load {
    my $self = YAML::Hobo->_load_string(@_);
    if (wantarray) {
        return @$self;
    }
    else {
        # To match YAML.pm, return the last document
        return $self->[-1];
    }
}

sub _dump_scalar {
    my $string = $_[1];
    my $is_key = $_[2];

    # Check this before checking length or it winds up looking like a string!
    my $has_string_flag = YAML::Tiny::_has_internal_string_value($string);
    return '~'  unless defined $string;
    return "''" unless length $string;
    if ( Scalar::Util::looks_like_number($string) ) {

        # keys and values that have been used as strings get quoted
        if ( $is_key || $has_string_flag ) {
            return qq|"$string"|;
        }
        else {
            return $string;
        }
    }
    if ( $string =~ /[\x00-\x09\x0b-\x0d\x0e-\x1f\x7f-\x9f\'\n]/ ) {
        $string =~ s/\\/\\\\/g;
        $string =~ s/"/\\"/g;
        $string =~ s/\n/\\n/g;
        $string =~ s/[\x85]/\\N/g;
        $string =~ s/([\x00-\x1f])/\\$UNPRINTABLE[ord($1)]/g;
        $string =~ s/([\x7f-\x9f])/'\x' . sprintf("%X",ord($1))/ge;
        return qq|"$string"|;
    }
    if (   $string =~ /(?:^[~!@#%&*|>?:,'"`{}\[\]]|^-+$|\s|:\z)/
        or $QUOTE{$string} )
    {
        return "'$string'";
    }
    return $is_key ? $string : qq|"$string"|;
}

1;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use YAML::Hobo;
#pod
#pod     $yaml = YAML::Hobo::Dump(
#pod         {   release => { dist => 'YAML::Tiny', version => '1.70' },
#pod             author  => 'ETHER'
#pod         }
#pod     );
#pod
#pod     # ---
#pod     # author: "ETHER"
#pod     # release:
#pod     #   dist: "YAML::Tiny"
#pod     #   version: "1.70"
#pod
#pod =head1 DESCRIPTION
#pod
#pod L<YAML::Hobo> is a module to read and write a limited subset of YAML.
#pod It does two things: reads YAML from a string – with C<Dump> –
#pod and dumps YAML into a string – via C<Load>.
#pod
#pod Its only oddity is that, when dumping, it prefers double-quoted strings,
#pod as illustrated in the L</SYNOPSIS>.
#pod
#pod L<YAML::Hobo> is built on the top of L<YAML::Tiny>.
#pod So it deals with the same YAML subset supported by L<YAML::Tiny>.
#pod
#pod =head1 WHY?
#pod
#pod The YAML specification requires a serializer to impose ordering
#pod when dumping map pairs, which results in a "stable" generated output.
#pod
#pod This module adds to this output normalization by insisting
#pod on double-quoted string for values whenever possible.
#pod This is meant to create a more familiar format avoiding
#pod frequent switching among non-quoted text, double-quoted and single-quoted strings.
#pod
#pod The intention is to create a dull homogeneous output,
#pod a poor man's YAML, which is quite obvious and readable.
#pod
#pod =head1 FUNCTIONS
#pod
#pod =head2 Dump
#pod
#pod     $string = Dump(list-of-Perl-data-structures);
#pod
#pod Turns Perl data into YAML.
#pod
#pod =head2 Load
#pod
#pod     @data_structures = Load(string-containing-a-YAML-stream);
#pod
#pod Turns YAML into Perl data.
#pod
#pod =head1 CAVEAT
#pod
#pod This module does not export any function.
#pod But it declares C<Dump> and C<Load> as exportable.
#pod That means you can use them fully-qualified – as C<YAML::Hobo::Dump>
#pod and C<YAML::Hobo::Load> – or you can use an I<importer>, like
#pod L<Importer> or L<Importer::Zim>. For example,
#pod
#pod     use zim 'YAML::Hobo' => qw(Dump Load);
#pod
#pod will make C<Dump> and C<Load> available to the code that follows.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<YAML::Tiny>
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

YAML::Hobo - Poor man's YAML

=head1 VERSION

version 0.1.0

=head1 SYNOPSIS

    use YAML::Hobo;

    $yaml = YAML::Hobo::Dump(
        {   release => { dist => 'YAML::Tiny', version => '1.70' },
            author  => 'ETHER'
        }
    );

    # ---
    # author: "ETHER"
    # release:
    #   dist: "YAML::Tiny"
    #   version: "1.70"

=head1 DESCRIPTION

L<YAML::Hobo> is a module to read and write a limited subset of YAML.
It does two things: reads YAML from a string – with C<Dump> –
and dumps YAML into a string – via C<Load>.

Its only oddity is that, when dumping, it prefers double-quoted strings,
as illustrated in the L</SYNOPSIS>.

L<YAML::Hobo> is built on the top of L<YAML::Tiny>.
So it deals with the same YAML subset supported by L<YAML::Tiny>.

=head1 WHY?

The YAML specification requires a serializer to impose ordering
when dumping map pairs, which results in a "stable" generated output.

This module adds to this output normalization by insisting
on double-quoted string for values whenever possible.
This is meant to create a more familiar format avoiding
frequent switching among non-quoted text, double-quoted and single-quoted strings.

The intention is to create a dull homogeneous output,
a poor man's YAML, which is quite obvious and readable.

=head1 FUNCTIONS

=head2 Dump

    $string = Dump(list-of-Perl-data-structures);

Turns Perl data into YAML.

=head2 Load

    @data_structures = Load(string-containing-a-YAML-stream);

Turns YAML into Perl data.

=head1 CAVEAT

This module does not export any function.
But it declares C<Dump> and C<Load> as exportable.
That means you can use them fully-qualified – as C<YAML::Hobo::Dump>
and C<YAML::Hobo::Load> – or you can use an I<importer>, like
L<Importer> or L<Importer::Zim>. For example,

    use zim 'YAML::Hobo' => qw(Dump Load);

will make C<Dump> and C<Load> available to the code that follows.

=head1 SEE ALSO

L<YAML::Tiny>

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
