# export TALK=AdvancedPgBackRest;export TALK_PATH=~/Documents/Talk
# docker build -f ./Dockerfile -t talk/u22 .
# docker run --rm -v ${TALK_PATH?}/template:/template -v ${TALK_PATH?}/${TALK?}:/talk talk/u22 bash -c "cd /talk/slides && make -f /template/Makefile"
FROM ubuntu:jammy

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y texlive-latex-extra texlive-font-utils inkscape make
