# Copyrights 2003-2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution User-Identity.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package User::Identity::Location;
use vars '$VERSION';
$VERSION = '1.02';

use base 'User::Identity::Item';

use strict;
use warnings;

use User::Identity;
use Scalar::Util 'weaken';


sub type { "location" }


sub init($)
{   my ($self, $args) = @_;

    $args->{postal_code} ||= delete $args->{pc};

    $self->SUPER::init($args);

    exists $args->{$_} && ($self->{'UIL_'.$_} = delete $args->{$_})
        foreach qw/city country country_code fax organization
                   pobox pobox_pc postal_code state street phone/;

    $self;
}


sub street() { shift->{UIL_street} }


sub postalCode() { shift->{UIL_postal_code} }


sub pobox() { shift->{UIL_pobox} }


sub poboxPostalCode() { shift->{UIL_pobox_pc} }

#-----------------------------------------


sub city() { shift->{UIL_city} }


sub state() { shift->{UIL_state} }


sub country()
{   my $self = shift;

    return $self->{UIL_country}
        if defined $self->{UIL_country};

    my $cc = $self->countryCode or return;

    eval 'require Geography::Countries';
    return if $@;

    scalar Geography::Countries::country($cc);
}


sub countryCode() { shift->{UIL_country_code} }


sub organization() { shift->{UIL_organization} }

#-----------------------------------------


sub phone()
{   my $self = shift;

    my $phone = $self->{UIL_phone} or return ();
    my @phone = ref $phone ? @$phone : $phone;
    wantarray ? @phone : $phone[0];
}
    

sub fax()
{   my $self = shift;

    my $fax = $self->{UIL_fax} or return ();
    my @fax = ref $fax ? @$fax : $fax;
    wantarray ? @fax : $fax[0];
}

#-----------------------------------------


sub fullAddress()
{   my $self = shift;
    my $cc   = $self->countryCode || 'en';

    my ($address, $pc);
    if($address = $self->pobox) { $pc = $self->poboxPostalCode }
    else { $address = $self->street; $pc = $self->postalCode }
    
    my ($org, $city, $state) = @$self{ qw/UIL_organization UIL_city UIL_state/ };
    return unless defined $city && defined $address;

    my $country = $self->country;
    $country
      = defined $country ? "\n$country"
      : defined $cc      ? "\n".uc($cc)
      : '';

    if(defined $org) {$org .= "\n"} else {$org = ''};

    if($cc eq 'nl')
    {   $pc = "$1 ".uc($2)."  " if defined $pc && $pc =~ m/(\d{4})\s*([a-zA-Z]{2})/;
        return "$org$address\n$pc$city$country\n";
    }
    else
    {   $state ||= '';
        return "$org$address\n$city$state$country\n$pc";
    }
}

1;

