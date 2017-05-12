package Text::Migemo;
use strict;
use warnings;
use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK);

BEGIN {
    $VERSION = '0.01';
    if ($] > 5.006) {
        require XSLoader;
        XSLoader::load(__PACKAGE__, $VERSION);
    } else {
        require DynaLoader;
        @ISA = qw(DynaLoader);
        __PACKAGE__->bootstrap;
    }

    require Exporter;
    push @ISA, 'Exporter';

    %EXPORT_TAGS = (all => [qw(
        MIGEMO_DICTID_MIGEMO
        MIGEMO_DICTID_ROMA2HIRA
        MIGEMO_DICTID_HIRA2KATA
        MIGEMO_DICTID_HAN2ZEN
        MIGEMO_DICTID_INVALID
        MIGEMO_OPINDEX_OR
        MIGEMO_OPINDEX_NEST_IN
        MIGEMO_OPINDEX_NEST_OUT
        MIGEMO_OPINDEX_SELECT_IN
        MIGEMO_OPINDEX_SELECT_OUT
        MIGEMO_OPINDEX_NEWLINE
    )]);
    @EXPORT_OK = map { @$_ } values %EXPORT_TAGS;
}

*open = \&new;

1;
__END__

=head1 NAME

Text::Migemo - Migemo library module for Perl

=head1 SYNOPSIS

    use Text::Migemo;

    my $migemo = Text::Migemo->new;
    $migemo->load(MIGEMO_DICTID_MIGEMO, $dict);
    # or my $migemo = Text::Migemo->new($dict);
    my $result = $migemo->query($query);

=head1 DESCRIPTION

This module is an interface for C/Migemo library.
It is available at: http://www.kaoriya.net/#CMIGEMO

=head1 METHODS

=over 4

=item new

Returns new Migemo object.

=item open

This is an alias to new.

=item load

Load dictionary.

=item query

Convert to regex.

=item is_enable

Returns Migemo object is enable or disable.

=item set_operator

Set operator.

=item get_operator

Get operator.

=back

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

http://www.kaoriya.net/#CMIGEMO

=cut
