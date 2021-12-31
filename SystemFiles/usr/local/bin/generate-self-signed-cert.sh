#!/bin/sh -x
# A tool to quickly generate new certs

OPENSSL=/usr/bin/openssl

if [ $# -ne 1 ] && [ $# -ne 2 ]; then
  echo "Usage: $0 domain [outfile]" 1>&2
  exit 1
fi

common_name="${1}"

if [ $# -ne 2 ]; then
  outfile="${common_name}.cert"
else
  outfile="${2}"
fi

# Certificate lasts 126 years (and half a day)
$OPENSSL req -new -newkey rsa:2048 -sha256 -days 46021  -nodes -x509 -subj \
        "/C=US/ST=CA/L=Cupertino/O=Lab126/CN=${common_name}" -keyout ${outfile} -out ${outfile}
