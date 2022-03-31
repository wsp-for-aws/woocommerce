FROM wordpress:5-apache

RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

ADD scripts/ /
RUN chmod +x /*.sh

ENTRYPOINT ["/new-entrypoint.sh"]
CMD ["apache2-foreground"]