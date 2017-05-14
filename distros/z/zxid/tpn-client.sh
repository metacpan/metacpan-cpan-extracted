#!/bin/sh
# 20091217, Sampo Kellomaki (sampo@iki.fi)
# $Id$
#
# systemf("./tpn-client.sh %s %s %s", idpnid, "urn:idhrxml:cv:update", host);
# $NID        -- Identifier of the user in the local user database
# $TNSTARGET  -- service type and method, e.g. urn:idhrxml:cv:update
# $TNSSERVER  -- Domain name of the server (TrustBuilder will run on port 9595)

export JAVA_HOME=/apps/java/jre1.6.0_05

NID=$1
TNSTARGET=$2
TNSSERVER=$3

#edu.uiuc.cs.TrustBuilder2.TrustBuilder2.log_config = /var/zxid/idptpn/log.properties

cd /var/zxid/idpuid/$NID/tpn
cat >client.properties <<EOF
edu.uiuc.cs.TrustBuilder2.TrustBuilder2.root = ./
edu.uiuc.cs.TrustBuilder2.TrustBuilder2.log_config = ../../../idptpn/log.properties
edu.uiuc.cs.TrustBuilder2.TrustBuilder2.SecureRandom = SHA1PRNG
edu.uiuc.cs.TrustBuilder2.TrustBuilder2.configuration_1 = \
  be.kuleuven.esat.cosic.negotiation.CUPRelevantStrategy; \
  be.kuleuven.esat.cosic.negotiation.AttributeCredential; \
  be.kuleuven.esat.cosic.negotiation.authz.AuthzPolicyBrick
edu.uiuc.cs.TrustBuilder2.IOManipulation.IOManipulationModule.enabled = false
edu.uiuc.cs.TrustBuilder2.IOManipulation.IOManipulationModule.load = \
  edu.uiuc.cs.TrustBuilder2.IOManipulation.viz.VisualizationModule
edu.uiuc.cs.TrustBuilder2.IOManipulation.viz.VisualizationModule.load = \
  edu.uiuc.cs.TrustBuilder2.IOManipulation.viz.GuiVisualizer
edu.uiuc.cs.TrustBuilder2.state.SessionManager.expire = 3600000
edu.uiuc.cs.TrustBuilder2.state.SessionManager.cleanup = 120000
edu.uiuc.cs.TrustBuilder2.strategy.StrategyModuleMediator.loadStrategies = \
  be.kuleuven.esat.cosic.negotiation.CUPRelevantStrategy
edu.uiuc.cs.TrustBuilder2.verification.CredentialChainMediator.loadVerifiers = \
  edu.uiuc.cs.TrustBuilder2.verification.RootToLeafVerifier
edu.uiuc.cs.TrustBuilder2.verification.CredentialChainMediator.loadBuilders = \
  edu.uiuc.cs.TrustBuilder2.verification.SimpleChainBuilder
edu.uiuc.cs.TrustBuilder2.compliance.ComplianceCheckerMediator.loadComplianceCheckers = \
be.kuleuven.esat.cosic.negotiation.CUPComplianceChecker
edu.uiuc.cs.TrustBuilder2.query.QueryEngineMediator.loadQueryEngines = \
  edu.uiuc.cs.TrustBuilder2.query.profile.ProfileManager, \
    be.kuleuven.esat.cosic.negotiation.CUPPolicyManager
be.kuleuven.esat.cosic.negotiation.CUPPolicyManager.policyDir=./policies
edu.uiuc.cs.TrustBuilder2.query.profile.ProfileManager.loaderFileDir=profile_loaders
edu.uiuc.cs.TrustBuilder2.query.profile.ProfileManager.loadLoaders = \
  edu.uiuc.cs.TrustBuilder2.query.profile.ClaimLoader, \
  be.kuleuven.esat.cosic.negotiation.AttributeCredentialLoader
TCPTimeout=20000
TNSTarget=$TNSTARGET
TNSServer=$TNSSERVER

EOF

/apps/java/jre1.6.0_05/bin/java -classpath /s/T3-TPN-TB2/client/tn.jar be.kuleuven.esat.cosic.negotiation.client.TAS3Client client.properties >tns.result

#/apps/java/jre1.6.0_05/bin/java -classpath /s/T3-TPN-TB2/server/tn.jar be.kuleuven.esat.cosic.negotiation.server.TrustNegotiationServer # >tns.result

grep 'NO ERROR' tns.result

# NO ERROR
# none | <list of credentials>
# 

#EOF