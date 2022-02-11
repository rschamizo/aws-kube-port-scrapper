FROM alpine:3.14.2

WORKDIR /home

COPY scrap-ports.sh scrap-ports.sh
RUN chmod +x scrap-ports.sh

CMD ["/bin/sh","scrap-ports.sh"]