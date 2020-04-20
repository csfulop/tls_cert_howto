#!/bin/bash -e

OUT=out


function init() {
  rm -rf $OUT
  mkdir $OUT
}


function generateCA() {
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
  openssl verify \
    -CAfile $OUT/ca-cert.pem \
    $OUT/server-cert.pem
}


function main() {
  init
  generateCA
  generateServerCert
  verifyServerCert
}

main
