#!/bin/sh

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# -----------------------------------------------------------------------------
# Stop script for the CATALINA Server
#
# $Id: shutdown.sh 1130937 2011-06-03 08:27:13Z markt $
# -----------------------------------------------------------------------------

# resolve links - $0 may be a softlink
PRG="$0"

while [ -h "$PRG" ] ; do
  ls=`ls -ld "$PRG"`
  link=`expr "$ls" : '.*-> \(.*\)$'`
  if expr "$link" : '/.*' > /dev/null; then
    PRG="$link"
  else
    PRG=`dirname "$PRG"`/"$link"
  fi
done
PRGDIR=$(cd `dirname "$PRG"`; pwd)
EXECUTABLE=catalina.sh

# Check that target executable exists
if $os400; then
  # -x will Only work on the os400 if the files are: 
  # 1. owned by the user
  # 2. owned by the PRIMARY group of the user
  # this will not work if the user belongs in secondary groups
  eval
else 
  if [ ! -x "$PRGDIR"/"$EXECUTABLE" ]; then
    echo "Cannot find $PRGDIR/$EXECUTABLE"
    echo "The file is absent or does not have execute permission"
    echo "This file is needed to run this program"
    exit 1
  fi
fi

pid=`ps -ef | grep "$PRGDIR" | grep -v $0 | grep -v "grep" | awk '{print $2}'` || return $?
for num in $pid; do
  "$PRGDIR"/"$EXECUTABLE" stop "$@"; reval=$?
  if [[ $reval -eq 0 ]]; then echo "Shutdown tomcat success!"; else echo "Shudown tomcat failure!"; exit $reval; fi
  kill -9 $pid "$@"; reval=$?
  if [[ $reval -eq 0 ]]; then echo "Kill process $num success!"; else echo "Kill process $num failure"; exit $reval; fi
done
echo "Tomcat is not running!"
rm -rf $PRGDIR/../work/Catalina "$@"; reval=$?
if [[ $reval -eq 0 ]]; then echo "Clean cache success!"; else echo "Clean cache failure!"; exit $reval; fi
"$PRGDIR"/"$EXECUTABLE" start "$@"; reval=$?
if [[ $reval -eq 0 ]]; then echo "Startup tomcat success!"; else echo "Startup tomcat failure!"; exit $reval; fi
