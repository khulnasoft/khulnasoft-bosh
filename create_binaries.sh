#!/bin/bash
cd /root/khulnasoft/src
make deps
make clean
make deps && make TARGET=server
cd ../..
tar -czvf khulnasoft-manager-$WAZUH_VERSION.tar.gz -C khulnasoft .
cd /root/khulnasoft/src
make clean
make deps && make TARGET=agent
cd ../..
tar -czvf khulnasoft-agent-$WAZUH_VERSION.tar.gz -C khulnasoft .
mv /root/*.gz /root/packages/