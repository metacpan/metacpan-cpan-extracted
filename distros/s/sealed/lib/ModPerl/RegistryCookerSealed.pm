package ModPerl::RegistryCookerSealed;
use strict;
use warnings;
use version;
our $VERSION = qv(1.3.0);

use Apache2::Const -compile => qw(:common &OPT_EXECCGI);
use ModPerl::RegistryCooker;
use constant DEBUG => ModPerl::RegistryCooker::DEBUG;
use constant D_NOISE => ModPerl::RegistryCooker::D_NOISE;
use sealed ();

sub convert_script_to_compiled_handler {
  my $self = shift;

  my $rc = Apache2::Const::OK;

  $self->debug("Adding package $self->{PACKAGE}") if DEBUG & D_NOISE;

  # get the script's source
  $rc = $self->read_script;
  return $rc unless $rc == Apache2::Const::OK;

  # convert the shebang line opts into perl code
  my $shebang = $self->shebang_to_perl;

  # mod_cgi compat, should compile the code while in its dir, so
  # relative require/open will work.
  $self->chdir_file;

  #    undef &{"$self->{PACKAGE}\::handler"}; unless DEBUG & D_NOISE; #avoid warnings
  #    $self->{PACKAGE}->can('undef_functions') && $self->{PACKAGE}->undef_functions;

  my $line = $self->get_mark_line;

  $self->strip_end_data_segment;

  # handle the non-parsed handlers ala mod_cgi (though mod_cgi does
  # some tricks removing the header_out and other filters, here we
  # just call assbackwards which has the same effect).
  my $base = File::Basename::basename($self->{FILENAME});
  my $nph = substr($base, 0, 4) eq 'nph-' ? '$_[0]->assbackwards(1);' : "";
  my $script_name = $self->get_script_name || $0;

  # handle sealed.pm's source filter ourselves, since the string eval won't.
  sealed::source_munger($self->{PACKAGE}) for ${$self->{CODE}};

  my $eval = join '',
    'package ',
    $self->{PACKAGE}, ";",
    "use base 'sealed';",
    "use types;",
    "use class;",
    "sub handler :Sealed {",
    "local \$0 = '$script_name';",
    $nph,
    $shebang,
    $line,
    ${ $self->{CODE} },
    "\n}"; # last line comment without newline?

  $rc = $self->compile(\$eval);
  return $rc unless $rc == Apache2::Const::OK;
  $self->debug(qq{compiled package \"$self->{PACKAGE}\"}) if DEBUG & D_NOISE;

  $self->chdir_file(Apache2::ServerUtil::server_root());

#    if(my $opt = $r->dir_config("PerlRunOnce")) {
#        $r->child_terminate if lc($opt) eq "on";
#    }

  $self->cache_it;

  return $rc;
}

undef &ModPerl::RegistryCooker::convert_script_to_compiled_handler;

*ModPerl::RegistryCooker::convert_script_to_compiled_handler = \&convert_script_to_compiled_handler;

__END__

=head1 NAME

ModPerl::RegistryCookerSealed - monkey-patch :Sealed registry handler() into ModPerl::RegistryCooker

=head2 SYNOPSIS

<VirtualHost *:443>
    PerlModule ModPerl::RegistryCookerSealed
    PerlResponseHandler ModPerl::Registry
    AddHandler perl-script .pl
    Options +ExecCGI
</VirtualHost>

=head2 LICENSE

Apache License v2.0
