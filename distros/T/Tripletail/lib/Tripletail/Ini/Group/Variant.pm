package Tripletail::Ini::Group::Variant;
use strict;
use warnings;
use Tripletail::Ini::Group::Annotation;

1;

=encoding utf-8

=head1 NAME

Tripletail::Ini::Group::Variant - 内部用


=head1 DESCRIPTION

L<Tripletail> によって内部的に使用される。


=head2 METHODS

=over 4

=item C<< new >>

=cut

use fields qw(annotation value_for keys);
sub new {
    my Tripletail::Ini::Group::Variant    $this = shift;
    my Tripletail::Ini::Group::Annotation $anno = shift;

    if (!ref $this) {
        $this = fields::new($this);
    }

    $this->{annotation} = $anno;
    $this->{value_for } = {}; # key => value
    $this->{keys      } = []; # [key]

    return $this;
}


=item C<< annotation >>

    my $anno = $variant->annotation();

Return the L<Tripletail::Ini::Group::Annotation> object for this
variant.

=cut

sub annotation {
    my Tripletail::Ini::Group::Variant $this = shift;

    return $this->{annotation};
}


=item C<< exists >>

=cut

sub exists {
    my Tripletail::Ini::Group::Variant $this = shift;
    my $key                                  = shift;

    if (exists $this->{value_for}{$key}) {
        return 1;
    }
    else {
        return;
    }
}


=item C<< keys >>

=cut

sub keys {
    my Tripletail::Ini::Group::Variant $this = shift;

    return @{ $this->{keys} };
}


=item C<< get >>

=cut

sub get {
    my Tripletail::Ini::Group::Variant $this = shift;
    my $key                                  = shift;

    if (exists $this->{value_for}{$key}) {
        return $this->{value_for}{$key};
    }
    else {
        return;
    }
}


=item C<< set >>

=cut

sub set {
    my Tripletail::Ini::Group::Variant $this = shift;
    my $key                                  = shift;
    my $value                                = shift;

    if (!exists $this->{value_for}{$key}) {
        push @{ $this->{keys} }, $key;
    }

    $this->{value_for}{$key} = $value;
    return $this;
}


=item C<< delete >>

=cut

sub delete {
    my Tripletail::Ini::Group::Variant $this = shift;
    my $key                                  = shift;

    if (exists $this->{value_for}{$key}) {
        delete $this->{value_for}{$key};
        @{ $this->{keys} } = grep { $_ ne $key } @{ $this->{keys} };
    }

    return $this;
}


=item C<< toStr >>

=cut

sub toStr {
    my Tripletail::Ini::Group::Variant $this = shift;
    my $basename                             = shift;

    my @lines = (
        sprintf('[%s%s]', $basename, $this->{annotation}),
        map {
            sprintf('%s = %s', $_, $this->{value_for}{$_})
          }
          @{ $this->{keys} });

    return join("\n", @lines) . "\n";
}


=back


=head1 SEE ALSO

L<Tripletail>


=head1 AUTHOR INFORMATION

Copyright 2006-2013 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

Web site : http://tripletail.jp/

=cut
