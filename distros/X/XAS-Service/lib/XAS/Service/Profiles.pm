package XAS::Service::Profiles;

our $VERSION = '0.01';

use Hash::Merge;
use Data::FormValidator;
use XAS::Utils ':validation';
use XAS::Constants 'HASHREF';
use Data::FormValidator::Results;
use Badger::Class import => 'class';

#use Data::Dumper;

# -----------------------------------------------------------------
# Overrides - WARNING Will Robinson WARNING here be dragons
# -----------------------------------------------------------------

class('Data::FormValidator::Results')->methods(
    _generate_msgs => sub {
        my $self = shift;
        my $controls = shift || {};

        if (defined $controls and ref $controls ne 'HASH') {

            die "$0: parameter passed to msgs must be a hash ref";

        }

        # Allow msgs to be called more than one to accumulate error messages

        $self->{msgs} ||= {};
        $self->{profile}{msgs} ||= {};
        $self->{msgs} = { %{ $self->{msgs} }, %$controls };

        # Legacy typo support.

        for my $href ($self->{msgs}, $self->{profile}{msgs}) {

            if ((not defined $href->{invalid_separator}) &&
                (defined $href->{invalid_seperator})) {

                $href->{invalid_separator} = $href->{invalid_seperator};

            }

        }

        my %profile = (
            prefix  => '',
            missing => 'Missing',
            invalid => 'Invalid',
            invalid_separator => ' ',

            format  => '<span style="color:red;font-weight:bold" class="dfv_errors">* %s</span>',
            %{ $self->{msgs} },
            %{ $self->{profile}{msgs} },
        );

        my %msgs = ();

        # Add invalid messages to hash
        #  look at all the constraints, look up their messages (or provide a default)
        #  add field + formatted constraint message to hash

        if ($self->has_invalid) {

            my @invalids = $self->invalid;

            foreach my $i (@invalids) {

                $msgs{$i} = join(
                    $profile{invalid_separator},
                    $self->_error_msg_fmt($profile{format}, ($profile{constraints}{$i} || $profile{invalid}))
                );

            }

        }

        # Add missing messages, if any

        if ($self->has_missing) {

            my $missing = $self->missing;

            for my $m (@$missing) {

                $msgs{$m} = $self->_error_msg_fmt($profile{format},$profile{missing});

            }

        }

        my $msgs_ref = $self->prefix_hash($profile{prefix},\%msgs);

        unless ($self->success) {

            $msgs_ref->{ $profile{any_errors} } = 1 if defined $profile{any_errors};

        }

        return $msgs_ref;

    },
    _error_msg_fmt => sub {
        my $self = shift;
        my $fmt  = shift;
        my $msg  = shift;

        $fmt ||= '<span style="color:red;font-weight:bold" class="dfv_errors">* %s</span>';

        ($fmt =~ m/%s/) || die 'format must contain %s';

        return sprintf $fmt, $msg;

    },
    prefix_hash => sub {
        my $self = shift;
        my $pre  = shift;
        my $href = shift;

        die "prefix_hash: need two arguments" unless (defined($pre) && defined($href));
        die "prefix_hash: second argument must be a hash ref" unless (ref $href eq 'HASH');

        my %out;

        for (keys %$href) {

            $out{$pre.$_} = $href->{$_};

        }

        return \%out;

    }
);

# -----------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------

sub new {
    my $class = shift;
    my @profiles = validate_params(\@_, [
        { type => HASHREF },
        ({ optional => 1, type => HASHREF}) x (@_ - 1),
    ]);

    my $profile = {};
    my $merger = Hash::Merge->new('RIGHT_PRECEDENT');

    foreach my $p (@profiles) {

        $profile = \%{ $merger->merge($profile, $p) };

    }

    return Data::FormValidator->new($profile);

}

# -----------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------

1;

=head1 NAME

XAS::Service::Profiles - A class for creating standard validation profiles.

=head1 SYNOPSIS

 use XAS::Service::Profiles;
 use XAS::Service::Profiles::Search;

 my $params = {
     start => 0,
     limit => 25,
     sort => qq/[{"field":"server',"direction":"DESC"}]/
 };

 my @fields = [qw(id server queue requestor typeofrequest status startdatetime)];

 my $search  = XAS::Service::Profiles::Search->new(\@fields);
 my $profile = XAS::Service::Profiles->new($search);

 my $results = $profile->check($params, 'pager');

 if ($results->has_invalid) {

     my @invalids = $results->invalid;

     foreach my $invalid (@invalids) {

         printf("%s %s\n", $invalid, $results->msgs->{$invalid});

     }

 }

=head1 DESCRIPTION

This module combines multiple validation profiles into one
L<Data::FormValidator|https://metacpan.org/pod/Data::FormValidator> validator.

=head1 METHODS

=head2 new($hash, ...)

This method initilizes the validator by combining multiple profiles.

=over 4

=item B<$hash>

A hash of validation profiles, there may be more then one. They are combined
such that later profiles may overwrite earlier ones.

=back

=head1 OVERRIDES

This module overrides the following methods in L<Data::FormValidator::Results|https://metacpan.org/pod/Data::FormValidator::Results>.

=head2 _generate_msgs

For whatever reason, it wouldn't find error messages for constraints. Not
sure why. No bugs reports have been filed about this. But it wouldn't work
for me as documented, now it does.

=head2 _error_msg_fmt

A supporting routine for _generate_msgs(). Allowed it to be referenced
from $self.

=head2 prefix_hash

A supporting routine for _generate_msgs(). Allowed it to be referenced
from $self.

=head1 SEE ALSO

=over 4

=item L<Data::FormValidator|https://metacpan.org/pod/Data::FormValidator>

=item L<XAS::Service|XAS::Service>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
