#!/bin/sh -x
# Calls the generate-self-signed-cert.sh certificate generation script to generate X509 certs

SETUP_DOMAIN="setup"
SETUP_PATH="/var/local/oobe-web-setup.cert"
SETUP_PATH_TEMP="/var/local/temporary-oobe-web-setup.cert"

OPENSSL=/usr/bin/openssl

generateCerts()
{
    logger -t system -p local4.info "I initscripts:generateCerts::Starting Generating $SETUP_PATH_TEMP"

    # if it does not, call generate-self-signed-cert.sh and generate it
    /usr/local/bin/generate-self-signed-cert.sh $SETUP_DOMAIN $SETUP_PATH_TEMP

    logger -t system -p local4.info "I initscripts:generateCerts::Done Generating $SETUP_PATH_TEMP"

    mv -f $SETUP_PATH_TEMP $SETUP_PATH

    logger -t system -p local4.info "I initscripts:generateCerts::Done Moving to $SETUP_PATH"
}

if [ ! -f $SETUP_PATH ]; then
    # verify if target cert exists
    generateCerts
else
    # verify if cert is of sha256
    SHA2_CHECK=$(${OPENSSL} x509 -text -in ${SETUP_PATH} -noout -text | grep "Signature Algorithm" | grep -c "sha256WithRSAEncryption")
    if [ "${SHA2_CHECK}" -eq 0 ]; then
        logger -t system -p local4.info "I initscripts:generateCerts::Deleting ${SETUP_PATH}"
        rm ${SETUP_PATH}
        generateCerts
    fi
fi

exit 0
