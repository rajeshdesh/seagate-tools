#!/usr/bin/env bash
#
#
# Copyright (c) 2022 Seagate Technology LLC and/or its Affiliates
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# For any questions about this software or licensing,
# please email opensource@seagate.com or cortx-questions@seagate.com.
#
# -*- coding: utf-8 -*-

set -x
SCRIPT_PATH="$(readlink -f $0)"
SCRIPT_DIR="${SCRIPT_PATH%/*}"
source "$SCRIPT_DIR/../../perfline.conf"



function parse_args()
{
    while [[ $# -gt 0 ]]; do
        case $1 in
            -b|--BucketName)
                BUCKET_NAME="$2"
                shift
                ;;
            -n|--NumSample)
                NUM_SAMPLES="$2"
                shift
                ;;
            -c|--NumClients)
                NUM_CLIENTS="$2"
                shift
                ;;
            -o|--ObjSize)
                OBJ_SIZE="$2"
                shift
                ;;
            -e|--EndPoint)
                ENDPOINT="$2"
                shift
                ;;
            -h|--help)
                echo "help information"
                exit 0
                ;;
            *)
                echo "unknown parameter: $1"
                exit 1
                ;;
        esac
        shift
    done
}


function parse_creds()
{
    if [[ -n "$ACCESS_KEY" && -n "$SECRET_KEY" ]]; then
        return 0
    fi
    ACCESS_KEY=$(egrep ^[^#] ~/.aws/credentials | grep aws_access_key_id | cut -d= -f2 | tr -d " ")
    SECRET_KEY=$(egrep ^[^#] ~/.aws/credentials | grep aws_secret_access_key | cut -d= -f2 | tr -d " ")
}


function run_s3bench()
{
    local format="Parameters:label;Parameters:numClients;Parameters:objectSize (MB);Parameters:copies;-Parameters:sampleReads;-Parameters:readObj;-Parameters:headObj;-Parameters:putObjTag;-Parameters:getObjTag;-Parameters:TLSHandshakeTimeout;-Parameters:bucket;-Parameters:connectTimeout;-Parameters:deleteAtOnce;-Parameters:deleteClients;-Parameters:deleteOnly;-Parameters:endpoints;-Parameters:httpClientTimeout;-Parameters:idleConnTimeout;-Parameters:maxIdleConnsPerHost;-Parameters:multipartSize;-Parameters:numTags;-Parameters:objectNamePrefix;-Parameters:protocolDebug;-Parameters:reportFormat;-Parameters:responseHeaderTimeout;-Parameters:s3Disable100Continue;-Parameters:profile;-Parameters:s3MaxRetries;-Parameters:skipRead;-Parameters:skipWrite;-Parameters:tagNamePrefix;-Parameters:tagValPrefix;-Parameters:validate;-Parameters:zero;-Parameters:outstream;-Parameters:outtype;Tests:Operation;Tests:RPS;Tests:Total Requests Count;Tests:Errors Count;Tests:Total Throughput (MB/s);Tests:Total Duration (s);Tests:Total Transferred (MB);Tests:Duration Max;Tests:Duration Avg;Tests:Duration Min;Tests:Ttfb Max;Tests:Ttfb Avg;Tests:Ttfb Min;-Tests:Duration 25th-ile;-Tests:Duration 50th-ile;-Tests:Duration 75th-ile;-Tests:Ttfb 25th-ile;-Tests:Ttfb 50th-ile;-Tests:Ttfb 75th-ile;-Tests:Errors;-Version;"

    if [[ -f "s3bench_report.csv" ]]; then
        $PERFLINE_DIR/bin/s3bench_perfline -region us-east-1 -reportFormat "$format" -accessKey $ACCESS_KEY -accessSecret $SECRET_KEY -bucket $BUCKET_NAME -numSamples $NUM_SAMPLES -objectSize $OBJ_SIZE -numClients $NUM_CLIENTS -endpoint "$ENDPOINT" -o s3bench_report.csv -t csv+
    else
        $PERFLINE_DIR/bin/s3bench_perfline -region us-east-1 -reportFormat "$format" -accessKey $ACCESS_KEY -accessSecret $SECRET_KEY -bucket $BUCKET_NAME -numSamples $NUM_SAMPLES -objectSize $OBJ_SIZE -numClients $NUM_CLIENTS -endpoint "$ENDPOINT" -o s3bench_report.csv -t csv
    fi


}

parse_args $@
parse_creds
run_s3bench
