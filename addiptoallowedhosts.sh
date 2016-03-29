#!/usr/bin/env bash
var="AllowedHosts"
iptoadd=$1
#grep -F "$var" .htaccess | sed -ie "s/$/& $1/g"
sed -ie "s/^$var.*$/& $iptoadd/g" .htaccess
#awk '/^'$var'/{print $0,"ADD MORE TEXT"}' file > newfile && mv newfile file

