#!/bin/bash -ex

# FIMXE: get from cli param
OPT_NO_PASSWORD="-nodes"
PW_NAME_PART=""
# OPT_NO_PASSWORD=""
# PW_NAME_PART="-pw"

OUT=out${PW_NAME_PART}


function init() {
  rm -rf $OUT
  mkdir $OUT
}


function generateCACert() {
  # generate self signed cert (with public key) and private key
  openssl req -x509 -newkey rsa:4096 -days 365 $OPT_NO_PASSWORD \
    -keyout $OUT/ca${PW_NAME_PART}-key.pem \
    -out $OUT/ca${PW_NAME_PART}-cert.pem \
    -subj "/C=HU/L=Leanyfalu/O=FCs CA Co./CN=ca.fcs.hu"

  # output the CA cert in text format
  openssl x509 -in $OUT/ca${PW_NAME_PART}-cert.pem -noout -text
}


function generateServerCert() {
  # generate server CSR (Certificate Signing Request)
  openssl req -newkey rsa:4096 $OPT_NO_PASSWORD \
    -keyout $OUT/server${PW_NAME_PART}-key.pem \
    -out $OUT/server${PW_NAME_PART}-req.pem \
    -subj "/C=HU/L=Leanyfalu/O=FCs Server Co./CN=server.fcs.hu"

  # sign the CSR with the CA private key
  openssl x509 -req -days 365 \
    -in $OUT/server${PW_NAME_PART}-req.pem \
    -CA $OUT/ca${PW_NAME_PART}-cert.pem \
    -CAkey $OUT/ca${PW_NAME_PART}-key.pem \
    -CAcreateserial \
    -out $OUT/server${PW_NAME_PART}-cert.pem \
    -extfile server-ext.cnf

  # output the server cert in text format
  openssl x509 -in $OUT/server${PW_NAME_PART}-cert.pem -noout -text
}


function verifyServerCert() {
  # issuer of the cert
  openssl x509 -in $OUT/server${PW_NAME_PART}-cert.pem -noout -issuer

  # subject of the CA cert
  openssl x509 -in $OUT/ca${PW_NAME_PART}-cert.pem -noout -subject

  openssl verify \
    -CAfile $OUT/ca${PW_NAME_PART}-cert.pem \
    $OUT/server${PW_NAME_PART}-cert.pem
}


function generateIntermediateCACert() {
  # generate Intermediate CA CSR (Certificate Signing Request)
  openssl req -newkey rsa:4096 $OPT_NO_PASSWORD \
    -extensions v3_ca -reqexts v3_req \
    -keyout $OUT/intermediateca${PW_NAME_PART}-key.pem \
    -out $OUT/intermediateca${PW_NAME_PART}-req.pem \
    -subj "/C=HU/L=Leanyfalu/O=FCs IntermediateCA Co./CN=intermediateca.fcs.hu"

  # sign the CSR with the CA private key
  openssl x509 -req -days 365 \
    -extfile v3_intermediateca_ext.cnf \
    -in $OUT/intermediateca${PW_NAME_PART}-req.pem \
    -CA $OUT/ca${PW_NAME_PART}-cert.pem \
    -CAkey $OUT/ca${PW_NAME_PART}-key.pem \
    -CAcreateserial \
    -out $OUT/intermediateca${PW_NAME_PART}-cert.pem

  # output the Intermediate CA cert in text format
  openssl x509 -in $OUT/intermediateca${PW_NAME_PART}-cert.pem -noout -text
}


function generateServerCertWithIntermediateCA() {
  # generate server CSR (Certificate Signing Request)
  openssl req -newkey rsa:4096 $OPT_NO_PASSWORD \
    -keyout $OUT/server2${PW_NAME_PART}-key.pem \
    -out $OUT/server2${PW_NAME_PART}-req.pem \
    -subj "/C=HU/L=Leanyfalu/O=FCs Server With IntermediateCA Co./CN=server2.fcs.hu"

  # sign the CSR with the CA private key
  openssl x509 -req -days 365 \
    -in $OUT/server2${PW_NAME_PART}-req.pem \
    -CA $OUT/intermediateca${PW_NAME_PART}-cert.pem \
    -CAkey $OUT/intermediateca${PW_NAME_PART}-key.pem \
    -CAcreateserial \
    -out $OUT/server2${PW_NAME_PART}-cert.pem \
    -extfile server2-ext.cnf

  # output the server cert in text format
  openssl x509 -in $OUT/server2${PW_NAME_PART}-cert.pem -noout -text
}


function verifyServerCertWithIntermediateCA() {
  # issuer of the cert
  openssl x509 -in $OUT/server2${PW_NAME_PART}-cert.pem -noout -issuer

  # subject and issuer of the IntermediateCA cert
  openssl x509 -in $OUT/intermediateca${PW_NAME_PART}-cert.pem -noout -subject -issuer

  # subject of the CA cert
  openssl x509 -in $OUT/ca${PW_NAME_PART}-cert.pem -noout -subject

  openssl verify \
    -CAfile $OUT/ca${PW_NAME_PART}-cert.pem \
    -untrusted $OUT/intermediateca${PW_NAME_PART}-cert.pem \
    $OUT/server2${PW_NAME_PART}-cert.pem
}


function main() {
  init

  generateCACert

  generateServerCert
  verifyServerCert

  generateIntermediateCACert

  generateServerCertWithIntermediateCA
  verifyServerCertWithIntermediateCA

  # FIXME: chain cert

  # FIXME: install Root CA into the system and use it for validation
}

main |& tee log.txt
