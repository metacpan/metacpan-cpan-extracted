#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2014 -- leonerd@leonerd.org.uk

package Circle::Configurable;

use strict;
use warnings;

use base qw( Circle::Commandable );

use Carp;

use Attribute::Storage qw( get_subattr get_subattrs apply_subattrs_for_pkg find_subs_with_attr );
use Data::Dump qw( pp );
require mro;

#############################################
### Attribute handlers for setting_* subs ###
#############################################

my %setting_types = (
   str => {},

   int => {
      check => sub { m/^\d+$/ },
   },

   bool => {
      parse => sub {
         return 1 if lc $_ eq "true"  or lc $_ eq "on"  or $_ eq "1";
         return 0 if lc $_ eq "false" or lc $_ eq "off" or $_ eq "0";
         die;
      },
      print => sub { $_ ? "true" : "false" },
   },
);

sub Setting_description :ATTR(CODE)
{
   my $class = shift;
   my ( $text ) = @_;

   return $text;
}

sub Setting_type :ATTR(CODE)
{
   my $class = shift;
   my ( $typename ) = @_;

   exists $setting_types{$typename} or croak "Not a recognised type name '$typename'";

   return $setting_types{$typename};
}

sub Setting_default :ATTR(CODE)
{
   my $class = shift;
   my ( $value ) = @_;

   return $value;
}

sub Setting_inheritable :ATTR(CODE)
{
   return 1;
}

sub APPLY_Setting
{
   my $class = shift;
   my ( $name, %args ) = @_;

   my $storage = $args{storage} || $name;

   no strict 'refs';
   *{"${class}::setting_$name"} = apply_subattrs_for_pkg $class,
      Setting_description => qq("\Q$args{description}\E"),
      Setting_type        => qq("\Q$args{type}\E"),
      ( exists $args{default} ?
         ( Setting_default => pp($args{default}) ) : () ),
      sub {
         my $self = shift;
         my ( $newvalue ) = @_;

         $self->{$storage} = $newvalue if @_;
         return $self->{$storage};
      };
}

sub APPLY_Inheritable_Setting
{
   my $class = shift;
   my ( $name, %args ) = @_;

   my $storage = $args{storage} || $name;

   my $setting = "setting_$name";

   no strict 'refs';
   *{"${class}::setting_$name"} = apply_subattrs_for_pkg $class,
      Setting_description => qq("\Q$args{description}\E"),
      Setting_type        => qq("\Q$args{type}\E"),
      Setting_inheritable => qq(),
      ( exists $args{default} ?
         ( Setting_default => pp($args{default}) ) : () ),
      sub {
         my $self = shift;
         my ( $newvalue ) = @_;

         $self->{$storage} = $newvalue if @_;
         return $self->{$storage} if defined $self->{$storage};
         if( my $parent = $self->parent ) {
            return $parent->$setting;
         }
         else {
            return undef;
         }
      };
   *{"${class}::_setting_${name}_inherits"} = sub {
      my $self = shift;
      return $self->parent && !defined $self->{$storage};
   };
}

sub _get_settings
{
   my $self = shift;

   my $class = ref $self || $self;

   my %subs = find_subs_with_attr( mro::get_linear_isa( $class ), "Setting_description",
      matching => qr/^setting_/
   );

   my %settings;
   foreach my $name ( keys %subs ) {
      ( my $settingname = $name ) =~ s/^setting_//;
      my $cv = $subs{$name};

      my $attrs = $settings{$settingname} = get_subattrs( $cv );
      m/^Setting_(.*)$/ and $attrs->{$1} = delete $attrs->{$_} for keys %$attrs;
   }

   return \%settings;
}

sub command_set
   : Command_description("Display or manipulate configuration settings")
   : Command_arg('setting?')
   : Command_arg('value?')
   : Command_opt('inherit=+', desc => "Inherit value from parent")
   : Command_opt('help=+',    desc => "Display help on setting(s)")
   : Command_opt('values=+',  desc => "Display value of each setting")
{
   my $self = shift;
   my ( $setting, $newvalue, $opts, $cinv ) = @_;

   my $opt_inherit = $opts->{inherit};
   my $opt_help    = $opts->{help};
   my $opt_values  = $opts->{values};

   if( !defined $setting ) {
      my $settings = $self->_get_settings;

      keys %$settings or $cinv->respond( "No settings exist" ), return;

      if( $opt_values ) {
         my @table;
         foreach my $settingname ( sort keys %$settings ) {
            $setting = $settings->{$settingname};

            my $curvalue = $self->can( "setting_$settingname" )->( $self );
            if( $setting->{type}->{print} ) {
               $curvalue = $setting->{type}->{print}->( local $_ = $curvalue );
            }

            if( $setting->{inheritable} && $self->can( "_setting_${settingname}_inherits" )->( $self ) ) {
               $settingname .= " [I]";
            }

            push @table, [
               $settingname,
               ( defined $curvalue ? $curvalue : "" ),
            ];
         }

         $self->respond_table( \@table, colsep => ": ", headings => [ "Setting", "Value" ] );
      }
      else {
         my @table;
         foreach my $settingname ( sort keys %$settings ) {
            my $setting = $settings->{$settingname};

            push @table, [ $settingname, ( $setting->{Setting_description} || "[no description]" ) ];
         }

         $cinv->respond_table( \@table, colsep => " - ", headings => [ "Setting", "Description" ] );
      }

      return;
   }

   my $cv = $self->can( "setting_$setting" );
   if( !defined $cv ) {
      $cinv->responderr( "No such setting $setting" );
      return;
   }

   if( $opt_help ) {
      my $description = get_subattr( $cv, 'Setting_description' ) || "[no description]";
      $cinv->respond( "$setting - $description" );
      return;
   }

   my $type = get_subattr( $cv, 'Setting_type' );

   my $curvalue;
   if( defined $newvalue or $opt_inherit ) {
      if( !$opt_inherit and $type->{check} ) {
         local $_ = $newvalue;
         $type->{check}->( $newvalue ) or
            $cinv->responderr( "'$newvalue' is not a valid value for $setting" ), return;
      }

      if( !$opt_inherit and $type->{parse} ) {
         local $_ = $newvalue;
         eval { $newvalue = $type->{parse}->( $newvalue ); 1 } or
            $cinv->responderr( "'$newvalue' is not a valid value for $setting" ), return;
      }

      undef $newvalue if $opt_inherit;
      $curvalue = $cv->( $self, $newvalue );
   }
   else {
      $curvalue = $cv->( $self );
   }

   if( $type->{print} ) {
      local $_ = $curvalue;
      $curvalue = $type->{print}->( local $_ = $curvalue );
   }

   if( defined $curvalue ) {
      $cinv->respond( "$setting: $curvalue" );
   }
   else {
      $cinv->respond( "$setting is not set" );
   }

   return;
}

sub get_configuration
{
   my $self = shift;

   my $ynode = YAML::Node->new({});
   $self->store_configuration( $ynode );

   return $ynode;
}

sub load_configuration
{
   my $self = shift;
   my ( $ynode ) = @_;

   foreach my $setting ( keys %{ $self->_get_settings } ) {
      my $cv = $self->can( "setting_$setting" ) or croak "$self has no setting $setting";
      my $value = $ynode->{$setting};
      if( !defined $value and
          defined( my $default = get_subattr( $cv, "Setting_default" ) ) ) {
         $value = $default;
      }
      $cv->( $self, $value ) if defined $value;
   }
}

sub store_configuration
{
   my $self = shift;
   my ( $ynode ) = @_;

   foreach my $setting ( keys %{ $self->_get_settings } ) {
      my $cv = $self->can( "setting_$setting" ) or croak "$self has no setting $setting";
      my $value = $cv->( $self );
      $ynode->{$setting} = $value if defined $value;
   }
}

0x55AA;
