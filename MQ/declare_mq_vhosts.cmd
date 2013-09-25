@echo off
set path=%PATH%;C:\Python26

rem python.exe rabbitmqadmin --help
rem python.exe rabbitmqadmin help subcommands
rem python.exe rabbitmqadmin help config

rem set HOST=devflax01
set HOST=devrma01

echo ============= ENRICHMENT ON %HOST% ==================
python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% declare vhost name="enrichment"
python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% declare permission vhost="enrichment" user="guest" configure=.* write=.* read=.*

python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% -V enrichment declare policy name="mirror+ha" pattern="" definition="{\"ha-mode\":\"all\",\"ha-sync-mode\":\"automatic\"}"

REM Auto Categorization WS
python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% -V enrichment declare exchange name=AutoCategorizationWS.FileContentEventMsg durable=true type="fanout"


REM Verity Categorization
python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% -V enrichment declare queue    name=qCategorizationSubscriber.FileContentEventMsg durable=true
python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% -V enrichment declare exchange name=CategorizationSubscriber.FileContentEventMsg durable=true type="fanout"

REM Semaphore Categorization
python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% -V enrichment declare queue    name=qSemaphoreSubscriber.FileContentEventMsg durable=true
python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% -V enrichment declare exchange name=SemaphoreSubscriber.FileContentEventMsg durable=true type="fanout"

REM Media Metadata
python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% -V enrichment declare queue    name=qMediaMetadataSubscriber.FileContentEventMsg durable=true
python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% -V enrichment declare exchange name=MediaMetadataSubscriber.FileContentEventMsg durable=true type="fanout"

REM FileSystemWebService
python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% -V enrichment declare queue    name=qFileSystemWebService.FileContentEventMsg durable=true
rem  FileSystemWebService send to "load" exchange

REM BINDINGS

REM AutoCategorizationWS => CategorizationSubscriber => SemaphoreSubscriber => MediaMetadataSubscriber => FileSystemWebService

python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% -V enrichment declare binding  source=AutoCategorizationWS.FileContentEventMsg destination=qCategorizationSubscriber.FileContentEventMsg routing_key="FileContentEventMsg" destination_type="queue"

python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% -V enrichment declare binding  source=CategorizationSubscriber.FileContentEventMsg destination=qSemaphoreSubscriber.FileContentEventMsg routing_key="FileContentEventMsg" destination_type="queue"

python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% -V enrichment declare binding  source=SemaphoreSubscriber.FileContentEventMsg destination=qMediaMetadataSubscriber.FileContentEventMsg routing_key="FileContentEventMsg" destination_type="queue"

python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% -V enrichment declare binding  source=MediaMetadataSubscriber.FileContentEventMsg destination=qFileSystemWebService.FileContentEventMsg routing_key="FileContentEventMsg" destination_type="queue"


echo ============= LOAD  ON %HOST% ==================
python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% declare vhost name="load"
python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% declare permission vhost="load" user="guest" configure=.* write=.* read=.*

python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% -V load declare policy name="mirror+ha" pattern="" definition="{\"ha-mode\":\"all\",\"ha-sync-mode\":\"automatic\"}"


REM FileSystemWebService
python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% -V load declare exchange name=FileSystemWebService.FileContentEventMsg durable=true type="fanout"

REM FLAX MS SOLR LOAD
python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% -V load declare queue    name=qFLAXSolrLoad.FileContentEventMsg durable=true

REM FLAX MONITOR
python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% -V load declare queue    name=qFLAXMonitor.FileContentEventMsg durable=true
python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% -V load declare exchange name=FLAXMonitor.FileMatchEventMsg durable=true type="fanout"

REM QUERY MATCH
python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% -V load declare queue    name=qQueryMatch.FileMatchEventMsg durable=true


REM BINDINGS

REM FileSystemWebService => FLAXSolrLoad 
REM FileSystemWebService => FLAXMonitor => QueryMatch

python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% -V load declare binding  source=FileSystemWebService.FileContentEventMsg destination=qFLAXSolrLoad.FileContentEventMsg routing_key="FileContentEventMsg" destination_type="queue"
python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% -V load declare binding  source=FileSystemWebService.FileContentEventMsg destination=qFLAXMonitor.FileContentEventMsg routing_key="FileContentEventMsg" destination_type="queue"

python.exe rabbitmqadmin -c serverconfig.conf  -N %HOST% -V load declare binding  source=FLAXMonitor.FileMatchEventMsg destination=qQueryMatch.FileMatchEventMsg routing_key="FileMatchEventMsg" destination_type="queue"

pause