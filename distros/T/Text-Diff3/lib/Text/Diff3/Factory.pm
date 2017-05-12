package Text::Diff3::Factory;
# Factory for component style interface.
use 5.006;
use strict;
use warnings;

use version; our $VERSION = '0.08';

use Text::Diff3::Diff3;
use Text::Diff3::DiffHeckel;
use Text::Diff3::Text;
use Text::Diff3::Range2;
use Text::Diff3::Range3;
use Text::Diff3::List;

# for user
sub new { return $_[0] }
sub create_text { return Text::Diff3::Text->new(@_) }
sub create_diff3 { return Text::Diff3::Diff3->new(@_) }
sub create_diff { return Text::Diff3::DiffHeckel->new(@_) }

# for internal use
sub create_list3 { return Text::Diff3::List->new(@_) }
sub create_range3 { return Text::Diff3::Range3->new(@_) }
sub create_null_range3 {
    return Text::Diff3::Range3->new($_[0], undef, 0,0, 0,0, 0,0)
}
sub create_list2 { return Text::Diff3::List->new(@_) }
sub create_range2 { return Text::Diff3::Range2->new(@_) }
sub create_test { return Text::Diff3::Base->new(@_) }

1;

__END__

=pod

=head1 NAME

Text::Diff3::Factory - factory for component used by Text::Diff3 modules.

=head1 VERSION

0.08

=head1 SYNOPSIS

  use Text::Diff3;
  my $f = Text::Diff3::Factory->new;
  my $p = $f->create_diff3;
  my $mytext = $f->create_text([ map{chomp;$_} <F0> ]);

=head1 DESCRIPTION

This is the factory for the Text::Diff3 modules. It provides you
to make data and processing instances, such as text, diff3,
and diff. If you need to use some data or processor class, you
replace this as your like.

=head1 METHODS

=over

=item C<< Text::Diff3::Factory->new >>

Returns a factory instance.

=item C<< $factory->create_text($array or $string) >>

Creates a text buffer object from parameters.

=item C<< $factory->create_diff3 >>

Creates a diff3 processor.

=item C<< $factory->create_diff >>

Creates a two-way diff processor.

=item C<< $factory->create_list3 >>

Creates a list of range3 instances for internal use.

=item C<< $factory->create_range3 >>

Creates a range container of diff3 for internal use.

=item C<< $factory->create_null_range3 >>

Creates a null range container of diff3 for internal use.

=item C<< $factory->create_list2 >>

Creates a list of range2 instances for internal use.

=item C<< $factory->create_range2 >>

Creates a range container of diff for internal use.

=item C<< $f->create_test >>

Creates a container for test suits.

=back

=head1 COMPATIBILITY

Use new function style interfaces introduced from version 0.08.
This module remained for backward compatibility before version 0.07.
This module is no longer maintenance after version 0.08.

=head1 AUTHOR

MIZUTANI Tociyuki C<< <tociyuki@gmail.com> >>.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2010 MIZUTANI Tociyuki

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

=cut

