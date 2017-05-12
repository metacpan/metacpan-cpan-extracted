package Text::Emoticon;

use strict;
our $VERSION = '0.04';

use UNIVERSAL::require;

my %map;

sub new {
    my $class  = shift;
    if ($class eq __PACKAGE__) {
        my $driver = shift;
        my $args   = @_ == 1 ? $_[0] : {@_};

        my $subclass = "Text::Emoticon::$driver";
        $subclass->require or die $@;
        return bless { %{$subclass->default_config}, %$args }, $subclass;
    } else {
        my $args   = @_ == 1 ? $_[0] : {@_};
        return bless { %{$class->default_config}, %$args }, $class;
    }
}

sub register_subclass {
    my $class = shift;
    my($map)  = @_;
    my $subclass = caller;
    $map{$subclass} = $map;
}

sub map { $map{ref($_[0])} }

sub pattern {
    my $self = shift;
    $self->{re} ||= "(" . join("|", map quotemeta($_), sort { length($b) <=> length($a) } keys %{$self->map}) . ")";
    $self->{re};
}

sub filter_one {
    my $self = shift;
    my($text) = @_;
    $self->do_filter($self->map->{$text});
}

sub filter {
    my($self, $text) = @_;
    return unless defined $text;
    my $re = $self->pattern;
    if ($self->{strict}) {
      $text =~ s{(?<!\w)$re(?!\w)}{$self->do_filter($self->map->{$1})}eg;
    } else {
      $text =~ s{$re}{$self->do_filter($self->map->{$1})}eg;
    }
    return $text;
}

sub do_filter {
    my($self, $icon) = @_;
    my $class = $self->{class} ? qq( class="$self->{class}") : "";
    my $xhtml = $self->{xhtml} ? qq( /) : "";

    return qq(<img src="$self->{imgbase}/$icon"$class$xhtml>); 
}


1;
__END__

=head1 NAME

Text::Emoticon - Factory class for Yahoo! and MSN emoticons

=head1 SYNOPSIS

  use Text::Emoticon;

  my $emoticon = Text::Emoticon->new('MSN', { strict => 1, xhtml => 0 });
  print $emoticon->filter('Hello ;)');

=head1 DESCRIPTION

Text::Emoticon is a factory class to dispatch MSN/YIM emoticon
set. It's made to become handy to be used in other applications like
Kwiki/MT plugins.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Text::Emoticon::MSN>, L<Text::Emoticon::Yahoo>

=cut
