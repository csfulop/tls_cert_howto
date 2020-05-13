#!/bin/bash -eux

# FIMXE: get from cli param
PASSWORD=0

if (( PASSWORD == 1 )); then
  OPT_NO_PASSWORD=""
  PW_NAME_PART="-pw"
else
  OPT_NO_PASSWORD="-nodes"
  PW_NAME_PART=""
fi

OUT=out${PW_NAME_PART}
CA=$OUT/ca${PW_NAME_PART}
INTERMEDIATE_CA=$OUT/intermediateca${PW_NAME_PART}
SERVER=$OUT/server${PW_NAME_PART}
SERVER2=$OUT/server2${PW_NAME_PART}


function init() {
  rm -rf $OUT
  mkdir $OUT
}


function generateCACert() {
  # generate self signed cert (with public key) and private key
  openssl req -x509 -newkey rsa:4096 -days 365 $OPT_NO_PASSWORD \
    -keyout $CA-key.pem \
    -out $CA-cert.pem \
    -subj "/C=HU/L=Leanyfalu/O=FCs CA Co./CN=ca.fcs.hu"

  # output the CA cert in text format
  openssl x509 -in $CA-cert.pem -noout -text
}


function generateServerCert() {
  # generate server CSR (Certificate Signing Request)
  openssl req -newkey rsa:4096 $OPT_NO_PASSWORD \
    -keyout $SERVER-key.pem \
    -out $SERVER-req.pem \
    -subj "/C=HU/L=Leanyfalu/O=FCs Server Co./CN=server.fcs.hu"

  # sign the CSR with the CA private key
  openssl x509 -req -days 365 \
    -in $SERVER-req.pem \
    -CA $CA-cert.pem \
    -CAkey $CA-key.pem \
    -CAcreateserial \
    -out $SERVER-cert.pem \
    -extfile server-ext.cnf

  # output the server cert in text format
  openssl x509 -in $SERVER-cert.pem -noout -text
}


function verifyServerCert() {
  # issuer of the cert
  openssl x509 -in $SERVER-cert.pem -noout -issuer

  # subject of the CA cert
  openssl x509 -in $CA-cert.pem -noout -subject

  openssl verify \
    -CAfile $CA-cert.pem \
    $SERVER-cert.pem
}


function generateIntermediateCACert() {
  # generate Intermediate CA CSR (Certificate Signing Request)
  openssl req -newkey rsa:4096 $OPT_NO_PASSWORD \
    -extensions v3_ca -reqexts v3_req \
    -keyout $INTERMEDIATE_CA-key.pem \
    -out $INTERMEDIATE_CA-req.pem \
    -subj "/C=HU/L=Leanyfalu/O=FCs IntermediateCA Co./CN=intermediateca.fcs.hu"

  # sign the CSR with the CA private key
  openssl x509 -req -days 365 \
    -extfile v3_intermediateca_ext.cnf \
    -in $INTERMEDIATE_CA-req.pem \
    -CA $CA-cert.pem \
    -CAkey $CA-key.pem \
    -CAcreateserial \
    -out $INTERMEDIATE_CA-cert.pem

  # output the Intermediate CA cert in text format
  openssl x509 -in $INTERMEDIATE_CA-cert.pem -noout -text
}


function generateServerCertWithIntermediateCA() {
  # generate server CSR (Certificate Signing Request)
  openssl req -newkey rsa:4096 $OPT_NO_PASSWORD \
    -keyout $SERVER2-key.pem \
    -out $SERVER2-req.pem \
    -subj "/C=HU/L=Leanyfalu/O=FCs Server With IntermediateCA Co./CN=server2.fcs.hu"

  # sign the CSR with the CA private key
  openssl x509 -req -days 365 \
    -in $SERVER2-req.pem \
    -CA $INTERMEDIATE_CA-cert.pem \
    -CAkey $INTERMEDIATE_CA-key.pem \
    -CAcreateserial \
    -out $SERVER2-cert.pem \
    -extfile server2-ext.cnf

  # output the server cert in text format
  openssl x509 -in $SERVER2-cert.pem -noout -text
}


function verifyServerCertWithIntermediateCA() {
  # issuer of the cert
  openssl x509 -in $SERVER2-cert.pem -noout -issuer

  # subject and issuer of the IntermediateCA cert
  openssl x509 -in $INTERMEDIATE_CA-cert.pem -noout -subject -issuer

  # subject of the CA cert
  openssl x509 -in $CA-cert.pem -noout -subject

  openssl verify \
    -CAfile $CA-cert.pem \
    -untrusted $INTERMEDIATE_CA-cert.pem \
    $SERVER2-cert.pem
}


function createCertChain() {
  cat $SERVER2-cert.pem $INTERMEDIATE_CA-cert.pem > $SERVER2-cert-chain.pem

  openssl crl2pkcs7 -nocrl -certfile $SERVER2-cert-chain.pem | openssl pkcs7 -print_certs -noout
}


function main() {
  init

  generateCACert

  generateServerCert
  verifyServerCert

  generateIntermediateCACert

  generateServerCertWithIntermediateCA
  verifyServerCertWithIntermediateCA

  createCertChain

  # FIXME: install Root CA into the system and use it for validation
}


main |& tee cert.log
