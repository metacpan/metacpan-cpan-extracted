package WebAPI::DBIC::Role::JsonEncoder;
$WebAPI::DBIC::Role::JsonEncoder::VERSION = '0.004002';

use JSON::MaybeXS qw(JSON);

use Moo::Role;


has _json_encoder => (
   is => 'ro',
   builder => '_build_json_encoder',
   handles => {
      encode_json => 'encode',
      decode_json => 'decode',
   },
);

sub _build_json_encoder {
    my $codec = JSON->new->ascii;
    $codec->canonical->pretty if $ENV{WEBAPI_DBIC_DEBUG};
    return $codec;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebAPI::DBIC::Role::JsonEncoder

=head1 VERSION

version 0.004002

=head1 NAME

WebAPI::DBIC::Resource::Role::JsonEncoder - provides encode_json and decode_json methods

=head1 AUTHOR

Tim Bunce <Tim.Bunce@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Tim Bunce.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
