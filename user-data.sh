#!/bin/bash

# grab and install packages
dnf update -y
dnf install -y dnf-plugins-core
dnf config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf install -y java-21-amazon-corretto-devel fontconfig terraform jenkins

# make new jenkins temp dir
mkdir -p /var/lib/jenkins/tmp
chown jenkins:jenkins /var/lib/jenkins/tmp
chmod 700 /var/lib/jenkins/tmp

# modify service unit to use new temp dir
mkdir -p /etc/systemd/system/jenkins.service.d
cat > /etc/systemd/system/jenkins.service.d/override.conf <<'EOF'
[Service]
Environment="JAVA_OPTS=-Djava.io.tmpdir=/var/lib/jenkins/tmp"
EOF

# install plugins
curl -fLs -o /tmp/jenkins-plugin-manager.jar \
  https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/2.14.0/jenkins-plugin-manager-2.14.0.jar

curl -fLs -o /tmp/plugins.yaml \ 
  https://raw.githubusercontent.com/lohodges/leeroyjenkins/master/plugins.yaml
#   https://raw.githubusercontent.com/aaron-dm-mcdonald/new-jenkins-s3-test/refs/heads/main/plugins.yaml

sudo -u jenkins java -jar /tmp/jenkins-plugin-manager.jar \
  --war /usr/share/java/jenkins.war \
  --plugin-download-directory /var/lib/jenkins/plugins \
  --plugin-file /tmp/plugins.yaml

# restart service
systemctl daemon-reload
systemctl enable --now jenkins