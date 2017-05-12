package QBit::Gettext::Extract;
$QBit::Gettext::Extract::VERSION = '0.006';
use qbit;

use base qw(QBit::Class);

use QBit::Gettext::PO;

__PACKAGE__->mk_ro_accessors(qw(po));

my %DEFAULT_LANG_EXTENSIONS = (
    'QBit::Gettext::Extract::Lang::Perl' => [qw(.pl .pm)],
    'QBit::Gettext::Extract::Lang::TT2'  => [qw(.tt2 .tpl)],
);

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    $self->{'po'} = QBit::Gettext::PO->new();

    my %lang_extensions = %DEFAULT_LANG_EXTENSIONS;
    push_hs(%lang_extensions, %{$self->{'lang_extensions'} || {}});

    $self->{'__EXT2LANG__'} = {};
    while (my ($lang, $exts) = each(%lang_extensions)) {
        $self->{'__EXT2LANG__'}{$_} = $lang foreach (@$exts);
    }
}

sub extract_from_file{
    my ($self, $filename) = @_;

    throw Exception::BadArguments gettext('File "%s" does not exists', $filename) unless -f $filename;

    my $lang_class_name = $self->_get_lang_class_by_filename($filename) || return;

    eval("require $lang_class_name");
    $lang_class_name->new()->extract_from_file($filename, $self->po);
}

sub _get_lang_class_by_filename {
    my ($self, $filename) = @_;

    my ($extension) = $filename =~ /((?:\.[^.]+)+)$/;

    do {
        return $self->{'__EXT2LANG__'}{$extension} if exists($self->{'__EXT2LANG__'}{$extension});
        ($extension) = $extension =~ /\.[^.]+((?:\.[^.]+)+)$/;
    } while defined($extension);

    return FALSE;
}

TRUE;
