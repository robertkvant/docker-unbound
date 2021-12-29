FROM alpine:latest

# https://www.nlnetlabs.nl/documentation/unbound/howto-anchor/
# - root.key -
# Unbound must be able to read and write it, to keep it up to date with the latest key(s). 
# It must therefore reside within the chroot of unbound (if that is used). 
# Access rights are world readable, user unbound write only.

RUN apk update && apk upgrade \
    && apk add unbound tzdata curl \
    && cp /usr/share/zoneinfo/Europe/Stockholm /etc/localtime \
    && echo "Europe/Stockholm" >  /etc/timezone \
    && apk del tzdata \
    && mkdir /etc/unbound/dnssec \
    && curl -s https://data.iana.org/root-anchors/root-anchors.xml \
       | awk -F "(<|>)" 'BEGIN{ORS=""}/<[KAD]/{if($2=="Digest"){o=$3"\n"}else{o=$3" "}print o}' \
       | awk '{print". IN DS"$0}' > /etc/unbound/dnssec/root.key \
    && unbound-anchor -4v -a /etc/unbound/dnssec/root.key \ 
    && chown unbound:unbound /etc/unbound/dnssec/root.key  \
    && chmod 744 /etc/unbound/dnssec/root.key \
    && curl -s https://www.internic.net/domain/named.root > /etc/unbound/root.hints


COPY ./unbound.conf /etc/unbound/
RUN unbound-checkconf

# Expose port 53 (udp/tcp)
EXPOSE 53/tcp
EXPOSE 53/udp

# Run unbound
ENTRYPOINT ["unbound"]

