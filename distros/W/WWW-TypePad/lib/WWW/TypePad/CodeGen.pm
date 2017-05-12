
=head1 NAME

WWW::TypePad::CodeGen - Functions for auto-generating this library from the API's reflection endpoint

=cut

package WWW::TypePad::CodeGen;

use strict;
use warnings;

use String::CamelCase qw(camelize decamelize);

sub handle_object {
    my($key, $mapping) = @_;

    my $name = camelize($key);
    my $file = "lib/WWW/TypePad/$name.pm";
    rewrite_file($mapping, $name, $file);
}

sub rewrite_file {
    my($mapping, $package, $file) = @_;

    my $content = slurp($file) || stub_for($package, $mapping);
    $content =~ s/### BEGIN auto-generated.*### END auto-generated\n/generate_code($package, $mapping)/egs
        or return warn "$file: auto-generated code marked was not found.\n";

    warn "Writing $file\n";
    open my $fh, ">", $file or die "$file: $!";
    print $fh $content;
}

sub generate_code {
    my($package, $mapping) = @_;

    my %podesc = ('<' => 'E<lt>', '>' => 'E<gt>');

    my $stash = {
        package => $package,
        mapping => $mapping,
        safe => sub { $_[0] =~ tr/-/_/; $_[0] },
        decamelize => sub { decamelize($_[0]) },
        mangle_method => sub {
            my $method = $_[0];
            $method =~ s/^get([A-Z])/$1/;
            decamelize($method);
        },
        path_format => sub { join '/', map { defined $_ ? $_ : '%s' } @{$_[0]} },
        keys_sorted_by_value => sub { sort { $_[0]->{$a} <=> $_[0]->{$b} } keys %{$_[0]} },
        escape_pod => sub {
            $_[0] =~ s/T<(.*?)>/B<$1>/g;
            $_[0] =~ s/([<>])/$podesc{$1}/g;
            $_[0];
        },
    };

    my $tt = Template->new;
    $tt->process(\<<'TEMPLATE', $stash, \my $output) or die $tt->error;
### BEGIN auto-generated
### This is an automatically generated code, do not edit!
### Scroll down to look for END to add additional methods

=pod

=head1 NAME

WWW::TypePad::[% package %] - [% package %] API methods

=head1 METHODS

=cut

use strict;
use Any::Moose;
extends 'WWW::TypePad::Noun';

use Carp ();

[% FOREACH method IN mapping.methods -%]

[%- SET canonical = decamelize(method.methodName);
    SET mangled   = mangle_method(method.methodName);
    SET params    = keys_sorted_by_value( method.pathParams ) -%]

=pod

[% IF loop.first %]=over 4
[% END %]

=item [% canonical %]

  my $res = $tp->[% decamelize(package) %]->[% canonical %]([% FOREACH param IN params %]$[% param %][% UNLESS loop.last %], [% END %][% END %]);

[% escape_pod(method.docString) %]

Returns [% escape_pod(method.returnObjectType.name) || 'hash reference' %] which contains following properties.

=over 8

[% FOREACH prop IN method.returnObjectType.properties -%]
=item [% prop.name %]

([% escape_pod(prop.type) %]) [% escape_pod(prop.docString) %]

[% END -%]

=back

=cut

sub [% canonical %] {
    my $api = shift;
    my @args;
[% FOREACH param IN params -%]
    push @args, shift; # [% param %]
[% END -%]
    my $uri = sprintf '/[% path_format(method.pathChunks) %].json', @args;
    $api->base->call("[% method.httpMethod %]", $uri, @_);
}

[% IF canonical != mangled %]
sub [% mangled %] {
    my $self = shift;
    Carp::carp("'[% mangled %]' is deprecated. Use '[% canonical %]' instead.");
    $self->[% canonical %](@_);
}
[% END -%]
[% END # FOREACH method -%]

=pod

=back

=cut

### END auto-generated
TEMPLATE

    return $output;
}

sub slurp {
    my $file = shift;
    open my $fh, "<", $file or return;
    join '', <$fh>;
}

sub stub_for {
    my $package = shift;
    my $accessor_name = decamelize($package);
    return <<EOT;
package WWW::TypePad::$package;

use strict;
use warnings;

# Install an accessor into WWW::TypePad to access an instance of this class
# bound to the WWW::TypePad instance.
sub WWW::TypePad::$accessor_name { __PACKAGE__->new( base => \$_[0] ) }

### BEGIN auto-generated

### END auto-generated

1;
EOT
}


1;
