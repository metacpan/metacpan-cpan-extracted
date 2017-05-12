package PerlConsole::Preferences;

#
# This class hanldes all the preferences the user can change within the console.
#

use strict;
use warnings;

# The main data structure of the preferences,
# _valid_values contains list for each possible value.
sub init
{
    my $self = {
        _valid_values => {
            output => ['scalar', 'dumper', 'yaml', 'dump', 'dds'],
        },
        _values => {
            output => "scalar"
        }
    };
    return $self;
}

# the help messages, dynamically built with the data structure
sub help($;$)
{
    my ($self, $pref) = @_;
    if (!defined $pref) {
        return "You can set a preference in the console with the following syntax:\n".
            ":set <preference>=<value>\n".
            "Available preferences are:\n\t- ".join("\n\t- ", keys(%{$self->{'_values'}}))."\n".
            "see :help <preference> for details.";
    }
    else {
        if (defined $self->{'_valid_values'}{$pref}) {
            return "Valid values for preference \"$pref\" are: ".join(", ", @{$self->{'_valid_values'}{$pref}});
        }
        else {
            return "No such preference: $pref";
        }
    }
}

# create an empty preference object, ready for being set
sub new 
{
    my ($class) = @_;
    my $self = PerlConsole::Preferences::init(); 
    bless($self, $class);
    return $self;
}

# set a preference to a given value, making sure it's an available value, and
# that the value given is valid.
sub set($$$)
{
    my ($self, $pref, $val) = @_;
    unless (defined $self->{'_valid_values'}{$pref}) {
        return 0;
    }
    unless (grep /$val/, @{$self->{'_valid_values'}{$pref}}) {
        return 0;
    }
    $self->{'_values'}{$pref} = $val;
}

# retrurn the preference's value
sub get($$)
{
    my ($self, $pref) = @_;
    unless (exists $self->{'_values'}{$pref}) {
        return 0;
    }
    return $self->{'_values'}{$pref};
}

# returns a list of all available preferences
sub getPreferences($)
{
    my ($self) = @_;
    return keys %{$self->{"_valid_values"}};
}

# returns a list of all possible values of a preference
sub getValidValues($$)
{
    my ($self, $pref) = @_;
    return [] unless defined $self->{'_valid_values'}{$pref};
    return $self->{'_valid_values'}{$pref};
}


# END
1;
