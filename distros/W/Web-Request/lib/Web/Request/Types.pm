package Web::Request::Types;
BEGIN {
  $Web::Request::Types::AUTHORITY = 'cpan:DOY';
}
{
  $Web::Request::Types::VERSION = '0.11';
}
use strict;
use warnings;

use Moose::Util::TypeConstraints;

class_type('HTTP::Headers');

subtype 'Web::Request::Types::StringLike',
    as 'Object',
    where {
        return unless overload::Method($_, '""');
        my $tc = find_type_constraint('Web::Request::Types::PSGIBodyObject');
        return !$tc->check($_);
    };

duck_type 'Web::Request::Types::PSGIBodyObject' => ['getline', 'close'];

subtype 'Web::Request::Types::PSGIBody',
    as 'ArrayRef[Str|Web::Request::Types::StringLike]|FileHandle|Web::Request::Types::PSGIBodyObject';

subtype 'Web::Request::Types::HTTPStatus',
    as 'Int',
    where { /^[1-5][0-9][0-9]$/ };

subtype 'Web::Request::Types::HTTP::Headers',
    as 'HTTP::Headers';
coerce 'Web::Request::Types::HTTP::Headers',
    from 'ArrayRef',
    via { HTTP::Headers->new(@$_) },
    from 'HashRef',
    via { HTTP::Headers->new(%$_) };

coerce 'Web::Request::Types::PSGIBody',
    from 'Str|Web::Request::Types::StringLike',
    via { [ $_ ] };

1;

__END__

=pod

=head1 NAME

Web::Request::Types

=head1 VERSION

version 0.11

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
