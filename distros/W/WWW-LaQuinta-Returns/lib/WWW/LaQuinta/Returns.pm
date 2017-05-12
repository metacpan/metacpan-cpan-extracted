package WWW::LaQuinta::Returns;

use strict;
use warnings;
use Carp;
use WWW::Mechanize;

our $VERSION = '0.03';

=head1 NAME

WWW::LaQuinta::Returns - Scraper for La Quinta Returns site

=head1 SYNOPSIS

  use WWW::LaQuinta::Returns;

  my $lq = WWW::LaQuinta::Returns->new(
     account  => 'W123456',
     password => 'opensesame',
  );

  my $points = $lq->balance;
  print "You have $points La Quinta Returns points";

=head1 DESCRIPTION

This module scrapes the La Quinta Returns website to obtain your reward points balance at the La Quinta hotel chain.

=head1 METHODS

=head2 new

Returns a new WWW::LaQuinta::Returns object.

=cut

sub new
{
    my $class  = shift;
    my %params = @_;
    my $self = \%params;
    bless $self, $class;

    my $mech = WWW::Mechanize->new;
    $self->{mech} = $mech;

    return $self;
}

=head2 balance

Returns your La Quinta Returns points balance.

=cut 

sub balance
{
    my $self    = shift;
    my %params  = @_;
    my $content = $self->_login;
    my $points;

    # Future proofing - support commified and non-commified points balances.
    # Right now LQ uses a mix of the two and this could obviously change in
    # the future.
    my $digit_regex = '([0-9]{1,3},([0-9]{3},)*[0-9]{3}|[0-9]+)';

    # More future proofing - pull the point balance from as many locations
    # as possible. That way, if one disappears, another will be found.
    my @regexes = (
        qq|<strong>$digit_regex<\/strong> points|,
        qq|<span style='color:#9bca14;'><b>$digit_regex<\/b><\/span> <span style='color:#cccccc;font-size:12px;'>points|,
    );

    my @matches;
    for my $regex (@regexes) {
        if ($content =~ /$regex/) {
            my $points = $1;
            if (defined($points)) {
                $points =~ s/\,//g;
                push @matches, $points;
            }
        }
    }

    if ($ENV{WWW_LaQuinta_Returns_DEBUG}) {
        my $match_count = scalar @matches;
        my $regex_count = scalar @regexes;
        if ($regex_count != $match_count) {
            warn "Layout change - $regex_count regexes matched $match_count times";
        }
    }

    my $generic_error = "Please alert the WWW::LaQuinta::Returns maintainer";

    if (@matches) {
        my $first = $matches[0];
        if (grep { $_ != $first } @matches) {
            croak "Getting inconsistent values. $generic_error";
        } else {
            return $first;
        }
    } else {
        croak "Unable to scrape LaQuinta.com. $generic_error";
    }

    return $points;
}

sub _login {
    my $self = shift;
    my $mech = $self->_mech;

    $mech->get('http://www.lq.com/lq/returns/');

    # HACK: Suspend WWW::Mechanize warnings because I don't want to specify a
    # specific form number for future-proofing purposes, but Mech will emit
    # a warning if there are more than one form matching the account/password
    # inputs.
    my $old_onwarn = $mech->{onwarn} ;
    $mech->{onwarn} = sub {};

    $mech->submit_form(
        with_fields => {
            account  => $self->{account},
            password => $self->{password},
        },
    );

    $mech->{onwarn} = $old_onwarn;

    my $content = $mech->content;

    if ($content =~ /password has not been defined/) {
        croak "Incorrect account number";
    } elsif ($content =~ /password you have entered is invalid/) {
        croak "Incorrect password";
    }

    return $content;
}

sub _mech {
    my $self = shift;
    return $self->{mech};
}

=head1 DEPENDENCIES

WWW::Mechanize

=head1 WHY?!

I wanted to write a cronjob that would alert me when my points balance changed or I became eligible for a free night. For an example of such a script, see bin/cron_example.pl.

=head1 TO-DO LIST

A few other features that I might code at some point. Send me an email if you would find them useful. Oh, and patches are welcome.

=over 4

=item * B<Account History>

Scraper for your account history - what hotels you spent your points at, how many points you used for free nights, how many points were earned from hotel stays/credit card usage/etc.

=back

=cut

=head1 BUGS

Like all screen-scraping tools, this module is prone to bugs or epic breakage if La Quinta changes their site design. It's not intended for use in production applications.

=head1 DISCLAIMER

The author of this module is not affiliated in any way with La Quinta Hotels.

Use this scraper like you would a web browser. You wouldn't sit at your computer refreshing the La Quinta website every second, so don't use this module to write a cronjob that does that.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Michael Aquilina. All rights reserved.

This code is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Michael Aquilina, aquilina@cpan.org

=cut

1;

