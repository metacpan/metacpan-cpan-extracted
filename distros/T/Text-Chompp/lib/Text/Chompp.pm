package Text::Chompp;

use warnings;
use strict;

use base 'Exporter';
our @EXPORT_OK = qw/ chompp chopp /;

# ABSTRACT: chomp and chop replacements that pass the changed value(s) back

our $VERSION = '0.001'; # VERSION


sub chompp {
    my @val = @_;
    @val = ($_) unless @val;

    chomp foreach @val;
    return wantarray ? @val : $val[0];
}

sub chopp {
    my @val = @_;
    @val = ($_) unless @val;

    chop foreach @val;
    return wantarray ? @val : $val[0];
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Text::Chompp - chomp and chop replacements that pass the changed value(s) back

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Text::Chompp qw/ chompp chopp /;
  
  ...
  
  # all the following work:
  my $chomped = chompp $string;
  my $chomped = chompp $_;
  my @chomped = map { chompp } @strings;
  my @chomped = chompp @strings;
  
  foreach (<FILE>) {
    chompp;
    push @chomped;
  }
   
  # ... etc ...

=head1 DESCRIPTION

Alternative to the builtins C<chop> and C<chomp>, which leave the original
intact, and instead return the altered value. The intention is to take the
same arguments as the originals.

=head1 LIMITATIONS

Text::Chompp will not process the values of hashes (as chop/chomp do).

=head1 SEE ALSO

Text::Chomped - requires alternative syntax for lists

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/mjemmeson/text-chompp/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/mjemmeson/text-chompp>

  git clone git://github.com/mjemmeson/text-chompp.git

=head1 AUTHOR

Michael Jemmeson <mjemmeson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Michael Jemmeson <mjemmeson@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
