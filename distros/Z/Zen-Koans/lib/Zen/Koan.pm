package Zen::Koan;
use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = '0.02';

sub new {
    my $class = shift;
    my %opts;
    if (@_ == 1 and ref($_[0]) eq 'HASH') {
        %opts = %{ $_[0] };
    }
    else { %opts = @_ }
    $opts{title} ||= 'A koan by no other name';
    $opts{body}  ||= 'This koan offers little wisdom.  It just is.';

    my $self = { title => $opts{title},
                 body  => $opts{body},
                 indent_level => 0,
                 current_indent => 0,
               };

    bless $self, $class;
    return $self;
}

sub title { $_[0]->{title} }
sub body  { $_[0]->{body} }

sub as_html {
    my $self = shift;
    my $body = '';
    for my $p (split "\n", $self->{body}) {
        next if $p =~ /^\s*$/;
        chomp $p;
        if ($p =~ s/^(\s+)//) {
            my $indent = length $1;
            if ($indent > $self->{current_indent}) {
                $self->{indent_level}++;
                $body .= "<blockquote>\n";
            }
            elsif ($indent < $self->{current_indent}) {
                $self->{indent_level}--;
                $body .= "</blockquote>\n";
            }
            $self->{current_indent} = $indent;
        }
        elsif ($self->{indent_level}) {
            while ($self->{indent_level}) {
                $self->{indent_level}--;
                $body .= "</blockquote>\n";
            }
        }
        $body .= "<p>$p</p>\n";
    }
    while ($self->{indent_level}) {
        $self->{indent_level}--;
        $body .= "</blockquote>\n";
    }
    return <<EOT;
<div id='koan_title'>$self->{title}</div>
<div id='koan_body'>
$body</div>
EOT
}

sub as_text {
    my $self = shift;
    return "\t$self->{title}\n\n$self->{body}";
}

sub AUTOLOAD {
    return <<EOT
You are expecting too much from this koan.  

Look within for more answers.
EOT
}

1;

__END__

=head1 NAME

Zen::Koan - A class for representing Zen Koans

=head1 SYNOPSIS

  use Zen::Koan;
  my $k = Zen::Koans->new( title => $title,
                           body  => $body,
                         );
  my $t = $k->title;
  my $b = $k->body;
  print $k->as_html;

=head1 DESCRIPTION

A koan (pronounced /ko.an/) is a story, dialog, question, or statement in
the history and lore of Chan (Zen) Buddhism, generally containing aspects
that are inaccessible to rational understanding, yet that may be
accessible to intuition.

This module contains code to represent a zen koan.  

=head1 INTERFACE

=over 4

=item new( %opts )

Create a new koan with C<new>.  The following options are suggested:

=over 4

=item title

=item body

These functions return the values of the koan.

=back

=item title

Returns the title of the koan.

=item body

Returs the body of the koan.

=item as_html

Returns the koan formatted in HTML.

=back

=head1 DEPENDENCIES

A creative mind or access to one.

=head1 BUGS AND LIMITATIONS

None.

=head1 AUTHOR

Luke Closs <lukec@cpan.org>

=head1 DISCLAIMER OF WARRANTY

This module can only offer you so much.  
It is up to you to make the most of it.

