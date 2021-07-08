=pod

=head1 NAME

WGmeta::Parser::Conf - Parser for Wireguard configurations

=head1 SYNOPSIS

    use Wireguard::WGmeta::Parser::Conf;
    use Wireguard::WGmeta::Util;

    # Parse a wireguard configuration file
    my $config_contents = read_file('/path/to/config.conf', 'interface_name');

    # Define callbacks
    my $on_every_value_callback = sub($attribute, $value, $is_wg_meta){
        # do you magic
        return $attribute, $value;
    };
    my $on_every_section_callback = sub($identifier, $section_type, $is_disabled){
        # do you magic
        return $identifier;
    };

    # And finally parse the configuration
    my $parsed_config = parse_raw_wg_config($config_contents, $on_every_value_callback, $on_every_section_callback);


=head1 DESCRIPTION

Parser for Wireguard I<.conf> files with support for custom attributes. A possible implementation is present in L<Wireguard::WGmeta::Parser::Middleware>.

=head1 METHODS

=cut

package Wireguard::WGmeta::Parser::Conf;
use strict;
use warnings FATAL => 'all';
use experimental 'signatures';

use constant INTERNAL_KEY_PREFIX => 'int_';

use base 'Exporter';
our @EXPORT = qw(parse_raw_wg_config INTERNAL_KEY_PREFIX);

our $VERSION = "0.3.1";

=head3 parse_raw_wg_config($file_content, $on_every_value, $on_new_section [, $skip, $wg_meta_prefix, $wg_disabled_prefix])

Parses a Wireguard configuration

=over 1

=item *

C<$file_content> Content of Wireguard configuration. Warning, if have to ensure that its a valid file!

=item *

C<$on_every_value> A reference to a callback function, fired at every key/value pair. Expected signature:

    my $on_every_value_callback = sub($attribute, $value, $is_wg_meta){
        # do you magic
        return $attribute, $value;
    };

=item *

C<$on_new_section> Callback for every section. Expected signature:

    my $on_every_section_callback = sub($identifier, $section_type, $is_disabled){
        # do you magic
        return $identifier;
    };

=item *

C<[$skip = 0]> When you want to skip some lines at the beginning

=item *

C<[$wg_meta_prefix = '#+']> wg-meta prefix. Must start with '#' or ';'

=item *

C<[$disabled_prefix = '#-']> disabled prefix. Must start with '#' or ';'

=back

B<Returns>

A reference to a hash similar as described in L<Wireguard::WGmeta::Parser::Middleware>.

=cut
sub parse_raw_wg_config($file_content, $on_every_value, $on_new_section, $skip = 0, $wg_meta_prefix = '#+', $wg_disabled_prefix = '#-') {
    my $IDENT_KEY = '';
    my $IS_ACTIVE_COUNTER = 0;
    my $IS_ROOT = 1;
    my $SECTION_TYPE = 'Root';
    my $IS_WG_META = 0;

    my $parsed_config = {};
    my @peer_order;
    my @root_order;

    my $section_data = {};
    my @section_order;
    my $generic_autokey = 0;
    my $line_count = 0;

    my $section_handler = sub {
        if ($IS_ROOT) {
            $parsed_config = $section_data;
            $section_data = {};
        }
        else {
            my $is_disabled = $IS_ACTIVE_COUNTER == 1 ? 1 : 0;
            my $identifier = &{$on_new_section}($section_data->{$IDENT_KEY}, $SECTION_TYPE, $is_disabled);
            die "`$identifier` is already present" if exists($parsed_config->{$identifier});
            $section_data->{INTERNAL_KEY_PREFIX . 'order'} = [ @section_order ];
            $section_data->{'disabled'} = $is_disabled;
            $section_data->{INTERNAL_KEY_PREFIX . 'type'} = $SECTION_TYPE;
            $parsed_config->{$identifier} = { %$section_data };
            push @peer_order, $identifier;
            $section_data = {};
        }

        @section_order = ();
        $IDENT_KEY = 'PublicKey';
        $IS_ACTIVE_COUNTER--;
        $IS_ROOT = 0;
    };

    for my $line (split "\n", $file_content) {
        $line_count++;
        next if $line_count <= $skip;

        # Strip-of any leading or trailing whitespace
        $line =~ s/^\s+|\s+$//g;

        if ((substr $line, 0, 2) eq $wg_disabled_prefix) {
            $line = substr $line, 2;
            $IS_ACTIVE_COUNTER = 2 if $IS_ACTIVE_COUNTER != 1;
        }
        if ((substr $line, 0, 2) eq $wg_meta_prefix) {
            # Also slice-off wg-meta prefixes
            $line = substr $line, 2;
            $IS_WG_META = 1;
        }
        else {
            $IS_WG_META = 0;
        }

        # skip empty lines
        next unless $line;

        # Simply decide if we are in an interface or peer section
        if ((substr $line, 0, 11) eq '[Interface]') {
            &$section_handler();
            $SECTION_TYPE = 'Interface';
            $IDENT_KEY = 'PrivateKey';
            next;
        }
        if ((substr $line, 0, 6) eq '[Peer]') {
            &$section_handler();
            $SECTION_TYPE = 'Peer';
            $IDENT_KEY = 'PublicKey';
            next;
        }
        my ($definitive_key, $definitive_value, $discard);
        unless ((substr $line, 0, 1) eq '#') {
            my ($raw_key, $raw_value) = _split_and_trim($line, '=');
            ($definitive_key, $definitive_value, $discard) = &$on_every_value($raw_key, $raw_value, $IS_WG_META);
            next if $discard == 1;

            # Update identity key if changed
            $IDENT_KEY = $definitive_key if $raw_key eq $IDENT_KEY;
        }
        else {
            # Handle "normal" comments
            $definitive_key = "comment_$generic_autokey";
            $definitive_value = $line;
        }
        $section_data->{$definitive_key} = $definitive_value;
        $IS_ROOT ? push @root_order, $definitive_key : push @section_order, $definitive_key;
        $generic_autokey++;
    }
    # and finalize
    &$section_handler();
    $parsed_config->{INTERNAL_KEY_PREFIX . 'section_order'} = \@peer_order;
    $parsed_config->{INTERNAL_KEY_PREFIX . 'root_order'} = \@root_order;

    return $parsed_config;
}

sub _split_and_trim($line, $separator) {
    return map {s/^\s+|\s+$//g;
        $_} split $separator, $line, 2;
}

1;