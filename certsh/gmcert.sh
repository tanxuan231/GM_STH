#!/bin/sh

# For a list of supported curves, use "apps/openssl ecparam -list_curves".

# Path to the openssl distribution
OPENSSL_DIR=.
# Path to the openssl program
#OPENSSL_CMD=openssl
OPENSSL_CMD=gmssl
# Option to find configuration file
OPENSSL_CNF="-config ./openssl.cnf"
# Directory where certificates are stored
CERTS_DIR=./sm2Certs
# Directory where private key files are stored
KEYS_DIR=$CERTS_DIR
# Directory where combo files (containing a certificate and corresponding
# private key together) are stored
COMBO_DIR=$CERTS_DIR
# cat command
CAT=/bin/cat
# rm command
RM=/bin/rm
# mkdir command
MKDIR=/bin/mkdir
# The certificate will expire these many days after the issue date.
DAYS=1500
TEST_CA=SM2
TEST_CA_CURVE=sm2p256v1
TEST_CA_FILE=CA
TEST_CA_DN="/C=CN/ST=BJ/L=HaiDian/O=Beijing RedCore./OU=RedCore/CN=Test CA (SM2)"

TEST_SERVER_CURVE=SM2
TEST_SERVER_FILE=SS
TEST_SERVER_DN="/C=CN/ST=BJ/L=HaiDian/O=Beijing RedCore/OU=RedCore/CN=server sign (SM2)"

TEST_SERVER_ENC_FILE=SE
TEST_SERVER_ENC_DN="/C=CN/ST=BJ/L=HaiDian/O=Beijing RedCore/OU=RedCore/CN=server enc (SM2)"

TEST_CLIENT_CURVE=SM2
TEST_CLIENT_FILE=CS
TEST_CLIENT_DN="/C=CN/ST=BJ/L=HaiDian/O=Beijing RedCore/OU=RedCore/CN=client sign (SM2)"

TEST_CLIENT_ENC_FILE=CE
TEST_CLIENT_ENC_DN="/C=CN/ST=BJ/L=HaiDian/O=Beijing RedCore/OU=RedCore/CN=client enc (SM2)"

# Generating an EC certificate involves the following main steps
# 1. Generating curve parameters (if needed)
# 2. Generating a certificate request
# 3. Signing the certificate request 
# 4. [Optional] One can combine the cert and private key into a single
#    file and also delete the certificate request

$MKDIR -p $CERTS_DIR
$MKDIR -p $KEYS_DIR
$MKDIR -p $COMBO_DIR

echo "Generating self-signed CA certificate (on curve $TEST_CA_CURVE)"
echo "==============================================================="
$OPENSSL_CMD ecparam -name $TEST_CA_CURVE -out $TEST_CA.pem

# Generate a new certificate request in $TEST_CA_FILE.req.pem. A 
# new ecdsa (actually ECC) key pair is generated on the parameters in
# $TEST_CA.pem and the private key is saved in $TEST_CA_FILE.key.pem
# WARNING: By using the -nodes option, we force the private key to be 
# stored in the clear (rather than encrypted with a password).
$OPENSSL_CMD req -config ./CA.cnf -nodes -subj "$TEST_CA_DN" \
    -keyout $KEYS_DIR/$TEST_CA_FILE.key.pem \
    -newkey ec:$TEST_CA.pem -new \
    -out $CERTS_DIR/$TEST_CA_FILE.req.pem -sm3

# Sign the certificate request in $TEST_CA_FILE.req.pem using the
# private key in $TEST_CA_FILE.key.pem and include the CA extension.
# Make the certificate valid for 1500 days from the time of signing.
# The certificate is written into $TEST_CA_FILE.cert.pem
$OPENSSL_CMD x509 -req -days $DAYS \
    -in $CERTS_DIR/$TEST_CA_FILE.req.pem \
    -extfile $OPENSSL_DIR/openssl.cnf \
    -extensions v3_ca \
    -signkey $KEYS_DIR/$TEST_CA_FILE.key.pem \
    -out $CERTS_DIR/$TEST_CA_FILE.cert.pem -sm3

# Display the certificate
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_CA_FILE.cert.pem -text

# Place the certificate and key in a common file
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_CA_FILE.cert.pem -issuer -subject \
	 > $COMBO_DIR/$TEST_CA_FILE.pem
$CAT $KEYS_DIR/$TEST_CA_FILE.key.pem >> $COMBO_DIR/$TEST_CA_FILE.pem

# Remove the cert request file (no longer needed)
$RM $CERTS_DIR/$TEST_CA_FILE.req.pem

echo "GENERATING A TEST SERVER CERTIFICATE (on elliptic curve $TEST_SERVER_CURVE)"
echo "=========================================================================="
# Generate a new certificate request in $TEST_SERVER_FILE.req.pem. A 
# new ecdsa (actually ECC) key pair is generated on the parameters in
# $TEST_SERVER_CURVE.pem and the private key is saved in 
# $TEST_SERVER_FILE.key.pem
# WARNING: By using the -nodes option, we force the private key to be 
# stored in the clear (rather than encrypted with a password).
$OPENSSL_CMD req -config eccsignuser.cnf -nodes -subj "$TEST_SERVER_DN" \
    -keyout $KEYS_DIR/$TEST_SERVER_FILE.key.pem \
    -newkey ec:$TEST_SERVER_CURVE.pem -new \
    -out $CERTS_DIR/$TEST_SERVER_FILE.req.pem -sm3

# Sign the certificate request in $TEST_SERVER_FILE.req.pem using the
# CA certificate in $TEST_CA_FILE.cert.pem and the CA private key in
# $TEST_CA_FILE.key.pem. Since we do not have an existing serial number
# file for this CA, create one. Make the certificate valid for $DAYS days
# from the time of signing. The certificate is written into 
# $TEST_SERVER_FILE.cert.pem
$OPENSSL_CMD x509 -req -days $DAYS \
    -in $CERTS_DIR/$TEST_SERVER_FILE.req.pem \
    -CA $CERTS_DIR/$TEST_CA_FILE.cert.pem \
    -CAkey $KEYS_DIR/$TEST_CA_FILE.key.pem \
	-extfile $OPENSSL_DIR/openssl.cnf \
	-extensions v3_req \
    -out $CERTS_DIR/$TEST_SERVER_FILE.cert.pem -CAcreateserial -sm3

# Display the certificate 
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_SERVER_FILE.cert.pem -text

# Place the certificate and key in a common file
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_SERVER_FILE.cert.pem -issuer -subject \
	 > $COMBO_DIR/$TEST_SERVER_FILE.pem
$CAT $KEYS_DIR/$TEST_SERVER_FILE.key.pem >> $COMBO_DIR/$TEST_SERVER_FILE.pem

# Remove the cert request file (no longer needed)
$RM $CERTS_DIR/$TEST_SERVER_FILE.req.pem

echo "	GENERATING A TEST SERVER ENCRYPT CERTIFICATE (on elliptic curve $TEST_SERVER_CURVE)"
echo "  ==================================================================================="
# Generate a new certificate request in $TEST_SERVER_FILE.req.pem. A 
# new ecdsa (actually ECC) key pair is generated on the parameters in
# $TEST_SERVER_CURVE.pem and the private key is saved in 
# $TEST_SERVER_FILE.key.pem
# WARNING: By using the -nodes option, we force the private key to be 
# stored in the clear (rather than encrypted with a password).
$OPENSSL_CMD req -config eccencuser.cnf -nodes -subj "$TEST_SERVER_ENC_DN" \
    -keyout $KEYS_DIR/$TEST_SERVER_ENC_FILE.key.pem \
    -newkey ec:$TEST_SERVER_CURVE.pem -new \
    -out $CERTS_DIR/$TEST_SERVER_ENC_FILE.req.pem -sm3

# Sign the certificate request in $TEST_SERVER_FILE.req.pem using the
# CA certificate in $TEST_CA_FILE.cert.pem and the CA private key in
# $TEST_CA_FILE.key.pem. Since we do not have an existing serial number
# file for this CA, create one. Make the certificate valid for $DAYS days
# from the time of signing. The certificate is written into 
# $TEST_SERVER_FILE.cert.pem
$OPENSSL_CMD x509 -req -days $DAYS \
    -in $CERTS_DIR/$TEST_SERVER_ENC_FILE.req.pem \
    -CA $CERTS_DIR/$TEST_CA_FILE.cert.pem \
    -CAkey $KEYS_DIR/$TEST_CA_FILE.key.pem \
	-extfile $OPENSSL_DIR/openssl.cnf \
	-extensions v3enc_req \
    -out $CERTS_DIR/$TEST_SERVER_ENC_FILE.cert.pem -CAcreateserial -sm3

# Display the certificate 
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_SERVER_ENC_FILE.cert.pem -text

# Place the certificate and key in a common file
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_SERVER_ENC_FILE.cert.pem -issuer -subject \
	 > $COMBO_DIR/$TEST_SERVER_ENC_FILE.pem
$CAT $KEYS_DIR/$TEST_SERVER_ENC_FILE.key.pem >> $COMBO_DIR/$TEST_SERVER_ENC_FILE.pem

# Remove the cert request file (no longer needed)
$RM $CERTS_DIR/$TEST_SERVER_ENC_FILE.req.pem



echo "GENERATING A TEST CLIENT CERTIFICATE (on elliptic curve $TEST_CLIENT_CURVE)"
echo "=========================================================================="
# Generate a new certificate request in $TEST_CLIENT_FILE.req.pem. A 
# new ecdsa (actually ECC) key pair is generated on the parameters in
# $TEST_CLIENT_CURVE.pem and the private key is saved in 
# $TEST_CLIENT_FILE.key.pem
# WARNING: By using the -nodes option, we force the private key to be 
# stored in the clear (rather than encrypted with a password).
$OPENSSL_CMD req -config eccsignuser.cnf -nodes -subj "$TEST_CLIENT_DN" \
	     -keyout $KEYS_DIR/$TEST_CLIENT_FILE.key.pem \
	     -newkey ec:$TEST_CLIENT_CURVE.pem -new \
	     -out $CERTS_DIR/$TEST_CLIENT_FILE.req.pem -sm3

# Sign the certificate request in $TEST_CLIENT_FILE.req.pem using the
# CA certificate in $TEST_CA_FILE.cert.pem and the CA private key in
# $TEST_CA_FILE.key.pem. Since we do not have an existing serial number
# file for this CA, create one. Make the certificate valid for $DAYS days
# from the time of signing. The certificate is written into 
# $TEST_CLIENT_FILE.cert.pem
$OPENSSL_CMD x509 -req -days $DAYS \
    -in $CERTS_DIR/$TEST_CLIENT_FILE.req.pem \
    -CA $CERTS_DIR/$TEST_CA_FILE.cert.pem \
    -CAkey $KEYS_DIR/$TEST_CA_FILE.key.pem \
	-extfile $OPENSSL_DIR/openssl.cnf \
	-extensions v3_req \
    -out $CERTS_DIR/$TEST_CLIENT_FILE.cert.pem -CAcreateserial -sm3

# Display the certificate 
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_CLIENT_FILE.cert.pem -text

# Place the certificate and key in a common file
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_CLIENT_FILE.cert.pem -issuer -subject \
	 > $COMBO_DIR/$TEST_CLIENT_FILE.pem
$CAT $KEYS_DIR/$TEST_CLIENT_FILE.key.pem >> $COMBO_DIR/$TEST_CLIENT_FILE.pem

# Remove the cert request file (no longer needed)
$RM $CERTS_DIR/$TEST_CLIENT_FILE.req.pem


echo "	GENERATING A TEST CLIENT ENCRYPT CERTIFICATE (on elliptic curve $TEST_CLIENT_CURVE)"
echo "	==================================================================================="
# Generate a new certificate request in $TEST_CLIENT_FILE.req.pem. A 
# new ecdsa (actually ECC) key pair is generated on the parameters in
# $TEST_CLIENT_CURVE.pem and the private key is saved in 
# $TEST_CLIENT_FILE.key.pem
# WARNING: By using the -nodes option, we force the private key to be 
# stored in the clear (rather than encrypted with a password).
$OPENSSL_CMD req -config eccencuser.cnf -nodes -subj "$TEST_CLIENT_ENC_DN" \
	     -keyout $KEYS_DIR/$TEST_CLIENT_ENC_FILE.key.pem \
	     -newkey ec:$TEST_CLIENT_CURVE.pem -new \
	     -out $CERTS_DIR/$TEST_CLIENT_ENC_FILE.req.pem -sm3

# Sign the certificate request in $TEST_CLIENT_FILE.req.pem using the
# CA certificate in $TEST_CA_FILE.cert.pem and the CA private key in
# $TEST_CA_FILE.key.pem. Since we do not have an existing serial number
# file for this CA, create one. Make the certificate valid for $DAYS days
# from the time of signing. The certificate is written into 
# $TEST_CLIENT_FILE.cert.pem
$OPENSSL_CMD x509 -req -days $DAYS \
    -in $CERTS_DIR/$TEST_CLIENT_ENC_FILE.req.pem \
    -CA $CERTS_DIR/$TEST_CA_FILE.cert.pem \
    -CAkey $KEYS_DIR/$TEST_CA_FILE.key.pem \
	-extfile $OPENSSL_DIR/openssl.cnf \
	-extensions v3enc_req \
    -out $CERTS_DIR/$TEST_CLIENT_ENC_FILE.cert.pem -CAcreateserial -sm3

# Display the certificate 
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_CLIENT_ENC_FILE.cert.pem -text

# Place the certificate and key in a common file
$OPENSSL_CMD x509 -in $CERTS_DIR/$TEST_CLIENT_ENC_FILE.cert.pem -issuer -subject \
	 > $COMBO_DIR/$TEST_CLIENT_ENC_FILE.pem
$CAT $KEYS_DIR/$TEST_CLIENT_ENC_FILE.key.pem >> $COMBO_DIR/$TEST_CLIENT_ENC_FILE.pem

# Remove the cert request file (no longer needed)
$RM $CERTS_DIR/$TEST_CLIENT_ENC_FILE.req.pem

# Verfiy Cert chain
echo "Verify $TEST_SERVER_FILE use $TEST_CA_FILE.cert.pem"
$OPENSSL_CMD verify -CAfile $CERTS_DIR/$TEST_CA_FILE.cert.pem $CERTS_DIR/$TEST_SERVER_FILE.pem
echo "Verify $TEST_SERVER_ENC_FILE use $TEST_CA_FILE.cert.pem"
$OPENSSL_CMD verify -CAfile $CERTS_DIR/$TEST_CA_FILE.cert.pem $CERTS_DIR/$TEST_SERVER_ENC_FILE.pem
echo "Verify $TEST_CLIENT_FILE use $TEST_CA_FILE.cert.pem"
$OPENSSL_CMD verify -CAfile $CERTS_DIR/$TEST_CA_FILE.cert.pem $CERTS_DIR/$TEST_CLIENT_FILE.pem
echo "Verify $TEST_CLIENT_ENC_FILE use $TEST_CA_FILE.cert.pem"
$OPENSSL_CMD verify -CAfile $CERTS_DIR/$TEST_CA_FILE.cert.pem $CERTS_DIR/$TEST_CLIENT_ENC_FILE.pem

