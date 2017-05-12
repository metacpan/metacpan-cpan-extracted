# -*- cperl -*-
# copyright (C) 2005 Topia <topia@clovery.jp>. all rights reserved.
# This is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
# $Id: I18N.pm 96 2005-02-04 16:55:48Z topia $
# $URL: file:///usr/minetools/svnroot/mixi/trunk/WWW-Mixi-OO/lib/WWW/Mixi/OO/I18N.pm $
package WWW::Mixi::OO::I18N;
use strict;
use warnings;
our %modules = (
    qr/utf-?8/i => 'UTF8',
    qr/euc-?jp/i => 'EUCJP',
   );

=head1 NAME

WWW::Mixi::OO::I18N - WWW::Mixi::OO's internationalization class

=head1 SYNOPSIS

  use WWW::Mixi::OO::I18N;
  my $i18n_class = WWW::Mixi::OO::I18N->get_processor('utf-8');
  # ...

=head1 DESCRIPTION

WWW::Mixi::OO::I18N is WWW::Mixi::OO's internationalization class.

This module provides multi internal charset processing to WWW::Mixi::OO.

=head1 METHODS

=over 4

=cut

=item supported_charsets

  my @charsets = WWW::Mixi::OO::I18N->supported_charsets;

return supported charset list

=cut

sub supported_charsets {
    my $this = shift;
    my (@supported, $retval);
    foreach (values %modules) {
	if ($this->is_supported($_)) {
	    push @supported, $_;
	}
    }
    @supported;
}

=item is_supported

  if (WWW::Mixi::OO::I18N->is_supported('utf-8')) {
      # use utf-8!
  } else {
      # blah...
  }

return true if charset supported

=cut

sub is_supported {
    my $retval = eval 'require ' . shift->_get_module_name(@_);
    warn $@ if $@;
    return $retval;
}

sub _get_module_name {
    my ($this, $charset) = @_;
    foreach (keys %modules) {
	if ($charset =~ /$_/) {
	    $charset = $modules{$_};
	    last;
	}
    }
    return __PACKAGE__ . '::' . $charset;
}

=item get_processor

  my $processor = WWW::Mixi::OO::I18N->get_processor('utf-8');
  $processor->convert_time(...);

return specified charset processor.

=cut

sub get_processor {
    my ($this, $charset) = @_;

    if ($this->is_supported($charset)) {
	return $this->_get_module_name($charset);
    } else {
	return undef;
    }
}

=back

=head1 INTERFACE

i18n class need to implement following methods.

=over 4

=item convert_from_http_content

  $i18n->convert_from_http_content($charset, $str);

charset conversion from $charset to internal charset.

=item convert_to_http_content

  $i18n->convert_to_http_content($charset, $str);

charset conversion from internal charset to $charset.

=item convert_login_time

  $i18n->convert_login_time($timestr);

convert mixi login time(such as '3 hours') to 'YYYY/mm/dd HH:MM' format and
time value

=item convert_time

  $i18n->convert_time($timestr);

convert japanese timestr to such as 'YYYY/mm/dd' format(ex. 2005/01/30, 01/30)

=cut

1;
__END__
=back

=head1 SEE ALSO

L<WWW::Mixi::OO>

=head1 AUTHOR

Topia E<lt>topia@clovery.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Topia.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
