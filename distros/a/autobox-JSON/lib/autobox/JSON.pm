package autobox::JSON;
$autobox::JSON::VERSION = '0.0006';
use 5.008;
use strict;
use warnings;

use parent 'autobox';

sub import {
    my ($class) = @_;

    $class->SUPER::import(
        HASH => 'autobox::JSON::Ref',
        ARRAY => 'autobox::JSON::Ref',
        STRING => 'autobox::JSON::String',
    );
}

=head1 NAME

autobox::JSON - bringing JSON functions to autobox

=head1 VERSION

version 0.0006

=head1 SYNOPSIS

    use autobox::JSON;

    say {name => 'Jim', age => 34}->encode_json;
    # {"name":"Jim","age":46}

    my $person = '{"name":"Jim","age":46}'->decode_json
    # {name => 'Jim', age => 34}

    my $serialized_person = $person->encode_json;
    # {"name":"Jim","age":46}

    # works on arrays too
    [1, 2, 3, 4, 5]->encode_json;

=head1 METHODS

=head2 encode_json

This method behaves the same as L<JSON/encode_json>.

=head2 encode_json_pretty

This method is identical to L</encode_json>, except that it also "prettifies"
the output, making it easier for us mortals to read.  This is useful
especially when dumping a JSON structure to something reasonable for, say,
debug or other purposes.

It is functionally the same as:

    JSON->new->utf8->canonical->pretty->encode($ref)

=head2 decode_json

This method behaves the same as L<JSON/decode_json>.

=head1 DEPRECIATED METHODS

=head2 to_json (depreciated)

This method behaves the same as L<JSON/to_json>.

This method is depreciated because the JSON documentation itself
prefers encode_json.

=head2 from_json (depreciated)

This method behaves the same as L<JSON/from_json>.

This method is depreciated as the JSON documentation itself
prefers decode_json.

=head1 SEE ALSO

C<autobox> C<JSON> C<autobox::Core>

=head1 AUTHOR

Robin Edwards, E<lt>robin.ge@gmail.comE<gt>

L<http://github.com/robinedwards/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Robin Edwards

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

package autobox::JSON::String;
$autobox::JSON::String::VERSION = '0.0006';
require JSON;
sub from_json { JSON::from_json(shift); }
sub decode_json { JSON::decode_json(shift); }

package autobox::JSON::Ref;
$autobox::JSON::Ref::VERSION = '0.0006';
require JSON;
sub to_json { JSON::to_json(shift); }
sub encode_json { JSON::encode_json(shift); }
sub encode_json_pretty { JSON->new->utf8->canonical->pretty->encode(shift); }

1;
