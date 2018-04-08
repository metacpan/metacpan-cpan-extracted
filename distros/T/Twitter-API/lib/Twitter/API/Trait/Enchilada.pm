package Twitter::API::Trait::Enchilada;
# ABSTRACT: Sometimes you want the whole enchilada
$Twitter::API::Trait::Enchilada::VERSION = '1.0001';
use Moo::Role;
use namespace::clean;

# because you usually want the whole enchilada

my $namespace = __PACKAGE__ =~ s/\w+$//r;
with map join('', $namespace, $_), qw/
    ApiMethods
    NormalizeBooleans
    RetryOnError
    DecodeHtmlEntities
/;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Twitter::API::Trait::Enchilada - Sometimes you want the whole enchilada

=head1 VERSION

version 1.0001

=head1 SYNOPSIS

    use Twitter::API;

    my $client = Twitter::API->new_with_traits(
        traits => 'Enchilada',
        %other_new_options
    );

=head1 DESCRIPTION

This is just a shortcut for applying commonly used traits. Because, sometimes, you just want the whole enchilada.

This role simply bundles the following traits. See those modules for details.

=over 4

=item *

L<ApiMethods|Twitter::API::Trait::ApiMethods>

=item *

L<NormalizeBooleans|Twitter::API::Trait::NormalizeBooleans>

=item *

L<RetryOnError|Twitter::API::Trait::RetryOnError>

=item *

L<DecodeHtmlEntites|Twitter::API::Trait::DecodeHtmlEntities>

=back

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2018 by Marc Mims.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
