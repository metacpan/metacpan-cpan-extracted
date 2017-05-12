#!/bin/bash

# Downloads WSDL and XSD Files

# check script call
if [ $# -ne 1 -a $# -ne 2 ];
then
  echo "USAGE: $0 zimbra.example.com"
  echo "  optional you can add the SOAP port"
  echo "  $0 zimbra.example.com 7071"
  exit 1
fi

SERVER="$1"
GIVENPORT="$2"
PORT=":${GIVENPORT:-7071}"

BASEDIR=$(dirname $0)

CONFIGDIR="${BASEDIR}/../etc/wsdl"
mkdir -p ${CONFIGDIR}
cd ${CONFIGDIR}

WGET='wget --no-check-certificate -nc'

echo "download WSDLs"
${WGET} https://${SERVER}${PORT}/service/wsdl/ZimbraAdminService.wsdl
${WGET} https://${SERVER}${PORT}/service/wsdl/ZimbraUserService.wsdl                  
${WGET} https://${SERVER}${PORT}/service/wsdl/ZimbraService.wsdl                   

echo "download XSDs"
${WGET} https://${SERVER}${PORT}/service/wsdl/zimbraAccount.xsd
${WGET} https://${SERVER}${PORT}/service/wsdl/zimbraAdminExt.xsd
${WGET} https://${SERVER}${PORT}/service/wsdl/zimbraAdmin.xsd
${WGET} https://${SERVER}${PORT}/service/wsdl/zimbraMail.xsd
${WGET} https://${SERVER}${PORT}/service/wsdl/zimbraRepl.xsd
${WGET} https://${SERVER}${PORT}/service/wsdl/zimbraSync.xsd
${WGET} https://${SERVER}${PORT}/service/wsdl/zimbraVoice.xsd
${WGET} https://${SERVER}${PORT}/service/wsdl/zimbra.xsd

