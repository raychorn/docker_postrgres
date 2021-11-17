FROM ubuntu:focal

COPY entrypoint.sh entrypoint.sh 
COPY postgresql.conf postgresql.conf
COPY pg_hba.conf pg_hba.conf

RUN chmod +x entrypoint.sh

ENTRYPOINT [ "/bin/bash", "-c" ]
CMD [ "./entrypoint.sh" ]
