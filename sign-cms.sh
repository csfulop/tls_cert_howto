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


function signWithCaCert() {
  # create signature in PEM format
  openssl cms -sign \
    -signer $CA-cert.pem \
    -inkey $CA-key.pem \
    -in $0 \
    -binary \
    -outform PEM \
    -out ${0}.ca.sig

  # print signature content
  openssl cms -cmsout -print \
    -inform PEM \
    -in ${0}.ca.sig
}


function validateCaSignature() {
  openssl cms -verify \
    -in ${0}.ca.sig \
    -inform PEM \
    -CAfile $CA-cert.pem \
    -binary \
    -content $0 \
    -out /dev/null
}


function signWithServerCert() {
  # create signature in PEM format
  openssl cms -sign \
    -signer $SERVER-cert.pem \
    -inkey $SERVER-key.pem \
    -in $0 \
    -binary \
    -outform PEM \
    -out ${0}.server.sig

  # print signature content
  openssl cms -cmsout -print \
    -inform PEM \
    -in ${0}.server.sig
}

function validateServerSignature() {
  openssl cms -verify \
    -in ${0}.server.sig \
    -inform PEM \
    -CAfile $CA-cert.pem \
    -binary \
    -content $0 \
    -out /dev/null
}


function signWithServer2Cert() {
  # create signature in PEM format
  # add the intermediate CA cert, too
  openssl cms -sign \
    -signer $SERVER2-cert.pem \
    -certfile $INTERMEDIATE_CA-cert.pem \
    -inkey $SERVER2-key.pem \
    -in $0 \
    -binary \
    -outform PEM \
    -out ${0}.server2.sig

  # print signature content
  openssl cms -cmsout -print \
    -inform PEM \
    -in ${0}.server2.sig
}

function validateServer2Signature() {
  openssl cms -verify \
    -in ${0}.server2.sig \
    -inform PEM \
    -CAfile $CA-cert.pem \
    -binary \
    -content $0 \
    -out /dev/null
}


function main() {
  signWithCaCert
  validateCaSignature

  signWithServerCert
  validateServerSignature

  signWithServer2Cert
  validateServer2Signature
}


main |& tee sign-cms.log
