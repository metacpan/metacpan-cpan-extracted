package Text2URI;
use Moose;
use Text::Unaccent::PurePerl qw(unac_string);

our $VERSION = "0.4";

has old_alphanumeric_regexp => (
    is   => 'rw',
    isa  => 'Int',
    default => sub {0}
);

sub translate {
    my ($self, $text, $sep) = @_;
    $sep ||= '-';

    $text = lc unac_string(   $text );

    $text =~ s/^\s+//o;
    $text =~ s/\s+$//o;

    if ($self->old_alphanumeric_regexp){
        $text =~ s/\W+/$sep/go;
    }else{
        $text =~ s/[^\w\.]+/$sep/go;
    }
    $text =~ s/$sep+/$sep/go;
    $text =~ s/$sep$//o;
    $text =~ s/^$sep//o;

    return $text;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Text2URI

=head1 VERSION

version 0.3001

=head1 SYNOPSIS

    use Text2URI;

    my $t = new Text2URI();

    print $t->translate("Atenção SomeText (0)2302-3234   otherthing    !!");
    # atencao-sometext-0-2302-3234-otherthing

    print $t->translate("Sell your house",'_');
    # sell_your_house

    # you can pass C<old_alphanumeric_regexp => 1> to alternate between C<\W+> or C<[^\w\.]+> regexp.
    # default to old_alphanumeric_regexp => 0 that means C<[^\w\.]+>
    # you can change it between calls too. $t->old_alphanumeric_regexp(1) to enable.


=head1 DESCRIPTION

Simple but effective transform text to a "url friendly" string! Just it

=head1 NAME

Text2URI - Transform text to a "url friendly" string


=head1 SEE ALSO

Text::Unaccent - Remove accents from a string. I'm using this since v0.3001 because lots of plataforms broken with ASNCI/Translit.



=head1 AUTHOR

Renato Cron <renato@aware.com.br>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Aware TI <http://www.aware.com.br>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


