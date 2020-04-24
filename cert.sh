#!/bin/bash -ex

OUT=out


function init() {
  rm -rf $OUT
  mkdir $OUT
}


function generateCACert() {
  # generate self signed cert (with public key) and private key
  openssl req -x509 -newkey rsa:4096 -days 365 -nodes \
    -keyout $OUT/ca-key.pem \
    -out $OUT/ca-cert.pem \
    -subj "/C=HU/L=Leanyfalu/O=FCs CA Co./CN=ca.fcs.hu"

  # output the CA cert in text format
  openssl x509 -in $OUT/ca-cert.pem -noout -text
}


function generateServerCert() {
  # generate server CSR (Certificate Signing Request)
  openssl req -newkey rsa:4096 -nodes \
    -keyout $OUT/server-key.pem \
    -out $OUT/server-req.pem \
    -subj "/C=HU/L=Leanyfalu/O=FCs Server Co./CN=server.fcs.hu"

  # sign the CSR with the CA private key
  openssl x509 -req -days 365 \
    -in $OUT/server-req.pem \
    -CA $OUT/ca-cert.pem \
    -CAkey $OUT/ca-key.pem \
    -CAcreateserial \
    -out $OUT/server-cert.pem \
    -extfile server-ext.cnf

  # output the server cert in text format
  openssl x509 -in $OUT/server-cert.pem -noout -text
}


function verifyServerCert() {
  # issuer of the cert
  openssl x509 -in $OUT/server-cert.pem -noout -issuer

  # subject of the CA cert
  openssl x509 -in $OUT/ca-cert.pem -noout -subject

  openssl verify \
    -CAfile $OUT/ca-cert.pem \
    $OUT/server-cert.pem
}


function generateIntermediateCACert() {
  # generate Intermediate CA CSR (Certificate Signing Request)
  openssl req -newkey rsa:4096 -nodes \
    -extensions v3_ca -reqexts v3_req \
    -keyout $OUT/intermediateca-key.pem \
    -out $OUT/intermediateca-req.pem \
    -subj "/C=HU/L=Leanyfalu/O=FCs IntermediateCA Co./CN=intermediateca.fcs.hu"

  # sign the CSR with the CA private key
  openssl x509 -req -days 365 \
    -extfile v3_intermediateca_ext.cnf \
    -in $OUT/intermediateca-req.pem \
    -CA $OUT/ca-cert.pem \
    -CAkey $OUT/ca-key.pem \
    -CAcreateserial \
    -out $OUT/intermediateca-cert.pem

  # output the Intermediate CA cert in text format
  openssl x509 -in $OUT/intermediateca-cert.pem -noout -text
}


function generateServerCertWithIntermediateCA() {
  # generate server CSR (Certificate Signing Request)
  openssl req -newkey rsa:4096 -nodes \
    -keyout $OUT/server2-key.pem \
    -out $OUT/server2-req.pem \
    -subj "/C=HU/L=Leanyfalu/O=FCs Server With IntermediateCA Co./CN=server2.fcs.hu"

  # sign the CSR with the CA private key
  openssl x509 -req -days 365 \
    -in $OUT/server2-req.pem \
    -CA $OUT/intermediateca-cert.pem \
    -CAkey $OUT/intermediateca-key.pem \
    -CAcreateserial \
    -out $OUT/server2-cert.pem \
    -extfile server2-ext.cnf

  # output the server cert in text format
  openssl x509 -in $OUT/server2-cert.pem -noout -text
}


function verifyServerCertWithIntermediateCA() {
  # issuer of the cert
  openssl x509 -in $OUT/server2-cert.pem -noout -issuer

  # subject and issuer of the IntermediateCA cert
  openssl x509 -in $OUT/intermediateca-cert.pem -noout -subject -issuer

  # subject of the CA cert
  openssl x509 -in $OUT/ca-cert.pem -noout -subject

  openssl verify \
    -CAfile $OUT/ca-cert.pem \
    -untrusted $OUT/intermediateca-cert.pem \
    $OUT/server2-cert.pem
}


function main() {
  init

  generateCACert

  generateServerCert
  verifyServerCert

  generateIntermediateCACert

  generateServerCertWithIntermediateCA
  verifyServerCertWithIntermediateCA
}

main |& tee log.txt
