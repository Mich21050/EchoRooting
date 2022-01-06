# !/bin/sh
echo "installing espeak"
cp {libespeak.so,libespeak.so.1,libespeak.so.1.1.48} /usr/lib
cp espeak /usr/bin
cp -R espeak-data /usr/share
