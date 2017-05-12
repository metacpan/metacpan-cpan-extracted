package Test::PAUSE::ConsistentPermissions::Check;

use strictures 2;

use Moo;
use PAUSE::Permissions;
use List::Compare;

our $VERSION = '0.003';

has permissions_client => (is => 'ro', lazy => 1, builder => '_build_permissions_client');

sub _build_permissions_client
{
    my $self = shift;
    my $pp = PAUSE::Permissions->new(preload => 1, max_age => '1 day');
    return $pp;
}

sub report_problems
{
    my $self = shift;
    my $modules = shift;
    my $authority_from = shift;

    my $pp = $self->permissions_client;
    my $master = $pp->module_permissions($authority_from);
    unless($master)
    {
        return {
            module => $authority_from,
            owner => 'UNKOWN',
            comaint => [],
            inconsistencies => 0,
            problems => [
                {
                    module => $authority_from,
                    issues => {
                        missing_authority => "$authority_from not found in permissions list",
                    }
                }
            ],
        };
    }
    my $owner = $master->owner;
    my @comaint = $master->co_maintainers;
    my $inconsistencies = 0;

    my @problem_list;
    for my $module (@$modules)
    {
        my $mp = $pp->module_permissions($module);
        unless($mp)
        {
            push @problem_list, { module => $module, issues => { missing_permissions => 'Permissions not found on PAUSE'} };
            next;
        }
        my $mod_owner = $mp->owner;
        my @mc = $mp->co_maintainers;
        my $problems = {};
        my $inconsistent = 0;
        if($mod_owner ne $owner)
        {
            $problems->{different_owner} = $mod_owner;
            $inconsistent = 1;
        }
        my $lc = List::Compare->new(\@comaint, \@mc);
        unless($lc->is_LequivalentR)
        {
            my @missing = $lc->get_unique();
            my @extra = $lc->get_complement();
            $problems->{missing} = \@missing if @missing;
            $problems->{extra} = \@extra if @extra;
            $inconsistent = 1;
        }
        $inconsistencies += $inconsistent;
        if(%$problems)
        {
            push @problem_list, { module => $module, issues => $problems };
        }
    }

    return {
        module => $authority_from,
        owner => $owner,
        comaint => \@comaint,
        problems => \@problem_list,
        inconsistencies => $inconsistencies,
    };
}

# FIXME: do these methods really belong here?
sub module_info_to_fh
{
    my $self = shift;
    my $report = shift;
    my $fh = shift;
    print $fh "Module: " . $report->{module}, "\n";
    print $fh "Owner: " . $report->{owner}, "\n";
    print $fh "Comaint: " . join(', ', @{$report->{comaint}}), "\n";
}

sub problems_to_fh
{
    my $self = shift;
    my $report = shift;
    my $fh = shift;
    my $problems = @{$report->{problems}};
    if($problems)
    {
        print $fh "Problems found:\n";
        for my $problem (@{$report->{problems}})
        {
            print $fh "Module: " . $problem->{module}. "\n";
            if(exists $problem->{issues}->{different_owner})
            {
                print $fh " has a different owner - " . $problem->{issues}->{different_owner} . "\n";
            }
            if($problem->{issues}->{missing_authority})
            {
                print $fh " unable to find permissions for the module\n";
            }
            if($problem->{issues}->{missing_permissions})
            {
                print $fh " unable to find permissions for the module\n";
            }
            if($problem->{issues}->{missing})
            {
                print $fh " is missing comaintainers - " . join(', ', @{$problem->{issues}->{missing}}) . "\n";
            }
            if($problem->{issues}->{extra})
            {
                print $fh " has additional comaintainers - " . join(', ', @{$problem->{issues}->{extra}}) . "\n";
            }
        }
    }
}

# achieve: 
# report incorrect owner.  
# report missing comaint.

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::PAUSE::ConsistentPermissions::Check

=head1 VERSION

version 0.003

=head1 DESCRIPTION

This class downloads the permissions from CPAN and checks them for consistency.

It returns basic permissions information about the module regardless (assuming
it was found on CPAN) and a problems array with any problems that were found.

    my $perms_test = Test::PAUSE::ConsistentPermissions::Check->new;
    my $report = $perms_test->report_problems([qw/
        OpusVL::AppKit
        OpusVL::AppKit::Action::AppKitForm
        OpusVL::AppKit::Builder
    /], 'OpusVL::AppKit');
    # report 
    # {
    #     module => 'OpusVL::AppKit',
    #     owner => 'NEwELLC',
    #     comaint => ['ALTREUS', 'BRADH'],
    #     inconsistencies => 0,
    #     problems => [],
    # }

It reports missing permissions in the problem array, but does not increment
the inconsistencies counter for that as they probably aren't inconsistent,
simply not present yet.  This is likely to happen when you are preparing
to upload a new version.

=head1 NAME

Test::PAUSE::ConsistentPermissions::Check - Class used to check permissions.

=head1 METHODS

=head2 report_problems

This expects an array reference of modules to check, and the module to use
as the authority for the permissions.

    my $report = $perms_test->report_problems($modules, $authority_module);

If the module was not found in the permissions list then the owner is set to 
UNKOWN and the problems has a hashref with the key 'missing'.

=head1 ATTRIBUTES

=head2 permissions_client

This is the L<PAUSE::Permissions> object used to check the PAUSE permissions.

=head1 AUTHOR

Colin Newell <colin.newell@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Colin Newell.

This is free software, licensed under:

  The MIT (X11) License

=cut
