#!/bin/bash
cd lib/WebService || exit
podchecker Hexonet.pm Hexonet/Connector.pm Hexonet/Connector/APIClient.pm Hexonet/Connector/Column.pm Hexonet/Connector/Record.pm Hexonet/Connector/Response.pm Hexonet/Connector/ResponseParser.pm Hexonet/Connector/ResponseTemplate.pm Hexonet/Connector/ResponseTemplateManager.pm Hexonet/Connector/SocketConfig.pm 
cd ../.. || exit