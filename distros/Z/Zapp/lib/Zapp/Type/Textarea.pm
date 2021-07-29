package Zapp::Type::Textarea;
use Mojo::Base 'Zapp::Type::Text', -signatures;

1;

=pod

=head1 NAME

Zapp::Type::Textarea

=head1 VERSION

version 0.005

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
@@ input.html.ep
%= include 'zapp/textarea', name => 'value', value => $value // $config

@@ config.html.ep
<label for="config">Value</label>
%= include 'zapp/textarea', name => 'config', value => $config

@@ output.html.ep
<div class="text-break text-pre-wrap">
    %= $value
</div>

