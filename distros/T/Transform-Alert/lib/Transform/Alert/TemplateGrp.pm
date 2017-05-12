package Transform::Alert::TemplateGrp;

our $VERSION = '1.00'; # VERSION
# ABSTRACT: Base class for Transform::Alert template groups

use sanity;
use Moo;
use MooX::Types::MooseLike::Base qw(Bool Str ArrayRef RegexpRef HashRef InstanceOf ConsumerOf Maybe);

use Template 2.24;
use Data::Dump 'pp';
use File::Slurp 'read_file';
use String::Escape qw(elide printable);
use Module::Load;  # yes, using both Class::Load and Module::Load, as M:L will load files
use Module::Metadata;

use namespace::clean;

has in_group => (
   is       => 'rwp',
   isa      => InstanceOf['Transform::Alert::InputGrp'],
   weak_ref => 1,
   handles  => [ 'log' ],
);
has regexp => (
   is       => 'ro',
   isa      => Maybe[RegexpRef],
   required => 1,
);
has munger => (
   is        => 'ro',
   isa       => ArrayRef[Str],
   predicate => 1,
);
has outputs => (
   is       => 'ro',
   isa      => HashRef[ConsumerOf['Transform::Alert::Output']],
   required => 1,
);

around BUILDARGS => sub {
   my ($orig, $self) = (shift, shift);
   my $hash = shift;
   $hash = { $hash, @_ } unless ref $hash;

   # temp hash with output objects
   my $outs = delete $hash->{output_objs};

   # replace OutputNames with Outputs
   my $outputs = delete $hash->{outputname};
   $outputs = [ $outputs ] unless (ref $outputs eq 'ARRAY');
   $hash->{outputs} = { map {
      $_ => ($outs->{$_} || die "OutputName '$_' doesn't have a matching Output block!")
   } @$outputs };

   # read template file
   if    ($hash->{templatefile}) { $hash->{regexp} = read_file( delete $hash->{templatefile} ); }
   elsif ($hash->{template})     { $hash->{regexp} = delete $hash->{template}; }
   else                          { $hash->{regexp} = undef; }

   # work with inline templates (and file above)
   if ($hash->{regexp} && not ref $hash->{regexp}) {
      my $tmpl_text = $hash->{regexp};
      $tmpl_text =~ s/^\s+|\s+$//g;  # remove leading/trailing spaces
      $tmpl_text =~ s/\r//g;         # make sure it works for all line-endings
      $tmpl_text = '^'.$tmpl_text.'$';
      $hash->{regexp} = qr/$tmpl_text/;
   }

   # munger class
   if (my $munger = delete $hash->{munger}) {
      # variable parsing
      my ($file, $class, $fc, $method);
      ($fc, $method)  = split /-\>/, $munger, 2;
      ($file, $class) = split /\s+/, $fc, 2;

      unless ($class) {
         my $info = Module::Metadata->new_from_file($file);
         $class = ($info->packages_inside)[0];
         die "No packages found in $file!" unless $class;
      }
      $method ||= 'munge';

      load $file;
      $hash->{munger} = [ $class, $method ];
   }

   $orig->($self, $hash);
};

sub send_all {
   my ($self, $vars) = @_;
   my $log = $self->log;
   $log->debug('Processing outputs...');

   $log->trace('Variables (pre-munged):');
   $log->trace( join "\n", map { '   '.$_ } split(/\n/, pp $vars) );

   # Munge the data if configured
   if ($self->munger) {
      my ($class, $method) = @{ $self->munger };
      no strict 'refs';
      $vars = $class->$method($vars, $self);

      unless ($vars) {
         $log->debug('Munger cancelled output');
         return 1;
      }

      $log->trace('Variables (post-munge):');
      $log->trace( join "\n", map { '   '.$_ } split(/\n/, pp $vars) );
   }

   # Support multiple outputs, if the munger sent them
   $vars = [ $vars ] unless (ref $vars eq 'ARRAY');

   my $tt = Template->new();
   foreach my $v (@$vars) {
      foreach my $out_key (keys %{ $self->outputs }) {
         $log->debug('Looking at Output "'.$out_key.'"...');
         my $out = $self->outputs->{$out_key};
         my $out_str = '';

         $tt->process($out->template, $v, \$out_str) || do {
            $log->error('TT error for "$out_key": '.$tt->error);
            $log->warn('Output error... bailing out of this process cycle!');
            $self->close_all;
            return;
         };

         # send alert
         unless ($out->opened) {
            $log->debug('Opening output connection');
            $out->open;
         }
         $log->info('Sending alert for "'.$out_key.'"');
         $log->info('   Output message: '.printable(elide($out_str, int(2.5 ** $log->level) )) );

         unless ($out->send(\$out_str)) {
            $log->warn('Output error... bailing out of this process cycle!');
            $self->close_all;
            return;
         }
      }
   }

   return 1;
}

sub close_all {
   my $self = shift;
   $_->close for (values %{ $self->outputs });
   return 1;
}

42;

__END__

=pod

=encoding utf-8

=head1 NAME

Transform::Alert::TemplateGrp - Base class for Transform::Alert template groups

=head1 SYNOPSIS

    # In your configuration
    <Input ...>
       <Template>  # one or more
          # Template/File can be optional
          TemplateFile  [file]      # not used with Template
          Template      "[String]"  # not used with TemplateFile
 
          Munger        [file] [class]->[method]  # optional
          OutputName    test_out    # one or more
       </Template>
    </Input>

=head1 DESCRIPTION

This is essentially a class used for handling C<<< Template >>> sections.  In the grand scheme of things, the classes follow this hierarchy:

    transalert_ctl
       Transform::Alert
          TA::InputGrp
             TA::Input::*
             TA::TemplateGrp
                TA::Output::* (referenced from the main TA object)
          TA::Output::* (stored list only)

In fact, the configuration file is parsed recursively in this fashion.

However, this isn't really a user-friendly interface.  So, shoo!

=head1 SEE ALSO

L<Transform::Alert>, which is what you should really be reading...

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/Transform-Alert/wiki>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Transform::Alert/>.

=head1 AUTHOR

Brendan Byrd <BBYRD@CPAN.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
