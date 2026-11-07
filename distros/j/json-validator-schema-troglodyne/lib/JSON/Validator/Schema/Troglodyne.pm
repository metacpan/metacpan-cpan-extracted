package JSON::Validator::Schema::Troglodyne;
$JSON::Validator::Schema::Troglodyne::VERSION = '1.001';
# ABSTRACT: Troglodyne extensions to the OpenAPIv3 schema validator.

use strict;
use warnings;

use 5.014;

use re '/aa';

use parent qw{JSON::Validator::Schema::OpenAPIv3};

use Data::Validate::Email();
use List::Util qw{any};


sub _validate_type_email {
    my ( $self, $input, $info ) = @_;
    my $path = $self->_troglodyne_path($info);
    return "wrong type, not email" if ref $input;
    return "$path ain't no email I never heard of pardner" unless Data::Validate::Email::is_email($input);
    return;
}


sub _validate_type_callback {
    my ( $self, $input, $info ) = @_;

    my $path = $self->_troglodyne_path($info);

    return "$path is not a fully qualified sub name" unless defined $input && !ref $input;
    my ($modname) = $input =~ m/^([\w:]+)::\w+$/;
    return "$path is not a fully qualified sub name" unless $modname;

    my $modpath = $modname;
    $modpath =~ s{::}{/}g;
    $modpath .= '.pm';

    local $@;
    # Require so we can check the sub exists, but don't dobule-require
    my @available = keys(%INC);
    my $loaded = any { m/\Q$modpath\E/ } @available;
    if (!$loaded) {
        eval { require $modpath; 1 } or return "$path refers to a module ($modname) which cannot be loaded";
    }

    no strict 'refs';
    return "$path refers to a sub which does not exist" unless defined &{$input};
    return;
}


sub _validate {
    my ( $self, $data, $state ) = @_;
    my @errors = $self->SUPER::_validate( $_[1], $state );
    my $schema = $state->{schema};
    return @errors if !@errors || ref $schema ne 'HASH' || ref $schema->{'x-errorMessage'} ne 'HASH';

    my $messages = $schema->{'x-errorMessage'};
    my $here     = JSON::Validator::Error->new( $state->{path} )->path;
    for my $error (@errors) {
        my $keyword = $error->details->[1];
        next if !defined $keyword || !defined $messages->{$keyword};
        my $at = $error->path;
        if ( $keyword eq 'required' ) {
            $at =~ s{/[^/]*\z}{};
            $at ||= '/';
        }
        $error->message( $messages->{$keyword} ) if $at eq $here;
    }
    return @errors;
}

# Build the path the module usually does for errors
sub _troglodyne_path {
    my ($self, $input) = @_;
    return "$input->{base_url}/".join('/', @{$input->{path}});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Validator::Schema::Troglodyne - Troglodyne extensions to the OpenAPIv3 schema validator.

=head1 VERSION

version 1.001

=head1 JSON::Validator::Schema::Troglodyne

Troglodyne LLC's extensions to L<JSON::Validator::Schema::OpenAPIv3>.

There isn't a mechanism to inject validators into L<JSON::Validator::Formats>,
so here we are.

Relies entirely on the dynamic dispatch of validator methods via _validate_type_*name* subs being called.

L</x-errorMessage> similarly uses the internal sub C<_validate>, to override less than useful error messages.

If any of that changes upstream, this module will break.

=head2 TYPES

=head3 email

Uses L<Data::Validate::Email>::is_email() to validate your email field.

=head3 callback

Signify that this data is a string describing a fully qualified perl subroutine.

=head2 KEYWORDS

=head3 x-errorMessage

A hash of messages by the keyword that fails, as the keyword of the same name
in ajv-errors takes it.  When the data fails the schema that has it, at that
place in the data, the error has the message of that keyword in place of the
generic one of L<JSON::Validator::Error>:

    {
        type             => 'object',
        minProperties    => 1,
        not              => { required => ['test'], maxProperties => 1 },
        'x-errorMessage' => {
            minProperties => 'names no packager',
            not           => 'names no packager, only a test',
        },
    }

Under C<additionalProperties>, that gives
C</ffmpeg: names no packager, only a test> for
C<< { ffmpeg => { test => 'x' } } >>, where JSON::Validator says
C<Should not match.>

The message of C<required> goes to the error of each missing property, whose
path is that of the property.  An error that a subschema gives deeper in the
data keeps its own message, and so does an error of a keyword that the hash
does not name.  OpenAPI v3 ignores the keywords that start with C<x->, so a
schema with this keyword is still a valid one.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/Troglodyne-Internet-Widgets/perl-json-validator-schema-troglodyne/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <teodesian@gmail.com>

=back

=head1 CONTRIBUTOR

=for stopwords troglodyne-robot

troglodyne-robot <trogbot@troglodyne.net>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
