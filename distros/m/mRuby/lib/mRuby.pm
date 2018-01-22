package mRuby;
use strict;
use warnings;
use 5.008008;
our $VERSION = '0.14';

use Carp ();
use Encode ();
use mRuby::Symbol;
use mRuby::Bool;

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

my $DEFAULT_ENCODING = Encode::find_encoding('utf-8');

sub new {
    my ($class, %args) = @_;
    if (exists $args{src}) {
        return $class->_new_with_src($args{src});
    }
    elsif (exists $args{file}) {
        return $class->_new_with_file(@args{qw/file encoding/});
    }
    else {
        Carp::croak('Invalid arguments.');
    }
}

sub _new_with_file {
    my ($class, $file, $encoding) = @_;
    $encoding ||= $DEFAULT_ENCODING;

    my $src = Encode::encode($encoding, do {
        open my $fh, '<:raw', $file or die $!;
        local $/;
        <$fh>
    });
    return $class->_new_with_src($src);
}

sub _new_with_src {
    my ($class, $src) = @_;
    my $mrb = mRuby::State->new();
    my $st = $mrb->parse_string($src);
    my $proc = $mrb->generate_code($st);
    return bless {
        mrb    => $mrb,
        proc   => $proc,
        run_fg => 0,
    } => $class;
}

sub run {
    my $self = shift;
    $self->{run_fg}++ unless $self->{run_fg};
    return $self->{mrb}->run($self->{proc});
}

sub funcall {
    my $self = shift;
    $self->run() unless $self->{run_fg};
    return $self->{mrb}->funcall(@_);
}

1;
__END__

=encoding utf8

=for stopwords mruby

=head1 NAME

mRuby - mruby binding for perl5.

=head1 SYNOPSIS

    use mRuby;

    my $mruby = mRuby->new(src => '9');
    my $ret = $mruby->run();

=head1 DESCRIPTION

mRuby is mruby binding for perl5.

=head1 METHODS

=over

=item C<< my $mruby = mRuby->new(src => $src : Str) : mRuby >>

Parse C<src> and generate C<mRuby> object.

=item C<< my $mruby = mRuby->new(file => $file : Str) : mRuby >>

Parse source from C<file> and generate C<mRuby> object.

=item C<< my $ret = $mruby->run() : Any >>

Run mruby code and get a return value.

=item C<< my $ret = $mruby->funcall($funcname : Str, ...) : Any >>

Call specified named mruby function from C<toplevel> context and get a return value.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

karupanerura E<lt>karupa@cpan.orgE<gt>

=head1 LOW LEVEL API

See L<mRuby::State>

=head1 SEE ALSO

L<mRuby>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
