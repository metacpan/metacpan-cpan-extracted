#!/bin/sh
# 20130331 sampo@synergetics.be

FIND=find
RM="rm -rf"
PGP=gpg
#zalgo=--compress-algo bzip2     # seems bzip2 does not help much for audit data
ses_atime=1
trail_atime=30
backupdir=~/zxbackup
now=`date -u '+%Y%m%d-%H%M%S'`

warning="WARNING: Running this script (zxlogclean.sh) in production environment
         may destroy valuable audit trail data, which you may be legally obliged
         to retain. Be sure any such data has already been copied to a safe place."

help="This is a ZXID log cleanup script, typically run from cron(8)
Copyright (c) 2013 Synergetics NV. All Rights Reserved.
Author: Sampo Kellomaki (sampo@synergetics.be)

$warning

The default behaviour is to
   - backup most files not touched in $trail_atime days to directory $backupdir
   - remove any sessions older than 1 day by access time stamp (find ses -atime +$ses_atime)
   - remove any debugging files, such as xml.dbg

zxlogclean.sh  - Runs default behaviour assuming CWD to be the instance dir
zxlogclean.sh [OPTIONS] path1 path2  - Runs in specified instance directories

Options:
  -d   Debug mode
  -n   Dryrun: do not actually delete or backup files, just print what would be done
  -r   Really remove: delete files that by default would have been backed up
  -b   Always backup: backup all files, even those that would usually be removed
  -pgp PUBKEY   - When backing up, encrypt the backups using $PGP and public key
       from the public keyring.
  -sig PRIVKEY  - When backing up, sign the backups using $PGP and private key
       from the secret keyring.
  -sym SYMKEYFILE  - When backing up, encrypt the backups using $PGP and symmetric
       key from the specified file. Warn: The key is protected by file permissions.
  -symfd SYMKEYFD  - When backing up, encrypt the backups using $PGP and symmetric
       key from the specified file descriptor.
  -symstr SYMSTR   - When backing up, encrypt the backups using specified symmetric key.
       WARNING: The supplied key will be visible from the command line history and ps.
                For the best security, you should use the -pgp PUBKEY option. 
  -pubring FILE - Specifies public keyring file for -pgp. Default ~/.gnupg/pubring.gpg 
  -secring FILE - Specifies secret keyring file for -sig. Default ~/.gnupg/secring.gpg 
  -bdir D  Backups are to be made to directory D (default $backupdir)
  -trail N Trail backup -atime value (in days) (default $trail_atime)
  -ses N   Session deletion -atime value (in days) (default $ses_atime)
  -nw  Shut down the warning about audit trail destruction
  -nd  No delete. Even when running for real and making backups, etc., do not delete
  -h   This help
  --   End of options

For -pgp and -sig options to work, you must have created keyrings, see $PGP --gen-key

To decrypt (and verify signature, if any):
gpg --secret-keyring log-decrypt-secret.gpg <~/zxbackup/trail-20130405-194808.tar.pgp | tar xvf -

BUGS: The -pgp options may be still buggy (20130404 --Sampo)
"

warn() { echo "$1" 1>&2; }
die()  { echo "$1" 1>&2; exit 1; }

while [ 1 ]; do
#warn "HERE($1)"
case "$1" in
-d)  debug=1;  shift; continue;;
-n)  dryrun=1; shift; continue;;
-r)  remove=1; shift; continue;;
-b)  backup=1; shift; continue;;
-f)  force=1;  shift; warn "Force not supported, see -r and -b\n$help"; continue;;
-pgp)    shift;  pubkey=$1;   shift; continue;;
-sig)    shift;  sig="-u $1 -s";   shift; continue;;
-sym)    shift;  symkeyf=$1;  shift; symenc=1; passphrase="--passphrase-file $symkeyf"; continue;;
-symfd)  shift;  symkeyfd=$1; shift; symenc=1; passphrase="--passphrase-fd $symkeyfd"; continue;;
-symstr) shift;  symkeys=$1;  shift; symenc=1; passphrase="--passphrase $symkeys"; continue;;
-pubring) shift; pubring="--no-default-keyring --keyring $1";   shift; continue;;
-secring) shift; secring="--secret-keyring $1";   shift; continue;;
-bdir)   shift;  backupdir=$1;   shift; continue;;
-trail)  shift;  trail_atime=$1; shift; continue;;
-ses)    shift;  ses_atime=$1;   shift; continue;;
-nw) warning=""; shift; continue;;
-nd) nodel=1; shift; continue;;
-h)  echo "$help"; exit;;
--)  shift; break;;
-*)  die "Unknown option: $1\n$help";;
*)   break;;
esac
done

[ "$warning" ] && warn "$warning"

[ -d $backupdir ] || die "Backup directory $backupdir does not exist. Run mkdir $backupdir"

tarup() {
    if xargs tar czf $1 < $2; then
	[ $debug ] && warn "tar: Created backup($1)"
	[ $nodel ] || xargs $RM < $2
    else
	warn "ERROR: Failed to create a backup($1). Originals not deleted."
    fi
}

pgppub() {
    #[ ! -r $pubkey ] && die "Public key($pubkey) not found or not readable ($?)"
    if cat $2 | xargs tar cf - | $PGP $zalgo $pubring $secring $sig -r $pubkey -e --batch > $1 ; then
	[ $debug ] && warn "pgppub: Created backup($1)"
	[ $nodel ] || xargs $RM < $2
    else
	warn "ERROR: Failed to create a backup($1). Originals not deleted!"
    fi
}

pgpsym() {
    #[ ! -r $symkey ] && die "Symmetric key($pubkey) not found or not readable ($?)"
    #warn "$PGP $zalgo $pubring $secring $sig --force-mdc $passphrase -c --batch"
    if xargs tar cf - < $2 | $PGP $zalgo $pubring $secring $sig --force-mdc $passphrase -c --batch > $1 ; then
	[ $debug ] && warn "pgpsym: Created backup($1)"
	[ $nodel ] || xargs $RM < $2
    else
	warn "ERROR: Failed to create a backup($1). Originals not deleted!"
    fi
}

### Per instance directory cleaning

clean_inst() {
    dir=$1

    #mkdir $dir/log/issue $dir/log/rely     # in case we accidentally delete them
    #chown si $dir/log/issue $dir/log/rely
    #chmod g+s $dir/log/issue $dir/log/rely

    [ $debug ] && warn "cleaning $dir"

    # Immediate cleanup items

    echo "$dir/log/xml.dbg" > $backupdir/zxlogclean-todel-$$

    if [ $dryrun ] ; then cat $backupdir/zxlogclean-todel-$$
    elif [ "$backup" -a "$pubkey" ] ; then
	pgppub $backupdir/junk-$now.tar.pgp $backupdir/zxlogclean-todel-$$
    elif [ "$backup" -a "$symenc" ] ; then
	pgpsym $backupdir/junk-$now-sym.tar.pgp $backupdir/zxlogclean-todel-$$
    elif [ $backup ] ; then
	tarup $backupdir/junk-$now.tgz $backupdir/zxlogclean-todel-$$
    else 
	[ $nodel ] || xargs $RM <$backupdir/zxlogclean-todel-$$
    fi

    [ $debug ] || $RM $backupdir/zxlogclean-todel-$$

    # Audit trail

    $FIND $dir/log -mindepth 2 \! -name .keep -atime +$trail_atime >$backupdir/zxlogclean-trail-$$
    echo "$dir/log/err" >> $backupdir/zxlogclean-trail-$$
    echo "$dir/log/act" >> $backupdir/zxlogclean-trail-$$

    #echo "Reset $now" > $dir/log/err
    #echo log/err* > $backupdir/zxlogclean-trail-$$
    #echo log/act* >> $backupdir/zxlogclean-trail-$$

    if [ $dryrun ] ; then cat $backupdir/zxlogclean-trail-$$
    elif [ $pubkey ] ; then
	pgppub $backupdir/trail-$now.tar.pgp $backupdir/zxlogclean-trail-$$
    elif [ $symenc ] ; then
	pgpsym $backupdir/trail-$now-sym.tar.pgp $backupdir/zxlogclean-trail-$$
    elif [ "$remove" -a !"$backup" ] ; then
	[ $nodel ] || xargs $RM <$backupdir/zxlogclean-trail-$$
    else # backup is the default for most trail items
	tarup $backupdir/trail-$now.tgz $backupdir/zxlogclean-trail-$$
    fi

    [ $debug ] || $RM $backupdir/zxlogclean-trail-$$

    # Session

    $FIND $dir/ses -mindepth 1 -depth -atime +$ses_atime -type d >$backupdir/zxlogclean-ses-to-rm-$$
    
    if [ $dryrun ] ; then cat $backupdir/zxlogclean-ses-to-rm-$$
    elif [ "$backup" -a "$pubkey" ] ; then
	pgppub $backupdir/ses-$now.tar.pgp $backupdir/zxlogclean-ses-to-rm-$$
    elif [ "$backup" -a "$symenc" ] ; then
	pgpsym $backupdir/ses-$now-sym.tar.pgp $backupdir/zxlogclean-ses-to-rm-$$
    elif [ $backup ] ; then
	tarup $backupdir/ses-$now.tgz $backupdir/zxlogclean-ses-to-rm-$$
    else 
	[ $nodel ] || xargs $RM <$backupdir/zxlogclean-ses-to-rm-$$
    fi

    [ $debug ] || $RM $backupdir/zxlogclean-ses-to-rm-$$

    # Other cleanup items ***
}

### Main loop

if [ "x$*" = "x" ] ; then clean_inst `pwd`; exit; fi

for inst in $* ; do
  if [ ! -d $inst ] ; then warn "Instance($inst) is not a directory. Skipping."; continue; fi
  if [ ! -d $inst/log ] ; then warn "Inst($inst) is missing log. Skipping."; continue; fi
  clean_inst $inst
done

#EOF