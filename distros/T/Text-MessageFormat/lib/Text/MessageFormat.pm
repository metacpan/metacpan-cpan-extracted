package Text::MessageFormat;

use strict;
use vars qw($VERSION);
$VERSION = 0.01;

use Text::Balanced qw(extract_multiple extract_bracketed extract_delimited);

sub new {
    my($class, $format) = @_;
    my $formats = $class->_parse_format($format);
    bless { _formats => $formats }, $class;
}

sub format {
    my($self, @args) = @_;
    return join '', map $_->format(\@args), @{$self->{_formats}};
}

sub _parse_format {
    my($class, $format) = @_;
    my @blocks = map {
	if (UNIVERSAL::isa($_, 'FormatElement')) {
	    $class->_handle_format_element($$_);
	} elsif (UNIVERSAL::isa($_, 'QuotedString')) {
	    $class->_handle_quoted_string($$_);
	} else {
	    $class->_handle_literal($_);
	}
    } extract_multiple(
	$format, [
	    { FormatElement => sub { extract_bracketed($_[0], q({})); } },
	    { QuotedString  => sub { extract_delimited($_[0], q(')); } },
	],
    );
    return \@blocks;
}

sub _handle_format_element {
    my($class, $pattern) = @_;
    my($index, $type, $style) = split /,\s*/, ($pattern =~ /^{(.*)}$/)[0], 3;

    my $element_class = 'Text::MessageFormat::Element';
    $element_class .= '::' . ucfirst $type if $type;
    return bless {
	index => $index,
	type  => $type,
	style => $style,
    }, $element_class;
}
sub _handle_quoted_string {
    my($class, $pattern) = @_;
    $pattern =~ s/^'(.*)'$/$1/;
    my $literal = $pattern eq '' ? q(') : $pattern;
    return bless {
	literal => $literal,
    }, 'Text::MessageFormat::String';
}

sub _handle_literal {
    my($class, $pattern) = @_;
    return bless {
	literal => $pattern,
    }, 'Text::MessageFormat::String';
}

package Text::MessageFormat::String;
sub format { shift->{literal} }

package Text::MessageFormat::Element;
sub format {
    my($self, $args) = @_;
    return $args->[$self->{index}];
}

package Text::MessageFormat::Element::Number;
use base qw(Text::MessageFormat::Element);

package Text::MessageFormat::Element::Date;
use base qw(Text::MessageFormat::Element);

package Text::MessageFormat::Element::Time;
use base qw(Text::MessageFormat::Element);

package Text::MessageFormat::Element::Choice;
use base qw(Text::MessageFormat::Element);

1;
__END__

=head1 NAME

Text::MessageFormat - Language neutral way to display messages

=head1 SYNOPSIS

  use Text::MessageFormat;

  my $form = Text::MessageFormat->new('The disk "{1}" contains {0} file(s).');
  print $form->format(3, 'MyDisk');

  # output: The disk "MyDisk" contains 3 file(s).

=head1 DESCRIPTION

Text::MessageFormat is a Perl version of Java's
java.text.MessageFormat and aims to be format-compatible with that
class.

MesageFormat provides a means to produce concatenated messages in
language-neutral way. Use this to construct messages displayed for end
users.

See L<Data::Properties> for java.util.Properties porting.

=head1 WARNINGS/TODO

=over 4

=item *

Following FormatElements are all B<NOT> implemented yet. Currently
they interpolate exactly same as just C<{0}>.

  {0,number,#.##}
  {0,date,short}
  {0,time,hh:mm:ss}
  {0,choice,0#are no files|1#is one file|1<are {0,number,integer} files}

Patches are always welcome!

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

http://java.sun.com/j2se/1.4/docs/api/java/text/MessageFormat.html
L<Data::Properties>

=cut
