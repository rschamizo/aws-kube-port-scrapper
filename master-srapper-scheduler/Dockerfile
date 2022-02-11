FROM centos:7

WORKDIR /home

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && yum -y install unzip \
    && unzip awscliv2.zip \
    && ./aws/install 
    
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl \
    && mv ./kubectl /usr/local/bin/kubectl

RUN yum install -y wget \
    && wget https://github.com/mikefarah/yq/releases/download/v4.18.1/yq_linux_amd64 -O /usr/bin/yq \
    && chmod +x /usr/bin/yq \
    && wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O /usr/bin/jq \
    && chmod +x /usr/bin/jq

COPY scrapper-scheduler.sh scrapper-scheduler.sh
COPY job.yaml job.yaml
RUN chmod +x scrapper-scheduler.sh

CMD ["/bin/sh","scrapper-scheduler.sh"]