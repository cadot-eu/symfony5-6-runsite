#!/bin/bash

XDEBUG_INI="/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini"

if [ -f "$XDEBUG_INI.disabled" ]; then
  mv "$XDEBUG_INI.disabled" "$XDEBUG_INI"
  echo "Xdebug enabled"
else
  mv "$XDEBUG_INI" "$XDEBUG_INI.disabled"
  echo "Xdebug disabled"
fi

# Redémarrage d'Apache pour appliquer les changements
apache2-foreground
