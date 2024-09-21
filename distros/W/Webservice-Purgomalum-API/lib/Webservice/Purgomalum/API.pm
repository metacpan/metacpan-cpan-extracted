use strict;
use warnings;

package Webservice::Purgomalum::API;

our $VERSION = 1.001;
use HTTP::Tiny;
use Carp;
use Data::Dumper;

my $base_url = 'https://www.purgomalum.com/service/';

sub new{
    my ($package) = @_;
    my $self = {
        'ua' => HTTP::Tiny->new(),
        'debug'=> 0,
    };
    bless $self, $package;
    return $self;
}

sub contains_profanity{
    my ($self, %params) = @_;
    return $self->fetch('containsprofanity?', %params);
}

sub get{
    my ($self, %params) = @_;
    return $self->fetch('plain?', %params);
}

sub fetch{
    my ($self, $endpoint, %options) = @_;
    my $params = $self->ua->www_form_urlencode( \%options );
    my $response = $self->ua->get($base_url.$endpoint.$params) or croak "$!";

    print STDERR Dumper($response) if $self->{debug};

    return $response->{content};
}

sub ua{
    my $self = shift;
    return $self->{ua};
}

sub debug{
    my ($self, $toggle) = @_;
    if (defined $toggle){
        $self->{debug} = $toggle;
    }
    return $self;
}
1;


__END__

=pod

=head1 NAME

Webservice::Purgomalum::API - Filter and removes profanity and unwanted text from input using PurgoMalum.com's free API

=head1 SYNOPSIS

    use Webservice::Purgomalum::API;

    my $api = Webservice::Purgomalum::API->new();

    print $api->contains_profanity(
            text => "what the hell?",
        )."\n";

    print $api->get(
        text => "what the heck dude?", #required
        add => "heck",             #optional
        fill_text => "[explicit]"  #optional
        fill_char => '-',          #optional (overridden by fill_text param)
    )."\n";

    # output debugging data to STDERR
    $api->debug(1);
    print $api->get(
        text => "what the heck dude?",
        add => "heck",
    )."\n";


=head1 DESCRIPTION

This module provides an object oriented interface to the PurgoMalum free API endpoint provided by L<https://Purgomalum.com/>.

=head1 METHODS

All methods have the same available parameters. Only the "text" parameter is required.

=over

=item

B<text> I<Required> Input text to be processed.

=item

B<add> I<Optional> Comma separated list of words to be added to the profanity list. Accepts letters, numbers, underscores (_) and commas (,). Accepts up to 10 words (or 200 maximum characters in length). The PurgoMalum filter is case-insensitive, so the case of your entry is not important.

=item

B<fill_text> I<Optional> Text used to replace any words matching the profanity list. Accepts letters, numbers, underscores (_) tildes (~), exclamation points (!), dashes/hyphens (-), equal signs (=), pipes (|), single quotes ('), double quotes ("), asterisks (*), open and closed curly brackets ({ }), square brackets ([ ]) and parentheses (). Maximum length of 20 characters. When not used, the default is an asterisk (*) fill.

=item

B<fill_char> I<Optional> Single character used to replace any words matching the profanity list. Fills designated character to length of word replaced. Accepts underscore (_) tilde (~), dash/hyphen (-), equal sign (=), pipe (|) and asterisk (*). When not used, the default is an asterisk (*) fill.

=back

=head2 contains_profanity()

Returns either "true" if profanity is detected or "false" otherwise.

=head2 get()

Returns the string with all profanities replaced with either the fill_text or fill_char


=head1 SEE ALSO

=over

=item

Call for API implementations on PerlMonks: L<https://perlmonks.org/?node_id=11161472>

=item

Listed at  freepublicapis.com: L<https://www.freepublicapis.com/profanity-filter-api>

=item

Official api webpage: L<https://www.purgomalum.com/>

=back

=head1 AUTHOR

Joshua Day, E<lt>hax@cpan.orgE<gt>

=head1 SOURCECODE

Source code is available on Github.com : L<https://github.com/haxmeister/perl-purgomalum>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Joshua Day

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
