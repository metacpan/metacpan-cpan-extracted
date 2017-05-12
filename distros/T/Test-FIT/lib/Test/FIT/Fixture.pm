package Test::FIT::Fixture;
$VERSION = '0.10';
use strict;
use Test::FIT;

attribute 'has_errors';
attribute 'headers';
attribute 'fixture_cell';
attribute 'value';
attribute 'passed';
attribute 'failed';
attribute 'erred';
attribute 'text';
attribute 'x';
attribute 'y';
attribute 'z';

sub XXX {
    require YAML;
    my $self = shift;
    local $YAML::UseVersion = 0;
    die YAML::Dump(@_);
}

sub WWW {
    require YAML;
    my $self = shift;
    warn("<pre>" . YAML::Dump(@_) . "</pre>");
}

my $header_printed = 0;
$SIG{__WARN__} = sub {
    print CGI::header() unless $header_printed++;
    my $warning = join '', @_;
    $warning =~ s/\n/<BR>\n/g;
    print qq{<P><FONT COLOR="red">WARNING</FONT></P>\n$warning\n};
};

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;
    $self->has_errors(0);
    return $self;
}

sub matrix {
    my $self = shift;
    return $self->{matrix} unless @_;
    my $matrix = $self->{matrix} = shift;
    $self->set_headers; 
    return if $self->has_errors;
    for my $header (@{$self->headers}) {
        my $method = $header->method;
        unless ($self->can($method)) {
            $header->mark_error;
            $self->has_errors(1);
        }
    }
}

sub rows {
    my $self = shift;
    my $matrix = $self->{matrix};
    return scalar @$matrix;
}

sub cols {
    my $self = shift;
    my $matrix = $self->{matrix};
    return 0 unless defined $matrix->[0];
    return scalar @{$matrix->[0]};
}

sub process {
    my $self = shift;
    while ($self->cols and $self->rows) {
        $self->has_errors(0);
        my $slice = $self->next_slice;
        for my $header (@{$self->headers}) {
            my $method = $header->method;
            my $cell = shift @$slice;
            my $value = $cell->clean_value;
            $self->value($value);
            $self->passed(0);
            $self->failed(0);
            $self->erred(0);
            $self->text('');
            $self->$method($value);
            my $text = $self->text;
            my @text = length($text) ? ($text) : ();
            $cell->mark_passed(@text) if $self->passed;
            $cell->mark_failed(@text) if $self->failed;
            $cell->mark_error(@text) if $self->erred;
            last if $self->has_errors;
        }
    }
}

sub pretty {
    my ($self, $text) = @_;
    $text =~ s/</\&lt;/g;
    $text =~ s/>/\&gt;/g;
    if ($text =~ /\n/) {
        $text = "<pre>$text</pre>\n";
    }
    return $text;
}

sub x_eq_str  {$_[0]->eq_str($_[0]->x)}
sub x_is_like {$_[0]->is_like($_[0]->x)}

sub eq_str {
    my ($self, $got) = @_;
    $self->ok($got eq $self->value);
}

sub ne_str {
    my ($self, $got) = @_;
    $self->ok($got ne $self->value);
}

sub is_like {
    my ($self, $got) = @_;
    my $pattern = $self->value;
    $self->ok($got =~ m/$pattern/);
}

sub is_unlike {
    my ($self, $got) = @_;
    my $pattern = $self->value;
    $self->ok($got !~ m/$pattern/);
}

sub eq_num {
    my ($self, $got) = @_;
    $self->ok($got == $self->value);
}

sub ne_num {
    my ($self, $got) = @_;
    $self->ok($got != $self->value);
}

sub ok {
    my ($self, $ok) = @_;
    $ok ? $self->pass : $self->fail;
}

sub stop {
    my $self = shift;
    $self->has_errors(1);
}

sub pass {
    my $self = shift;
    $self->passed(1);
    $self->text($self->pretty(shift)) if @_;
}

sub fail {
    my $self = shift;
    $self->failed(1);
    $self->text($self->pretty(shift)) if @_;
}

sub error {
    my $self = shift;
    $self->erred(1);
    $self->text($self->pretty(shift)) if @_;
}

sub set_headers {
    my $self = shift;
    my $class = ref $self;
    die "$class needs to implement set_headers";
}

sub next_slice {
    my $self = shift;
    my $class = ref $self;
    die "$class needs to implement next_slice";
}

1;

__END__

=head1 NAME

Test::FIT::Fixture - A FIT Fixture Base Class

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.gnu.org/licenses/gpl.html>

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
