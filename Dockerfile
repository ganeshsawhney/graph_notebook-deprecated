FROM amazonlinux:latest
USER root
COPY ./install.sh /root/install.sh
COPY ./service.sh /root/service.sh
COPY ./graph_notebook.tar.gz /root/graph_notebook.tar.gz
RUN yum install -y wget curl tar gzip which
RUN /root/install.sh
ENTRYPOINT [ "bash","-c","/root/service.sh" ]
