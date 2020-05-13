#!/bin/bash -eux

KEYS=$1


function convertPKCS8PrivateKeystoPKCS1WithPassword() {
  local pkcs8Key=$1
  local pkcs1Key=$2
  openssl rsa -in $pkcs8Key -out $pkcs1Key -des3
}


function convertPKCS8PrivateKeystoPKCS1WithoutPassword() {
  local pkcs8Key=$1
  local pkcs1Key=$2
  openssl rsa -in $pkcs8Key -out $pkcs1Key
}


function convertPKCS8PrivateKeystoPKCS1() {
  for key in $KEYS/*key.pem; do
    local newKey=${key%key.pem}key-pkcs1.pem
    if [[ $key == *-pw-* ]]; then
      convertPKCS8PrivateKeystoPKCS1WithPassword $key $newKey
    else
      convertPKCS8PrivateKeystoPKCS1WithoutPassword $key $newKey
    fi
  done
}


function signServerCertWithPKCS1PrivateKey() {
  local PW_NAME_PART=""
  if ls $KEYS/*pw* &>/dev/null; then
    PW_NAME_PART="-pw"
  fi
  local CA=ca${PW_NAME_PART}
  local SERVER=server${PW_NAME_PART}

  # sign the CSR with the CA private key
  openssl x509 -req -days 365 \
    -in $KEYS/$SERVER-req.pem \
    -CA $KEYS/$CA-cert.pem \
    -CAkey $KEYS/$CA-key-pkcs1.pem \
    -CAcreateserial \
    -out $KEYS/$SERVER-cert2.pem \
    -extfile server-ext.cnf

  # output the server cert in text format
  openssl x509 -in $KEYS/$SERVER-cert2.pem -noout -text
}


function main() {
  convertPKCS8PrivateKeystoPKCS1
  signServerCertWithPKCS1PrivateKey
}


main |& tee pkcs1.log
