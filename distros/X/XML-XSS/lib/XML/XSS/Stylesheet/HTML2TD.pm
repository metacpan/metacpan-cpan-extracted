package XML::XSS::Stylesheet::HTML2TD;
our $AUTHORITY = 'cpan:YANICK';
$XML::XSS::Stylesheet::HTML2TD::VERSION = '0.3.5';
use Moose;
use XML::XSS;
use Perl::Tidy;

extends 'XML::XSS';

style '*' => (
    pre  => \&pre_element,
    post => '};',
);

style '#text' => (
    process => sub { $_[1]->data =~ /\S/ },
    pre     => "outs '",
    post    => "';",
    filter  => sub { s/'/\\'/g; s/^\s+|\s+$//gm; $_ },
);

style '#document' => (
    content => sub {
        my ( $self, $node, $args ) = @_;
        my $raw = $self->stylesheet->render( $node->childNodes );

        my $output;
        my $err;
        eval { 
            Perl::Tidy::perltidy( 
                source      => \$raw,
                destination => \$output,
                errorfile     => \$err,
             )
        };

        # send the raw output if Tidy failed
        return $err ? $raw : $output;
    },
);

sub pre_element {
    my ( $self, $node ) = @_;

    my $name = $node->nodeName;

    return "$name {" . pre_attrs( $node );
}

sub pre_attrs {
    my $node = shift;

    my @attr = $node->attributes or return '';

    my $output = 'attr { ';

    for ( @attr ) {
        my $value = $_->value;
        $value =~ s/'/&apos;/g;
        $output .= $_->nodeName . ' => ' . "'$value'" . ', ';
    }

    $output .= '};';

    return $output;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::XSS::Stylesheet::HTML2TD

=head1 VERSION

version 0.3.5

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2013, 2011, 2010 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
