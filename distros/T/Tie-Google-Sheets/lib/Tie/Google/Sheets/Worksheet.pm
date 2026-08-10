use warnings;
use v5.42;

package Tie::Google::Sheets::Worksheet 0.02 {

    # ABSTRACT: Tie a hash to the cells of a single Google Sheets worksheet

    use Carp qw( croak );

    our @CARP_NOT = qw( Tie::Google::Sheets Tie::Google::Sheets::Client Class::Tiny::Object );

    use Class::Tiny qw( _client _title ), {
        _fetch_mode => 'value',
    };

    sub BUILDARGS ($class, %args) {
        return {
            _client => $args{client},
            _title  => $args{title},
        };
    }

    sub TIEHASH ($class, %args) {
        return $class->new(%args);
    }

    sub fetch_mode ($self, @args) {
        if(@args) {
            my $mode = $args[0];
            croak "fetch_mode must be 'value' or 'formula'"
                unless defined $mode && ($mode eq 'value' || $mode eq 'formula');
            $self->_fetch_mode($mode);
        }
        return $self->_fetch_mode;
    }

    sub _normalize_key ($self, $key) {
        croak "invalid cell reference: $key" unless $key =~ /^[A-Za-z]+[1-9][0-9]*\z/;
        return uc $key;
    }

    sub FETCH ($self, $key) {
        my $method = $self->_fetch_mode eq 'formula' ? 'get_formula' : 'get_value';
        return $self->_client->$method($self->_title, $self->_normalize_key($key));
    }

    sub STORE ($self, $key, $value) {
        $self->_client->update_value($self->_title, $self->_normalize_key($key), $value);
        return $value;
    }

    sub DELETE ($self, $key) {
        $key = $self->_normalize_key($key);
        my $old = $self->FETCH($key);
        $self->_client->clear_value($self->_title, $key);
        return $old;
    }

    sub EXISTS ($self, $key) {
        return defined $self->FETCH($key);
    }

    sub CLEAR ($self) {
        $self->_client->clear_range($self->_title);
        return;
    }

    sub FIRSTKEY ($self) {
        my $method = $self->_fetch_mode eq 'formula' ? 'get_all_formulas' : 'get_all_values';
        my $grid   = $self->_client->$method($self->_title);
        my @keys;
        for my $r (0 .. $grid->$#*) {
            my $row = $grid->[$r] // [];
            for my $c (0 .. $row->$#*) {
                my $val = $row->[$c];
                next unless defined $val && length $val;
                push @keys, _col_letter($c + 1) . ($r + 1);
            }
        }
        $self->{_iter}     = \@keys;
        $self->{_iter_pos} = 0;
        return $self->NEXTKEY;
    }

    sub NEXTKEY ($self, $lastkey = undef) {
        my $keys = $self->{_iter} // [];
        return undef if $self->{_iter_pos} >= @$keys;
        return $keys->[ $self->{_iter_pos}++ ];
    }

    sub _col_letter ($n) {
        my $s = '';
        while($n > 0) {
            my $rem = ($n - 1) % 26;
            $s = chr(65 + $rem) . $s;
            $n = int(($n - 1) / 26);
        }
        return $s;
    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Google::Sheets::Worksheet - Tie a hash to the cells of a single Google Sheets worksheet

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Tie::Google::Sheets;
 
 tie my %doc, 'Tie::Google::Sheets', spreadsheet_id => $id, service_account => $key_file;
 
 # $doc{Sheet1} is a plain hashref backed by this class
 $doc{Sheet1}{A1} = 'hello';
 print $doc{Sheet1}{A1};

=head1 DESCRIPTION

This class implements a tied hash representing the cells of a single Google
Sheets worksheet, keyed by A1 notation (C<A1>, C<B12>, and so on). You do not
normally tie this class directly; instead access a worksheet through a
L<Tie::Google::Sheets> hash, which returns one of these for each worksheet
tab.

Hash keys are case insensitive and are normalized to upper case. A key that
does not look like an A1-style cell reference will throw an exception.

=head1 TIE METHODS

This class implements the standard L<perltie> C<TIEHASH> protocol; see
L<perltie> for the full semantics of each method.

=head2 TIEHASH

Constructor, called via C<tie>. Expects C<client> and C<title> named
arguments (a L<Tie::Google::Sheets::Client> instance and a worksheet title,
respectively).

=head2 FETCH

Returns the value of a cell, or C<undef> if it is empty. Returns the
cell's formula instead if L</fetch_mode> is set to C<formula>.

=head2 STORE

Sets the value of a cell.

=head2 DELETE

Clears a cell and returns its previous value (or formula; see
L</fetch_mode>).

=head2 EXISTS

Returns true if a cell has a defined value.

=head2 CLEAR

Clears every cell in the worksheet.

=head2 FIRSTKEY, NEXTKEY

Together implement iteration (C<keys>, C<values>, C<each>) over every
non-empty cell in the worksheet's used range. If L</fetch_mode> is set to
C<formula>, C<values> (and C<each>) yield formulas instead of values.

=head1 METHODS

These are ordinary (non-tie) methods available on the underlying object via
C<tied %{ $doc{$title} }>.

=head2 fetch_mode

 tied(%{ $doc{$title} })->fetch_mode($mode);
 my $mode = tied(%{ $doc{$title} })->fetch_mode;

Gets or sets whether L</FETCH> (and so reading a cell, iterating with
C<values>/C<each>, or deleting a cell) returns a cell's computed value or
its formula text. C<$mode> must be C<value> (the default) or C<formula>.
Does not affect L</STORE>: cells are always written the same way regardless
of C<fetch_mode>, and writing a string starting with C<=> creates a
formula just as it would when typed directly into Google Sheets.

=head1 CAVEATS

Every C<FETCH> or C<STORE> is a separate Google Sheets API call, unless the
owning L<Tie::Google::Sheets> document was constructed with C<batch_size>,
in which case C<STORE> writes are queued and sent together; see
L<Tie::Google::Sheets/batch_size>. Iterating over the hash (with C<keys>,
C<each>, and so on) fetches the whole used range of the worksheet in a
single call. There is no local caching, so be mindful of
L<Google's API quotas|https://developers.google.com/sheets/api/limits>
when accessing many cells.

=head1 SEE ALSO

=over 4

=item L<Tie::Google::Sheets>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
