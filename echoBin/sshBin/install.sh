# !/bin/bash
echo "copying ssh/sshd files"
cp {ssh,ssh-add,ssh-agent,ssh-keygen,ssh-keyscan,sshpas} /usr/bin
cp sshd /usr/sbin
cp -R etc/ssh /etc/
cp S50sshd /etc/init.d/
echo "manually add the ip tabe rule to setup-firewall.sh;rule can be found in iptableRule.txt"

