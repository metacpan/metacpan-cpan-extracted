package UMMF::Config::Profile;

use 5.6.0;
use strict;
use warnings;


our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/10/20 };
our $VERSION = do { my @r = (q$Revision: 1.6 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Config::Profile - Configuration Profile object.

=head1 SYNOPSIS

  my $profile = UMMF::Config::Profile->new('profile' => 'UML-1.5');

  my $value = $profile->config_value($modelElement, $name, $default);

=head1 DESCRIPTION

This class is used by bin/ummf.pl to allow the configuration profiles to be reused for different models, particularly for specifing how specific ModelElements may be mapped to implementation language types.

=head1 USAGE

  my $value = $profile->config_*($model_element, $key, $default);

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/10/20

=head1 SEE ALSO

L<UMMF::UML::MetaMetaModel::Config|UMMF::UML::MetaMetaModel::Config>

L<lib/ummf/profile/*.ummfprofile>

=head1 VERSION

$Revision: 1.6 $

=head1 METHODS

=cut


#######################################################################

use base qw(UMMF::Core::Config);

#######################################################################

use Carp qw(confess);

#######################################################################


sub set_profile
{
  my ($self, $profile) = @_;

  # $DB::single = 1;

  $self->{'profile'} = $profile;
  $self->{'.profile'} = undef;

  $self;
}


#######################################################################


sub override
{
  my ($self) = @_;

  # $DB::single = 1;

  $self->_profile;
}


#######################################################################


sub _profile
{
  my ($self) = @_;

  my $_profile = $self->{'.profile'};

  unless ( $_profile ) {
    my $profile = $self->{'profile'};

    if ( ref($profile) eq 'HASH' ) {
      # $DB::single = 1;

      $_profile = $profile;
    }
    elsif ( $profile ) {
      $profile = [ split(/\s+|\s*,\s*/, $profile) ] unless ref($profile);

      print STDERR "Profile: using profile @$profile\n";

      $profile = join("\n",
		      map(qq{[% PROCESS "$_.ummfprofile" %]},
			  @$profile,
			 )
		     );

      # $DB::single = 1;

      # Use template to process profile.
      my $template = 
	{
	 'INCLUDE_PATH' => [ UMMF->resource_path('profile') ],
	 'INTERPOLATE' => 0,
	 'POST_CHOMP' => 1,
	 'EVAL_PERL' => 1,
	 'DEBUG' => 1,
	 'ABSOLUTE' => 1,
	 'RELATIVE' => 1,
	};

      {
	use Template;
	
	$template = Template->new($template) || confess($Template::ERROR);
      }
      
      # print STDERR "profile = '$profile'\n";

      {
	my $vars = $self;
	my $output = '';
	$template->process(\$profile, $vars, \$output);
	$profile = $output;
      }


      # print STDERR "profile = '$profile'\n";

      {
	use YAML ();

	# $DB::single = 1;
	$_profile = YAML::Load($profile);
      }
    }

    $self->{'.profile'} = $_profile || { };

    # print STDERR Data::Dumper->new([ $_profile ], [ qw($_profile) ])->Dump;
  }


  $_profile;
}


#######################################################################

1;

#######################################################################


### Keep these comments at end of file: kstephens@users.sourceforge.net 2003/10/20 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###

