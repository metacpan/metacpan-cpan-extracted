package Test::Smoke::App::ConfigSmoke::Mail;
use warnings;
use strict;

our $VERSION = '0.001';

use Exporter 'import';
our @EXPORT = qw/ config_mail /;

use Test::Smoke::App::AppOption;
use Test::Smoke::App::Options;

=head1 NAME

Test::Smoke::App::ConfigSmoke::Mail - Mixin for Test::Smoke::App::ConfigSmoke.

=head1 DESCRIPTION

These methods will be added to the L<Test::Smoke::App::ConfigSmoke> class.

=head2 config_mail

Configure options: C<mail>, C<mail_type>, C<mserver>, C<to>, C<cc>, C<bcc>, C<swcc>, C<swbcc>

=cut

sub config_mail {
    my $self = shift;

    print "\n-- Mail section --\n";

    my $use_mail = $self->handle_option(Test::Smoke::App::Options->mail);
    return if !$use_mail;

    # discurrage ccp5p_onfail
    $self->current_values->{ccp5p_onfail} = 0;

    my $mail_type = $self->handle_option(Test::Smoke::App::Options->mail_type());
    for my $option (qw( from to cc bcc )) {
        $self->handle_option(Test::Smoke::App::Options->$option);
    }

    # Use the option definitions as a guide for asking values
    my %mc = Test::Smoke::App::Options->mailer_config;
    my $soptions = $mc{special_options}->{$mail_type};

    for my $option (qw( sendmailbin sendemailbin mailbin mailxbin mserver msport msuser )) {
        if ( grep { $_->name eq $option } @{$soptions} ) {
            $self->handle_option(Test::Smoke::App::Options->$option);
        }
    }

    if ($self->current_values->{msuser}) {
        $self->handle_option(Test::Smoke::App::Options->mspass);
    }

    if ($mail_type !~ /::/) {
        for my $option (qw( swcc swbcc )) {
            (my $related = $option) =~ s{^sw}{};
            next if ! $self->current_values->{$related};

            if ( grep { $_->name eq $option } @{$soptions} ) {
                $self->handle_option(Test::Smoke::App::Options->$option);
            }
        }
    }
}

1;

=head1 COPYRIGHT

E<copy> MMXXII - All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
