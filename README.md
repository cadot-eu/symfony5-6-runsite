# symfony5
Docker for symfony 5/php 8.3.1 with:
- composer
- yarn
- nodejs
- npm
- pandoc
- ghostscript
- memcache
- opcache
- mbstring
- wget
- curl
- imagemagick
- git
- tree
- nano
- environnement PANTHER
- php.iuni
- apache.conf
- eml2svg

## execution in your symfony directory
`
docker run -d -p 80:80  --name symfony5 -v .:/app cadotinfo/symfony5
`
## or by docker-compose with traefik
```bash
...
image: cadotinfo/symfony5 
    container_name: symfony5
    volumes:
      - /home/ubuntu/my_symfony:/app
    networks:
      - web
    restart: always
    labels:
        - "traefik.enable=true"
        - "traefik.http.routers.symfony5.rule=Host(`symfony5.website.com`)"
...
```
# symfony5-6-runsite
