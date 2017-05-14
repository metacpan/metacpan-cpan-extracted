#!/bin/sh
# 2.2.2010, Sampo Kellomaki (sampo@iki.fi)
# Create the ZXID directory hierarchy
#
# Usage: ./zxmkdirs.sh     # By default creates and populates /var/zxid/
#        ./zxmkdirs.sh /var/zxid/idp
#        ./zxmkdirs.sh wsp/

ZXID_PATH=$1
if [ "x$ZXID_PATH" = "x" ] ; then ZXID_PATH=/var/zxid/; fi

ZXDIR="ses user uid nid log log/rely log/issue cot inv dimd uid/.all uid/.all/.bs tmp ch ch/default ch/default/.ack ch/default/.del"

mkdir -p $ZXID_PATH

for d in $ZXDIR; do
  echo "$ZXID_PATH$d"
  mkdir "$ZXID_PATH$d"
  chmod 02770 "$ZXID_PATH$d"
done

mkdir ${ZXID_PATH}pem  # Certificates and private keys (must protect well)

chmod -R 02750 ${ZXID_PATH}pem
#cp default-cot/* ${ZXID_PATH}cot

echo "You may need to run"
echo
echo "    chown -R nobody $ZXID_PATH"
echo
echo "to make sure the zxid CGI script can write to the $ZXID_PATH"
echo "directory (substitute nobody with the user your web server runs as)."
echo

#EOF