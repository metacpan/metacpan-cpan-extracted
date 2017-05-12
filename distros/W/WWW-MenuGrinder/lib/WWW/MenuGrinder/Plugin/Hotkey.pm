package WWW::MenuGrinder::Plugin::Hotkey;
BEGIN {
  $WWW::MenuGrinder::Plugin::Hotkey::VERSION = '0.06';
}

# ABSTRACT: WWW::MenuGrinder plugin that generates hotkeys from labels.

use Moose;

with 'WWW::MenuGrinder::Role::ItemMogrifier';

sub item_mogrify {
  my ($self, $item) = @_;

  return $item unless exists $item->{label};

  if ($item->{label} =~ s#_(.)#<u>$1</u>#) {
    $item->{hotkey} = uc $1 unless defined $item->{hotkey};
  }

  return $item;
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;


__END__
=pod

=head1 NAME

WWW::MenuGrinder::Plugin::Hotkey - WWW::MenuGrinder plugin that generates hotkeys from labels.

=head1 VERSION

version 0.06

=head1 DESCRIPTION

C<WWW::MenuGrinder::Plugin::HotKey> is a plugin for C<WWW::MenuGrinder>. You
should not use it directly, but include it in the C<plugins> section of a
C<WWW::MenuGrinder> config.

When loaded, this plugin will scan the menu for C<label> keys containing
underscores. If an underscore is found, it will be removed, and the following
character wrapped in C<< <u> >> tags (for example, C<"Hot_key"> becomes 
C<< "Hot<u>k</u>ey" >>, and the item's C<hotkey> key is set to the underlined
character.

=head2 Configuration

None.

=head2 Bugs

This should probably be way more generic, instead of only useful for me.
Suggestions welcome.

=head1 AUTHOR

Andrew Rodland <andrew@hbslabs.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by HBS Labs, LLC..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

