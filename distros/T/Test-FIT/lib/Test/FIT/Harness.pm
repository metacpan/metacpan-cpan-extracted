package Test::FIT::Harness;
$VERSION = '0.10';
use strict;
use base 'Test::FIT::Fixture';
use Test::FIT;
use Test::FIT::Cell;

use CGI ();
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);

attribute('input_html');
attribute('parsed_html');
attribute('fixtures');

sub run_cgi {
    my $url = shift(@ARGV);
    $url ||= CGI::referer() 
      or die "No FIT url detected\n";
    my $fit = Test::FIT::Harness->new();
    $fit->from_url($url);
    print CGI::header(), $fit->to_html;
}

sub from_url {
    require LWP::Simple;
    my ($self, $url) = @_;

    my $html = LWP::Simple::get($url) or die;
    $self->input_html($html);
    $self->parse_html;
    $self->fixtures_from_html;
    for my $fixture (@{$self->fixtures}) {
        $fixture->process;
    }
}

sub parse_html {
    my $self = shift;
    my $html = $self->input_html;
    my $parts = [];
    @$parts = ($html =~ m#
        (.*?)
        ( <body\b.*?>
        | <table\b.*?>
        | <tr\b.*?>
        | <td\b.*?>
        | </td>
        | </tr>
        | </table>
        | <a\b.*?>
        )
    #gsix);
    push @$parts, $'; # XXX supposedly a slowdown.
    $self->parsed_html($parts);
}

sub fixtures_from_html {
    my $self = shift;
    my $parts = $self->parsed_html;
    my $i = 0;
    $self->fixtures([]);
    while (1) {
        $i++ while ($i < @$parts or last) and $parts->[$i] !~ /^<table\b/i;
        $i++ while ($i < @$parts or last) and $parts->[$i] !~ /^<td\b/i;
        my $fixture_cell = Test::FIT::Cell->new($parts, $i);
        my $fixture_class = $fixture_cell->class;
        eval qq{require $fixture_class};
        if ($@) {
            $fixture_cell->mark_error($@);
            next;
        }
        my $fixture = $fixture_class->new;
        $fixture->fixture_cell($fixture_cell);
        my $matrix = [];
        my $row;

        while ($i < @$parts and $parts->[$i] !~ m!^</table>!i) {
            if ($parts->[$i] =~ /^<tr\b/) {
                $row = [];
                push @$matrix, $row;
                $i++;
                next;
            }
            elsif ($parts->[$i] =~ /^<td\b/) {
                my $cell = Test::FIT::Cell->new($parts, $i);
                push @$row, $cell;
                $i += 2;
                next;
            }
            else {
                $i++;
                next;
            }
        }
        $fixture->matrix($matrix);
        unless ($fixture->has_errors) {
            my $fixtures = $self->fixtures;
            push @$fixtures, $fixture;
            $self->fixtures($fixtures);
        }
    }
}

sub to_html {
    require CGI;
    my $self = shift;
    join '', map {
        if (/^<a\b.*?href=['"].*?cgi['"]/is) {
            s/href=/hrefxxx=/i;
            $_ = q{<a href="} . CGI::referer() . q{">&lt;&lt;&lt;</a>} . $_;
        }
        $_
    } @{$self->parsed_html};
}

1;

__END__

=head1 NAME

Test::FIT::Harness - Run FIT Tests in Perl

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.gnu.org/licenses/gpl.html>

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
