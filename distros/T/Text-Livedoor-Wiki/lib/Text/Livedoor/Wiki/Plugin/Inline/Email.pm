package Text::Livedoor::Wiki::Plugin::Inline::Email;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Inline);

__PACKAGE__->regex(q{([a-zA-Z0-9_\-\.]+\@[a-zA-Z0-9_\-\.]+)});
__PACKAGE__->n_args(1);

sub process {
    my ( $class , $inline , $email ) = @_;
    return (qq{<a href="mailto:$email">$email</a>});
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Inline::Email - Email Inline Plugin

=head1 DESCRIPTION

make clickable email text

=head1 SYNOPSIS

 polocky@livedoor.com

=head1 FUNCTION

=head2 process

=head1 AUTHOR

polocky

=cut
